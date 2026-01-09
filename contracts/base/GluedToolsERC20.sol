// SPDX-License-Identifier: BUSL-1.1

/**
 * @title GluedToolsERC20 - Advanced ERC20-Only Glue Protocol Development Kit  
 * @author @BasedToschi - Glue Finance
 * 
 * @notice The complete advanced toolkit for building ERC20-focused DeFi applications on top of Glue Protocol
 * 
 * @dev **GluedToolsERC20 is the FULL-FEATURED ERC20 version for developers building ON TOP of Glue Protocol:**
 * 
 * 🎯 **Who Should Use GluedToolsERC20:**
 * - ✅ Building ERC20-only routers and aggregators for Glue Protocol
 * - ✅ Creating flash loan arbitrage strategies  
 * - ✅ Developing yield farming protocols for fungible glued assets
 * - ✅ Building lending/borrowing platforms (ERC20-only)
 * - ✅ Any contract that INTERACTS with glued ERC20 tokens but is NOT a sticky asset itself
 * 
 * ❌ **Do NOT use GluedToolsERC20 if:**
 * - You want to create a sticky asset → Use StickyAsset.sol or InitStickyAsset.sol instead
 * - You need ERC721 support → Use GluedTools for full ERC20 + ERC721 support
 * - You want minimal features → Use GluedToolsERC20Min for ultra-lightweight integration
 * 
 * 🔧 **What GluedToolsERC20 Adds (Beyond GluedToolsERC20Min):**
 * - ✅ **GluedMath Integration**: High-precision calculations with 512-bit intermediate values
 * - ✅ **Decimal Adjustment**: Automatic conversion between different token decimals (USDC ↔ WETH)
 * - ✅ **Advanced Transfers**: Batch operations, checked transfers, and excess handling
 * - ✅ **Burn Functions**: Direct burning to glue contracts (burnAsset, burnAssetFrom)
 * - ✅ **Collateral Calculations**: Get exact collateral amounts for given sticky token amounts
 * - ✅ **Unglue Operations**: High-level unglue wrappers with automatic approval
 * - ✅ **Extended OpenZeppelin**: Full SafeERC20 and Address library support
 * 
 * 📦 **Complete Feature Set:**
 * - Everything from GluedToolsERC20Min (transfers, glue initialization, balance tracking)
 * - High-precision math operations (md512, md512Up)
 * - Decimal adjustment between any token pairs
 * - Batch transfer operations for multiple recipients
 * - Checked transfers with actual amount returned
 * - Approve and unglue helper functions
 * - Collateral-by-amount calculations
 * - Automatic excess token handling
 * - Token decimal queries
 * 
 * 💡 **Usage:**
 * Inherit from GluedToolsERC20 to access the complete suite of ERC20 helper functions. This
 * provides everything you need to build complex ERC20-focused DeFi applications that interact
 * with Glue Protocol.
 * 
 * 🆚 **Version Comparison:**
 * - **GluedToolsERC20Min**: Minimal features, no GluedMath, smallest bytecode, ERC20-only
 * - **GluedToolsERC20**: Full features, GluedMath included, optimized bytecode, ERC20-only
 * - **GluedTools**: Full features, GluedMath included, supports ERC20 + ERC721 (largest)
 * 
 * ⚠️ **Important:**
 * This is for building APPLICATIONS on top of Glue Protocol, not for creating sticky assets.
 * If you want to create a new ERC20 token that integrates with Glue, use StickyAsset.sol instead.
 * 
 * 💪 **Gas Optimization:**
 * GluedToolsERC20 is smaller than GluedTools because it excludes all ERC721 functionality.
 * If you only work with fungible tokens, this is the optimal choice.
 */

pragma solidity ^0.8.28;

// Base minimal ERC20 glue tools
import {GluedToolsERC20Min} from "../tools/GluedToolsERC20Min.sol";
// Strategic import of proprietary mathematical operations library for precision calculations
import {GluedMath} from "../libraries/GluedMath.sol";
// OpenZeppelin imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
// Glue interface imports
import {IGlueStickERC20, IGlueERC20} from "../interfaces/IGlueERC20.sol";

abstract contract GluedToolsERC20 is GluedToolsERC20Min {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using GluedMath for uint256;

    // ===== CONSTANTS =====
    
    /// @notice Precision for percentage and ratio calculations
    uint256 internal constant PRECISION = 1e18;

    address internal constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // ===== GLUE PROTOCOL INTEGRATION =====
    // Core Glue Protocol contract reference - immutable across all networks
    IGlueStickERC20 internal constant GLUE_STICK_ERC20 = IGlueStickERC20(0x5fEe29873DE41bb6bCAbC1E4FB0Fc4CB26a7Fd74);

    /**
    * @notice Reentrancy guard using transient storage (EIP-1153)
    * @dev Gas-efficient protection for functions with external calls
    */
    modifier nnrtnt() virtual {
        bytes32 slot = keccak256(abi.encodePacked(address(this), "ReentrancyGuard"));
        
        assembly {
            if tload(slot) { 
                mstore(0x00, 0x3ee5aeb5) // ReentrancyGuardReentrantCall()
                revert(0x1c, 0x04)
            }
            tstore(slot, 1)
        }
        
        _;
        
        assembly {
            tstore(slot, 0)
        }
    }

    // ===== EXTENDED GLUE FUNCTIONS =====
    // initializeGlue, tryInitializeGlue, hasAGlue, getGlueBalances, getTotalSupply inherited from GluedToolsERC20Min
    // transferAsset, transferFromAsset, balanceOfAsset inherited from GluedToolsERC20Min

    function getGlue(address stickyAsset) internal returns (address glue, bool isSticky) {
        (isSticky, glue) = _isSticky(stickyAsset);
        if (!isSticky) {
            glue = _glueAnAsset(stickyAsset);
            isSticky = true;
        }
    }

    function getCollateralbyAmount(address stickyAsset, uint256 amount, address[] memory collaterals) internal view returns (uint256[] memory balances) {
        (bool isSticky, address glue) = _isSticky(stickyAsset);
        if (!isSticky) {
            balances = new uint256[](collaterals.length);
            for (uint256 i = 0; i < collaterals.length; i++) {
                balances[i] = 0;
            }
            return balances;
        } else {
            balances = IGlueERC20(glue).collateralByAmount(amount, collaterals);
            return balances;
        }
    }

    // ===== EXTENDED TRANSFER FUNCTIONS =====

    /**
     * @notice Transfers an asset in a batch
     * @param token Token address (address(0) for ETH)
     * @param to Recipient addresses
     * @param amounts Amounts to transfer
     * @param fullAmount Full amount to transfer
     */
    function batchTransferAsset(address token, address[] memory to, uint256[] memory amounts, uint256 fullAmount) internal {
        uint256 amountRemaining = fullAmount;

        if (amounts.length == 0 || amounts.length != to.length) {
            revert("Amounts and to must be the same length");
        }

        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > amountRemaining) {
                amounts[i] = amountRemaining;
            }

            transferAsset(token, to[i], amounts[i]);
            amountRemaining -= amounts[i];
        }
    }

    /**
     * @notice Transfers with balance check (for tax tokens)
     */
    function transferAssetChecked(address token, address to, uint256 amount) internal returns (uint256 actualAmount) {
        if (token == address(0)) {
            if (to != address(this)) {
                Address.sendValue(payable(to), amount);
            }
            actualAmount = amount;
        } else {
            uint256 balanceBefore = balanceOfAsset(token, to);
            IERC20(token).safeTransfer(to, amount);
            uint256 balanceAfter = balanceOfAsset(token, to);

            require(balanceAfter > balanceBefore, "Transfer failed");

            actualAmount = balanceAfter - balanceBefore;
        }
    }

    // ===== BURN FUNCTIONS =====

    function burnAsset(address token, uint256 amount) internal {
        address glue = initializeGlue(token);
        transferAsset(token, glue, amount);
    }

    function burnAssetFrom(address token, address from, uint256 amount) internal {
        address glue = initializeGlue(token);
        transferFromAsset(token, from, glue, amount);
    }

    // ===== APPROVAL & UNGLUE =====

    function approveAsset(address token, address spender, uint256 amount) internal {
        if (token == address(0)) {
            return;
        } else {
            IERC20(token).approve(spender, amount);
        }
    }

    function unglueAsset(address token, uint256 amount, address[] memory collaterals, address recipient) internal {
        address glue = initializeGlue(token);
        approveAsset(token, glue, amount);
        IGlueERC20(glue).unglue(collaterals, amount, recipient);
    }
    
    // ===== UTILITY FUNCTIONS =====

    /**
     * @notice Handles excess tokens/ETH by sending to glue contract
     */
    function handleExcess(address token, uint256 amount, address glue) internal {
        if (amount > 0 && glue != address(0)) {
            transferAsset(token, glue, amount);
        }
    }

    function getTokenDecimals(address token) internal view returns (uint256 decimals) {
        return GluedMath.getDecimals(token);
    }

    /**
     * @notice Adjusts decimals between tokens using GluedMath
     */
    function adjustDecimals(uint256 amount, address tokenIn, address tokenOut) internal view returns (uint256) {
        return GluedMath.adjustDecimals(amount, tokenIn, tokenOut);
    }

    /**
     * @notice Wrapper for GluedMath.md512 - multiply-divide with full precision
     */
    function md512(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        return GluedMath.md512(a, b, denominator);
    }

    /**
     * @notice Wrapper for GluedMath.md512Up - multiply-divide with full precision (rounds up)
     */
    function md512Up(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        return GluedMath.md512Up(a, b, denominator);
    }

    // ===== INTERNAL HELPER OVERRIDES =====
    // Override to use GLUE_STICK_ERC20 constant

    function _glueAnAsset(address stickyAsset) internal override returns (address glue) {
        glue = GLUE_STICK_ERC20.applyTheGlue(stickyAsset);
        return glue;
    }

    function _isSticky(address stickyAsset) internal view override returns (bool isSticky, address glue) {
        (isSticky, glue) = GLUE_STICK_ERC20.isStickyAsset(stickyAsset);
        return (isSticky, glue);
    }
}
