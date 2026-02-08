# Glue Helper Functions Reference

These helpers are available in GluedToolsBase and inherited by all Glue contracts. **Always use these instead of raw Solidity operations.**

## Critical Rule: Always Use Helpers

| ❌ Never Do This | ✅ Always Do This | Why |
|-----------------|------------------|-----|
| `IERC20(token).transfer(to, amount)` | `_transferAsset(token, to, amount, ids, fungible)` | Handles tax tokens, ETH, ERC20, ERC721 safely |
| `IERC20(token).transferFrom(from, to, amount)` | `_transferFromAsset(token, from, to, amount, ids, fungible)` | Returns actual received amount after tax |
| `payable(to).transfer(amount)` | `_transferAsset(address(0), to, amount, ids, true)` | Can't fail on gas limit |
| `token.burn(amount)` | `_burnAsset(token, amount, fungible, ids)` | Burns to Glue safely, handles non-burnable |
| `a * b / c` | `_md512(a, b, c)` | 512-bit precision, prevents overflow |
| Manual decimal conversion | `_adjustDecimals(amount, tokenIn, tokenOut)` | Handles all decimal differences |
| `0xEeee...` for ETH | `address(0)` | Glue Protocol standard |

**Teach these every single time** a user needs a transfer, burn, or math operation.

## Reentrancy Guard

```solidity
modifier nnrtnt()
```
EIP-1153 transient storage reentrancy guard. Use on all external/public state-changing functions.

## Glue Management

```solidity
// Create a Glue for an asset (reverts if already exists or invalid)
_initializeGlue(address asset, bool fungible) → address glue

// Try to create a Glue (returns address(0) if fails)
_tryInitializeGlue(address asset, bool fungible) → address glue

// Get Glue address and check if sticky
_getGlue(address asset, bool fungible) → (address glue, bool isSticky)

// Check if an asset has a Glue
_hasAGlue(address asset, bool fungible) → bool

// Get all collateral balances for a Glue
_getGlueBalances(address asset, address[] collaterals, bool fungible) → uint256[]

// Get total supply of sticky asset
_getTotalSupply(address asset, bool fungible) → uint256

// Calculate collateral amounts for a given burn amount
_getCollateralbyAmount(address asset, uint256 amount, address[] collaterals, bool fungible) → uint256[]
```

## Asset Transfers

```solidity
// Safe transfer — handles ETH, ERC20, ERC721, tax tokens
_transferAsset(
    address token,      // Token address (address(0) for ETH)
    address to,         // Recipient
    uint256 amount,     // Amount (for ERC20/ETH)
    uint256[] tokenIDs, // Token IDs (for ERC721, empty array for ERC20)
    bool fungible       // true = ERC20, false = ERC721
)

// Safe transferFrom — returns actual received amount (handles tax tokens)
_transferFromAsset(
    address token,
    address from,
    address to,
    uint256 amount,
    uint256[] tokenIDs,
    bool fungible
) → uint256 actualReceived

// Transfer with balance check
_transferAssetChecked(
    address token,
    address to,
    uint256 amount,
    uint256[] tokenIDs,
    bool fungible
) → uint256 actual

// Batch transfer (available in GluedTools / GluedToolsERC20)
_batchTransferAsset(
    address token,
    address[] recipients,
    uint256[] amounts,
    uint256[] tokenIDs,
    uint256 total,
    bool fungible
)
```

## Asset Burns

```solidity
// Burn tokens — burns to the asset's Glue safely
_burnAsset(
    address token,
    uint256 amount,
    bool fungible,
    uint256[] tokenIDs
)

// Burn from a specific address
_burnAssetFrom(
    address token,
    address from,
    uint256 amount,
    bool fungible,
    uint256[] tokenIDs
)
```

## Math (512-bit Precision)

```solidity
// (a * b) / denominator — 512-bit intermediate, rounds down
_md512(uint256 a, uint256 b, uint256 denominator) → uint256

// (a * b) / denominator — 512-bit intermediate, rounds up
_md512Up(uint256 a, uint256 b, uint256 denominator) → uint256

// Adjust amount between different decimal tokens
_adjustDecimals(uint256 amount, address tokenIn, address tokenOut) → uint256
```

## Percentage Math with PRECISION

`PRECISION = 1e18 = 100%`

| Percentage | Value |
|-----------|-------|
| 100% | `1e18` |
| 50% | `5e17` |
| 10% | `1e17` |
| 5% | `5e16` |
| 1% | `1e16` |
| 0.1% | `1e15` |
| 0.01% | `1e14` |

**Calculate a fee:**
```solidity
uint256 feeAmount = _md512(amount, 5e16, PRECISION); // 5% of amount
```

**Round up (prevents underpayment):**
```solidity
uint256 feeAmount = _md512Up(amount, 1e15, PRECISION); // 0.1% rounded up
```

## Utility

```solidity
// Get token decimals
_getTokenDecimals(address token, bool fungible) → uint8

// Get balance of an asset for an account
_balanceOfAsset(address token, address account, bool fungible) → uint256

// Get owner of an NFT
_getNFTOwner(address token, uint256 tokenId) → address
```

## ETH Handling

ETH is always represented as `address(0)` in Glue Protocol.

```solidity
// Check if dealing with ETH
if (token == address(0)) { ... }
if (token == ETH_ADDRESS) { ... } // ETH_ADDRESS == address(0)

// Transfer ETH
_transferAsset(address(0), recipient, amount, new uint256[](0), true);
```
