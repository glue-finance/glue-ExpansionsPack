# Glue Protocol Architecture

## Lore (Terminology)

| Term | Meaning |
|------|---------|
| **Glue Stick** | Factory contract that creates Glue contracts |
| **Sticky Asset** | A token or NFT with an associated Glue (backed by collateral) |
| **Glue** | The contract holding collateral for a specific token |
| **Glued Collaterals** | Assets held in a Glue (ETH, USDC, DAI, etc.) |
| **Apply the Glue** | Create a Glue for a token, making it sticky |
| **Unglue** | Burn tokens to withdraw proportional collateral |
| **Glued Loan** | Flash loan from Glue collateral |
| **Glued Hooks** | Custom logic executed on unglue |
| **Sticky Asset Standard** | Contracts to expand Glue functionality |
| **Sticky Asset Native** | Contracts natively compatible with the standard |

## Core Protocol Contracts (V1)

- **GlueStickERC20** — Factory for ERC20 token Glues
- **GlueStickERC721** — Factory for ERC721 Enumerable NFT Glues
- **GlueERC20** — Glue contract for a specific ERC20 token
- **GlueERC721** — Glue contract for a specific ERC721 collection
- **GluedSettings** — Protocol settings management
- **GluedMath** — Math library (512-bit precision)

## Expansion Pack Inheritance Hierarchy

```
GluedConstants (113 lines)
  ├── Provides: GLUE_STICK addrs, PRECISION, ETH_ADDRESS, DEAD_ADDRESS
  │
  ├── GluedToolsBase (606 lines) — Full toolkit for ERC20 + ERC721
  │   ├── GluedTools (186 lines) — Adds batch operations
  │   └── StickyAsset (760 lines) — Native Glue-compatible token
  │       └── InitStickyAsset (825 lines) — Proxy/factory pattern
  │
  ├── GluedToolsERC20Base (486 lines) — ERC20-only toolkit (smaller)
  │   ├── GluedToolsERC20 (137 lines) — Adds batch operations
  │   └── GluedLoanReceiver (527 lines) — Flash loan strategies
```

## Core Mechanics: ERC20 Unglue Flow

1. `applyTheGlue(token)` → Creates Glue clone, initialized with token
2. `Glue.initialize(token)` → Sets sticky asset, auto-detects token properties (burnable? includes address(0)? tax?)
3. Anyone transfers collateral (ETH or ERC20) to the Glue address
4. Holder calls `unglue(collaterals[], amount, recipient)`:
   - **Step 1:** Transfer tokens from holder to Glue
   - **Step 2:** Detect actual amount received (handles tax tokens)
   - **Step 3:** Execute sticky hook if enabled (reduces effective amount)
   - **Step 4:** Calculate `supplyDelta = realAmount * PRECISION / beforeTotalSupply`
   - **Step 5:** Burn or store tokens (tries `burn()`, else transfer to DEAD, else store in Glue)
   - **Step 6:** For each collateral: `share = (balance * supplyDelta / PRECISION) * (1 - 0.1%)`
   - **Step 7:** Execute collateral hook if enabled (reduces recipient amount)
   - **Step 8:** Split protocol fee: `glueFee%` to glueFeeAddr, rest to teamAddr
   - **Step 9:** Transfer final amounts to recipient
5. Flash Loan: borrow from Glue collateral → execute callback → verify repayment + 0.01% fee

## Core Mechanics: ERC721 Unglue Flow

Same as ERC20 but:
- Uses `tokenIds[]` instead of `amount`
- `supplyDelta = nftCount * PRECISION / beforeTotalSupply`
- NFT hooks: sticky hook does NO transfer (only tracks burned IDs), collateral hook DOES transfer
- Burn tries: `burn(tokenId)`, transfer to DEAD, store in Glue

## Arbitrage Mechanism (Self-Balancing)

**Token trades below backing →** Arbitrageur buys cheap token → Burns for collateral → Profits from difference → Price rises back to backing

**Token trades above backing →** People hold/buy token → Collateral accumulates in Glue → Backing increases

No oracle needed. Price discovery via burn mechanism + market arbitrage.

## Key Interfaces

```
IGlueERC20.unglue(collaterals[], amount, recipient) → (supplyDelta, realAmount, beforeSupply, afterSupply)
IGlueERC721.unglue(collaterals[], tokenIds[], recipient) → (supplyDelta, realAmount, beforeSupply, afterSupply)
IGlueStick.applyTheGlue(asset) → glue
IGlueStick.batchUnglue(assets[], amounts[]/tokenIds[][], collaterals[], recipients[])
IGlueStick.gluedLoan(glues[], collateral, amount, receiver, params)
IStickyAsset.unglue(collaterals[], amount, tokenIds[], recipient)
IStickyAsset.flashLoan(collateral, amount, receiver, params)
IGluedHooks.hasHook() → bool
IGluedHooks.hookSize(asset, amount) → size
IGluedHooks.executeHook(asset, amount, tokenIds[], recipient)
IGluedLoanReceiver.executeOperation(glues[], collateral, expectedAmounts[], params) → bool
```

## Supported Networks

| Network | Chain ID |
|---------|----------|
| Ethereum Mainnet | 1 |
| Base | 8453 |
| Optimism | 10 |
| Sepolia | 11155111 |
| Base Sepolia | 84532 |
| OP Sepolia | 11155420 |

All factory addresses are identical across all chains.
