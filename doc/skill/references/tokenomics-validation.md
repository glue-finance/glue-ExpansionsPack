# Tokenomics Validation

Always double-check math and provide **at least 5 scenarios** for every project.

## Standard Scenarios to Show

### Scenario 1: Small Burn
- Supply: 1,000,000 tokens
- Backing: 100 ETH
- Burn: 1,000 tokens
- Receives: `(1,000 / 1,000,000) × 100 × 0.999 = 0.0999 ETH`

### Scenario 2: Large Burn
- Supply: 1,000,000 tokens
- Backing: 100 ETH
- Burn: 100,000 tokens
- Receives: `(100,000 / 1,000,000) × 100 × 0.999 = 9.99 ETH`

### Scenario 3: With 10% Sticky Hook
- Supply: 1,000,000 tokens
- Backing: 100 ETH
- Burn: 10,000 tokens, Hook: 10%
- Base: `(10,000 / 1,000,000) × 100 × 0.999 = 0.999 ETH`
- After hook: `0.999 × 0.9 = 0.899 ETH`

### Scenario 4: Multiple Collaterals
- Supply: 1,000,000 tokens
- Backing: 50 ETH + 50,000 USDC
- Burn: 10,000 tokens
- ETH received: `(10,000 / 1,000,000) × 50 × 0.999 = 0.4995 ETH`
- USDC received: `(10,000 / 1,000,000) × 50,000 × 0.999 = 499.5 USDC`

### Scenario 5: After Supply Reduction
- Supply was 1,000,000, now 900,000 (100k already burned)
- Backing: 100 ETH (minus what was already withdrawn)
- Burn: 10,000 tokens
- Receives: `(10,000 / 900,000) × remaining_collateral × 0.999`
- **Key insight:** Each token is worth MORE as supply decreases

## What to Validate for Custom Projects

### Fee Impact
- Show calculations with and without hooks
- Show protocol fee (0.1%) impact
- Show custom fee impact if applicable
- **Worst case:** Maximum fees + maximum hooks
- **Best case:** No hooks, just protocol fee
- **Expected case:** Normal 0.1% fee, typical hook sizes

### Arbitrage Alignment
Explain how arbitrage keeps price aligned:
1. Market price drops below backing → arbitrageur buys cheap → burns for collateral → profits → price rises
2. Market price above backing → holders accumulate → collateral grows → backing increases
3. Show the profit calculation: `profit = collateral_received - market_price_paid - gas`

### Supply Dynamics
- More burns = less supply = more value per remaining token
- Show how recovery after a bear market benefits holders who didn't sell
- Example: If 50% supply burned, same market cap = 2x token price

## Revenue-to-Glue Examples

When a project generates revenue and routes it to Glue:

```
Initial: 1M supply, 100 ETH backing → backed price = 0.0001 ETH/token
Revenue: 10 ETH added to Glue
After:   1M supply, 110 ETH backing → backed price = 0.00011 ETH/token (+10%)

With burns:
If 100k tokens burned during this period:
900k supply, ~109 ETH remaining → backed price = 0.000121 ETH/token (+21%)
```

## Warning Signs in Tokenomics

Flag these to the user:
- Hooks too high (>20%) — reduces incentive to burn
- Revenue too low — backing grows too slowly to matter
- Supply too high with low backing — backed price is negligible
- No mechanism for collateral growth — static backing loses relevance over time
- Circular dependencies — token price depends on itself
