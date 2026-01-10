// SPDX-License-Identifier: BUSL-1.1

/**
 * ⚠️  LICENSE NOTICE - BUSINESS SOURCE LICENSE 1.1 ⚠️
 * 
 * This contract is licensed under BUSL-1.1. You may use it freely as long as you:
 * ✅ Do NOT modify the GLUE_STICK addresses in GluedConstants
 * ✅ Maintain integration with official Glue Protocol addresses
 * 
 * ❌ Editing GLUE_STICK_ERC20 or GLUE_STICK_ERC721 addresses = LICENSE VIOLATION
 * 
 * See LICENSE file for complete terms.
 */

/**
 ██████╗ ██╗     ██╗   ██╗███████╗██████╗                                              
██╔════╝ ██║     ██║   ██║██╔════╝██╔══██╗                                             
██║  ███╗██║     ██║   ██║█████╗  ██║  ██║                                             
██║   ██║██║     ██║   ██║██╔══╝  ██║  ██║                                             
╚██████╔╝███████╗╚██████╔╝███████╗██████╔╝                                             
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝                                              
████████╗ ██████╗  ██████╗ ██╗     ███████╗    ███████╗██████╗  ██████╗ ██████╗  ██████╗ 
╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝    ██╔════╝██╔══██╗██╔════╝██╔════╝ ██╔═████╗
   ██║   ██║   ██║██║   ██║██║     ███████╗    █████╗  ██████╔╝██║     ╚█████╗  ██║██╔██║
   ██║   ██║   ██║██║   ██║██║     ╚════██║    ██╔══╝  ██╔══██╗██║      ╚═══██╗ ████╔╝██║
   ██║   ╚██████╔╝╚██████╔╝███████╗███████║    ███████╗██║  ██║╚██████╗██████╔╝ ╚██████╔╝
   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝    ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═════╝   ╚═════╝ 
██████╗  █████╗ ███████╗███████╗
██╔══██╗██╔══██╗██╔════╝██╔════╝
██████╔╝███████║███████╗█████╗  
██╔══██╗██╔══██║╚════██║██╔══╝  
██████╔╝██║  ██║███████║███████╗
╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
*/

/**
 * @title GluedToolsERC20Base - Complete Base ERC20-Only Glue Protocol Development Kit
 * @author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi - Glue Finance
 * 
 * @notice The complete base toolkit for building ERC20-focused DeFi applications with Glue Protocol
 * 
 * @dev **GluedToolsERC20Base provides everything you need for ERC20-only Glue integrations:**
 * 
 * 🔧 **What GluedToolsERC20Base Solves:**
 * - ✅ **Tax Token Handling**: Automatically detects and handles transfer taxes, returning actual received amounts
 * - ✅ **ETH/ERC20 Unified Interface**: Single clean API for both ETH and ERC20 tokens
 * - ✅ **Safe Transfers**: Built-in SafeERC20 and Address.sendValue for maximum security
 * - ✅ **Glue Integration**: Seamless ERC20 glue interaction without complex setup
 * - ✅ **Reentrancy Protection**: Built-in EIP-1153 transient storage guard
 * - ✅ **High-Precision Math**: GluedMath integration for 512-bit intermediate calculations
 * - ✅ **Burn Functions**: Direct burning to glue contracts
 * - ✅ **Balance Tracking**: Precise balance calculations accounting for transfer taxes
 * - ✅ **Gas Optimized**: Smaller bytecode than GluedToolsBase (no NFT support)
 * 
 * 📦 **Key Features:**
 * - Initialize/check glue status for ERC20 assets
 * - Query glue balances and total supply with precision
 * - Transfer ERC20/ETH with automatic tax detection
 * - Burn assets to glue contracts
 * - Approve and unglue helpers
 * - High-precision math (md512, md512Up, adjustDecimals)
 * - Try-catch wrappers that never revert unexpectedly
 * - ETH handling with excess refund logic
 * 
 * 🎯 **Perfect For:**
 * - ERC20-only routers and aggregators
 * - Flash loan arbitrage bots (GluedLoanReceiver inherits this)
 * - Yield farming strategies
 * - Any fungible-only DeFi protocol integration
 * - Gas-sensitive applications
 * 
 * 💡 **Usage:**
 * Inherit from GluedToolsERC20Base to access all ERC20 helper functions. This is the complete
 * base for ERC20-only support. For ERC20 + ERC721, use GluedToolsBase.
 * 
 * 🆚 **Version Comparison:**
 * - **GluedToolsERC20Base**: Complete base with ERC20-only (smaller bytecode)
 * - **GluedToolsBase**: Complete base with ERC20 + ERC721 support
 * - **GluedToolsERC20**: Extends GluedToolsERC20Base with batch operations
 * - **GluedTools**: Extends GluedToolsBase with batch operations
 */

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IGlueStickERC20, IGlueERC20} from "../interfaces/IGlueERC20.sol";
import {GluedConstants} from "../libraries/GluedConstants.sol";
import {GluedMath} from "../libraries/GluedMath.sol";

abstract contract GluedToolsERC20Base is GluedConstants {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using GluedMath for uint256;

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // REENTRANCY GUARD
    // ═══════════════════════════════════════════════════════════════════════════════════════

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

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // GLUE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Initialize glue for an ERC20 asset, creating it if it doesn't exist
     * @param stickyAsset The asset to glue
     * @return glue The glue contract address
     */
    function _initializeGlue(address stickyAsset) internal virtual returns (address glue) {
        (bool isSticky, address existingGlue) = _isSticky(stickyAsset);
        if (!isSticky) {
            glue = _glueAnAsset(stickyAsset);
        } else {
            glue = existingGlue;
        }
    }

    /**
     * @notice Safe version of initializeGlue that doesn't revert on failure
     * @dev Returns address(0) if glue creation fails
     * @param stickyAsset The asset to glue
     * @return glue The glue address, or address(0) if failed
     */
    function _tryInitializeGlue(address stickyAsset) internal virtual returns (address glue) {
        (bool isSticky, address existingGlue) = _isSticky(stickyAsset);
        if (isSticky) {
            return existingGlue;
        }
        
        try GLUE_STICK_ERC20.applyTheGlue(stickyAsset) returns (address _glue) {
            return _glue;
        } catch {
            return address(0);
        }
    }

    /**
     * @notice Get glue address, initializing if needed
     * @param stickyAsset The asset to check/glue
     * @return glue The glue contract address
     * @return isSticky Whether the asset was already sticky
     */
    function _getGlue(address stickyAsset) internal returns (address glue, bool isSticky) {
        (isSticky, glue) = _isSticky(stickyAsset);
        if (!isSticky) {
            glue = _glueAnAsset(stickyAsset);
            isSticky = true;
        }
    }

    /**
     * @notice Check if an ERC20 asset has a glue
     * @param stickyAsset The asset to check
     * @return isSticky Whether the asset has a glue
     */
    function _hasAGlue(address stickyAsset) internal view virtual returns (bool isSticky) {
        (isSticky, ) = _isSticky(stickyAsset);
        return isSticky;
    }
    
    /**
     * @notice Get collateral balances in a glue contract
     * @param stickyAsset The sticky asset
     * @param collaterals Array of collateral addresses to check
     * @return balances Array of collateral balances
     */
    function _getGlueBalances(address stickyAsset, address[] memory collaterals) internal view virtual returns (uint256[] memory balances) {
        (bool isSticky, address glue) = _isSticky(stickyAsset);

        balances = new uint256[](collaterals.length);
        
        if (!isSticky) {
            for (uint256 i = 0; i < collaterals.length; i++) {
                balances[i] = 0;
            }
            return balances;
        }
        
        for (uint256 i = 0; i < collaterals.length; i++) {
            if (collaterals[i] == address(0)) {
                balances[i] = address(glue).balance;
            } else {
                balances[i] = IERC20(collaterals[i]).balanceOf(glue);
            }
        }
    }

    /**
     * @notice Get the total supply of a sticky asset (adjusted if glued)
     * @param stickyAsset The asset to check
     * @return totalSupply The total supply
     */
    function _getTotalSupply(address stickyAsset) internal view virtual returns (uint256 totalSupply) {
        if (stickyAsset == address(0)) {
            return type(uint256).max;
        }
        
        (bool isSticky, address glue) = _isSticky(stickyAsset);

        if (!isSticky) {
            return IERC20(stickyAsset).totalSupply();
        } else {
            return IGlueERC20(glue).getAdjustedTotalSupply();
        }
    }

    /**
     * @notice Get collateral amounts for a given sticky token amount
     * @param stickyAsset The sticky asset
     * @param amount Amount of sticky tokens
     * @param collaterals Array of collateral addresses
     * @return balances Array of collateral amounts
     */
    function _getCollateralbyAmount(address stickyAsset, uint256 amount, address[] memory collaterals) internal view returns (uint256[] memory balances) {
        (bool isSticky, address glue) = _isSticky(stickyAsset);
        
        balances = new uint256[](collaterals.length);
        
        if (!isSticky) {
            for (uint256 i = 0; i < collaterals.length; i++) {
                balances[i] = 0;
            }
            return balances;
        }
        
        balances = IGlueERC20(glue).collateralByAmount(amount, collaterals);
        return balances;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // TRANSFER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Transfers an asset (ETH or ERC20 token)
     * @param token Token address (address(0) for ETH)
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _transferAsset(address token, address to, uint256 amount) internal virtual {
        if (amount == 0) return;
        
        if (token == address(0)) {
            if (to == address(this)) {
                return; // ETH already in contract
            }
            Address.sendValue(payable(to), amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /**
     * @notice Transfers an asset from one address to another
     * @param token Token address (address(0) for ETH)
     * @param from Source address (ignored for ETH)
     * @param to Destination address
     * @param amount Amount to transfer
     * @return actualAmount The actual amount received (handles tax tokens)
     */
    function _transferFromAsset(address token, address from, address to, uint256 amount) internal virtual returns (uint256 actualAmount) {
        if (amount == 0) return 0;
        
        if (token == address(0)) {
            require(msg.value >= amount, "Insufficient ETH sent");
            
            if (to != address(this)) {
                Address.sendValue(payable(to), amount);
            }
            
            if (msg.value > amount) {
                Address.sendValue(payable(msg.sender), msg.value - amount);
            }
            
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(to);
            IERC20(token).safeTransferFrom(from, to, amount);
            uint256 balanceAfter = IERC20(token).balanceOf(to);

            if (balanceAfter <= balanceBefore) {
                return 0;
            } else {
                return balanceAfter - balanceBefore;
            }
        }
    }

    /**
     * @notice Transfer with balance check (returns actual amount for tax tokens)
     * @param token Token address (address(0) for ETH)
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return actualAmount The actual amount received
     */
    function _transferAssetChecked(address token, address to, uint256 amount) internal returns (uint256 actualAmount) {
        if (amount == 0) return 0;
        
        if (token == address(0)) {
            if (to != address(this)) {
                Address.sendValue(payable(to), amount);
            }
            actualAmount = amount;
        } else {
            uint256 balanceBefore = _balanceOfAsset(token, to);
            IERC20(token).safeTransfer(to, amount);
            uint256 balanceAfter = _balanceOfAsset(token, to);

            require(balanceAfter > balanceBefore, "Transfer failed");

            actualAmount = balanceAfter - balanceBefore;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // BURN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Burn an ERC20 by sending it to its glue contract
     * @param token Token address
     * @param amount Amount to burn
     */
    function _burnAsset(address token, uint256 amount) internal {
        address glue = _initializeGlue(token);
        _transferAsset(token, glue, amount);
    }

    /**
     * @notice Burn an ERC20 from a user by sending it to its glue contract
     * @param token Token address
     * @param from User address
     * @param amount Amount to burn
     */
    function _burnAssetFrom(address token, address from, uint256 amount) internal {
        address glue = _initializeGlue(token);
        _transferFromAsset(token, from, glue, amount);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // APPROVAL & UNGLUE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Approve a spender to spend tokens
     * @param token Token address (no-op for ETH)
     * @param spender Spender address
     * @param amount Amount to approve
     */
    function _approveAsset(address token, address spender, uint256 amount) internal {
        if (token == address(0)) {
            return; // ETH doesn't need approval
        }
        IERC20(token).approve(spender, amount);
    }

    /**
     * @notice Approve and unglue a sticky asset
     * @param token Token address
     * @param amount Amount to unglue
     * @param collaterals Array of collateral addresses to receive
     * @param recipient Address to receive the collaterals
     */
    function _unglueAsset(address token, uint256 amount, address[] memory collaterals, address recipient) internal {
        address glue = _initializeGlue(token);
        _approveAsset(token, glue, amount);
        IGlueERC20(glue).unglue(collaterals, amount, recipient);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // BALANCE & READ FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Gets the balance of an asset (ETH or ERC20 token)
     * @param token Token address (address(0) for ETH)
     * @param account Account to check balance of
     * @return Balance of the asset
     */
    function _balanceOfAsset(address token, address account) internal view virtual returns (uint256) {
        if (token == address(0)) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    /**
     * @notice Get decimals of a token
     * @param token Token address (address(0) for ETH = 18)
     * @return decimals The token decimals
     */
    function _getTokenDecimals(address token) internal view returns (uint8 decimals) {
        if (token == address(0)) {
            return 18;
        } else {
            return IERC20Metadata(token).decimals();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // MATH FUNCTIONS (GluedMath wrappers)
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Performs a multiply-divide operation with full precision
     * @dev Calculates floor(a * b / denominator) with 512-bit intermediate values
     * @param a The multiplicand
     * @param b The multiplier
     * @param denominator The divisor
     * @return result The result of the operation
     */
    function _md512(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        return GluedMath.md512(a, b, denominator);
    }

    /**
     * @notice Performs a multiply-divide operation with full precision (rounds up)
     * @dev Calculates ceil(a * b / denominator) with 512-bit intermediate values
     * @param a The multiplicand
     * @param b The multiplier
     * @param denominator The divisor
     * @return result The result rounded up
     */
    function _md512Up(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        return GluedMath.md512Up(a, b, denominator);
    }

    /**
     * @notice Adjusts decimal places between different tokens
     * @dev Converts amount from tokenIn decimals to tokenOut decimals
     * @param amount The amount to adjust
     * @param tokenIn The input token address
     * @param tokenOut The output token address
     * @return adjustedAmount The adjusted amount
     */
    function _adjustDecimals(uint256 amount, address tokenIn, address tokenOut) internal view returns (uint256 adjustedAmount) {
        return GluedMath.adjustDecimals(amount, tokenIn, tokenOut);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // INTERNAL HELPERS (can be overridden)
    // ═══════════════════════════════════════════════════════════════════════════════════════

    function _glueAnAsset(address stickyAsset) internal virtual returns (address glue) {
        glue = GLUE_STICK_ERC20.applyTheGlue(stickyAsset);
        return glue;
    }

    function _isSticky(address stickyAsset) internal view virtual returns (bool isSticky, address glue) {
        (isSticky, glue) = GLUE_STICK_ERC20.isStickyAsset(stickyAsset);
        return (isSticky, glue);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // ETH RECEIVER
    // ═══════════════════════════════════════════════════════════════════════════════════════
    
    receive() external payable virtual {}
}
