# Security Checklist

Run this checklist before providing ANY contract to a user.

## Pre-Code Analysis

### Attack Vector Analysis
- [ ] **Access control:** Who can call what? Are admin functions protected?
- [ ] **Fund flow:** Is money-in vs money-out balanced? Can more be withdrawn than deposited?
- [ ] **Frontrunning:** Can transactions be sandwiched or front-run for profit?
- [ ] **Reentrancy:** Are state changes made before external calls? Is `nnrtnt` used?
- [ ] **Griefing:** Can someone make the contract unusable for others at low cost?
- [ ] **Admin rug:** Can an owner drain funds or change rules unfairly?
- [ ] **Edge cases:** Zero amounts? Empty arrays? Duplicate entries? Max values?
- [ ] **Economic incentives:** Is it profitable to attack? Does game theory work?

### Common Bad Design Patterns to Catch

**"Anyone can close bet and say who won"** → Anyone calls with their address as winner, steals funds.
*Fix:* Oracle for results, OR dispute period + staking, OR predetermined conditions on-chain.

**"Betting where house always wins 100%"** → No one would rationally participate.
*Fix:* Fair odds, fee-based revenue, provably fair randomness.

**"Staking with no rewards, just lockup"** → No incentive to stake.
*Fix:* Add yield, governance rights, fee distribution.

**"Everyone deposits and everyone loses"** → Zero-sum with no winners = no participation.
*Fix:* Add winner rewards, balanced risk/reward.

## Code-Level Checks

### 1. Access Control
```solidity
// ✅ Protected admin functions
function setFee(uint256 fee) external onlyOwner { ... }

// ❌ Unprotected critical function
function withdrawAll() external { ... } // ANYONE can drain!
```

### 2. Reentrancy Protection
```solidity
// ✅ Use nnrtnt modifier (EIP-1153 transient storage)
function withdraw() external nnrtnt { ... }

// ❌ No protection on state-changing + external call
function withdraw() external {
    uint256 bal = balances[msg.sender];
    payable(msg.sender).call{value: bal}(""); // REENTRANT!
    balances[msg.sender] = 0;
}
```

### 3. Safe Math
```solidity
// ✅ 512-bit precision
uint256 share = _md512(amount, feeRate, PRECISION);

// ❌ Raw operations — overflow risk
uint256 share = amount * feeRate / PRECISION;
```

### 4. Input Validation
```solidity
// ✅ Proper validation
require(amount > 0, "Zero amount");
require(recipient != address(0), "Zero address");
require(arr.length <= 100, "Too many items");
require(arr.length > 0, "Empty array");

// ❌ Missing checks
function process(uint256 amount, address to) { ... } // No validation!
```

### 5. Safe Transfers
```solidity
// ✅ Glue helpers handle everything
_transferAsset(token, to, amount, new uint256[](0), true);
uint256 received = _transferFromAsset(token, from, to, amount, ids, true);

// ❌ Raw transfers — no tax handling, can fail
IERC20(token).transfer(to, amount);
payable(to).transfer(amount); // Can fail on gas limit!
```

### 6. Loop Safety
```solidity
// ✅ Bounded loop
require(users.length <= 100, "Limit exceeded");
for (uint i; i < users.length; i++) { ... }

// ❌ Unbounded loop — DoS attack vector
for (uint i; i < users.length; i++) { ... } // If users[] grows, tx runs out of gas
```

### 7. Fund Accounting
```solidity
// ✅ Track balances properly
mapping(address => uint256) public deposits;
function withdraw(uint256 amount) external {
    require(deposits[msg.sender] >= amount, "Insufficient");
    deposits[msg.sender] -= amount;
    _transferAsset(token, msg.sender, amount, new uint256[](0), true);
}

// ❌ No tracking — can withdraw infinite times
function withdraw() external {
    _transferAsset(token, msg.sender, totalBalance, new uint256[](0), true);
}
```

## If ANY Issue Is Found

1. **Fix it** before giving code to the user
2. **Explain** what was wrong
3. **Teach** the security principle so they learn

Never give obviously exploitable code to non-expert users.
