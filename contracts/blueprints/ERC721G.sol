// SPDX-License-Identifier: MIT
/**
 *
 *    ███████╗██████╗  ██████╗███████╗██████╗  ██╗ ██████╗
 *    ██╔════╝██╔══██╗██╔════╝╚════██║╚════██╗███║██╔════╝
 *    █████╗  ██████╔╝██║         ██╔╝ █████╔╝╚██║██║  ███╗
 *    ██╔══╝  ██╔══██╗██║        ██╔╝ ██╔═══╝  ██║██║   ██║
 *    ███████╗██║  ██║╚██████╗   ██║  ███████╗ ██║╚██████╔╝
 *    ╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝  ╚══════╝ ╚═╝ ╚═════╝
 *
 *    ERC721G: The Glue Standard for On-Chain Royalty Enforcement
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * ABSTRACT
 * ════════════════════════════════════════════════════════════════════════════════
 *
 * ERC721G extends ERC721 with guaranteed on-chain royalty enforcement. Unlike
 * ERC-2981 which is merely informational, or ERC721C which requires permissioned
 * marketplace whitelisting, ERC721G makes royalty payment a prerequisite for
 * token transferability—while remaining fully permissionless. The standard introduces:
 *
 *   • Deferred payment support (compatible with marketplace payment flows)
 *   • Dynamic floor pricing via GLUE Protocol collateral oracle
 *   • Per-token locking mechanism for unpaid royalties
 *   • transferFrom2: A new transfer primitive with native royalty enforcement
 *   • approve2: ERC20-style count-based allowances for transferFrom2
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * MOTIVATION
 * ════════════════════════════════════════════════════════════════════════════════
 *
 * Creator royalties are fundamental to sustainable NFT ecosystems, yet existing
 * standards fail to enforce them:
 *
 *   ERC-2981 Problem:
 *   ┌─────────────────────────────────────────────────────────────────────────┐
 *   │  royaltyInfo() returns (receiver, amount)                               │
 *   │  ↓                                                                      │
 *   │  Marketplace receives this information                                  │
 *   │  ↓                                                                      │
 *   │  Marketplace CHOOSES whether to pay (optional, often ignored)           │
 *   │  ↓                                                                      │
 *   │  Result: Race to zero royalties, creators unpaid                        │
 *   └─────────────────────────────────────────────────────────────────────────┘
 *
 *   ERC721C Problem (Whitelisting Approach):
 *   ┌─────────────────────────────────────────────────────────────────────────┐
 *   │  Creator deploys collection with transfer restrictions                  │
 *   │  ↓                                                                      │
 *   │  Only WHITELISTED marketplaces can facilitate transfers                 │
 *   │  ↓                                                                      │
 *   │  New/competing marketplaces blocked unless manually approved            │
 *   │  ↓                                                                      │
 *   │  Result: Permissioned system, poor marketplace adoption,                │
 *   │          fragmented liquidity, centralized control                      │
 *   └─────────────────────────────────────────────────────────────────────────┘
 *
 *   Our R&D Requirement: The solution MUST be permissionless and backward
 *   compatible with ANY marketplace—existing or future—without whitelisting.
 *
 *   ERC721G Solution:
 *   ┌─────────────────────────────────────────────────────────────────────────┐
 *   │  transfer() attempted                                                   │
 *   │  ↓                                                                      │
 *   │  Token added to locked list (optimistic execution)                      │
 *   │  ↓                                                                      │
 *   │  Payment received? → Token unlocked, transfer succeeds                  │
 *   │  No payment?       → Token LOCKED, future transfers blocked             │
 *   │  ↓                                                                      │
 *   │  Result: Royalties enforced at protocol level                           │
 *   └─────────────────────────────────────────────────────────────────────────┘
 *
 * Additionally, marketplaces like OpenSea execute royalty payments AFTER the
 * NFT transfer within the same transaction. Traditional "check before transfer"
 * approaches would block these legitimate sales. ERC721G solves this with
 * deferred payment reconciliation.
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * SPECIFICATION
 * ════════════════════════════════════════════════════════════════════════════════
 *
 * ┌───────────────────────────────────────────────────────────────────────────────┐
 * │                              INTERFACE                                        │
 * ├───────────────────────────────────────────────────────────────────────────────┤
 * │                                                                               │
 * │  CORE FUNCTIONS                                                               │
 * │  ─────────────────────────────────────────────────────────────────────────    │
 * │  transferFrom2(from, to, tokenId)      Royalty-enforced single transfer       │
 * │  batchTransferFrom2(from, to, ids[])   Royalty-enforced batch transfer        │
 * │  approve2(operator, amount)            ERC20-style count allowance            │
 * │  allowance2(owner, spender) → uint256  Query approve2 allowance               │
 * │                                                                               │
 * │  ROYALTY FUNCTIONS                                                            │
 * │  ─────────────────────────────────────────────────────────────────────────    │
 * │  processRoyalties()                    Distribute accumulated royalties       │
 * │  unlockItems()                         Pay to unlock caller's locked items    │
 * │  unlockItems(itemIds[])                Pay royalty to unlock specific items   │
 * │                                                                               │
 * │  VIEW FUNCTIONS                                                               │
 * │  ─────────────────────────────────────────────────────────────────────────    │
 * │  getMinimumRoyalty() → uint256         Minimum royalty per transfer           │
 * │  getImpliedFloorPrice() → uint256      Floor price from GLUE collateral       │
 * │  isItemLocked(id) → bool               Check if item is locked                │
 * │  isRoyaltyActive() → bool              Check if enforcement is enabled        │
 * │  getRoyaltyOwed(itemIds[])             Check which items locked + cost        │
 * │                                                                               │
 * │  EVENTS                                                                       │
 * │  ─────────────────────────────────────────────────────────────────────────    │
 * │  ItemLocked(itemId)                    Emitted when item becomes locked       │
 * │  ItemUnlocked(itemId)                  Emitted when item is unlocked          │
 * │  RoyaltyProcessed(reward,unlocked,collateral,supply)  Consolidated event      │
 * │  Approval2(owner, operator, amount)    Emitted on approve2                    │
 * │                                                                               │
 * └───────────────────────────────────────────────────────────────────────────────┘
 *
 * ┌───────────────────────────────────────────────────────────────────────────────┐
 * │                           STORAGE LAYOUT                                      │
 * ├───────────────────────────────────────────────────────────────────────────────┤
 * │                                                                               │
 * │  ROYALTY STATE                                                                │
 * │  ─────────────────────────────────────────────────────────────────────────    │
 * │  _royaltyReceivers[]           Array of payment recipients (GLUE at [0])      │
 * │  _receiverSharesBps{}          Mapping: receiver → share in BPS               │
 * │  _totalRoyaltyBps              Sum of all shares (max 1000 = 10%)             │
 * │  _royaltyActive                Toggle for enforcement (true/false)            │
 * │                                                                               │
 * │  LOCK STATE (Deferred Payments)                                               │
 * │  ─────────────────────────────────────────────────────────────────────────    │
 * │  _locked{}                Mapping: tokenId → locked status                    │
 * │  _lockedIds[]               LIFO array of locked items                        │
 * │  _lockedIndex{}             Mapping: tokenId → array index+1                  │
 * │                                                                               │
 * │  SNAPSHOT (Flash loan + excess tracking)                                      │
 * │  ─────────────────────────────────────────────────────────────────────────    │
 * │  _snapshot[0]                  Collateral: ETH+WETH per NFT from GLUE         │
 * │  _snapshot[1]                  Supply: totalSupply at last check              │
 * │  _snapshot[2]                  ExcessETH: leftover from splits (accumulates)  │
 * │                                                                               │
 * │  APPROVE2 STATE                                                               │
 * │  ─────────────────────────────────────────────────────────────────────────    │
 * │  _approve2Allowance{}          Mapping: owner → operator → count              │
 * │                                                                               │
 * └───────────────────────────────────────────────────────────────────────────────┘
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * TRANSFER FLOWS
 * ════════════════════════════════════════════════════════════════════════════════
 *
 * ┌───────────────────────────────────────────────────────────────────────────────┐
 * │                    STANDARD TRANSFER (transferFrom)                           │
 * ├───────────────────────────────────────────────────────────────────────────────┤
 * │                                                                               │
 * │  transferFrom(from, to, tokenId)                                              │
 * │         │                                                                     │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ EXEMPTION CHECK                                                     │      │
 * │  │ Skip enforcement if:                                                │      │
 * │  │   • Minting (from = 0)           • Burning (to = 0/DEAD/GLUE)       │      │
 * │  │   • Gift (msg.sender = owner)    • Approved address                 │      │
 * │  │   • Enforcement disabled         • transferFrom2 in progress        │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │         │ Not exempt                                                          │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ LOCK CHECK                                                          │      │
 * │  │ If _locked[tokenId] == true → REVERT                                │      │
 * │  │ Token locked from previous TX, must pay first                       │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │         │ Not locked                                                          │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ EXECUTE TRANSFER FIRST                                              │      │
 * │  │ super._update() - token ownership changes to `to`                   │      │
 * │  │ (Transfer happens BEFORE locking so _isAuthorized passes)           │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │         │                                                                     │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ ADD TO LOCKED LIST                                                  │      │
 * │  │ _locked[tokenId] = true                                             │      │
 * │  │ _lockedIds.push(tokenId)  // LIFO priority                          │      │
 * │  │ Counter assigned to `to` (new owner)                                │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │         │                                                                     │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ PROCESS ROYALTY SPLIT                                               │      │
 * │  │ Check for accumulated payments (ETH/WETH)                           │      │
 * │  │ If sufficient: unlock this token (LIFO priority)                    │      │
 * │  │ Send executor reward to recipient                                   │      │
 * │  │ If TX ends without payment: token remains LOCKED                    │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │                                                                               │
 * └───────────────────────────────────────────────────────────────────────────────┘
 *
 * ┌───────────────────────────────────────────────────────────────────────────────┐
 * │                    ROYALTY-PAID TRANSFER (transferFrom2)                      │
 * ├───────────────────────────────────────────────────────────────────────────────┤
 * │                                                                               │
 * │  transferFrom2{value: royalty}(from, to, tokenId)                             │
 * │         │                                                                     │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ CHECK msg.value >= getMinimumRoyalty()                              │      │
 * │  │ CHECK approve2 allowance sufficient                                 │      │
 * │  │ CONSUME allowance (decrement by 1)                                  │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │         │                                                                     │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ SET _royaltyPaidTransferActive = true                               │      │
 * │  │ Execute _transfer(from, to, tokenId)                                │      │
 * │  │ SET _royaltyPaidTransferActive = false                              │      │
 * │  │ Note: If item was ALREADY locked, it STAYS locked (old debt)        │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │         │                                                                     │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ DISTRIBUTE ROYALTY                                                  │      │
 * │  │ Marketplace reward: 1% of msg.value → msg.sender                    │      │
 * │  │ Remaining 99% → royalty receivers (proportional to BPS)             │      │
 * │  │ Update GLUE collateral snapshot                                     │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │                                                                               │
 * │  Benefits: Token never locked, marketplace earns 1%, atomic operation         │
 * │                                                                               │
 * └───────────────────────────────────────────────────────────────────────────────┘
 *
 * ┌───────────────────────────────────────────────────────────────────────────────┐
 * │                         RECEIVE FLOW (ETH Payment)                            │
 * ├───────────────────────────────────────────────────────────────────────────────┤
 * │                                                                               │
 * │  receive() external payable                                                   │
 * │         │                                                                     │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ 1. UNWRAP WETH                                                      │      │
 * │  │    If WETH balance >= TRESHOLD, convert to ETH                      │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │         │                                                                     │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ 2. DISTRIBUTE TO RECEIVERS                                          │      │
 * │  │    executorReward = balance × 0.05%                                 │      │
 * │  │    distributable = balance - executorReward                         │      │
 * │  │    For each receiver: send share proportional to their BPS          │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │         │                                                                     │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ 3. _getGlueSnapshot() - ALL-IN-ONE FUNCTION                         │      │
 * │  │    Query GLUE: currentCollateral = ETH+WETH per 1 NFT               │      │
 * │  │    Query: currentSupply = getAdjustedTotalSupply()                  │      │
 * │  │    FLASH LOAN PROTECTION:                                           │      │
 * │  │      If currentCollateral < last AND currentSupply <= last:         │      │
 * │  │        → Use old values (don't let attacker benefit)                │      │
 * │  │        → DON'T update snapshot                                      │      │
 * │  │      Else: Update _snapshot[0,1] and return new values              │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │         │                                                                     │
 * │         ▼                                                                     │
 * │  ┌─────────────────────────────────────────────────────────────────────┐      │
 * │  │ 4. UNLOCK ITEMS (LIFO)                                              │      │
 * │  │    availableForUnlock = distributableAmount + _snapshot[2]          │      │
 * │  │    numToUnlock = availableForUnlock / minRoyalty                    │      │
 * │  │    Pop from _lockedIds[] (most recent first)                        │      │
 * │  │    _snapshot[2] = leftover after unlocking (accumulates)            │      │
 * │  └─────────────────────────────────────────────────────────────────────┘      │
 * │                                                                               │
 * └───────────────────────────────────────────────────────────────────────────────┘
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * APPROVAL SEIZURE
 * ════════════════════════════════════════════════════════════════════════════════
 *
 * Locked items have their approvals "seized" - they appear as unapproved to
 * marketplaces, preventing listing and sale attempts:
 *
 *   getApproved(tokenId):
 *   ├── Token locked? → return address(0)     // Appears unapproved
 *   └── Token unlocked? → return actual approved address
 *
 *   isApprovedForAll(owner, operator):
 *   ├── Owner has ANY locked item? → return false   // Can't list anything
 *   └── No locked items? → return actual approval status
 *
 *   _isAuthorized(owner, spender, tokenId):
 *   ├── Token locked + spender is GLUE/whitelisted? → Allow
 *   ├── Token locked + spender is owner? → Allow (gift)
 *   ├── Token locked + other spender? → Block
 *   └── Token unlocked? → Normal ERC721 rules
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * ECONOMIC MODEL
 * ════════════════════════════════════════════════════════════════════════════════
 *
 * ┌───────────────────────────────────────────────────────────────────────────────┐
 * │                          ROYALTY CALCULATION                                  │
 * ├───────────────────────────────────────────────────────────────────────────────┤
 * │                                                                               │
 * │  Floor Price Derivation:                                                      │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  floorPrice = GLUE.getcollateralByAmount(1, [ETH, WETH])                      │
 * │             = (ETH collateral per NFT) + (WETH collateral per NFT)            │
 * │             = max(calculated, TRESHOLD)   // MIN = 1e11 wei                   │   
 * │                                                                               │
 * │  Minimum Royalty:                                                             │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  minRoyalty = floorPrice × totalRoyaltyBps / 10000                            │
 * │                                                                               │
 * │  Example: floorPrice = 0.1 ETH, totalRoyalty = 500 BPS (5%)                   │
 * │           minRoyalty = 0.1 ETH × 500 / 10000 = 0.005 ETH                      │
 * │                                                                               │
 * └───────────────────────────────────────────────────────────────────────────────┘
 *
 * ┌───────────────────────────────────────────────────────────────────────────────┐
 * │                           FEE STRUCTURE                                       │
 * ├───────────────────────────────────────────────────────────────────────────────┤
 * │                                                                               │
 * │  Distribution Rewards:                                                        │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  • processRoyalties() caller:  0.05% (5 BPS) of distributed amount            │
 * │  • receive() auto-distribution: 0.05% (5 BPS) as unlock budget                │
 * │                                                                               │
 * │  Marketplace Incentive (transferFrom2):                                       │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  • 1.0% (100 BPS) of royalty payment → msg.sender (marketplace)               │
 * │  • 99.0% → royalty receivers                                                  │
 * │                                                                               │
 * │  BPS Reference:                                                               │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  10000 BPS = 100%  │  1000 BPS = 10%  │  100 BPS = 1%  │  10 BPS = 0.1%       │
 * │                                                                               │
 * └───────────────────────────────────────────────────────────────────────────────┘
 *
 * ┌───────────────────────────────────────────────────────────────────────────────┐
 * │                        ROYALTY CONFIGURATION                                  │
 * ├───────────────────────────────────────────────────────────────────────────────┤
 * │                                                                               │
 * │  Receivers:                                                                   │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  • Index 0: GLUE (permanent, minimum 1 BPS = 0.01%)                           │
 * │  • Index 1-10: Custom receivers (optional)                                    │
 * │  • Maximum 11 total receivers                                                 │
 * │                                                                               │
 * │  Limits:                                                                      │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  • Maximum total royalty: 1000 BPS (10%)                                      │
 * │  • Minimum GLUE share: 1 BPS (0.01%)                                          │
 * │  • GLUE cannot be removed (permanent at index 0)                              │
 * │                                                                               │
 * └───────────────────────────────────────────────────────────────────────────────┘
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * SECURITY CONSIDERATIONS
 * ════════════════════════════════════════════════════════════════════════════════
 *
 * ┌───────────────────────────────────────────────────────────────────────────────┐
 * │                         THREAT MITIGATIONS                                    │
 * ├───────────────────────────────────────────────────────────────────────────────┤
 * │                                                                               │
 * │  Reentrancy:                                                                  │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  All state-changing functions protected by nnrtnt modifier (transient         │
 * │  storage-based reentrancy guard). External calls to receivers cannot          │
 * │  re-enter to manipulate state.                                                │
 * │                                                                               │
 * │  Flash Loan Attacks:                                                          │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  Attack: Flash loan → drain GLUE collateral → transfer at low royalty         │
 * │  Defense: Snapshot comparison detects collateral decrease without             │
 * │           supply increase → uses old (higher) values, ignoring manipulation.  │
 * │                                                                               │
 * │  Approval Griefing:                                                           │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  approve2 allowances are atomic with transfers - if _transfer fails,          │
 * │  the entire transaction reverts including allowance consumption.              │
 * │                                                                               │
 * │  Locked List Corruption:                                                      │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  Burning/sinking locked items removes them from locked list to prevent        │
 * │  corruption. Uses swap-and-pop pattern for O(1) removal.                      │
 * │                                                                               │
 * │  Integer Overflow:                                                            │
 * │  ──────────────────────────────────────────────────────────────────────────   │
 * │  Solidity 0.8+ provides built-in overflow checks. Additional precision        │
 * │  is provided by _md512 for multiplication/division operations.                │
 * │                                                                               │
 * └───────────────────────────────────────────────────────────────────────────────┘
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * RATIONALE
 * ════════════════════════════════════════════════════════════════════════════════
 *
 * Why LIFO Unlocking?
 * ───────────────────────────────────────────────────────────────────────────────
 * When a marketplace transfers an NFT and pays royalty in the same transaction,
 * the most recently locked item (the one being transferred) should unlock first.
 * LIFO ensures the current transaction's token has priority over historical debt.
 *
 * Why Global Unlock?
 * ───────────────────────────────────────────────────────────────────────────────
 * The goal is ensuring TOTAL royalties match TOTAL transfers, not per-token
 * accounting. This simplifies payment flows and enables third parties to pay
 * royalties for others.
 *
 * Why Approval Seizure?
 * ───────────────────────────────────────────────────────────────────────────────
 * Marketplaces check approvals before displaying listings. By making locked
 * items appear unapproved, users cannot list items they owe royalties on,
 * providing clear UX: "Pay royalties, then trade."
 *
 * Why transferFrom2?
 * ───────────────────────────────────────────────────────────────────────────────
 * Standard transferFrom requires post-hoc royalty payment which can fail.
 * transferFrom2 atomically bundles payment with transfer, guaranteeing the
 * token is never locked and incentivizing marketplace adoption with rewards.
 *
 * Why approve2?
 * ───────────────────────────────────────────────────────────────────────────────
 * Standard approve(tokenId) requires approving each token individually.
 * setApprovalForAll grants unlimited access. approve2 provides a middle ground:
 * approve exactly N tokens, similar to ERC20 allowances.
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * BACKWARDS COMPATIBILITY
 * ════════════════════════════════════════════════════════════════════════════════
 *
 * ERC721G is fully backwards compatible with ERC721:
 *
 *   • All standard ERC721 functions work normally
 *   • ERC721Enumerable extension included
 *   • ERC-2981 royaltyInfo() implemented for marketplace discovery
 *   • Existing tools and indexers work without modification
 *
 * New functions (transferFrom2, approve2) are additive and optional.
 * Marketplaces can continue using standard transferFrom with deferred payment.
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * REFERENCE IMPLEMENTATION
 * ════════════════════════════════════════════════════════════════════════════════
 *
 *   contract MyNFT is ERC721G {
 *       constructor() ERC721G(
 *           "My NFT",                                    // name
 *           "MNFT",                                      // symbol  
 *           "ipfs://contract-metadata",                  // contractURI
 *           0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH address
 *           100,                                         // GLUE royalty: 1%
 *           new address[](0),                            // no additional receivers
 *           new uint256[](0),                            // no additional shares
 *           true                                         // enforcement active
 *       ) {}
 *
 *       function mint(address to, uint256 tokenId) external {
 *           _mint(to, tokenId);
 *       }
 *   }
 *
 * ════════════════════════════════════════════════════════════════════════════════
 * TEST VECTORS
 * ════════════════════════════════════════════════════════════════════════════════
 *
 * Scenario 1: Marketplace pays BEFORE transfer
 * ───────────────────────────────────────────────────────────────────────────────
 *   1. marketplace.call{value: royalty}(nft)  // receive() processes payment
 *   2. nft.transferFrom(seller, buyer, 1)     // Token unlocked during transfer
 *   Result: Transfer succeeds, token never marked as locked
 *
 * Scenario 2: Marketplace pays AFTER transfer (OpenSea)
 * ───────────────────────────────────────────────────────────────────────────────
 *   1. nft.transferFrom(seller, buyer, 1)     // Token marked locked
 *   2. marketplace.call{value: royalty}(nft)  // receive() unlocks token 1
 *   Result: Transfer succeeds, token unlocked in same TX
 *
 * Scenario 3: Batch purchase, single payment
 * ───────────────────────────────────────────────────────────────────────────────
 *   1. nft.transferFrom(seller, buyer, 1)     // Token 1 locked
 *   2. nft.transferFrom(seller, buyer, 2)     // Token 2 locked
 *   3. nft.transferFrom(seller, buyer, 3)     // Token 3 locked
 *   4. marketplace.call{value: 3*royalty}(nft) // Unlocks 3, 2, 1 (LIFO)
 *   Result: All transfers succeed, all tokens unlocked
 *
 * Scenario 4: No payment
 * ───────────────────────────────────────────────────────────────────────────────
 *   1. nft.transferFrom(seller, buyer, 1)     // Token 1 locked
 *   2. (no payment in TX)
 *   Result: Token 1 remains locked, future marketplace transfers blocked
 *
 * Scenario 5: Using transferFrom2
 * ───────────────────────────────────────────────────────────────────────────────
 *   1. seller.approve2(marketplace, 1)
 *   2. nft.transferFrom2{value: royalty}(seller, buyer, 1)
 *   Result: Atomic transfer with royalty, marketplace earns 1%
 *
 */

pragma solidity ^0.8.28;

// ═══════════════════════════════════════════════════════════════════════════════
// IMPORTS
// ═══════════════════════════════════════════════════════════════════════════════

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {StickyAsset} from "../base/StickyAsset.sol";
import {IERC721G} from "../interfaces/IERC721G.sol";

/**
 * @dev WETH interface for balance checking and unwrapping
 */
interface IWETH721G {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title ERC721G - ERC721 with Guaranteed Royalty Enforcement
 * @author Glue Protocol
 * @notice Abstract base contract for NFT collections with on-chain royalty enforcement.
 *         Extends ERC721 with deferred payment support, approval seizure, and transferFrom2.
 * @dev Inheritance chain: ERC721Enumerable → StickyAsset → IERC721G → IERC2981
 * 
 *      Key features:
 *      - Deferred payments: Compatible with marketplace flows (pay after transfer)
 *      - Approval seizure: Locked items appear unapproved to prevent listing
 *      - Flash loan protection: Prevents GLUE collateral manipulation attacks
 *      - transferFrom2/approve2: New primitives for royalty-guaranteed transfers
 *      - Dynamic floor price: Derived from GLUE Protocol collateral oracle
 * 
 *      To implement:
 *      1. Inherit from ERC721G
 *      2. Implement mint/burn functions using _mint/_burn
 *      3. Optionally override _setRoyaltyActive to control enforcement
 * 
 *      Storage slots used: ~10 (receivers, shares, snapshots, locked list, approve2)
 */
abstract contract ERC721G is ERC721Enumerable, StickyAsset, IERC721G, IERC2981 {

// ═══════════════════════════════════════════════════════════════════════════
// ███████╗████████╗ ██████╗ ██████╗  █████╗  ██████╗ ███████╗
// ██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔══██╗██╔════╝ ██╔════╝
// ███████╗   ██║   ██║   ██║██████╔╝███████║██║  ███╗█████╗  
// ╚════██║   ██║   ██║   ██║██╔══██╗██╔══██║██║   ██║██╔══╝  
// ███████║   ██║   ╚██████╔╝██║  ██║██║  ██║╚██████╔╝███████╗
// ╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
// ═══════════════════════════════════════════════════════════════════════════


    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice BPS denominator (10000 = 100%)
    uint256 private constant BPS_DENOMINATOR = 10000;

    /// @notice Minimum GLUE royalty share (0.01% = 1 BPS)
    uint256 private constant MIN_GLUE_ROYALTY_BPS = 1;

    /// @notice Executor reward for splitting royalties (0.05% = 5 BPS)
    uint256 private constant EXECUTOR_REWARD_BPS = 5;

    /// @notice Maximum total royalty (10% = 1000 BPS)
    uint256 private constant MAX_ROYALTY_BPS = 1000;

    /// @notice Maximum number of royalty receivers (including GLUE)
    uint256 private constant MAX_ROYALTY_RECEIVERS = 11;

    /// @dev Minimum threshold (0.0000001 ETH = 1e11 wei)
    uint256 private constant TRESHOLD = 1e11;

    /// @notice WETH contract address (immutable per deployment)
    address internal immutable WETH;

    // ═══════════════════════════════════════════════════════════════════════════
    // ROYALTY RECEIVER STORAGE
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice Array of royalty receivers (index 0 is always GLUE)
    address[] internal _royaltyReceivers;

    /// @notice Mapping of receiver address to their share in BPS
    mapping(address => uint256) internal _receiverSharesBps;

    /// @notice Total royalty share in BPS (sum of all receivers)
    uint256 internal _totalRoyaltyBps;

    /// @notice Whether royalty enforcement is currently active
    bool internal _royaltyActive;

    // ═══════════════════════════════════════════════════════════════════════════
    // SNAPSHOT STORAGE (Flash loan protection + excess tracking)
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice Packed snapshot: [0]=collateral, [1]=supply, [2]=excessETH
    /// @dev Stores together for common access pattern:
    ///      [0] lastCollateral - ETH+WETH per NFT from GLUE (for flash loan protection)
    ///      [1] lastSupply - totalSupply snapshot (for flash loan detection)
    ///      [2] excessETH - leftover ETH from splits not used for unlocking (accumulates)
    uint256[3] internal _snapshot;

    // ═══════════════════════════════════════════════════════════════════════════
    // APPROVED ADDRESSES
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice Addresses that skip royalty check (GLUE always approved)
    mapping(address => bool) internal _royaltyExempt;

    // ═══════════════════════════════════════════════════════════════════════════
    // DEFERRED ROYALTY STORAGE (Persistent)
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice Mapping of tokenId => true if token owes royalty
    mapping(uint256 => bool) internal _locked;

    /// @notice Array of item IDs that currently owe royalty (locked)
    uint256[] internal _lockedIds;

    /// @notice Mapping of tokenId => index+1 in _lockedIds (0 = not in list)
    mapping(uint256 => uint256) internal _lockedIndex;

    /// @notice Counter of locked items per owner (for O(1) approval blocking)
    mapping(address => uint256) internal _lockedCountByOwner;

    /// @notice Flag indicating a royalty-paid transfer is in progress
    /// @dev When true, _update() skips all lock/unlock logic (royalty already paid)
    bool private _royaltyPaidTransferActive;

    /// @notice Flag indicating receive() is currently processing
    /// @dev Prevents re-entrancy when WETH.withdraw() sends ETH back to contract
    bool private _receiveActive;

    // ═══════════════════════════════════════════════════════════════════════════
    // APPROVE2 STORAGE (ERC20-style allowances for transferFrom2)
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice Allowance for transferFrom2: owner => operator => number of items allowed
    mapping(address => mapping(address => uint256)) private _approve2Allowance;

// ═══════════════════════════════════════════════════════════════════════════
// ███████╗███████╗████████╗██╗   ██╗██████╗ 
// ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
// ███████╗█████╗     ██║   ██║   ██║██████╔╝
// ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ 
// ███████║███████╗   ██║   ╚██████╔╝██║     
// ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     
// ═══════════════════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Initialize an ERC721G collection with royalty enforcement
     * @param name_ Collection name
     * @param symbol_ Collection symbol
     * @param contractURI_ ERC-7572 contract metadata URI
     * @param weth_ WETH contract address for this network
     * @param glueRoyaltyBps_ GLUE's royalty share in BPS (minimum 1 = 0.01%)
     * @param receivers_ Additional royalty receivers (excluding GLUE)
     * @param sharesBps_ Shares for additional receivers in BPS
     * @param royaltyActive_ Whether to enable royalty enforcement initially
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address weth_,
        uint256 glueRoyaltyBps_,
        address[] memory receivers_,
        uint256[] memory sharesBps_,
        bool royaltyActive_
    )
        ERC721(name_, symbol_)
        StickyAsset(contractURI_, [false, true]) // [fungible=false, hooks=true]
    {
        // Validate arrays match
        if (receivers_.length != sharesBps_.length) revert Unauthorized();

        // Validate minimum GLUE royalty
        if (glueRoyaltyBps_ < MIN_GLUE_ROYALTY_BPS) revert Unauthorized();

        // Validate and set WETH address
        if (weth_ == address(0)) revert Unauthorized();
        WETH = weth_;

        // Initialize GLUE as first receiver (index 0 - cannot be removed)
        _royaltyReceivers.push(GLUE);
        _receiverSharesBps[GLUE] = glueRoyaltyBps_;
        _totalRoyaltyBps = glueRoyaltyBps_;

        // Add additional receivers
        for (uint256 i = 0; i < receivers_.length; i++) {
            if (receivers_[i] == address(0)) revert Unauthorized();
            if (receivers_[i] == GLUE) continue;

            _royaltyReceivers.push(receivers_[i]);
            _receiverSharesBps[receivers_[i]] = sharesBps_[i];
            _totalRoyaltyBps += sharesBps_[i];
        }

        // Validate total doesn't exceed 10%
        if (_totalRoyaltyBps > MAX_ROYALTY_BPS) revert Unauthorized();

        // Set initial state
        _royaltyActive = royaltyActive_;

        // GLUE is always approved for transfers
        _royaltyExempt[GLUE] = true;

        // Emit initialization event with all configuration
        uint256[] memory allShares = new uint256[](_royaltyReceivers.length);
        for (uint256 i = 0; i < _royaltyReceivers.length; i++) {
            allShares[i] = _receiverSharesBps[_royaltyReceivers[i]];
        }
        emit ERC721GInitialized(
            contractURI_,
            _royaltyReceivers,
            allShares,
            _totalRoyaltyBps,
            royaltyActive_
        );
    }



    // ═══════════════════════════════════════════════════════════════════════════
// ██╗    ██╗██████╗ ██╗████████╗███████╗
// ██║    ██║██╔══██╗██║╚══██╔══╝██╔════╝
// ██║ █╗ ██║██████╔╝██║   ██║   █████╗  
// ██║███╗██║██╔══██╗██║   ██║   ██╔══╝  
// ╚███╔███╔╝██║  ██║██║   ██║   ███████╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝
// ═══════════════════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════════════════
    //  ▀▀█▀▀ █▀▀█ █▀▀█ █▀▀▄ █▀▀ █▀▀ █▀▀ █▀▀█    █▀▀ █▀▀█ █▀▀█ █▀▄▀█ ▀▀▄
    //    █   █▄▄▀ █▄▄█ █  █ ▀▀█ █▀▀ █▀▀ █▄▄▀    █▀▀ █▄▄▀ █  █ █ ▀ █ ▄▀▀
    //    ▀   ▀ ▀▀ ▀  ▀ ▀  ▀ ▀▀▀ ▀   ▀▀▀ ▀ ▀▀    ▀   ▀ ▀▀ ▀▀▀▀ ▀   ▀ ▀▀▀
    // ═══════════════════════════════════════════════════════════════════════════
    //
    // The evolution of NFT transfers. Like Permit2 revolutionized token approvals,
    // transferFrom2 revolutionizes NFT trading by making royalties native.
    //
    // WHY transferFrom2?
    // ┌─────────────────────────────────────────────────────────────────────────┐
    // │  OLD WAY (transferFrom):                                                │
    // │  - Royalties? Maybe. Depends on marketplace goodwill.                   │
    // │  - Creator gets paid? Sometimes. Often bypassed.                        │
    // │  - Marketplace incentive? None. Race to zero royalties.                 │
    // │                                                                         │
    // │  NEW WAY (transferFrom2):                                               │
    // │  - Royalties: GUARANTEED. Built into the transfer itself.               │
    // │  - Creator gets paid: ALWAYS. No exceptions.                            │
    // │  - Marketplace incentive: 1% reward for integration.                    │
    // │  - Gas efficient: Single atomic operation.                              │
    // │  - No locked items: Pay upfront, transfer clean.                        │
    // └─────────────────────────────────────────────────────────────────────────┘
    //
    // MARKETPLACE INTEGRATION:
    // Replace your transferFrom calls with transferFrom2 and earn 1% on every
    // trade. It's that simple. Creators win. Marketplaces win. Everyone wins.
    //
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice transferFrom2 - The next evolution of NFT transfers
     * @dev Like Permit2 revolutionized approvals, transferFrom2 revolutionizes trading.
     *      Native royalty enforcement with marketplace incentives.
     *      
     *      ╔═══════════════════════════════════════════════════════════════════╗
     *      ║  transferFrom  │  Royalties optional, often bypassed              ║
     *      ║  transferFrom2 │  Royalties guaranteed, marketplace rewarded      ║
     *      ╚═══════════════════════════════════════════════════════════════════╝
     *      
     *      Benefits:
     *      - Atomic: royalty + transfer in one call
     *      - Clean: token never gets locked
     *      - Rewarding: marketplace earns 1% (from the royalty) fee
     *      - Gas efficient: no post-transfer unlocking
     *      
     *      Usage:
     *      ```
     *      uint256 royalty = nft.getMinimumRoyalty();
     *      uint256 refund = nft.transferFrom2{value: royalty}(seller, buyer, tokenId);
     *      ```
     *      
     * @param from Current owner of the token
     * @param to Recipient address
     * @param tokenId Token to transfer
     * @return excess Amount of ETH refunded to msg.sender
     */
    function transferFrom2(
        address from,
        address to,
        uint256 tokenId
    ) external payable virtual nnrtnt returns (uint256 excess) {
        if (tokenId == 0) revert Unauthorized();
        
        // Redirect burns to GLUE (protocol sink)
        if (to == address(0) || to == DEAD_ADDRESS) {
            to = GLUE;
        }

        // Check and consume approve2 allowance (1 token)
        _useApprove2Allowance(from, 1);

        // If royalty enforcement is disabled, just transfer (no payment required)
        if (!_royaltyActive) {
            _transfer(from, to, tokenId);
            // Refund any ETH sent (user shouldn't have paid)
            if (msg.value > 0) {
                _transferAsset(address(0), msg.sender, msg.value, new uint256[](0), true);
                return msg.value;
            }
            return 0;
        }
        
        // Get snapshot (flash loan protected + auto-updates) and calculate minRoyalty
        (uint256 effectiveCollateral, ) = _getGlueSnapshot();
        uint256 minRoyalty = _getMinimumRoyalty(effectiveCollateral);
        if (msg.value < minRoyalty) revert Unauthorized();

        // Execute the transfer with royalty-paid flag
        _executeRoyaltyPaidTransfer(from, to, tokenId);

        // Process the royalty payment (distribute + marketplace reward from minRoyalty only)
        _processMarketplaceRoyalty(minRoyalty);

        // Refund excess ETH to msg.sender (marketplace handles user refund)
        excess = msg.value > minRoyalty ? msg.value - minRoyalty : 0;
        if (excess > 0) {
            _transferAsset(address(0), msg.sender, excess, new uint256[](0), true);
        }
    }

    /**
     * @notice batchTransferFrom2 - Batch evolution of NFT transfers
     * @dev Transfer multiple NFTs with royalties in a single atomic operation.
     *      Even more gas efficient than multiple transferFrom2 calls.
     *      
     *      Why batch?
     *      - Single royalty distribution (saves gas)
     *      - One marketplace reward calculation
     *      - Atomic: all succeed or all fail
     *      
     *      Usage:
     *      ```
     *      uint256 royalty = nft.getMinimumRoyalty() * tokenIds.length;
     *      uint256 refund = nft.batchTransferFrom2{value: royalty}(seller, buyer, tokenIds);
     *      ```
     *      
     * @param from Current owner of all tokens
     * @param to Recipient address
     * @param tokenIds Array of token IDs to transfer
     * @return excess Amount of ETH refunded to msg.sender
     */
    function batchTransferFrom2(
        address from,
        address to,
        uint256[] calldata tokenIds
    ) external payable virtual nnrtnt returns (uint256 excess) {
        // Redirect burns to GLUE (protocol sink)
        if (to == address(0) || to == DEAD_ADDRESS) {
            to = GLUE;
        }

        uint256 count = tokenIds.length;
        if (count == 0) revert Unauthorized();
        
        // Check and consume approve2 allowance (batch size)
        _useApprove2Allowance(from, count);

        // If royalty enforcement is disabled, just transfer (no payment required)
        if (!_royaltyActive) {
            for (uint256 i = 0; i < count; i++) {
                _transfer(from, to, tokenIds[i]);
            }
            // Refund any ETH sent (user shouldn't have paid)
            if (msg.value > 0) {
                _transferAsset(address(0), msg.sender, msg.value, new uint256[](0), true);
                return msg.value;
            }
            return 0;
        }

        // Get snapshot (flash loan protected + auto-updates) and calculate minRoyalty
        (uint256 effectiveCollateral, ) = _getGlueSnapshot();
        uint256 minRoyalty = _getMinimumRoyalty(effectiveCollateral);
        uint256 totalRequired = _md512(minRoyalty, count, 1);
        if (msg.value < totalRequired) revert Unauthorized();

        // Execute all transfers using shared helper
        // Note: If items were locked from previous unpaid transfers, they STAY locked
        for (uint256 i = 0; i < count; i++) {
            _executeRoyaltyPaidTransfer(from, to, tokenIds[i]);
        }

        // Process the royalty payment (distribute + marketplace reward from totalRequired only)
        _processMarketplaceRoyalty(totalRequired);

        // Refund excess ETH to msg.sender (marketplace handles user refund)
        excess = msg.value > totalRequired ? msg.value - totalRequired : 0;
        if (excess > 0) {
            _transferAsset(address(0), msg.sender, excess, new uint256[](0), true);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    //  █▀▀█ █▀▀█ █▀▀█ █▀▀█ █▀▀█ ▀█ █▀ █▀▀ ▀▀▄
    //  █▄▄█ █▄▄█ █▄▄█ █▄▄▀ █  █  █▄█  █▀▀ ▄▀▀
    //  ▀  ▀ ▀    ▀    ▀ ▀▀ ▀▀▀▀   ▀   ▀▀▀ ▀▀▀
    // ═══════════════════════════════════════════════════════════════════════════
    //
    // Like Permit2 introduced better approval patterns for ERC20, approve2
    // introduces ERC20-style allowances for ERC721 transfers via transferFrom2.
    //
    // Instead of approving specific tokenIds, approve2 grants an allowance for
    // a NUMBER of items. Use type(uint256).max for unlimited (like ERC20).
    //
    // Each transferFrom2 call reduces the allowance by 1 (or batch size).
    // This is the new standard for marketplace integration.
    //
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice approve2 - ERC20-style allowance for transferFrom2
     * @dev Grant an operator permission to transfer a NUMBER of your tokens.
     *      Unlike standard approve (per-tokenId), this is a count-based allowance.
     *      
     *      ╔═══════════════════════════════════════════════════════════════════╗
     *      ║  approve(tokenId)   │  Per-token, need to approve each one        ║
     *      ║  setApprovalForAll  │  All or nothing, no middle ground           ║
     *      ║  approve2(amount)   │  ERC20-style, approve exactly N tokens      ║
     *      ╚═══════════════════════════════════════════════════════════════════╝
     *      
     *      Use type(uint256).max for unlimited (like ERC20 infinite approval).
     *      
     * @param operator Address to grant approval to
     * @param amount Number of items they can transfer (max for unlimited)
     */
    function approve2(address operator, uint256 amount) external virtual {
        if (operator == address(0)) revert Unauthorized();
        _approve2Allowance[msg.sender][operator] = amount;
        emit Approval2(msg.sender, operator, amount);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ROYALTY DISTRIBUTION & PAYMENTS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Unlock items by paying their royalties
     * @dev Flexible payment function with multiple modes:
     *      
     *      MODE 1: Auto-unlock ([0])
     *      - Pass [0] as itemIds to unlock as many items as msg.value allows
     *      - Calculates max unlockable from payment, unlocks LIFO order
     *      - Refunds any excess ETH
     *      
     *      MODE 2: Specific items ([id1, id2, ...])
     *      - For each itemId: if locked → unlock, else → unlock from LIFO
     *      - Refunds unused payment if items weren't locked
     *      
     *      Frontend integration:
     *      ```javascript
     *      // Auto-unlock: pay X ETH, unlock as many as possible
     *      await nft.unlockItems([0], { value: ethers.parseEther("0.1") });
     *      
     *      // Specific: unlock exact items
     *      const [lockedIds, amount] = await nft.getRoyaltyOwed([5, 10, 15]);
     *      await nft.unlockItems(lockedIds, { value: amount });
     *      ```
     * @param itemIds Array of item IDs to unlock, or [0] for auto-unlock mode
     */
    function unlockItems(uint256[] calldata itemIds) external payable virtual nnrtnt {
        if (itemIds.length == 0) revert Unauthorized();
        
        (uint256 effectiveCollateral, ) = _getGlueSnapshot();
        uint256 minRoyalty = _getMinimumRoyalty(effectiveCollateral);
        
        uint256 itemsUnlocked = 0;

        // MODE 1: Auto-unlock - [0] means "unlock as many as msg.value allows"
        if (itemIds.length == 1 && itemIds[0] == 0) {
            // Calculate how many items we can unlock with msg.value
            // If minRoyalty == 0, maxUnlockable = 0, nothing unlocks, ETH refunded
            uint256 maxUnlockable = minRoyalty > 0 ? _md512(msg.value, 1, minRoyalty) : 0;
            uint256 lockedLength = _lockedIds.length;
            
            // Unlock up to maxUnlockable items (or all locked, whichever is smaller)
            while (itemsUnlocked < maxUnlockable && lockedLength > 0) {
                _removeFromLockedList(0); // LIFO pop
                itemsUnlocked++;
                lockedLength--;
            }
        } 
        // MODE 2: Specific items
        else {
            uint256 totalRequired = _md512(minRoyalty, itemIds.length, 1);
            if (msg.value < totalRequired) revert Unauthorized();

            for (uint256 i = 0; i < itemIds.length; i++) {
                uint256 itemId = itemIds[i];

                if (_locked[itemId]) {
                    // Item is locked - unlock it directly
                    _removeFromLockedList(itemId);
                    itemsUnlocked++;
                } else {
                    // Item not locked - try to unlock another item from locked list (LIFO)
                    if (_removeFromLockedList(0) > 0) { // 0 = LIFO pop, returns unlocked ID
                        itemsUnlocked++;
                    }
                    // If no items to unlock, don't count as "spent"
                }
            }
        }

        // Update GLUE collateral snapshot (flash loan protected)
        _getGlueSnapshot();

        // Refund unused payment
        uint256 spent = _md512(minRoyalty, itemsUnlocked, 1);
        if (msg.value > spent) {
            _transferAsset(address(0), msg.sender, msg.value - spent, new uint256[](0), true);
        }
    }

 
// ═══════════════════════════════════════════════════════════════════════════
// ██████╗ ███████╗ █████╗ ██████╗ 
// ██╔══██╗██╔════╝██╔══██╗██╔══██╗
// ██████╔╝█████╗  ███████║██║  ██║
// ██╔══██╗██╔══╝  ██╔══██║██║  ██║
// ██║  ██║███████╗██║  ██║██████╔╝
// ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ 
// ═══════════════════════════════════════════════════════════════════════════


    // ============================================
    // Approve2 and ERC721 Approve
    // ============================================

    /**
     * @notice Check approve2 allowance for an operator (ERC20-style naming)
     * @param owner Token owner
     * @param spender Address to check allowance for
     * @return Current allowance (number of items they can transferFrom2)
     */
    function allowance2(address owner, address spender) external view virtual returns (uint256) {
        return _approve2Allowance[owner][spender];
    }

    // ============================================
    // Legacy Allowance
    // ============================================

    /**
     * @notice Override getApproved to return address(0) for locked items
     * @dev Makes locked items appear as "not approved" to marketplaces.
     *      
     *      How marketplaces use this:
     *      - Check getApproved(tokenId) to see if token can be listed/sold
     *      - If returns address(0), marketplace shows "not approved" or hides token
     *      
     *      Behavior:
     *      - Locked item + approved = GLUE/whitelisted → return approved address
     *      - Locked item + approved = other → return address(0) (seizure!)
     *      - Unlocked item → return normal approved address
     *      
     *      If _royaltyActive is false, returns normal approval.
     *      
     * @param tokenId Token ID to check approval for
     * @return Approved address, or address(0) if locked and not whitelisted
     */
    function getApproved(uint256 tokenId) public view virtual override(ERC721, IERC721) returns (address) {
        address approved = super.getApproved(tokenId);
        
        // Bypass if royalty enforcement disabled
        if (!_royaltyActive) {
            return approved;
        }

        // Seize approval for locked items (unless whitelisted)
        if (_locked[tokenId]) {
            if (_royaltyExempt[approved]) {
                return approved; // Whitelisted operators keep approval
            }
            return address(0); // SEIZURE: appears as not approved
        }
        
        return approved;
    }

    /**
     * @notice Override isApprovedForAll to return false if owner has ANY locked items
     * @dev AGGRESSIVE enforcement: If you have ANY locked item, you can't list ANY item.
     *      
     *      Why so aggressive?
     *      - Better UX: Clear message "pay royalties, then trade"
     *      - Prevents confusion: Can't list unlocked items while having locked ones
     *      - Encourages compliance: Users must clear ALL debt to trade
     *      
     *      How marketplaces use this:
     *      - Check isApprovedForAll(owner, marketplaceAddress) before showing listings
     *      - If false, marketplace may hide user's NFTs or show "not approved"
     *      
     *      Behavior:
     *      - Operator = GLUE/whitelisted → return actual approval (bypass)
     *      - Owner has ANY locked item → return false (enforcement!)
     *      - Owner has NO locked items → return actual approval
     *      
     *      If _royaltyActive is false, returns normal approval.
     *      
     * @param owner The token owner
     * @param operator The operator (typically marketplace contract)
     * @return True if operator is approved for all AND no locked items, false otherwise
     */
    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721, IERC721) returns (bool) {
        // Bypass if royalty enforcement disabled
        if (!_royaltyActive) {
            return super.isApprovedForAll(owner, operator);
        }

        // Whitelisted operators always bypass the lock check
        if (_royaltyExempt[operator]) {
            return super.isApprovedForAll(owner, operator);
        }
        
        // If owner has ANY locked items, block ALL operator approvals
        // This prevents listing any items until all royalties are paid
        if (_lockedCountByOwner[owner] > 0) {
            return false;
        }
        
        return super.isApprovedForAll(owner, operator);
    }


    // ============================================
    // Royalty and Floor Price
    // ============================================

    /**
     * @notice Check if royalty enforcement is currently active
     * @dev When false, all royalty checks are bypassed.
     * @return True if enforcement is active
     */
    function isRoyaltyActive() external view virtual returns (bool) {
        return _royaltyActive;
    }

    /**
     * @notice Get total royalty percentage in basis points
     * @dev Sum of all receivers' shares. 100 BPS = 1%, max 1000 BPS = 10%
     * @return Total royalty in BPS
     */
    function getRoyaltyBPS() external view virtual returns (uint256) {
        return _totalRoyaltyBps;
    }

    /**
     * @notice Check if an address is approved for royalty-free transfers
     * @dev Approved addresses bypass all royalty checks.
     * @param addr Address to check
     * @return True if address is approved
     */
    function isRoyaltyExempt(address addr) external view virtual returns (bool) {
        return _royaltyExempt[addr];
    }
    
    /**
     * @notice ERC-2981 royalty info - standard interface for marketplace royalty queries
     * @dev Returns this contract as receiver (royalties collected here, then distributed).
     *      Marketplaces call this to know how much royalty to pay.
     *      Note: Actual enforcement happens in _update(), this is just informational.
     * @param salePrice The sale price of the NFT
     * @return receiver Address to receive royalty (always this contract)
     * @return royaltyAmount Royalty amount based on totalRoyaltyBps
     */
    function royaltyInfo(uint256, uint256 salePrice) 
        external 
        view 
        virtual 
        override(IERC2981, IERC721G) 
        returns (address receiver, uint256 royaltyAmount) 
    {
        receiver = address(this);
        royaltyAmount = _md512(salePrice, _totalRoyaltyBps, BPS_DENOMINATOR);
    }

    /**
     * @notice Get implied floor price from GLUE collateral
     * @dev Floor price = ETH collateral per 1 NFT, derived from GLUE Protocol's
     *      StickyAsset collateral system. This creates a price floor that
     *      automatically adjusts based on actual collateral backing.
     * @return Floor price in wei (ETH)
     */
    function getImpliedFloorPrice() external view virtual returns (uint256) {
        (uint256 floorPrice, uint256 supply) = _getLiveGlue();
        
        // Flash loan protection: if collateral dropped without supply increase, use old value
        if (floorPrice < _snapshot[0] && supply <= _snapshot[1]) {
            return _snapshot[0] < TRESHOLD ? TRESHOLD : _snapshot[0];
        }
        return floorPrice < TRESHOLD ? TRESHOLD : floorPrice;
    }

    /**
     * @notice Get minimum required royalty per transfer
     * @dev Calculated as: floorPrice × totalRoyaltyBps / 10000
     *      Includes flash loan protection: if collateral dropped without supply increase,
     *      uses last safe snapshot value instead of manipulated current value.
     * @return Minimum royalty amount in wei
     */
    function getMinimumRoyalty() external view virtual returns (uint256) {
        (uint256 floorPrice, uint256 supply) = _getLiveGlue();
        
        // Flash loan protection: if collateral dropped without supply increase, use old value
        if (floorPrice < _snapshot[0] && supply <= _snapshot[1]) {
            return _getMinimumRoyalty(_snapshot[0]);
        }
        return _getMinimumRoyalty(floorPrice);
    }

    /**
     * @notice Check which items are locked and get the royalty amount to unlock them
     * @dev Primary function for frontends to display unlock costs.
     *      Pass an array of item IDs, get back only the locked ones + total payment.
     *      
     *      Frontend integration:
     *      ```javascript
     *      const myItems = [1, 5, 10, 15];
     *      const [lockedIds, amount] = await nft.getRoyaltyOwed(myItems);
     *      if (lockedIds.length > 0) {
     *          await nft.unlockItems(lockedIds, { value: amount });
     *      }
     *      ```
     * @param itemIds Array of item IDs to check
     * @return lockedIds Array of item IDs that are actually locked
     * @return amount Total ETH required to unlock all locked items
     */
    function getRoyaltyOwed(uint256[] calldata itemIds) external view virtual returns (
        uint256[] memory lockedIds, 
        uint256 amount
    ) {
        // First pass: count locked items
        uint256 lockedCount = 0;
        for (uint256 i = 0; i < itemIds.length; i++) {
            if (_locked[itemIds[i]]) {
                lockedCount++;
            }
        }
        
        // Second pass: populate locked IDs array
        lockedIds = new uint256[](lockedCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < itemIds.length; i++) {
            if (_locked[itemIds[i]]) {
                lockedIds[idx] = itemIds[i];
                idx++;
            }
        }
        
        amount = _md512(_getMinimumRoyalty(_snapshot[0]), lockedCount, 1);
    }

    /**
     * @notice Get all royalty receivers and their shares
     * @dev Returns parallel arrays of receivers and their BPS shares
     * @return receivers Array of receiver addresses
     * @return shares Array of BPS shares (parallel to receivers)
     */
    function getRoyaltyReceivers() external view virtual returns (address[] memory receivers, uint256[] memory shares) {
        uint256 len = _royaltyReceivers.length;
        receivers = new address[](len);
        shares = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            receivers[i] = _royaltyReceivers[i];
            shares[i] = _receiverSharesBps[_royaltyReceivers[i]];
        }
    }

    // ============================================
    // Item Status
    // ============================================

    /**
     * @notice Check if a specific item is locked due to unpaid royalty
     * @dev Locked items cannot be transferred (except by owner as gift or approved addresses).
     * @param itemId Item ID to check
     * @return True if item is locked
     */
    function isItemLocked(uint256 itemId) external view virtual returns (bool) {
        return _locked[itemId];
    }

    /**
     * @notice Get total count of items currently locked for unpaid royalties
     * @dev Useful for monitoring collection-wide royalty compliance.
     * @return Number of locked items
     */
    function getTotalLockedCount() external view virtual returns (uint256) {
        return _lockedIds.length;
    }

// ═══════════════════════════════════════════════════════════════════════════
// ██╗███╗   ██╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗     
// ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║     
// ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║     
// ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║     
// ██║██║ ╚████║   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗
// ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
// ═══════════════════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════════════════
    // APPROVE2 ALLOWANCE CHECK & CONSUMPTION
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @dev Check and consume approve2 allowance for transferFrom2 operations
     *      Reverts if msg.sender doesn't have sufficient allowance from owner.
     *      Decrements allowance by the number of items being transferred.
     *      
     *      Called at the start of transferFrom2/batchTransferFrom2 to ensure
     *      the operator has permission to transfer the specified count of items.
     *      
     * @param from Token owner whose allowance to check
     * @param count Number of items being transferred (decremented from allowance)
     */
    function _useApprove2Allowance(address from, uint256 count) private {
        // Load current allowance
        uint256 allowed = _approve2Allowance[from][msg.sender];
        
        // Skip check and decrement for unlimited allowance (ERC20-style gas optimization)
        if (allowed == type(uint256).max) return;
        
        // Verify sufficient allowance
        if (allowed < count) revert Unauthorized();
        
        // Consume allowance
        _approve2Allowance[from][msg.sender] = allowed - count;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ROYALTY MANAGEMENT (Internal functions for derived contracts)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Toggle royalty enforcement on/off
     * @dev When disabled:
     *      - Transfers proceed without royalty checks
     *      - Locked items can still be transferred  
     *      - Approval seizure is disabled (getApproved/isApprovedForAll return normal values)
     *      - Existing locked items remain in locked list (can be cleared by payments)
     *      Use case: Emergency disable, migration, or promotional periods
     * @param active True to enable enforcement, false to disable
     */
    function _setRoyaltyActive(bool active) internal virtual {
        _royaltyActive = active;
        emit RoyaltiesUpdated(address(0), 0, 0, _totalRoyaltyBps, active);
    }

    /**
     * @notice Manages royalty receivers: add, update, or remove based on current state and input
     * @dev Determines action automatically:
     *      - ADD: receiver has no existing share and shareBps > 0
     *      - UPDATE: receiver has existing share and shareBps > 0  
     *      - REMOVE: receiver has existing share and shareBps = 0
     *
     *      Constraints enforced:
     *      - receiver cannot be address(0)
     *      - GLUE receiver cannot have share below MIN_GLUE_ROYALTY_BPS (1 BPS)
     *      - Total royalty across all receivers cannot exceed MAX_ROYALTY_BPS (1000 BPS / 10%)
     *      - Maximum MAX_ROYALTY_RECEIVERS (11) receivers allowed
     *      - GLUE is set at index 0 during construction and cannot be removed
     *
     *      Removal uses swap-and-pop pattern starting from index 1 (preserving GLUE at 0)
     *
     * @param receiver Address to add, update, or remove as royalty receiver
     * @param shareBps Share in basis points: 0 to remove, >0 to add or update
     */
    function _editRoyaltyReceiver(address receiver, uint256 shareBps) internal virtual {
        // Validate receiver address
        if (receiver == address(0)) revert Unauthorized();
        // GLUE must maintain minimum share (also prevents removal since 0 < MIN)
        if (receiver == GLUE && shareBps < MIN_GLUE_ROYALTY_BPS) revert Unauthorized();
        
        // Get current share to determine action type
        uint256 oldShareBps = _receiverSharesBps[receiver];
        // Calculate new total (works for add/update/remove)
        uint256 newTotal = _totalRoyaltyBps - oldShareBps + shareBps;
        // Ensure total royalty doesn't exceed maximum
        if (newTotal > MAX_ROYALTY_BPS) revert Unauthorized();
        
        if (oldShareBps == 0) {
            // ─────────────────────────────────────────────────────────────
            // ADD: receiver not in list, adding new share
            // ─────────────────────────────────────────────────────────────
            if (shareBps == 0) revert Unauthorized(); // Nothing to add
            if (_royaltyReceivers.length >= MAX_ROYALTY_RECEIVERS) revert Unauthorized();
            // Append to receivers array and set share
            _royaltyReceivers.push(receiver);
            _receiverSharesBps[receiver] = shareBps;
        } else if (shareBps == 0) {
            // ─────────────────────────────────────────────────────────────
            // REMOVE: receiver exists, removing entirely
            // ─────────────────────────────────────────────────────────────
            // Find receiver in array (start at 1 to preserve GLUE at index 0)
        uint256 lastIndex = _royaltyReceivers.length - 1;
        for (uint256 i = 1; i < _royaltyReceivers.length; i++) {
            if (_royaltyReceivers[i] == receiver) {
                    // Swap with last element if not already last
                if (i != lastIndex) {
                    _royaltyReceivers[i] = _royaltyReceivers[lastIndex];
                }
                    // Remove last element
                _royaltyReceivers.pop();
                break;
            }
        }
            // Clear share mapping
        delete _receiverSharesBps[receiver];
        } else {
            // ─────────────────────────────────────────────────────────────
            // UPDATE: receiver exists, changing share amount
            // ─────────────────────────────────────────────────────────────
            _receiverSharesBps[receiver] = shareBps;
        }
        
        // Update total and emit event
        _totalRoyaltyBps = newTotal;
        emit RoyaltiesUpdated(receiver, oldShareBps, shareBps, newTotal, _royaltyActive);
    }

// ═══════════════════════════════════════════════════════════════════════════
// ROYALTY EXEMPTIONS
// ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Set an address as exempt from royalty enforcement
     * @dev Exempt addresses bypass the "approval seizure" mechanism:
     *      - Can transfer locked items (not blocked by _isAuthorized)
     *      - getApproved/isApprovedForAll bypass lock checks for exempt operators
     *      - Still requires normal ERC721 approval (not auto-approved!)
     *      GLUE is always exempt and cannot be modified.
     *      Use case: Whitelisting trusted marketplaces, staking contracts, bridges.
     * @param addr Address to exempt/unexempt
     * @param exempt True to exempt, false to revoke
     */
    function _setExemptAddress(address addr, bool exempt) internal virtual {
        if (addr == GLUE) revert Unauthorized();
        _royaltyExempt[addr] = exempt;
        emit ExemptAddressUpdated(addr, exempt);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ROYALTY DISTRIBUTION
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @dev Distribute ETH to all royalty receivers proportionally
     *      Each receiver gets: amount × receiverBps / totalRoyaltyBps
     *      
     *      Used by:
     *      - _processRoyaltySplit() for deferred payments
     *      - _processMarketplaceRoyalty() for transferFrom2 payments
     *      
     *      GLUE (at index 0) always receives its share first.
     *      
     * @param amount Total ETH to distribute (in wei)
     */
    function _distributeToReceivers(uint256 amount) private {
        if (amount == 0) return;
        
        // Iterate through all receivers and send proportional shares
        for (uint256 i = 0; i < _royaltyReceivers.length; i++) {
            address receiver = _royaltyReceivers[i];
            uint256 shareBps = _receiverSharesBps[receiver];

            // Skip receivers with 0 share (shouldn't happen, but defensive)
            if (shareBps == 0) continue;

            // Calculate proportional share: amount × shareBps / totalBps
            uint256 ethShare = _md512(amount, shareBps, _totalRoyaltyBps);
            if (ethShare > 0) {
                _transferAsset(address(0), receiver, ethShare, new uint256[](0), true);
            }
        }
    }

    /**
     * @notice Check if there's ETH or WETH available for royalty processing
     * @dev Returns both balances and whether processing should occur.
     *      Used by _update(), approve(), setApprovalForAll() to skip expensive
     *      _processRoyaltySplit() call when there's nothing to process.
     *      
     * @return shouldProcess True if ETH > TRESHOLD OR WETH >= TRESHOLD
     * @return ethBalance Current ETH balance
     * @return wethBalance Current WETH balance
     */
    function _checkRoyaltyBalances() internal view returns (bool shouldProcess, uint256 ethBalance, uint256 wethBalance) {
        ethBalance = address(this).balance;
        wethBalance = IWETH721G(WETH).balanceOf(address(this));
        shouldProcess = ethBalance > TRESHOLD || wethBalance >= TRESHOLD;
    }

    /**
     * @notice Core royalty processing: split to receivers, unlock items based on ETH distributed
     * @dev Unified logic used by receive(), approve(), setApprovalForAll(), processRoyalties().
     *      
     *      Flow:
     *      1. Unwrap any WETH to ETH
     *      2. Get GLUE snapshot (flash loan protection + auto-update)
     *      3. Early exit if no ETH and no accumulated excess
     *      4. Calculate executor reward (0.05%) and distribute to receivers
     *      5. Calculate availableForUnlock = distributed + accumulated excess
     *      6. Unlock items (LIFO) up to availableForUnlock / minRoyalty
     *      7. Update accumulated excess with leftover
     *      
     *      IMPORTANT: Executor reward is ONLY returned if items are unlocked.
     *      This incentivizes useful calls, not spam.
     *      
     * @param ethBalance Pre-checked ETH balance (0 = read inside)
     * @param wethBalance Pre-checked WETH balance (0 = read inside)
     * @return executorReward 0.05% reward (only if itemsUnlocked > 0)
     * @return itemsUnlocked Number of items unlocked during processing
     */
    function _processRoyaltySplit(uint256 ethBalance, uint256 wethBalance) private nnrtnt returns (uint256 executorReward, uint256 itemsUnlocked) {
        // Step 1: Read balances if not provided (saves gas when caller pre-checked)
        if (wethBalance == 0) {
            wethBalance = IWETH721G(WETH).balanceOf(address(this));
        }
        if (ethBalance == 0) {
            ethBalance = address(this).balance;
        }

        // Step 2: Unwrap WETH to ETH (only if above threshold)
        if (wethBalance >= TRESHOLD) {
            IWETH721G(WETH).withdraw(wethBalance);
            ethBalance += wethBalance; // Track unwrapped amount
        }

        // Step 3: Get snapshot with flash loan protection (auto-updates if safe)
        (uint256 effectiveCollateral, uint256 effectiveSupply) = _getGlueSnapshot();

        // Step 4: Check balance - only exit early if BOTH no new ETH AND no accumulated excess
        uint256 contractBalance = ethBalance;
        if (contractBalance <= TRESHOLD && _snapshot[2] == 0) {
            emit RoyaltyProcessed(0, 0, 0, effectiveSupply);
            return (0, 0);
        }

        // Step 5: Calculate executor reward (held until we confirm unlock) and distribute
        executorReward = _md512(contractBalance, EXECUTOR_REWARD_BPS, BPS_DENOMINATOR);
        uint256 distributableAmount = contractBalance - executorReward;
        if (distributableAmount > 0) {
            _distributeToReceivers(distributableAmount);
        }

        // Step 6: Calculate available for unlock (distributed + accumulated excess)
        uint256 availableForUnlock = distributableAmount + _snapshot[2];

        // Step 7: Calculate how many IDs we can unlock
        uint256 minRoyalty = _getMinimumRoyalty(effectiveCollateral);
        
        if (availableForUnlock < minRoyalty || minRoyalty == 0) {
            // Not enough to unlock any ID - accumulate as excess, no executor reward
            _snapshot[2] = availableForUnlock;
            emit RoyaltyProcessed(0, 0, effectiveCollateral, effectiveSupply);
            return (0, 0); // No reward if nothing unlocked
        }

        uint256 numToUnlock = _md512(availableForUnlock, 1, minRoyalty);

        // Step 8: Unlock IDs from locked list (LIFO order)
        uint256 lockedLength = _lockedIds.length;
        while (itemsUnlocked < numToUnlock && lockedLength > 0) {
            _removeFromLockedList(0); // 0 = LIFO pop
            itemsUnlocked++;
            lockedLength--;
        }

        // Step 9: Calculate new excess (leftover after unlocking)
        uint256 usedForUnlock = _md512(minRoyalty, itemsUnlocked, 1);
        _snapshot[2] = availableForUnlock > usedForUnlock ? availableForUnlock - usedForUnlock : 0;

        // Step 10: Success - items unlocked, return executor reward
        emit RoyaltyProcessed(executorReward, itemsUnlocked, effectiveCollateral, effectiveSupply);

        return (executorReward, itemsUnlocked); // Reward only given when items unlocked
    }

    /**
     * @notice Process accumulated WETH or ETH payments and unlock items
     * @dev Anyone can call this to trigger payment processing.
     *      ExecutorReward goes to caller as incentive.
     *      
     *      Flow:
     *      1. Unwraps WETH to ETH (if above threshold)
     *      2. Distributes to royalty receivers (including GLUE)
     *      3. Unlocks items based on distributed ETH + accumulated excess
     *      4. Sends executorReward to msg.sender
     *      
     * @return itemsUnlocked Number of items that were unlocked
     */
    function processRoyalties() external virtual returns (uint256 itemsUnlocked) {
        (uint256 executorReward, uint256 unlocked) = _processRoyaltySplit(0, 0);
        
        // Send executor reward to caller as incentive
        if (executorReward > 0) {
            _transferAsset(address(0), msg.sender, executorReward, new uint256[](0), true);
        }
        
        return unlocked;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PAYMENTS PROCESSING
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @dev Execute a transfer with royalty-paid flag active
     *      Used by transferFrom2 and batchTransferFrom2 to bypass lock logic.
     *      
     *      Sets _royaltyPaidTransferActive = true before transfer, which tells
     *      _update() to skip the normal lock/unlock processing since royalty
     *      was already paid upfront via msg.value.
     *      
     *      Important: If token was ALREADY locked from a previous unpaid transfer,
     *      it remains locked. This function only prevents NEW locks, not clearing old ones.
     *      
     * @param from Current token owner
     * @param to Recipient address
     * @param tokenId Token to transfer
     */
    function _executeRoyaltyPaidTransfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        // Set flag to bypass lock logic in _update()
        _royaltyPaidTransferActive = true;

        // Execute the actual ERC721 transfer
        _transfer(from, to, tokenId);

        // Clear flag for subsequent operations
        _royaltyPaidTransferActive = false;
    }

    /**
     * @dev Process royalty payment from transferFrom2/batchTransferFrom2
     *      Distributes royalty to receivers and sends marketplace incentive to caller.
     *      
     *      Distribution breakdown:
     *      - 1% (100 BPS) → msg.sender (marketplace incentive)
     *      - 99% → royalty receivers (proportional to their BPS shares)
     *      
     *      Also updates GLUE collateral snapshot for flash loan protection.
     *      
     * @param amount Total royalty payment (msg.value from transferFrom2)
     */
    function _processMarketplaceRoyalty(uint256 amount) private {
        // Calculate marketplace incentive (1% = EXECUTOR_REWARD_BPS * 20)
        uint256 marketplaceReward = _md512(amount, EXECUTOR_REWARD_BPS * 20, BPS_DENOMINATOR);

        // Distribute remaining 99% to royalty receivers
        uint256 distributableAmount = amount - marketplaceReward;
        if (distributableAmount > 0) {
            _distributeToReceivers(distributableAmount);
        }

        // Update GLUE collateral snapshot (flash loan protection)
        _getGlueSnapshot();

        // Send marketplace incentive to caller (msg.sender)
        if (marketplaceReward > 0) {
            _transferAsset(address(0), msg.sender, marketplaceReward, new uint256[](0), true);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GLUE SNAPSHOT
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get GLUE snapshot with flash loan protection and auto-update
     * @dev Queries GLUE for current collateral, applies flash loan protection,
     *      and updates snapshot if safe. ONE function handles all logic.
     *      
     *      Flash loan protection: if collateral dropped without supply increase,
     *      returns old (higher) values and does NOT update snapshot.
     *      This prevents attackers from benefiting from manipulated low royalties.
     *      
     * @return collateral Effective ETH+WETH per 1 NFT (safe value)
     * @return supply Effective totalSupply (safe value)
     */
    function _getGlueSnapshot() internal returns (uint256 collateral, uint256 supply) {
        (uint256 currentCollateral, uint256 currentSupply) = _getLiveGlue();
        
        // Flash loan detection: collateral dropped without supply increase
        if (currentCollateral < _snapshot[0] && currentSupply <= _snapshot[1]) {
            return (_snapshot[0], _snapshot[1]);
        }
        
        // Safe - update snapshot and return new values
        _snapshot[0] = currentCollateral;
        _snapshot[1] = currentSupply;
        return (currentCollateral, currentSupply);
    }

    /**
     * @dev Query live GLUE collateral and supply directly from protocol
     *      No caching, no flash loan protection - raw values only.
     *      Used by view functions and _getGlueSnapshot() for fresh data.
     *      
     *      Queries GLUE Protocol's collateralByAmount(1, [ETH, WETH]) to get
     *      the current backing value per NFT.
     *      
     * @return collateral ETH + WETH backing per 1 NFT (in wei)
     * @return supply Current adjusted total supply from getAdjustedTotalSupply()
     */
    function _getLiveGlue() private view returns (uint256 collateral, uint256 supply) {
        // Get current supply (excludes burned/sunk tokens)
        supply = getAdjustedTotalSupply();
        if (supply == 0) return (0, 0);
        
        // Query GLUE for ETH + WETH collateral per 1 NFT
        address[] memory cols = new address[](2);
        cols[0] = ETH_ADDRESS;
        cols[1] = WETH;
        uint256[] memory amounts = this.getcollateralByAmount(1, cols);
        collateral = amounts[0] + amounts[1];
    }

    /**
     * @dev Calculate minimum royalty amount from floor price
     *      Applies TRESHOLD as minimum floor to prevent zero royalties.
     *      Formula: max(floorPrice, TRESHOLD) × totalRoyaltyBps / 10000
     *      
     * @param floorPrice Collateral value per NFT (from _snapshot[0] or fresh query)
     * @return Minimum royalty amount in wei
     */
    function _getMinimumRoyalty(uint256 floorPrice) internal view virtual returns (uint256) {
        // Enforce minimum threshold to prevent dust royalties
        if (floorPrice < TRESHOLD) floorPrice = TRESHOLD;
        return _md512(floorPrice, _totalRoyaltyBps, BPS_DENOMINATOR);
    }


    // ═══════════════════════════════════════════════════════════════════════════
    // LOCKED LIST HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @dev Add token to the locked list (mark as locked)
     *      Called AFTER super._update() in _update(), so _ownerOf(tokenId)
     *      already returns the NEW owner (recipient).
     *      
     *      Counter is incremented for the new owner automatically.
     *      No migration needed since transfer completed before locking.
     *      Idempotent: safe to call multiple times for same token.
     *      
     * @param tokenId The token to lock
     */
    function _addToLockedList(uint256 tokenId) private {
        if (_lockedIndex[tokenId] > 0) return; // Already in list

        _locked[tokenId] = true;
        _lockedIds.push(tokenId);
        _lockedIndex[tokenId] = _lockedIds.length; // Store index+1 (0 = not in list)
        _lockedCountByOwner[_ownerOf(tokenId)]++; // Increment CURRENT owner's counter

        emit ItemLocked(tokenId);
    }

    /**
     * @dev Remove item from locked list (unlock it)
     *      Dual-mode function:
     *      - tokenId > 0: Remove specific token (swap-and-pop for O(1))
     *      - tokenId = 0: Pop last item (LIFO mode)
     *      
     *      Uses swap-and-pop for O(1) removal:
     *      1. Swap target with last element (if not already last)
     *      2. Update swapped element's index
     *      3. Pop last element
     *      
     *      Also updates _lockedCountByOwner for the current owner.
     *      Idempotent: safe to call for tokens not in list or empty list.
     *      
     * @param tokenId The token to remove, or 0 to pop last item (LIFO)
     * @return The tokenId that was actually removed (0 if list empty or token not found)
     */
    function _removeFromLockedList(uint256 tokenId) private returns (uint256) {
        // LIFO mode: tokenId 0 means "pop the last one"
        if (tokenId == 0) {
            if (_lockedIds.length == 0) return 0;
            tokenId = _lockedIds[_lockedIds.length - 1];
        }

        uint256 indexPlusOne = _lockedIndex[tokenId];
        if (indexPlusOne == 0) return 0; // Not in list

        // Decrement owner's counter before removal
        address owner = _ownerOf(tokenId);
        if (_lockedCountByOwner[owner] > 0) {
            _lockedCountByOwner[owner]--;
        }

        uint256 index = indexPlusOne - 1;
        uint256 lastIndex = _lockedIds.length - 1;

        // Swap with last element if not already last
        if (index != lastIndex) {
            uint256 lastTokenId = _lockedIds[lastIndex];
            _lockedIds[index] = lastTokenId;
            _lockedIndex[lastTokenId] = indexPlusOne;
        }

        // Pop and cleanup
        _lockedIds.pop();
        _locked[tokenId] = false;
        delete _lockedIndex[tokenId];

        emit ItemUnlocked(tokenId);
        
        return tokenId;
    }

// ═══════════════════════════════════════════════════════════════════════════
// ██╗     ███████╗ ██████╗  █████╗  ██████╗██╗   ██╗
// ██║     ██╔════╝██╔════╝ ██╔══██╗██╔════╝╚██╗ ██╔╝
// ██║     █████╗  ██║  ███╗███████║██║      ╚████╔╝ 
// ██║     ██╔══╝  ██║   ██║██╔══██║██║       ╚██╔╝  
// ███████╗███████╗╚██████╔╝██║  ██║╚██████╗   ██║   
// ╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝   ╚═╝   
    // ═══════════════════════════════════════════════════════════════════════════

    // ═══════════════════════════════════════════════════════════════════════════
    // RECEIVE ETH (Automatic royalty processing for ETH payments)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Receive ETH and automatically process royalty payments
     * @dev Called when ETH is sent to this contract. Uses _checkRoyaltyBalances()
     *      to skip processing if nothing to process (saves gas).
     *      
     *      Flow:
     *      1. Check if re-entry (WETH callback) → skip
     *      2. _checkRoyaltyBalances() → get ETH/WETH and shouldProcess
     *      3. If shouldProcess → set flag, process, send reward to GLUE
     *      
     *      Note: WETH transfers don't trigger receive()! Use processRoyalties().
     */
    receive() external payable virtual {
        // Re-entry guard (WETH.withdraw callback)
        if (_receiveActive) return;

        // Pre-check balances
        (bool shouldProcess, uint256 ethBal, uint256 wethBal) = _checkRoyaltyBalances();
        if (shouldProcess) {
            _receiveActive = true; // Prevent re-entry from WETH unwrap

            (uint256 executorReward, ) = _processRoyaltySplit(ethBal, wethBal);
            if (executorReward > 0) {
                _transferAsset(address(0), GLUE, executorReward, new uint256[](0), true);
            }

            _receiveActive = false;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TRANSFER OVERRIDE (Core Royalty Enforcement Logic)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Override _update to enforce royalties with deferred payment
     * @dev THE HEART OF ERC721G - deferred royalty enforcement system.
     *      
     *      Key insight: OpenSea sends ETH BEFORE transfers in the same TX.
     *      The ETH triggers receive() which accumulates in _snapshot[2].
     *      After transfer, we process royalty split to unlock items.
     *      
     *      Transfer flow:
     *      ┌───────────────────────────────────────────────────┐
     *      │ 1. Check exemptions (mint/burn/gift/exempt/etc)   │
     *      │ 2. Check if ALREADY locked → REVERT               │
     *      │ 3. Execute transfer (super._update)               │
     *      │ 4. Add item to locked list (LIFO priority)        │
     *      │ 5. Process royalty split → unlock if paid         │
     *      └───────────────────────────────────────────────────┘
     *      
     *      OpenSea purchase flow:
     *      1. ETH sent → receive() → distributed, excess in _snapshot[2]
     *      2. transferFrom → item locked → _processRoyaltySplit() → unlocks
     *      
     * @param to Recipient address
     * @param tokenId Token being transferred
     * @param auth Authorized operator (for approval checks)
     * @return from Previous owner address
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        // Token ID 0 is reserved and cannot exist
        if (tokenId == 0) revert Unauthorized();
        
        address from = _ownerOf(tokenId);

        // ─────────────────────────────────────────────────────────────────────
        // EXEMPTIONS: These transfers don't require royalty
        // ─────────────────────────────────────────────────────────────────────

        // Minting
        if (from == address(0)) {
            return super._update(to, tokenId, auth);
        }

        // Burning or sink transfer - clean up locked list to prevent corruption
        if (to == address(0) || to == DEAD_ADDRESS || to == GLUE) {
            if (_locked[tokenId]) {
                _removeFromLockedList(tokenId);
            }
            return super._update(to, tokenId, auth);
        }

        // Direct owner transfer (gift)
        if (msg.sender == from) {
            // Migrate counter if token is locked
            if (_locked[tokenId]) {
                if (_lockedCountByOwner[from] > 0) {
                    _lockedCountByOwner[from]--;
                }
                _lockedCountByOwner[to]++;
            }
            return super._update(to, tokenId, auth);
        }

        // Approved addresses (GLUE, custom)
        if (_royaltyExempt[msg.sender] || 
            _royaltyExempt[from] || 
            _royaltyExempt[to]) {
            // Migrate counter if token is locked
            if (_locked[tokenId]) {
                if (_lockedCountByOwner[from] > 0) {
                    _lockedCountByOwner[from]--;
                }
                _lockedCountByOwner[to]++;
            }
            return super._update(to, tokenId, auth);
        }

        // Royalty enforcement disabled
        if (!_royaltyActive) {
            // Migrate counter if token is locked (could be locked from when royalties were active)
            if (_locked[tokenId]) {
                if (_lockedCountByOwner[from] > 0) {
                    _lockedCountByOwner[from]--;
                }
                _lockedCountByOwner[to]++;
            }
            return super._update(to, tokenId, auth);
        }

        // Royalty-paid transfer in progress (via transferFrom2)
        // Skip lock/unlock logic - royalty already paid upfront
        // But if token was ALREADY locked, migrate counter from old owner to new owner
        if (_royaltyPaidTransferActive) {
            if (_locked[tokenId]) {
                // Token stays locked, but ownership changes - update counters
                if (_lockedCountByOwner[from] > 0) {
                    _lockedCountByOwner[from]--;
                }
                _lockedCountByOwner[to]++;
            }
            return super._update(to, tokenId, auth);
        }

        // ─────────────────────────────────────────────────────────────────────
        // STEP 1: Check if token is ALREADY locked (from previous TX)
        // ─────────────────────────────────────────────────────────────────────
        // Locked items cannot be transferred by marketplaces until royalty paid.
        // Owner can still gift (checked earlier), but marketplace transfers fail.

        if (_locked[tokenId]) {
            revert Unauthorized();
        }

        // ─────────────────────────────────────────────────────────────────────
        // STEP 2: Execute the transfer FIRST
        // ─────────────────────────────────────────────────────────────────────
        // Transfer happens before locking so _isAuthorized sees unlocked token.
        // After this, _ownerOf(tokenId) returns `to` (new owner).

        address result = super._update(to, tokenId, auth);

        // ─────────────────────────────────────────────────────────────────────
        // STEP 3: Lock item (LIFO priority for unlocking)
        // ─────────────────────────────────────────────────────────────────────

        _addToLockedList(tokenId);

        // ─────────────────────────────────────────────────────────────────────
        // STEP 4: Process royalty if ETH/WETH available
        // ─────────────────────────────────────────────────────────────────────

        (bool shouldProcess, uint256 ethBal, uint256 wethBal) = _checkRoyaltyBalances();
        if (shouldProcess) {
            _processRoyaltySplit(ethBal, wethBal);
        }

        return result;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // APPROVAL OVERRIDE (Approval Seizure Logic)
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Override approve to process royalty splits
     * @dev Uses _checkRoyaltyBalances() to skip processing if nothing available.
     *      ExecutorReward goes to msg.sender as incentive.
     * @param to Address to approve
     * @param tokenId Token to approve
     */
    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        if (tokenId == 0) revert Unauthorized();
        
        if (_royaltyActive) {
            (bool shouldProcess, uint256 ethBal, uint256 wethBal) = _checkRoyaltyBalances();
            if (shouldProcess) {
                (uint256 executorReward, ) = _processRoyaltySplit(ethBal, wethBal);
                if (executorReward > 0) {
                    _transferAsset(address(0), msg.sender, executorReward, new uint256[](0), true);
                }
            }
        }
        super.approve(to, tokenId);
    }

    /**
     * @notice Override setApprovalForAll to process royalty splits
     * @dev Uses _checkRoyaltyBalances() to skip processing if nothing available.
     *      ExecutorReward goes to msg.sender as incentive.
     * @param operator Operator to approve/revoke
     * @param approved True to approve, false to revoke
     */
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) {
        if (_royaltyActive) {
            (bool shouldProcess, uint256 ethBal, uint256 wethBal) = _checkRoyaltyBalances();
            if (shouldProcess) {
                (uint256 executorReward, ) = _processRoyaltySplit(ethBal, wethBal);
                if (executorReward > 0) {
                    _transferAsset(address(0), msg.sender, executorReward, new uint256[](0), true);
                }
            }
        }
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Override _isAuthorized to block authorization for locked items
     * @dev THE CORE of royalty enforcement via approval seizure.
     *      
     *      This function is called by ERC721's transferFrom/safeTransferFrom
     *      to check if spender is allowed to transfer the token.
     *      
     *      For LOCKED items (owes royalty):
     *      - GLUE: Always authorized (protocol can always operate)
     *      - Exempt addresses: Authorized (whitelisted marketplaces)
     *      - Owner: Authorized (can still gift/transfer their own tokens)
     *      - Everyone else: NOT authorized (must pay via unlockItems first)
     *      
     *      For UNLOCKED items:
     *      - Normal ERC721 rules apply (approve, approveForAll)
     *      
     *      If _royaltyActive is false, all enforcement is bypassed.
     *      
     * @param owner The token owner
     * @param spender The address trying to transfer (marketplace, buyer, etc.)
     * @param tokenId The token being transferred
     * @return True if spender is authorized to transfer this token
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) 
        internal 
        view 
        virtual 
        override 
        returns (bool) 
    {
        // Token ID 0 is reserved and cannot exist
        if (tokenId == 0) return false;
        
        // Bypass all enforcement if royalty system is disabled
        if (!_royaltyActive) {
            return super._isAuthorized(owner, spender, tokenId);
        }

        // Special handling for LOCKED items (from PREVIOUS transactions)
        if (_locked[tokenId]) {
            // Exempt addresses bypass lock (whitelisted operators)
            if (_royaltyExempt[spender]) {
                return super._isAuthorized(owner, spender, tokenId);
            }
            // Owner can always transfer their own tokens (gift/P2P)
            if (spender == owner) {
                return true;
            }
            // Block all other transfers of locked items
            return false;
        }
        
        // Item NOT locked - use RAW approval (bypass our isApprovedForAll override)
        // This allows OLD LISTINGS to be purchased even if owner has other locked items
        // Only NEW listings are blocked (via isApprovedForAll external check)
        return spender != address(0) &&
            (owner == spender || 
             super.isApprovedForAll(owner, spender) ||
             getApproved(tokenId) == spender);
    }

    /**
     * @notice ERC165 interface support
     * @dev Declares support for:
     *      - IERC2981: Royalty info standard
     *      - All ERC721Enumerable interfaces
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721G).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}