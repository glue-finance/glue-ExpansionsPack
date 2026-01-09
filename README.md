# Glue Protocol Expansions Pack

[![npm version](https://badge.fury.io/js/@glue-finance/expansions-pack.svg)](https://badge.fury.io/js/@glue-finance/expansions-pack)
[![License: BUSL-1.1](https://img.shields.io/badge/License-BUSL--1.1-blue.svg)](https://github.com/glue-finance/glue-expansionspack/blob/main/LICENSE)

**Build on Glue Protocol with pre-built, battle-tested contracts. Focus on your innovation, not protocol complexity.**

```bash
npm install @glue-finance/expansions-pack
```

---

## 🎯 What is This?

The Glue Expansions Pack provides **three core tools** for building with Glue Protocol:

### **1. Sticky Assets** - Create Tokens Native to Glue
Build tokens that integrate natively with Glue Protocol. Automatic glue creation, collateral backing, and holder redemption.

```solidity
import "@glue-finance/expansions-pack/base/StickyAsset.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20, StickyAsset {
    constructor() 
        ERC20("My Token", "MTK")
        StickyAsset("https://metadata.json", [true, false])
    {
        _mint(msg.sender, 1000000 * 10**18);
    }
}
```

**Use StickyAsset when:** Creating tokens that should have native Glue integration (collateral backing, holder redemption)

---

### **2. GluedTools** - Build Smart Contracts That Interact with Glue
Build routers, aggregators, or any contract that needs to interact with glued assets. Includes helpers for transfers, burns, math, and more.

```solidity
import "@glue-finance/expansions-pack/base/GluedToolsERC20.sol";

contract MyRouter is GluedToolsERC20 {
    function swap(address token, uint256 amount) external {
        address glue = _initializeGlue(token);
        _transferFromAsset(token, msg.sender, address(this), amount);
        // Use helper functions for safe operations
    }
}
```

**Use GluedTools when:** Building applications that interact with Glue Protocol  
**Use GluedToolsERC20 when:** Only working with ERC20 tokens (smaller bytecode)

---

### **3. GluedLoanReceiver** - Build Flash Loan Applications
Create flash loan bots, arbitrage strategies, or MEV applications with automatic repayment handling.

```solidity
import "@glue-finance/expansions-pack/base/GluedLoanReceiver.sol";

contract ArbitrageBot is GluedLoanReceiver {
    function _executeFlashLoanLogic(bytes memory params) internal override returns (bool) {
        address token = getCurrentCollateral();
        uint256 borrowed = getCurrentTotalBorrowed();
        
        // Your arbitrage strategy here
        
        return true; // Repayment is automatic!
    }
}
```

**Use GluedLoanReceiver when:** Building flash loan applications (arbitrage, MEV, liquidations)

---

## 📦 Full Package Contents

### **Creating Sticky Assets**
| Contract | Purpose |
|----------|---------|
| `StickyAsset` | Standard sticky asset (constructor-based) |
| `InitStickyAsset` | Proxy-friendly sticky asset (factory pattern) |

### **Building on Glue**
| Contract | Purpose | Size |
|----------|---------|------|
| `GluedToolsMin` | Minimal helpers (ERC20 + ERC721) | 296 lines |
| `GluedToolsERC20Min` | Minimal helpers (ERC20 only) | 244 lines |
| `GluedTools` | Full-featured (ERC20 + ERC721 + GluedMath) | 355 lines |
| `GluedToolsERC20` | Full-featured (ERC20 only + GluedMath) | 279 lines |
| `GluedLoanReceiver` | Flash loan receiver | 627 lines |

### **Libraries**
| Library | Purpose |
|---------|---------|
| `GluedConstants` | Protocol addresses & constants (single source of truth) |
| `GluedMath` | High-precision math, decimal conversion |

### **Interfaces**
`IGlueERC20`, `IGlueERC721`, `IGlueStickERC20`, `IGlueStickERC721`, `IStickyAsset`, `IInitStickyAsset`, `IGluedHooks`, `IGluedLoanReceiver`

### **Testing Mocks**
`MockUnglueERC20`, `MockUnglueERC721`, `MockBatchUnglueERC20`, `MockBatchUnglueERC721`, `MockFlashLoan`, `MockGluedLoan`, `MockStickyAsset`, `MockGluedLoanReceiver`

### **Examples**
`BasicStickyToken`, `AdvancedStickyToken`, `ExampleArbitrageBot`

---

## 🛠️ Helper Functions You Get

### **From GluedToolsMin** (All sticky assets and tools inherit these)

```solidity
// Safe transfers (handles tax tokens, ETH, ERC20, ERC721)
_transferAsset(token, to, amount, tokenIds, fungible);
_transferFromAsset(token, from, to, amount, tokenIds, fungible) returns (actualReceived);

// Glue operations
_initializeGlue(asset, fungible) returns (glue);
_hasAGlue(asset, fungible) returns (bool);

// Balances
_balanceOfAsset(token, account, fungible) returns (balance);
_getGlueBalances(asset, collaterals, fungible) returns (balances);
_getTotalSupply(asset, fungible) returns (supply);

// NFT helpers
_getNFTOwner(nftContract, tokenId) returns (owner);
```

### **From GluedTools** (Advanced features + GluedMath)

```solidity
// Burns to glue
_burnAsset(token, amount, fungible, tokenIds);
_burnAssetFrom(token, from, amount, fungible, tokenIds);

// High-precision math (512-bit, prevents overflow)
_md512(a, b, denominator) returns (result);
_md512Up(a, b, denominator) returns (result); // rounds up

// Decimal conversion (USDC ↔ WETH, any token ↔ any token)
_adjustDecimals(amount, tokenIn, tokenOut) returns (adjusted);

// Batch operations
_batchTransferAsset(token, recipients, amounts, tokenIds, total, fungible);

// Additional utilities
_getTokenDecimals(token, fungible) returns (decimals);
_handleExcess(token, amount, glue);
_transferAssetChecked(token, to, amount, tokenIds, fungible) returns (actual);
```

**Why use helpers?**
- ✅ Handles tax tokens automatically
- ✅ Safe for ETH, ERC20, and ERC721
- ✅ Prevents overflow with 512-bit math
- ✅ Automatic decimal adjustments
- ✅ Battle-tested across all contracts

---

## 🏗️ Architecture

```
GluedConstants (86 lines)
  ├─ Protocol addresses (GLUE_STICK_ERC20, GLUE_STICK_ERC721)
  ├─ Common constants (PRECISION, ETH_ADDRESS, DEAD_ADDRESS)
  └─ Interface imports
        ↓
GluedToolsMin (296L) / GluedToolsERC20Min (244L)
  ├─ Safe transfer functions
  ├─ Glue initialization
  └─ Balance helpers
        ↓
GluedTools (355L) / GluedToolsERC20 (279L)
  ├─ All Min features
  ├─ GluedMath integration
  ├─ Burn functions
  └─ Advanced operations
        ↓
Your Contract
  └─ Inherits everything above
```

**Single source of truth. Zero duplication. Clean inheritance.**

---

## 🎯 Quick Guide

### **I want to create a token backed by collateral**
→ Use `StickyAsset` (standard) or `InitStickyAsset` (for factories)

```solidity
contract MyToken is ERC20, StickyAsset {
    constructor() 
        ERC20("My Token", "MTK")
        StickyAsset("https://metadata.json", [true, false])
    {
        _mint(msg.sender, 1000000 * 10**18);
    }
}
```

### **I want to build an app that interacts with Glue**
→ Use `GluedTools` (supports ERC20 + ERC721) or `GluedToolsERC20` (ERC20 only, smaller)

```solidity
contract MyRouter is GluedToolsERC20 {
    function myFunction() external {
        // Access all helpers: _transferAsset, _burnAsset, _md512, etc.
    }
}
```

### **I want to build a flash loan bot**
→ Use `GluedLoanReceiver`

```solidity
contract Bot is GluedLoanReceiver {
    function _executeFlashLoanLogic(bytes memory) internal override returns (bool) {
        // Your strategy - repayment is automatic
        return true;
    }
}
```

---

## 💡 How Glue Works

1. **Apply Glue** - `applyTheGlue(token)` creates a Glue contract for your token
2. **Add Collateral** - Anyone sends ETH, USDC, or any ERC20 to the Glue
3. **Holders Burn to Claim** - Burn tokens → receive `(burned / totalSupply) × collateral × (1 - 0.1% fee)`
4. **Flash Loans Available** - Borrow from glue collateral, repay + 0.01% fee

**Fully onchain. No oracles. Trustless. Permissionless.**

---

## 🌍 Deployed Networks

| Network | Chain ID | Status |
|---------|----------|--------|
| Ethereum Mainnet | 1 | ✅ |
| Base | 8453 | ✅ |
| Optimism | 10 | ✅ |
| Sepolia (testnet) | 11155111 | ✅ |
| Base Sepolia | 84532 | ✅ |
| Optimism Sepolia | 11155420 | ✅ |

**Same addresses on all networks.**

**Want another network?** [Join Discord](https://discord.gg/ZxqcBxC96w)

---

## 🔐 License & Protocol Addresses

**BUSL-1.1 License** - Free to use with official addresses:
- ✅ Build and deploy sticky assets
- ✅ Create applications on Glue
- ✅ Earn money from your integrations

**You CANNOT:**
- ❌ Modify these addresses in GluedConstants:
  - `GLUE_STICK_ERC20`: `0x5fEe29873DE41bb6bCAbC1E4FB0Fc4CB26a7Fd74`
  - `GLUE_STICK_ERC721`: `0xe9B08D7dC8e44F1973269E7cE0fe98297668C257`

See [LICENSE](./LICENSE) for complete terms.

---

## 📖 Documentation

- **[Protocol Wiki](https://wiki.glue.finance)** - Complete Glue Protocol documentation
- **[V2 Update Guide](./doc/V2_UPDATE.md)** - What's new in v2.0 (for existing users)
- **[vibecodersBible.txt](./doc/vibecodersBible.txt)** - AI context guide (paste in Claude/ChatGPT)
- **[Solidity Docs](https://docs.soliditylang.org/en/v0.8.33/)** - Language reference

---

## 🎨 Examples

### Revenue-Sharing Token (with hooks)
```solidity
contract RevenueToken is ERC20, StickyAsset {
    address public treasury;
    
    constructor(address _treasury) 
        ERC20("Revenue", "REV")
        StickyAsset("https://metadata.json", [true, true]) // Enable hooks
    {
        treasury = _treasury;
        _mint(msg.sender, 1000000 * 10**18);
    }
    
    // 10% of withdrawn collateral goes to treasury
    function _calculateCollateralHookSize(address, uint256 amount) internal pure override returns (uint256) {
        return _md512(amount, 1e17, PRECISION); // 10%
    }
    
    function _processCollateralHook(address asset, uint256 amount, bool isETH, address) internal override {
        if (isETH) {
            payable(treasury).transfer(amount);
        } else {
            _transferAsset(asset, treasury, amount, new uint256[](0), true);
        }
    }
}
```

### Flash Loan Bot
```solidity
contract MyBot is GluedLoanReceiver {
    function executeArbitrage(address stickyAsset, address collateral, uint256 amount) external {
        address[] memory glues = new address[](1);
        glues[0] = _initializeGlue(stickyAsset);
        _requestGluedLoan(true, glues, collateral, amount, "");
    }
    
    function _executeFlashLoanLogic(bytes memory) internal override returns (bool) {
        // Your strategy
        return true;
    }
}
```

More examples in `contracts/examples/`

---

## 📚 Import Paths

```solidity
// Creating sticky assets
import "@glue-finance/expansions-pack/base/StickyAsset.sol";
import "@glue-finance/expansions-pack/base/InitStickyAsset.sol";

// Building apps that interact with Glue (supports ERC20 + ERC721)
import "@glue-finance/expansions-pack/base/GluedTools.sol";
import "@glue-finance/expansions-pack/tools/GluedToolsMin.sol"; // Minimal version

// Building apps (ERC20 only - better if you don't use NFTs)
import "@glue-finance/expansions-pack/base/GluedToolsERC20.sol";
import "@glue-finance/expansions-pack/tools/GluedToolsERC20Min.sol"; // Minimal version

// Flash loans
import "@glue-finance/expansions-pack/base/GluedLoanReceiver.sol";

// Libraries
import "@glue-finance/expansions-pack/libraries/GluedMath.sol";
import "@glue-finance/expansions-pack/libraries/GluedConstants.sol";

// Interfaces
import "@glue-finance/expansions-pack/interfaces/IGlueERC20.sol";
import "@glue-finance/expansions-pack/interfaces/IGlueERC721.sol";
```

---

## 💡 Key Concepts

### **Sticky Asset**
A token (ERC20 or ERC721) that has been "glued" - it has a Glue contract holding collateral. Token holders can burn tokens to receive proportional collateral.

### **Glue**
A contract that holds collateral for a specific sticky asset. Created by calling `applyTheGlue(token)`.

### **Ungluing**
Burning sticky tokens to withdraw collateral: `(tokens burned / total supply) × collateral × (1 - 0.1% fee)`

### **Glued Loan**
Flash loan from glue collateral. Borrow, execute strategy, auto-repay + 0.01% fee.

### **Hooks**
Custom logic executed during ungluing. Use to capture fees, redistribute value, or implement custom mechanics.

---

## 🎓 Best Practices

### **DO:**
- ✅ Use `_transferAsset()` for transfers (handles tax tokens automatically)
- ✅ Use `_burnAsset()` for burns (safe, automatic)
- ✅ Use `_md512()` for fee calculations (high-precision, prevents overflow)
- ✅ Use `address(0)` for ETH
- ✅ Use `PRECISION` (1e18) for percentages
- ✅ Add limits to loops (`require(arr.length <= 100)`)
- ✅ Inherit from appropriate base contract

### **DON'T:**
- ❌ Modify GLUE_STICK addresses (license violation)
- ❌ Use `IERC20.transfer()` (doesn't handle tax tokens)
- ❌ Use `payable.transfer()` (can fail silently)
- ❌ Use raw `* /` for fees (overflow risk)
- ❌ Manually handle decimals (use `_adjustDecimals()`)
- ❌ Create unbounded loops

---

## 🔧 Helper Functions Reference

### **Transfers**
```solidity
_transferAsset(token, to, amount, tokenIds, fungible);
_transferFromAsset(token, from, to, amount, tokenIds, fungible) returns (actualReceived);
```

### **Burns**
```solidity
_burnAsset(token, amount, fungible, tokenIds);
_burnAssetFrom(token, from, amount, fungible, tokenIds);
```

### **Math**
```solidity
_md512(a, b, denominator); // High-precision mul-div
_md512Up(a, b, denominator); // Rounds up
_adjustDecimals(amount, tokenIn, tokenOut); // Decimal conversion
```

### **Balances**
```solidity
_balanceOfAsset(token, account, fungible);
_getGlueBalances(asset, collaterals, fungible);
```

### **Glue Operations**
```solidity
_initializeGlue(asset, fungible) returns (glue);
_hasAGlue(asset, fungible) returns (bool);
```

**Full reference:** See contract files or [V2_UPDATE.md](./doc/V2_UPDATE.md)

---

## 🌟 Why Glue Protocol?

- **Fully Onchain** - No oracles, no keepers, no offchain dependencies
- **Composable** - Works with ANY ERC20/ERC721, integrates with ANY DeFi protocol
- **Capital Efficient** - Flash loans across multiple sources, batch operations
- **Developer Friendly** - 3-line integration, inherit-and-done
- **Battle-Tested** - Live on mainnet handling real value

---

## 📊 Package Structure

```
contracts/
├── base/
│   ├── StickyAsset.sol          (Create sticky assets)
│   ├── InitStickyAsset.sol      (Proxy-friendly version)
│   ├── GluedLoanReceiver.sol    (Flash loans)
│   ├── GluedTools.sol           (Full helpers, ERC20 + ERC721)
│   └── GluedToolsERC20.sol      (Full helpers, ERC20 only)
├── tools/
│   ├── GluedToolsMin.sol        (Minimal helpers, ERC20 + ERC721)
│   └── GluedToolsERC20Min.sol   (Minimal helpers, ERC20 only)
├── libraries/
│   ├── GluedConstants.sol       (Protocol constants)
│   └── GluedMath.sol            (High-precision math)
├── interfaces/
│   └── [All protocol interfaces]
├── mocks/
│   └── [Testing mocks]
└── examples/
    └── [Ready-to-deploy examples]
```

---

## 🤖 AI-Assisted Development

**Using Claude, ChatGPT, or other AI?**

Paste [`doc/vibecodersBible.txt`](./doc/vibecodersBible.txt) into your chat for:
- ✅ Expert Glue Protocol assistance
- ✅ Always uses helper functions (never raw operations)
- ✅ Creates TypeScript tests + deployment scripts automatically
- ✅ Suggests fully onchain solutions
- ✅ Protects protocol addresses (won't help modify them)
- ✅ Explains onchain vs offchain tradeoffs
- ✅ Suggests revenue generation ideas

---

## 🧪 Testing

Use included mocks for easy testing:

```solidity
import "@glue-finance/expansions-pack/mocks/MockUnglueERC20.sol";

MockUnglueERC20 mockGlue = new MockUnglueERC20();
mockGlue.setStickyAsset(myToken);
mockGlue.addCollateral(USDC, 1000e6);
mockGlue.unglue([USDC], 100e18, recipient);
```

Mocks simulate real protocol behavior without full deployment.

---

## 🔗 Resources

- 📖 **[Wiki](https://wiki.glue.finance)** - Complete documentation
- 💬 **[Discord](https://discord.gg/ZxqcBxC96w)** - Community & support
- 💻 **[GitHub](https://github.com/glue-finance/glue-ExpansionsPack)** - Source code
- 🌐 **[Website](https://glue.finance)** - Learn more
- 🐦 **[Twitter/X](https://x.com/glue_finance)** - Updates

---

## 📈 Coming from v1.x?

See [V2_UPDATE.md](./doc/V2_UPDATE.md) for:
- What's new in v2.0
- Why the architecture is superior
- Migration guide
- Performance improvements (27% smaller bytecode!)
- Development speed improvements (10-96x faster!)

**No code changes needed for existing StickyAsset users.**

---

## 🎁 What You Get

- **31 Contracts** ready to use
- **6 Networks** supported (+ more on request)
- **Helper Functions** for safe operations
- **Testing Mocks** for easy testing
- **Professional Documentation** throughout

---

**Built with ❤️ by La-Li-Lu-Le-Lo (@lalilulel0z) and the Glue Finance Team**

🚀 **Start building:** `npm install @glue-finance/expansions-pack`
