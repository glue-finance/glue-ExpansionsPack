# 📚 Glue Protocol - Inherited Functions Reference

> A simple guide to all functions and constants you get when inheriting from Glue Protocol base contracts.

---

## 📋 Table of Contents

- [Which Contract Should I Use?](#-which-contract-should-i-use)
- [GluedTools](#-gluedtools)
- [GluedToolsERC20](#-gluedtoolserc20)
- [StickyAsset](#-stickyasset)
- [InitStickyAsset](#-initstickyasset)
- [GluedLoanReceiver](#-gluedloanreceiver)

---

## 🎯 Which Contract Should I Use?

| I want to... | Use this contract |
|--------------|-------------------|
| Build a router, aggregator, or DeFi app that works with ERC20 and NFTs | **GluedTools** |
| Build an ERC20-only DeFi app (smaller contract size) | **GluedToolsERC20** |
| Create a new ERC20 or ERC721 token with Glue backing | **StickyAsset** |
| Create tokens using a factory/clone pattern | **InitStickyAsset** |
| Build a flash loan bot or arbitrage contract | **GluedLoanReceiver** |

---

## 🔧 GluedTools

**Import:** `@glue-finance/expansions-pack/base/GluedTools.sol`

**Best for:** Routers, aggregators, yield strategies, any contract needing full ERC20 + ERC721 support.

### Constants You Get

| Name | What It Is |
|------|------------|
| `GLUE_STICK_ERC20` | The official ERC20 glue factory contract. Use it to create glues or check if tokens are sticky. |
| `GLUE_STICK_ERC721` | The official ERC721 glue factory contract. Same as above but for NFTs. |
| `PRECISION` | The number `1e18`. Represents 100% in all percentage calculations. Use for fees, ratios, etc. |
| `ETH_ADDRESS` | `address(0)`. When you see this as a token address, it means native ETH, not a token. |
| `DEAD_ADDRESS` | Standard burn address `0x...dEaD`. Used when burning tokens that don't have a burn function. |

### Modifiers You Get

| Name | What It Does |
|------|--------------|
| `nnrtnt` | Reentrancy protection. Add to any function that makes external calls to prevent reentrancy attacks. Uses EIP-1153 transient storage for gas efficiency. |

### Glue Functions

| Function | What It Does |
|----------|--------------|
| `_initializeGlue(token, fungible)` | Creates a glue for a token if it doesn't exist, or returns the existing one. Set `fungible` to `true` for ERC20, `false` for ERC721. |
| `_tryInitializeGlue(token, fungible)` | Same as above, but returns `address(0)` instead of reverting if it fails. Good for handling edge cases safely. |
| `_getGlue(token, fungible)` | Returns the glue address and whether the token was already sticky. Creates glue if needed. |
| `_hasAGlue(token, fungible)` | Just checks if a token already has a glue. Doesn't create anything. View function (free to call). |
| `_getGlueBalances(token, collaterals, fungible)` | Returns how much of each collateral is stored in a token's glue. Pass an array of collateral addresses. |
| `_getTotalSupply(token, fungible)` | Returns the circulating supply of a sticky token (excludes tokens sent to the glue/burned). |
| `_getCollateralbyAmount(token, amount, collaterals, fungible)` | Calculates how much collateral you'd get back if you burned a specific amount of sticky tokens. |

### Transfer Functions

| Function | What It Does |
|----------|--------------|
| `_transferAsset(token, to, amount, tokenIDs, fungible)` | Sends ETH, ERC20, or ERC721 to an address. For ETH use `ETH_ADDRESS`. For ERC20 pass empty `tokenIDs`. For NFTs pass the IDs and set `amount` to 0. |
| `_transferFromAsset(token, from, to, amount, tokenIDs, fungible)` | Transfers from another address. Returns the actual amount received (important for tax tokens that take a fee on transfer). |
| `_transferAssetChecked(token, to, amount, tokenIDs, fungible)` | Same as `_transferAsset` but verifies the recipient actually received the tokens. Returns actual amount. Good for tax tokens. |
| `_batchTransferAsset(token, to[], amounts[], tokenIDs[], fullAmount, fungible)` | **GluedTools exclusive.** Send to multiple addresses in one call. For ERC20 you can use one amount for all or different amounts per recipient. |

### Burn Functions

| Function | What It Does |
|----------|--------------|
| `_burnAsset(token, amount, fungible, tokenIDs)` | Burns tokens by sending them to the glue contract. This is the proper way to burn sticky tokens. Creates glue if needed. |
| `_burnAssetFrom(token, from, amount, fungible, tokenIDs)` | Same but burns from another address (requires approval). |

### Read Functions

| Function | What It Does |
|----------|--------------|
| `_balanceOfAsset(token, account, fungible)` | Returns how much of a token an address holds. Works for ETH, ERC20, and ERC721. |
| `_getNFTOwner(token, tokenId)` | Returns who owns a specific NFT. Returns `address(0)` if the token doesn't exist. |
| `_getTokenDecimals(token, fungible)` | Returns decimals for a token. ETH returns 18, NFTs return 0. |

### Math Functions

| Function | What It Does |
|----------|--------------|
| `_md512(a, b, denominator)` | High-precision multiply-divide: `(a × b) ÷ denominator`. Uses 512-bit math internally to prevent overflow. Rounds down. |
| `_md512Up(a, b, denominator)` | Same as above but rounds up. Use when you want to guarantee you collect at least the calculated amount (like fees). |
| `_adjustDecimals(amount, tokenIn, tokenOut)` | Converts an amount from one token's decimals to another's. E.g., convert USDC (6 decimals) amount to DAI (18 decimals). |

### Utility Functions

| Function | What It Does |
|----------|--------------|
| `_handleExcess(token, amount, glue)` | **GluedTools exclusive.** Sends leftover tokens/ETH to a glue contract. Useful for cleaning up dust after swaps. |
| `onERC721Received(...)` | Automatically implemented. Allows your contract to receive NFTs via `safeTransferFrom`. |

---

## 🔧 GluedToolsERC20

**Import:** `@glue-finance/expansions-pack/base/GluedToolsERC20.sol`

**Best for:** ERC20-only protocols, flash loan bots, yield farming. Smaller bytecode than GluedTools.

### What's Different from GluedTools?

- ❌ No NFT support (no `tokenIDs` parameters, no `fungible` flag)
- ❌ No `_getNFTOwner` function
- ✅ Has `_approveAsset` and `_unglueAsset` helpers
- ✅ Smaller contract size (saves gas on deployment)

### Constants & Modifiers

Same as GluedTools: `GLUE_STICK_ERC20`, `GLUE_STICK_ERC721`, `PRECISION`, `ETH_ADDRESS`, `DEAD_ADDRESS`, and `nnrtnt` modifier.

### Glue Functions (Simplified)

| Function | What It Does |
|----------|--------------|
| `_initializeGlue(token)` | Creates or returns glue for an ERC20. No `fungible` flag needed. |
| `_tryInitializeGlue(token)` | Safe version, returns `address(0)` on failure. |
| `_getGlue(token)` | Returns glue address and sticky status. |
| `_hasAGlue(token)` | Checks if token has a glue (view function). |
| `_getGlueBalances(token, collaterals)` | Returns collateral balances in the glue. |
| `_getTotalSupply(token)` | Returns circulating supply. |
| `_getCollateralbyAmount(token, amount, collaterals)` | Calculates redeemable collateral for an amount. |

### Transfer Functions (Simplified)

| Function | What It Does |
|----------|--------------|
| `_transferAsset(token, to, amount)` | Sends ETH or ERC20. Use `ETH_ADDRESS` for ETH. |
| `_transferFromAsset(token, from, to, amount)` | Transfers from another address. Returns actual received amount. |
| `_transferAssetChecked(token, to, amount)` | Transfer with balance verification. Returns actual amount. |
| `_batchTransferAsset(token, to[], amounts[], fullAmount)` | **GluedToolsERC20 exclusive.** Batch transfer to multiple recipients. |

### Burn Functions (Simplified)

| Function | What It Does |
|----------|--------------|
| `_burnAsset(token, amount)` | Burns by sending to glue. |
| `_burnAssetFrom(token, from, amount)` | Burns from another address. |

### Approval Functions (ERC20-specific)

| Function | What It Does |
|----------|--------------|
| `_approveAsset(token, spender, amount)` | Approves a spender to use your tokens. Does nothing for ETH (since ETH doesn't need approval). |
| `_unglueAsset(token, amount, collaterals, recipient)` | Approves the glue and calls unglue in one step. Convenient way to redeem collateral. |

### Read Functions (Simplified)

| Function | What It Does |
|----------|--------------|
| `_balanceOfAsset(token, account)` | Returns ETH or ERC20 balance. |
| `_getTokenDecimals(token)` | Returns decimals (18 for ETH). |

### Math Functions

Same as GluedTools: `_md512`, `_md512Up`, `_adjustDecimals`.

### Utility Functions

| Function | What It Does |
|----------|--------------|
| `_handleExcess(token, amount, glue)` | Sends excess tokens to glue. |
| `receive()` | Automatically implemented. Allows your contract to receive ETH. |

---

## 🎨 StickyAsset

**Import:** `@glue-finance/expansions-pack/base/StickyAsset.sol`

**Best for:** Creating new ERC20 or ERC721 tokens that integrate natively with Glue Protocol.

### What You Get

When you inherit from StickyAsset and pass your config to the constructor, you get:
- A glue contract automatically created for your token
- Automatic approval of glue to spend your tokens
- Native `unglue()` function on your token
- Flash loan capability
- Optional hook system for custom logic

### Variables Set in Constructor

| Name | What It Is |
|------|------------|
| `GLUE` | Your token's glue contract address (immutable). |
| `FUNGIBLE` | `true` if ERC20, `false` if ERC721 (immutable). |
| `HOOK` | `true` if hooks are enabled (immutable). |
| `_contractURI` | EIP-7572 metadata URI for your token. |

### Modifiers You Get

| Name | What It Does |
|------|--------------|
| `nnrtnt` | Reentrancy protection (inherited from GluedToolsBase). |
| `onlyGlue` | Restricts function to only be callable by the GLUE contract. Used for hook functions. |

### Hook Functions to Override

Override these if you set `HOOK = true`:

| Function | What It Does |
|----------|--------------|
| `_calculateStickyHookSize(amount)` | Return the percentage (in PRECISION units) of sticky tokens to redirect to your hook when users unglue. Return 0 to disable. |
| `_calculateCollateralHookSize(asset, amount)` | Return the percentage of collateral to redirect to your hook when users withdraw it. |
| `_processStickyHook(amount, tokenIds, recipient)` | Called when sticky tokens are sent to your hook. Do whatever you want with them (stake, burn, redistribute, etc.). |
| `_processCollateralHook(asset, amount, isETH, recipient)` | Called when collateral is sent to your hook. Process as needed. |

### Built-in Public Functions

| Function | What It Does |
|----------|--------------|
| `unglue(collaterals, amount, tokenIds, recipient)` | Users call this to burn sticky tokens and receive collateral. Works directly on your token. |
| `flashLoan(collateral, amount, receiver, params)` | Initiates a flash loan using collateral in your token's glue. |
| `hookSize(asset, amount)` | Returns the hook size for an asset (calls your internal `_calculateX` functions). |
| `executeHook(asset, amount, tokenIds, recipient)` | Called by GLUE to execute hooks. Only GLUE can call this. |

### Read Functions (External)

| Function | What It Does |
|----------|--------------|
| `getcollateralByAmount(amount, collaterals)` | How much collateral you'd get for burning `amount` tokens. |
| `getAdjustedTotalSupply()` | Circulating supply (excludes burned tokens). |
| `getSupplyDelta(amount)` | The proportion of total supply that `amount` represents. |
| `getBalances(collaterals)` | Collateral balances in your glue. |
| `hooksImpact(collateral, collateralAmount, stickyAmount)` | Total impact of all hooks combined. |
| `getFlashLoanFeeCalculated(amount)` | Flash loan fee for a given amount. |
| `contractURI()` | Returns EIP-7572 metadata URI. |
| `hasHook()` | Returns if hooks are enabled. |
| `isFungible()` | Returns if token is ERC20. |
| `getGlue()` | Returns your glue address. |
| `getGlueStick()` | Returns the factory address. |

### Helper Function

| Function | What It Does |
|----------|--------------|
| `_updateContractURI(newURI)` | Updates the metadata URI. Call from your own admin function. |

### All GluedToolsBase Functions

You also inherit everything from [GluedTools](#-gluedtools) (all glue ops, transfers, burns, math, etc.).

---

## 🏭 InitStickyAsset

**Import:** `@glue-finance/expansions-pack/base/InitStickyAsset.sol`

**Best for:** Token factories, clone patterns, upgradeable tokens, launchpads.

### How It's Different from StickyAsset

| Feature | StickyAsset | InitStickyAsset |
|---------|-------------|-----------------|
| Glue created | In constructor | Via `initializeStickyAsset()` |
| Variables | Immutable | Regular (set once during init) |
| Pattern | Standard deploy | Proxy/Clone/Factory |
| Use case | Single token deploy | Many token deploys |

### Extra Modifier

| Name | What It Does |
|------|--------------|
| `onlyInitialized` | Reverts if the contract hasn't been initialized yet. Add to functions that need glue. |

### Initialization Functions

| Function | What It Does |
|----------|--------------|
| `initializeStickyAsset(uri, [fungible, hook])` | Call once after deployment to create glue and set config. |
| `isInitialized()` | Returns `true` if already initialized. |

### Everything Else

Same as [StickyAsset](#-stickyasset) - all the same hooks, functions, and inherited capabilities.

---

## ⚡ GluedLoanReceiver

**Import:** `@glue-finance/expansions-pack/base/GluedLoanReceiver.sol`

**Best for:** Flash loan bots, arbitrage, liquidations, collateral swaps.

### How Flash Loans Work

1. You call `_requestFlashLoan` or `_requestGluedLoan`
2. Glue Protocol sends you the borrowed tokens
3. Your `_executeFlashLoanLogic` function runs
4. Repayment happens automatically
5. If you don't have enough to repay, the whole tx reverts

### The Function You MUST Override

| Function | What It Does |
|----------|--------------|
| `_executeFlashLoanLogic(params)` | **Override this.** Put your arbitrage/strategy logic here. Return `true` on success. You have full access to borrowed funds at this point. |

### Request Flash Loans

| Function | What It Does |
|----------|--------------|
| `_requestGluedLoan(useERC721, glues[], collateral, amount, params)` | Borrow from multiple glues at once. Great for large loans. Set `useERC721` to `false` for ERC20 glues. |
| `_requestFlashLoan(glue, collateral, amount, params)` | Borrow from a single glue. Simpler option. |

### Info Getters (Use Inside Your Logic)

| Function | What It Does |
|----------|--------------|
| `getCurrentTotalBorrowed()` | How much you borrowed total. |
| `getCurrentCollateral()` | The token address you borrowed. |
| `getCurrentTotalRepayAmount()` | Total you need to repay (borrowed + fees). |
| `getCurrentTotalFees()` | Just the fee amount. |
| `getCurrentLoanInfo()` | All loan details in one call. |
| `isFlashLoanActive()` | True if you're inside a flash loan execution. |

### Planning Functions (Use Before Requesting)

| Function | What It Does |
|----------|--------------|
| `maxLoan(glue, collateral)` | Maximum you can borrow from one glue. |
| `multiMaxLoan(useERC721, glues[], collateral)` | Maximum from each glue in an array. |
| `getFlashLoanFee(glue)` | Fee percentage (in PRECISION units). |
| `getFlashLoanFeeCalculated(glue, amount)` | Exact fee for a specific amount. |

### All GluedToolsERC20Base Functions

You also inherit everything from [GluedToolsERC20](#-gluedtoolserc20) (all glue ops, transfers, burns, approvals, math, etc.).

---

## 🗺️ Visual Inheritance Map

```
                    GluedConstants
                    ┌──────────────────────────────────┐
                    │ GLUE_STICK_ERC20                 │
                    │ GLUE_STICK_ERC721                │
                    │ PRECISION, ETH_ADDRESS           │
                    │ DEAD_ADDRESS                     │
                    └────────────┬─────────────────────┘
                                 │
           ┌─────────────────────┴─────────────────────┐
           │                                           │
           ▼                                           ▼
    GluedToolsBase                            GluedToolsERC20Base
    ┌────────────────────┐                    ┌────────────────────┐
    │ nnrtnt modifier    │                    │ nnrtnt modifier    │
    │ Glue functions     │                    │ Glue functions     │
    │ Transfers (all)    │                    │ Transfers (ERC20)  │
    │ Burns (all)        │                    │ Burns (ERC20)      │
    │ Math functions     │                    │ Approvals          │
    │ NFT support        │                    │ Math functions     │
    └────────┬───────────┘                    └────────┬───────────┘
             │                                         │
      ┌──────┴──────┐                           ┌──────┴──────┐
      │             │                           │             │
      ▼             ▼                           ▼             ▼
 GluedTools    StickyAsset               GluedToolsERC20  GluedLoan
 ┌──────────┐  InitStickyAsset           ┌──────────────┐  Receiver
 │ + Batch  │  ┌──────────────┐          │ + Batch      │ ┌─────────┐
 │ + Excess │  │ + Hooks      │          │ + Excess     │ │ + Loans │
 └──────────┘  │ + unglue()   │          └──────────────┘ │ + Info  │
               │ + flashLoan  │                           └─────────┘
               └──────────────┘
```

---

## 📝 Quick Cheat Sheet

### Most Used Constants
- `PRECISION` = 1e18 (100%)
- `ETH_ADDRESS` = address(0)

### Most Used Functions
- `_initializeGlue()` - Get or create glue
- `_transferAsset()` - Send tokens
- `_burnAsset()` - Burn to glue
- `_md512()` - Safe math
- `_balanceOfAsset()` - Check balance

### Remember
- Always use `nnrtnt` modifier on external functions with transfers
- Use `_md512` instead of `*` and `/` for large number math
- `ETH_ADDRESS` means native ETH, not WETH
- Burns should go to the glue, not `DEAD_ADDRESS`

---

<div align="center">

**Need help?** Join our [Discord](https://discord.gg/ZxqcBxC96w)

</div>
