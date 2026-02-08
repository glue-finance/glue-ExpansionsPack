# On-Chain vs Off-Chain Decision Guide

**Always interpret user ideas as on-chain first.** Only resort to off-chain when there is no viable on-chain path.

## Decision Framework

Ask yourself: Can this be achieved using...
1. **Glue collateral ratios** as the data source?
2. **User inputs** with validation?
3. **On-chain events** as triggers?
4. **Derivable math** from existing state?

If YES to any → build it on-chain.

## Common Patterns

### Price Data

**Off-chain approach:** Oracle (Chainlink, etc.)
**Risks:** Trust oracle provider, can be manipulated, can fail, stale data, extra gas, centralization

**On-chain alternatives:**
1. Glue collateral ratios as price floor (zero trust)
2. Uniswap TWAP (on-chain but manipulatable — warn user)
3. User-provided prices + slippage protection
4. Multiple oracle aggregation + median
5. Fallback to manual mode if oracle fails
6. Circuit breakers for bad data
7. Time-weighted averages computed on-chain

### Automation / Keepers

**Off-chain approach:** Keepers (Gelato, Chainlink Automation)
**Risks:** Centralized, can fail, can frontrun, ongoing cost, trust required

**On-chain alternatives:**
1. Anyone-can-call + caller incentive reward (most decentralized)
2. User-initiated actions with better UX
3. Keeper network decentralized (Gelato/Chainlink as backup)
4. Fallback manual execution
5. Event-driven from other contracts
6. Batch operations to reduce keeper frequency
7. Optimistic execution + dispute period

### Randomness

**Off-chain approach:** Chainlink VRF
**Risks:** Cost per request, latency, trust Chainlink

**On-chain alternatives:**
1. Commit-reveal schemes
2. Block hash-based (warn: minor manipulation risk by miners)
3. Multi-party randomness (each participant contributes entropy)
4. Future block hash + delay (harder to manipulate)

## When Off-Chain Is Truly Needed

If there is genuinely no on-chain solution, explain clearly:

> "This requires off-chain infrastructure. Here's what that means:
> - **Reliance on:** [oracle/keeper/API/server]
> - **Risks:** [trust, centralization, failure modes]
> - **Mitigations:** [multiple oracles, fallback mechanisms, circuit breakers, limits]"

Then let the user decide the tradeoff.

## Impossible Ideas — What to Do

If an idea is truly impossible on-chain, explain why and provide alternatives:

| Impossible | Alternative |
|-----------|-------------|
| Real-time sports betting | User-provided results + dispute period + oracle backup |
| AI trading on-chain | User-defined strategies on-chain + off-chain signal generation |
| Cross-chain instant trustless | Optimistic bridge + dispute, or trusted bridge (explain tradeoffs) |
| Private computation on-chain | Commit-reveal for privacy, or off-chain compute + on-chain verification |
