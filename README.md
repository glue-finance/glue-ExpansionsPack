# Glue Protocol Expansions Pack

[![npm version](https://badge.fury.io/js/@glueExpansionsPack.svg)](https://badge.fury.io/js/@glueExpansionsPack)
[![License: BUSL-1.1](https://img.shields.io/badge/License-BUSL--1.1-blue.svg)](https://github.com/glue-finance/glue-expansionspack/blob/main/LICENSE)

**Expand the Glue Protocol with pre-built, battle-tested smart contracts designed for rapid development.**

## What is the Glue Expansions Pack?

The Glue Expansions Pack provides **ready-to-use smart contract components** that allow developers to build on top of the Glue Protocol without needing to understand all the complex underlying interactions. Instead of implementing protocol-specific logic from scratch, builders can focus entirely on their unique business logic while leveraging the power of the Glue ecosystem.

### 🎯 **Main Use Cases**

The Expansions Pack is built around **two primary expansion patterns**:

#### 1. **StickyAsset** - Create Your Own Sticky Tokens
Transform any token (ERC20, ERC721, or custom) into a **sticky asset** backed by collateral from the Glue Protocol. Perfect for:
- **Native Glue integration** with automatic protocol compatibility
- **Hook implementations** for custom logic during ungluing operations
- **Collateral-backed tokens** using Glue's native backing system
- **Protocol fee handling** with automatic distribution mechanisms
- **Multi-interface support** for both ERC20 and ERC721 sticky assets

#### 2. **GluedLoanReceiver** - Access Instant Liquidity
Build applications that leverage **flash loans** from the Glue Protocol with automatic repayment handling. Ideal for:
- **Glue Protocol flash loans** with type-safe interface integration
- **Automatic repayment handling** built into the base contract
- **Cross-glue liquidity** aggregation for larger loan amounts
- **Protocol-native fee calculations** with built-in fee handling
- **Multi-glue support** for both ERC20 and ERC721 glue contracts

### 💡 **Why Use the Expansions Pack?**

**Focus on Your Innovation, Not Protocol Complexity:**
- ✅ **Pre-built integrations** - No need to understand Glue's internal mechanics
- ✅ **Battle-tested code** - Production-ready contracts with comprehensive testing
- ✅ **Automatic protocol handling** - Fees, hooks, and edge cases handled automatically  
- ✅ **Plug-and-play design** - Import, inherit, and customize for your needs
- ✅ **Comprehensive documentation** - Examples and guides for every use case
- ✅ **Future-proof** - Automatically compatible with Glue Protocol updates

**Example: Create a Yield Token in 10 Lines:**
```solidity
import "@glueExpansionsPack/base/StickyAsset.sol";

contract MyYieldToken is ERC20, StickyAsset {
    constructor() 
        ERC20("Yield Token", "YIELD")
        StickyAsset("https://metadata.json", [true, true]) // ERC20 with hooks
    {
        _mint(msg.sender, 1000000 * 10**18);
    }
    
    // Your yield logic automatically benefits from Glue Protocol backing!
}

## Overview

The Glue Expansions Pack includes essential interfaces, base contracts, libraries, and testing utilities for rapid Glue Protocol integration:

- **Base Contracts**: `StickyAsset`, `GluedLoanReceiver` - Core building blocks for protocol expansion
- **Interfaces**: `IGlueERC20`, `IGlueERC721`, `IStickyAsset`, `IGluedLoanReceiver` - Standard protocol interfaces  
- **Libraries**: `GluedMath` - High-precision mathematical operations and decimal conversions
- **Examples**: Ready-to-deploy implementations for common use cases
- **Testing Mocks**: Comprehensive testing framework with accurate protocol simulation

## Installation

```bash
npm install @glueExpansionsPack
```

## Usage

Once installed, you can import and use the base contracts in your Solidity files. The two main expansion patterns are:

### 1. Creating Sticky Assets with StickyAsset

Inherit from `StickyAsset` to transform any token into a sticky asset backed by the Glue Protocol:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@glueExpansionsPack/base/StickyAsset.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20, StickyAsset {
    constructor() 
        ERC20("My Sticky Token", "MST")
        StickyAsset(
            "https://example.com/metadata.json", // EIP-7572 contract URI
            [true, false] // [FUNGIBLE: true (ERC20), HOOK: false (no hooks)]
        ) 
    {
        _mint(msg.sender, 1000000 * 10**18);
        // Your token now automatically integrates with Glue Protocol!
    }
    
    // Optional: Override hook functions for custom behavior
    function _calculateStickyHookSize(uint256 amount) internal view override returns (uint256) {
        // Custom logic for sticky asset hooks
        return 0; // No hooks by default
    }
    
    function _processStickyHook(uint256 amount, uint256[] memory tokenIds) internal override {
        // Custom logic when hooks are executed
        // Example: burn tokens, distribute to treasury, etc.
    }
}
```

### 2. Building Flash Loan Applications with GluedLoanReceiver

Inherit from `GluedLoanReceiver` to build applications that leverage instant liquidity:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@glueExpansionsPack/base/GluedLoanReceiver.sol";

contract MyArbitrageBot is GluedLoanReceiver {
    
    // Implement your core business logic here
    function _executeFlashLoanLogic(bytes memory params) internal override returns (bool success) {
        // Access loan information
        uint256 totalBorrowed = this.getCurrentTotalBorrowed();
        address collateral = this.getCurrentCollateral();
        
        // Decode your custom parameters
        (address targetDEX, uint256 minProfit) = abi.decode(params, (address, uint256));
        
        // Your arbitrage/MEV/liquidation logic here
        uint256 profit = _executeYourStrategy(collateral, totalBorrowed, targetDEX);
        
        // Return true if successful (repayment is automatic)
        return profit >= minProfit;
    }
    
    function _executeYourStrategy(address token, uint256 amount, address dex) internal returns (uint256 profit) {
        // Your custom strategy implementation
        // Buy low, sell high, liquidate positions, etc.
        return 0; // Return actual profit
    }
    
    // Public function to initiate flash loans
    function executeStrategy(
        address stickyAsset,
        address collateral,
        uint256 amount,
        address targetDEX,
        uint256 minProfit
    ) external {
        bytes memory params = abi.encode(targetDEX, minProfit);
        _requestFlashLoan(stickyAsset, collateral, amount, params);
    }
}
```

### 3. Using Protocol Interfaces

Import standard interfaces for type-safe interactions with the Glue Protocol:

```solidity
import "@glueExpansionsPack/interfaces/IGlueERC20.sol";
import "@glueExpansionsPack/interfaces/IGlueERC721.sol";
import "@glueExpansionsPack/interfaces/IStickyAsset.sol";

contract MyDApp {
    function interactWithGlue(address glueContract, address collateral, uint256 amount) external {
        // Type-safe interaction with any Glue contract
        IGlueERC20(glueContract).unglue([collateral], amount, msg.sender);
    }
}
```

### 4. High-Precision Math Operations

Use the GluedMath library for accurate calculations:

```solidity
import "@glueExpansionsPack/libraries/GluedMath.sol";

contract MyContract {
    using GluedMath for uint256;

    function calculatePreciseAmount(uint256 a, uint256 b, uint256 denominator) public pure returns (uint256) {
        return GluedMath.md512(a, b, denominator);
    }
    
    function adjustTokenDecimals(uint256 amount, address tokenIn, address tokenOut) public view returns (uint256) {
        return GluedMath.adjustDecimals(amount, tokenIn, tokenOut);
    }
}
```

## GluedMath Library - High-Precision Calculations

The `GluedMath` library provides **ultra-precise mathematical operations** and **automatic decimal adjustments** essential for DeFi applications. It handles the complex math needed for cross-token calculations, fee computations, and proportion calculations.

### Key Functions

#### 1. **High-Precision Multiplication and Division (`md512`)**
Performs multiplication and division with 512-bit intermediate precision to prevent overflow and maintain accuracy:

```solidity
import "@glueExpansionsPack/libraries/GluedMath.sol";

contract PrecisionExample {
    using GluedMath for uint256;
    
    uint256 constant PRECISION = 1e18;
    
    function calculateFee(uint256 amount, uint256 feeRate) public pure returns (uint256) {
        // Calculate 2.5% fee with perfect precision
        // feeRate = 25e15 (2.5% in 1e18 precision)
        return GluedMath.md512(amount, feeRate, PRECISION);
    }
    
    function calculateProportion(uint256 userAmount, uint256 totalSupply, uint256 totalValue) public pure returns (uint256) {
        // Calculate user's proportional share: (userAmount * totalValue) / totalSupply
        return GluedMath.md512(userAmount, totalValue, totalSupply);
    }
}
```

#### 2. **Automatic Decimal Adjustment (`adjustDecimals`)**
Automatically converts amounts between tokens with different decimal places:

```solidity
contract DecimalExample {
    using GluedMath for uint256;
    
    function convertTokenAmounts(uint256 amount, address fromToken, address toToken) public view returns (uint256) {
        // Automatically handles USDC (6 decimals) ↔ WETH (18 decimals) conversions
        return GluedMath.adjustDecimals(amount, fromToken, toToken);
    }
    
    function convertUSDCToWETH(uint256 usdcAmount) public view returns (uint256) {
        // Convert 1000 USDC (1000 * 1e6) to WETH decimals (1000 * 1e18)
        address USDC = 0xA0b86a33E6417c4e2fDF5F3A4EB59b6A3DFEd3B5;
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        return GluedMath.adjustDecimals(usdcAmount, USDC, WETH);
    }
}
```

The Expansions Pack helps you build on top of Glue Protocol without needing to be an expert in its internal mechanics. As a bonus, **GluedMath** simplifies common mathematical challenges when working with different token decimals and precision calculations.

**Key Benefits:**
- **Prevents Overflow**: 512-bit intermediate calculations prevent overflow in large multiplications
- **Maintains Precision**: No rounding errors in critical financial calculations  
- **Handles Decimals**: Automatic conversion between different token decimal formats
- **Gas Optimized**: Efficient assembly implementation for production use
- **Battle Tested**: Used throughout the Glue Protocol for all precision-critical operations

## Examples

The Expansions Pack includes **ready-to-deploy example contracts** for common use cases. These are complete implementations that you can deploy directly or use as starting points:

### Ready-to-Deploy Sticky Tokens

#### BasicStickyToken - Minimal Implementation

```solidity
import "@glueExpansionsPack/examples/BasicStickyToken.sol";

// Deploy with minimal configuration
contract MyToken is BasicStickyToken {
    constructor() BasicStickyToken(
        [
            "https://mytoken.com/metadata.json", // contractURI
            "My Sticky Token",                   // name
            "MST"                               // symbol
        ],
        1000000 * 10**18 // initial supply
    ) {
        // Ready to use! Your token is now backed by Glue Protocol
    }
}
```

#### AdvancedStickyToken - Full-Featured Implementation

```solidity
import "@glueExpansionsPack/examples/AdvancedStickyToken.sol";

// Deploy with full configuration including fees, governance, and limits
contract MyAdvancedToken is AdvancedStickyToken {
    constructor() AdvancedStickyToken(
        [
            "https://mytoken.com/metadata.json",
            "Advanced Token", 
            "ADV"
        ],
        [
            5e16,  // maxOwnerFee (5%)
            1e16,  // ownerFee (1%)
            0,     // maxSupply (unlimited)
            3,     // feeSource (FROM_BOTH)
            1000000 * 10**18 // initialSupply
        ],
        [
            msg.sender, // owner
            msg.sender, // feeReceiver
            address(0), // blacklist (none)
            msg.sender  // collateralManager
        ],
        [
            false, false, false, false, // locks for security
            false, false, false, false
        ]
    ) {
        // Full-featured token with governance, fees, and collateral management
    }
}
```

### Ready-to-Deploy Flash Loan Applications

#### ExampleArbitrageBot - Complete MEV Bot

```solidity
import "@glueExpansionsPack/examples/ExampleArbitrageBot.sol";

// Deploy a complete arbitrage bot
contract MyArbitrageBot is ExampleArbitrageBot {
    constructor(address _owner) ExampleArbitrageBot(_owner) {
        // Ready-to-use MEV bot with:
        // - Multi-DEX arbitrage capabilities
        // - Automatic profit calculation
        // - Emergency controls and access management
        // - Gas optimization and slippage protection
    }
    
    // Start arbitraging immediately!
    function startArbitrage(
        address stickyAsset,
        address collateral,
        uint256 amount,
        address dexA,
        address dexB
    ) external onlyOwner {
        executeArbitrage(stickyAsset, collateral, amount, dexA, dexB);
    }
}
```

### Custom Strategy Examples

#### Creating a Rebasing Token
```solidity
import "@glueExpansionsPack/base/StickyAsset.sol";

contract RebasingToken is ERC20, StickyAsset {
    constructor() 
        ERC20("Rebase Token", "REBASE")
        StickyAsset("https://metadata.json", [true, true]) // Enable hooks
    {
        _mint(msg.sender, 1000000 * 10**18);
    }
    
    // Implement rebasing logic in hooks
    function _processCollateralHook(address asset, uint256 amount, bool isETH) internal override {
        // Automatically compound rewards into token supply
        if (asset == rewardToken) {
            _mint(address(this), amount); // Increase supply = rebasing!
        }
    }
}
```

#### Treasury-Funded Token  
```solidity
import "@glueExpansionsPack/base/StickyAsset.sol";

contract TreasuryToken is ERC20, StickyAsset {
    address public treasury;
    
    constructor(address _treasury) 
        ERC20("Treasury Token", "TREAS")
        StickyAsset("https://metadata.json", [true, true])
    {
        treasury = _treasury;
        _mint(msg.sender, 1000000 * 10**18);
    }
    
    function _calculateCollateralHookSize(address asset, uint256 amount) internal view override returns (uint256) {
        return _md512(amount, 10e16, PRECISION); // 10% to treasury
    }
    
    function _processCollateralHook(address asset, uint256 amount, bool isETH) internal override {
        // Automatically fund treasury from ungluing operations
        if (isETH) {
            payable(treasury).transfer(amount);
        } else {
            IERC20(asset).transfer(treasury, amount);
        }
    }
}
```

#### Simple Arbitrage Bot Implementation
```solidity
import "@glueExpansionsPack/base/GluedLoanReceiver.sol";

contract ArbitrageBot is GluedLoanReceiver {
    function _executeFlashLoanLogic(bytes memory params) internal override returns (bool success) {
        // Use enhanced interface for comprehensive loan information
        (
            address[] memory glues,
            address collateral,
            uint256[] memory expectedAmounts,
            uint256 totalBorrowed,
            uint256 totalRepay,
            uint256 totalFees
        ) = this.getCurrentLoanInfo();
        
        // Execute arbitrage strategy
        uint256 profit = _performArbitrage(collateral, totalBorrowed);
        
        // Return true if profitable (repayment is automatic)
        return profit > totalFees;
    }
    
    function _performArbitrage(address token, uint256 amount) internal returns (uint256 profit) {
        // Your arbitrage logic here
        // Buy low on DEX A, sell high on DEX B
        return 0; // Return actual profit
    }
}
```

## 🧪 Mock Contracts for Testing

The Glue Expansions Pack includes **simple mock contracts** designed for testing your integrations without deploying the full Glue Protocol. Each mock focuses on **one specific function** with **manual parameter control** and **realistic protocol behavior**.

### Hook Simulation

All mock contracts implement accurate hook behavior from the real Glue Protocol:

#### **For ERC20 Contracts (`MockUnglueERC20`, `MockBatchUnglueERC20`)**
- **Phase 1 - Sticky Asset Hooks**: Applied via `tryHook(stickyAsset, amount)` during initialization
  - Reduces the effective amount used for proportion calculation
  - Hook amount is transferred to sticky asset (simulated)
  - Matches `GlueERC20.initialization() -> tryHook()` flow exactly
- **Phase 2 - Collateral Hooks**: Applied via `tryHook(collateral, netAmount)` during distribution
  - Reduces the final amount received by user
  - Hook amount is transferred to sticky asset (simulated)
  - Matches `GlueERC20.computeCollateral() -> tryHook()` flow exactly

#### **For ERC721 Contracts (`MockUnglueERC721`, `MockBatchUnglueERC721`)**
- **Phase 1 - Sticky Asset Hooks (NFTs)**: Applied via `tryHook(stickyAsset, nftCount, tokenIds)`
  - **Does NOT transfer** any amount to sticky asset (key difference!)
  - **Still calls executeHook** with NFT count and actual tokenIds array
  - **Returns 0** (no amount reduction)
  - Used for **tracking burned NFT IDs** in expanded integrations
- **Phase 2 - Collateral Hooks (ERC20/ETH)**: Applied via `tryHook(collateral, netAmount, tokenIds)`
  - Same as ERC20 behavior - transfers hook amount to sticky asset
  - Calls executeHook with hookAmount and tokenIds
  - Returns `netAmount - hookAmount`

#### **Real Protocol Matching Features**
- ✅ **BIO State Management**: 0=UNCHECKED, 1=NO_HOOK, 2=HOOK (matches real protocol)
- ✅ **Hook Interface Simulation**: `hasHook()`, `hookSize()`, `hooksImpact()`, `executeHook()`
- ✅ **Proper Hook Discovery**: Simulates real protocol's hook detection process
- ✅ **Accurate Transfers**: Hook amounts actually transferred to sticky asset (simulated)
- ✅ **NFT ID Tracking**: Full tokenIds array passed to executeHook for NFT hooks
- ✅ **Fee Calculations**: Real protocol fee math (0.1% protocol fee)
- ✅ **Event Emissions**: Standard unglued events with correct parameters

### ⚠️ **Important: ERC20 vs ERC721 Interface Differences**

The Glue Protocol has different interfaces for ERC20 tokens and ERC721 NFTs. We provide **separate mock contracts** for each interface:

| Function | ERC20 Interface | ERC721 Interface |
|----------|-----------------|------------------|
| **Individual Unglue** | `unglue(collaterals[], amount, recipient)` | `unglue(collaterals[], tokenIds[], recipient)` |
| **Batch Unglue** | `batchUnglue(assets[], amounts[], collaterals[], recipients[])` | `batchUnglue(assets[], tokenIds[][], collaterals[], recipients[])` |

**Key Differences:**
- **ERC20**: Uses `uint256 amount` parameter for token amounts
- **ERC721**: Uses `uint256[] tokenIds` or `uint256[][]` arrays for NFT token IDs
- **Calculations**: ERC20 uses amount/totalSupply, ERC721 uses nftCount/totalSupply
- **Hook Behavior**: ERC20 hooks transfer amounts, NFT hooks only track (no transfers)

### Why Use These Mocks?

- ✅ **Test without mainnet deployment**: No need for full protocol setup
- ✅ **Complete control**: Manually set supply deltas, balances, fees  
- ✅ **Standard interfaces**: Use real IGlueERC20/IGlueERC721/IGlueStickERC20/IGlueStickERC721 interfaces
- ✅ **Individual focus**: Each mock tests one specific function
- ✅ **Comprehensive documentation**: Extensive examples and clear instructions
- ✅ **Accurate behavior**: Real protocol fee calculations and hook simulation
- ✅ **Hook testing**: Test hooks with proper two-phase simulation
- ✅ **Real hook transfers**: Hook amounts actually transferred to sticky asset

### Available Mock Contracts

#### 1. MockUnglueERC20 - Test Individual ERC20 Unglue Operations

**Focus**: Testing `IGlueERC20.unglue(collaterals, amount, recipient)` functionality with accurate hook simulation.

```solidity
// Import and deploy
import "@glueExpansionsPack/mocks/MockUnglueERC20.sol";

contract TestMyERC20Strategy {
    MockUnglueERC20 mockGlue;
    
    function setUp() public {
        mockGlue = new MockUnglueERC20();
        
        // Configure the mock
        mockGlue.setStickyAsset(myERC20Token);
        mockGlue.setMockTotalSupply(1000e18); // 1000 token total supply
        
        // Add collateral
        mockGlue.addCollateral(USDC, 1000e6); // 1000 USDC
        mockGlue.addETH{value: 1e18}();       // 1 ETH
        
        // Configure the mock hooks (matches real protocol)
        mockGlue.configureHooks(true, 5e16); // 5% sticky asset hook
        mockGlue.setAssetHookSize(USDC, 2e16); // 2% USDC hook
    }
    
    function testHookSimulation() public {
        address[] memory collaterals = new address[](2);
        collaterals[0] = USDC;
        collaterals[1] = address(0); // ETH
        
        // Execute unglue - burn 100 tokens
        mockGlue.unglue(collaterals, 100e18, alice);
        
        // PHASE 1: tryHook(myERC20Token, 100e18) 
        // → 5e18 tokens sent to myERC20Token, 95e18 effective amount
        // PHASE 2: tryHook(USDC, netAmount)
        // → 2% of USDC sent to myERC20Token, Alice gets remainder
        
        // Verify hook tracking
        assertEq(mockGlue.getHookAmountTransferred(myERC20Token), 5e18); // Sticky hook amount
        assertGt(mockGlue.getHookAmountTransferred(USDC), 0); // USDC hook amount
        assertEq(mockGlue.getHookExecutionCount(myERC20Token), 1); // Hook executed once
        
        // Check hook status  
        assertEq(mockGlue.getHookStatus(), 2); // BIO.HOOK
        assertTrue(mockGlue.hasHook()); // Hook interface simulation
    }
}
```

#### 2. MockUnglueERC721 - Test Individual NFT Unglue Operations

**Focus**: Testing `IGlueERC721.unglue(collaterals, tokenIds[], recipient)` functionality with accurate NFT hook simulation.

```solidity
// Import and deploy
import "@glueExpansionsPack/mocks/MockUnglueERC721.sol";

contract TestMyNFTStrategy {
    MockUnglueERC721 mockGlue;
    
    function setUp() public {
        mockGlue = new MockUnglueERC721();
        
        // Configure the mock
        mockGlue.setStickyAsset(myNFTCollection);
        mockGlue.setMockTotalSupply(10000); // 10k NFT collection
        
        // Add collateral
        mockGlue.addCollateral(USDC, 100000e6); // 100k USDC
        mockGlue.addETH{value: 100e18}();       // 100 ETH
        
        // Configure NFT hooks (special behavior!)
        mockGlue.configureHooks(true, 0); // Enable hooks but sticky hook has no economic impact
        mockGlue.setAssetHookSize(USDC, 2e16); // 2% USDC hook
    }
    
    function testNFTHookSimulation() public {
        address[] memory collaterals = new address[](2);
        collaterals[0] = USDC;
        collaterals[1] = address(0); // ETH
        
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1; tokenIds[1] = 2; tokenIds[2] = 3;
        
        // Execute unglue - burn 3 NFTs
        mockGlue.unglue(collaterals, tokenIds, alice);
        
        // PHASE 1: tryHook(myNFTCollection, 3, [1,2,3]) 
        // → NO AMOUNT TRANSFERRED (key NFT difference!)
        // → Still calls executeHook with 3 and [1,2,3] for tracking
        // → Returns 0 (no amount reduction)
        // PHASE 2: tryHook(USDC, netAmount, [1,2,3])
        // → 2% of USDC sent to myNFTCollection, Alice gets remainder
        
        // Verify NFT hook tracking
        assertEq(mockGlue.getHookAmountTransferred(myNFTCollection), 0); // NO TRANSFER for NFTs!
        assertGt(mockGlue.getHookAmountTransferred(USDC), 0); // USDC hook amount transferred
        assertEq(mockGlue.getHookExecutionCount(myNFTCollection), 1); // Hook executed for tracking
        
        // Check NFT tracking
        assertTrue(mockGlue.isTokenIdBurned(1));
        assertTrue(mockGlue.isTokenIdBurned(2));
        assertTrue(mockGlue.isTokenIdBurned(3));
        
        // Verify executeHook call details
        (address asset, uint256 amount, uint256[] memory ids, uint256 timestamp) = 
            mockGlue.getLastExecuteHookCall();
        assertEq(asset, myNFTCollection);
        assertEq(amount, 3); // NFT count passed to hook
        assertEq(ids.length, 3); // Actual tokenIds passed
        assertEq(ids[0], 1); assertEq(ids[1], 2); assertEq(ids[2], 3);
    }
}
```

#### 3. MockBatchUnglueERC20 - Test Multi-Asset ERC20 Operations

**Focus**: Testing `IGlueStickERC20.batchUnglue(assets, amounts[], collaterals, recipients)` functionality with per-glue hook configuration.

```solidity
// Import and deploy
import "@glueExpansionsPack/mocks/MockBatchUnglueERC20.sol";

contract TestMyERC20BatchStrategy {
    MockBatchUnglueERC20 mockBatch;
    
    function setUp() public {
        mockBatch = new MockBatchUnglueERC20();
        
        // Register multiple ERC20 tokens with their glues
        mockBatch.registerStickyAsset(tokenA, mockGlueA);
        mockBatch.registerStickyAsset(tokenB, mockGlueB);
        
        // Set different total supplies
        mockBatch.setMockTotalSupply(tokenA, 1000e18); // 1000 tokens for A
        mockBatch.setMockTotalSupply(tokenB, 2000e18); // 2000 tokens for B
        
        // Add collateral to each glue
        mockBatch.addCollateralToGlue(mockGlueA, USDC, 1000e6);
        mockBatch.addCollateralToGlue(mockGlueB, USDC, 2000e6);
        
        // Configure hooks per glue (accurate simulation)
        mockBatch.configureHooksForGlue(mockGlueA, true, 2e16); // 2% sticky hook for A
        mockBatch.setAssetHookSizeForGlue(mockGlueA, USDC, 1e16); // 1% USDC hook for A
        mockBatch.configureHooksForGlue(mockGlueB, false, 0); // No hooks for B
    }
    
    function testERC20BatchHooks() public {
        address[] memory assets = new address[](2);
        assets[0] = tokenA; assets[1] = tokenB;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100e18; amounts[1] = 200e18; // 10% from A, 10% from B
        
        address[] memory collaterals = new address[](1);
        collaterals[0] = USDC;
        
        address[] memory recipients = new address[](1);
        recipients[0] = alice;
        
        // Execute batch unglue
        mockBatch.batchUnglue(assets, amounts, collaterals, recipients);
        
        // Verify per-glue hook behavior
        assertGt(mockBatch.getHookAmountTransferredForGlue(mockGlueA, tokenA), 0); // Sticky hook A
        assertGt(mockBatch.getHookAmountTransferredForGlue(mockGlueA, USDC), 0); // USDC hook A
        assertEq(mockBatch.getHookAmountTransferredForGlue(mockGlueB, tokenB), 0); // No hooks B
        assertEq(mockBatch.getHookAmountTransferredForGlue(mockGlueB, USDC), 0); // No hooks B
    }
}
```

#### 4. MockBatchUnglueERC721 - Test Multi-Collection NFT Operations

**Focus**: Testing `IGlueStickERC721.batchUnglue(assets, tokenIds[][], collaterals, recipients)` functionality with NFT-specific hook behavior.

```solidity
// Import and deploy
import "@glueExpansionsPack/mocks/MockBatchUnglueERC721.sol";

contract TestMyNFTBatchStrategy {
    MockBatchUnglueERC721 mockBatch;
    
    function testNFTBatchHooks() public {
        // ... setup similar to above ...
        
        // Create 2D tokenIds array
        uint256[][] memory tokenIds = new uint256[][](2);
        tokenIds[0] = new uint256[](3); // 3 NFTs from collection A
        tokenIds[0][0] = 1; tokenIds[0][1] = 2; tokenIds[0][2] = 3;
        tokenIds[1] = new uint256[](2); // 2 NFTs from collection B  
        tokenIds[1][0] = 100; tokenIds[1][1] = 200;
        
        // Execute batch unglue
        mockBatch.batchUnglue(assets, tokenIds, collaterals, recipients);
        
        // Verify NFT-specific hook behavior
        assertEq(mockBatch.getHookAmountTransferredForGlue(mockGlueA, collectionA), 0); // NO TRANSFER for NFTs!
        assertGt(mockBatch.getHookExecutionCountForGlue(mockGlueA, collectionA), 0); // But hook was called for tracking
        
        // Check NFT tracking per collection
        assertTrue(mockBatch.isTokenIdBurnedForCollection(collectionA, 1));
        assertTrue(mockBatch.isTokenIdBurnedForCollection(collectionB, 100));
    }
}
```

### Hook Testing Helper Functions

All mock contracts include comprehensive helper functions for testing hook behavior:

```solidity
// Hook status and configuration
uint8 status = mock.getHookStatus(); // 0=UNCHECKED, 1=NO_HOOK, 2=HOOK
uint256 hookSize = mock.getAssetHookSize(USDC); // Get configured hook size
bool hasHooks = mock.hasHook(); // Simulates IGluedHooks.hasHook()

// Hook execution tracking
uint256 executions = mock.getHookExecutionCount(myToken); // Number of executeHook calls
uint256 transferred = mock.getHookAmountTransferred(USDC); // Total amount transferred via hooks

// Last executeHook call details (NFT contracts include tokenIds)
(address asset, uint256 amount, uint256[] memory tokenIds, uint256 timestamp) = 
    mock.getLastExecuteHookCall();

// Hook interface simulation (matches IGluedHooks)
uint256 hookSize = mock.hookSize(USDC, 1000e6); // Simulates hookSize() call
uint256 impact = mock.hooksImpact(USDC, 1000e6, 100e18); // Simulates hooksImpact() call
```

### Other Mock Contracts

- **MockFlashLoan.sol**: Test individual flash loan functionality
- **MockGluedLoan.sol**: Test cross-glue flash loans
- **MockStickyAsset.sol**: Mock sticky asset with configurable addresses (testing only)
- **MockGluedLoanReceiver.sol**: Mock flash loan receiver for testing

### Mock Contract Imports

```solidity
// Import specific mocks as needed
import "@glueExpansionsPack/mocks/MockUnglueERC20.sol";
import "@glueExpansionsPack/mocks/MockUnglueERC721.sol";
import "@glueExpansionsPack/mocks/MockBatchUnglueERC20.sol";
import "@glueExpansionsPack/mocks/MockBatchUnglueERC721.sol";

// Or import via index (includes all contracts)
import {MockUnglueERC20, MockUnglueERC721} from "@glueExpansionsPack";
```

Each mock contract is **ultra-documented** with comprehensive examples, parameter explanations, and usage patterns. They're designed to make testing your Glue Protocol integrations as simple and reliable as possible, with **full interface compatibility** and **accurate protocol behavior including proper hook simulation**!

## Documentation

For detailed documentation and advanced usage examples, visit the [Glue Protocol Wiki](https://wiki.glue.finance).

## License

Glue Protocol Expansions Pack is licensed under the [Business Source License 1.1](https://github.com/glue-finance/glue/blob/main/LICENCE.txt). With an end date of 2029-02-29 or a date specified at [v1-license-date.gluefinance.eth](https://v1-license-date.gluefinance.eth).

### ⚠️ StickyAsset Specific License Terms (BUSL-1.1)

**StickyAsset.sol** is the core contract implementing the Sticky Asset Native Standard and is subject to strict licensing terms under BUSL-1.1. This contract MUST maintain integration with the official Glue Protocol deployment.

#### ✅ **StickyAsset - What You CAN Do:**

- **Inherit from StickyAsset** for your tokens while maintaining official glue stick addresses:
  ```solidity
  contract MyToken is ERC20, StickyAsset {
      // ✅ This is permitted - inherits and uses official addresses
  }
  ```

- **Deploy tokens using StickyAsset** that integrate with the official Glue Protocol
- **Customize hook functions** (`_calculateStickyHookSize`, `_processCollateralHook`, etc.) for your specific use case
- **Create factory contracts** that deploy StickyAsset-based tokens with official addresses
- **Earn money** from tokens that inherit from StickyAsset while following license terms
- **Build interfaces and tools** that interact with StickyAsset-based tokens
- **Use StickyAsset** on all officially supported networks

#### ❌ **StickyAsset - What You CANNOT Do:**

- **Deploy StickyAsset with custom glue stick addresses** on mainnet or production networks:
  ```solidity
  // ❌ This violates the license
  contract MyToken is StickyAsset {
      constructor() StickyAsset(
          "ipfs://metadata",
          [true, false],
          myCustomGlueStick20,    // ❌ LICENSE VIOLATION
          myCustomGlueStick721    // ❌ LICENSE VIOLATION  
      ) {}
  }
  ```

- **Modify or replace** the official GLUE_STICK_ERC20 and GLUE_STICK_ERC721 addresses
- **Deploy your own version** of the Glue Protocol with different addresses
- **Create StickyAsset variants** that bypass the official Glue deployment
- **Deploy StickyAsset** on unsupported networks
- **Fork the entire Glue Protocol** and deploy it independently

#### 🧪 **MockStickyAsset for Testing (MIT License)**

For testing purposes, we provide **MockStickyAsset.sol** which allows configurable glue stick addresses:

```solidity
// ✅ Testing only - MockStickyAsset allows custom addresses
import "@glueExpansionsPack/mocks/MockStickyAsset.sol";

contract TestToken is MockStickyAsset {
    constructor() MockStickyAsset(
        "ipfs://test-metadata",
        [true, false],
        mockGlueStick20Address,   // ✅ OK for testing
        mockGlueStick721Address   // ✅ OK for testing
    ) {}
}
```

**⚠️ CRITICAL WARNING**: MockStickyAsset is ONLY for testing. Deploying MockStickyAsset on mainnet or any production network **VIOLATES THE GLUE PROTOCOL LICENSE**.

#### 🎯 **Required Official Addresses**

When inheriting from StickyAsset, your contract MUST interact with these official addresses:

- **GLUE_STICK_ERC20**: `0x49fc990E2E293D5DeB1BC0902f680A3b526a6C60`
- **GLUE_STICK_ERC721**: `0x049A5F502Fd740E004526fb74ef66b7a6615976B`

Any attempts to bypass, modify, or replace these addresses in production deployments violates the license.

### General Protocol License Terms

The protocol is permissionless, you can both use it and build on top of it, both as a form of public good or for profit. But you can't fork it and deploy it on your own.

**StickyToken** is referred to the entire invention and logic of the protocol, including the deployed contracts, the interfaces, the libraries, the extensions and the documentation. Glue Labs Inc. (Delaware) is the exclusive owner of all intellectual property rights, copyrights, and licensing rights for Glue V1 and its software components, while Glue Labs LTD (BVI) is responsible for the development of smart contracts, their deployment, on-chain royalty enforcement mechanisms, and all future protocol development on the blockchain.

### License Summary for Developers

| Component | License | Production Use | Custom Addresses | Notes |
|-----------|---------|----------------|------------------|-------|
| **StickyAsset.sol** | BUSL-1.1 | ✅ Permitted | ❌ Forbidden | Must use official glue stick addresses |
| **MockStickyAsset.sol** | MIT | ❌ Forbidden | ✅ Testing only | License violation if deployed on mainnet |
| **GluedLoanReceiver.sol** | BUSL-1.1 | ✅ Permitted | Uses StickyAsset addresses | Same restrictions as StickyAsset |
| **MockGluedLoanReceiver.sol** | MIT | ✅ Permitted | ✅ Testing only | Safe for mainnet, no protocol addresses |
| **Interfaces** | MIT | ✅ Permitted | N/A | No restrictions |
| **Libraries** | MIT | ✅ Permitted | N/A | No restrictions |
| **Examples** | MIT | ✅ Permitted | N/A | No restrictions |

For complete licensing details, permitted uses, restrictions, enforcement rights, license transition timeline, and collaboration opportunities, please visit [glue.finance/legal#licence](https://glue.finance/legal#licence).

Have a brilliant idea that pushes beyond our license boundaries? Go to [License and Partnerships](http://glue.finance/legal#license) to explore collaboration opportunities.

## Security

This project is provided "as is" and may contain bugs or security vulnerabilities. Please use at your own risk and consider getting a security audit before using in production.

## Links

- [Website](https://glue.finance)
- [Wiki](https://wiki.glue.finance) 
- [GitHub](https://github.com/glue-finance)
- [Discord](https://discord.gg/glue-finance) 