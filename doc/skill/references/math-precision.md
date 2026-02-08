# Math & Precision Reference

## Golden Rule

**Never use raw `*` and `/` for token math.** Always use `_md512()` for 512-bit intermediate precision.

```solidity
// ❌ DANGEROUS — overflow and precision loss
uint256 result = amount * rate / PRECISION;

// ✅ SAFE — 512-bit intermediate
uint256 result = _md512(amount, rate, PRECISION);
```

## PRECISION System

`PRECISION = 1e18` represents 100%.

### Percentage Table

| Human | Solidity | Description |
|-------|----------|-------------|
| 100% | `1e18` | Full amount |
| 50% | `5e17` | Half |
| 25% | `25e16` | Quarter |
| 10% | `1e17` | Ten percent |
| 5% | `5e16` | Five percent |
| 1% | `1e16` | One percent |
| 0.5% | `5e15` | Half percent |
| 0.1% | `1e15` | Protocol fee |
| 0.01% | `1e14` | Flash loan fee |

### Common Calculations

```solidity
// Calculate 5% of an amount
uint256 fivePercent = _md512(amount, 5e16, PRECISION);

// Calculate 0.1% fee
uint256 fee = _md512(amount, 1e15, PRECISION);

// Calculate amount after 10% deduction
uint256 afterDeduction = _md512(amount, 9e17, PRECISION); // 90% of amount

// Round up (prevents underpayment in fees)
uint256 feeUp = _md512Up(amount, 1e15, PRECISION);
```

### Proportional Share (Unglue Formula)

```solidity
// How much collateral a user gets when burning tokens
uint256 supplyDelta = _md512(burnAmount, PRECISION, totalSupply);
uint256 collateralShare = _md512(collateralBalance, supplyDelta, PRECISION);
uint256 afterFee = _md512(collateralShare, PRECISION - PROTOCOL_FEE, PRECISION);
```

## Decimal Handling

Different tokens have different decimals (USDC = 6, ETH = 18, WBTC = 8). Use `_adjustDecimals()` to convert between them.

```solidity
// Convert amount from tokenIn decimals to tokenOut decimals
uint256 adjusted = _adjustDecimals(amount, tokenIn, tokenOut);
```

## Protocol Constants

```solidity
uint256 constant PRECISION = 1e18;        // 100%
uint256 constant PROTOCOL_FEE = 1e15;     // 0.1%
uint256 constant FLASH_LOAN_FEE = 1e14;   // 0.01%
address constant ETH_ADDRESS = address(0);
```
