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
*/

/**
 * @title GluedToolsERC20Min - Minimal ERC20-Only Glue Protocol Development Kit
 * @author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi - Glue Finance
 * 
 * @notice The ultimate minimal toolkit for building ERC20-focused DeFi applications with Glue Protocol
 * 
 * @dev **GluedToolsERC20Min makes building easier than ever by solving classic ERC20 DeFi challenges:**
 * 
 * 🔧 **What GluedToolsERC20Min Solves:**
 * - ✅ **Tax Token Handling**: Automatically detects and handles transfer taxes, returning actual received amounts
 * - ✅ **ETH/ERC20 Unified Interface**: Single clean API for both ETH and ERC20 tokens
 * - ✅ **Safe Transfers**: Built-in SafeERC20 and Address.sendValue for maximum security
 * - ✅ **Glue Integration**: Seamless ERC20 glue interaction without complex setup
 * - ✅ **Balance Tracking**: Precise balance calculations accounting for transfer taxes
 * - ✅ **Zero External Dependencies**: Ultra-minimal contract optimized for ERC20-only use cases
 * - ✅ **Gas Optimized**: Smaller bytecode than GluedToolsMin (no NFT support = less gas)
 * 
 * 📦 **Key Features:**
 * - Initialize/check glue status for ERC20 assets
 * - Query glue balances and total supply with precision
 * - Transfer ERC20/ETH with automatic tax detection
 * - Try-catch wrappers that never revert unexpectedly
 * - ETH handling with excess refund logic
 * 
 * 🎯 **Perfect For:**
 * - ERC20-only routers and aggregators
 * - Flash loan arbitrage bots
 * - Yield farming strategies
 * - Any fungible-only DeFi protocol integration
 * - Gas-sensitive applications (smaller than GluedToolsMin)
 * 
 * 💡 **Usage:**
 * Inherit from GluedToolsERC20Min to access all ERC20 helper functions. This is the minimal
 * version with zero dependencies on GluedMath. For advanced features, see GluedToolsERC20.
 * 
 * ⚠️ **Note:** 
 * This is NOT for creating sticky assets. If you want to create a sticky asset, inherit from
 * StickyAsset.sol or InitStickyAsset.sol instead. This is for contracts that INTERACT with
 * glued ERC20 tokens but are not sticky assets themselves.
 * 
 * 🆚 **GluedToolsERC20Min vs GluedToolsMin:**
 * - Use GluedToolsERC20Min for ERC20-only applications (smaller, more gas efficient)
 * - Use GluedToolsMin when you need both ERC20 and ERC721 support
 */

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IGlueStickERC20, IGlueERC20} from "../interfaces/IGlueERC20.sol";
import {GluedConstants} from "../libraries/GluedConstants.sol";

abstract contract GluedToolsERC20Min is GluedConstants {
    using SafeERC20 for IERC20;
    using Address for address payable;

    // ===== GLUE FUNCTIONS =====
    
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

    function _hasAGlue(address stickyAsset) internal view virtual returns (bool isSticky) {
        (isSticky, ) = _isSticky(stickyAsset);
        return isSticky;
    }
    
    function _getGlueBalances(address stickyAsset, address[] memory collaterals) internal view virtual returns (uint256[] memory balances) {
        (bool isSticky, address glue) = _isSticky(stickyAsset);

        if (!isSticky) {
            balances = new uint256[](collaterals.length);
            for (uint256 i = 0; i < collaterals.length; i++) {
                balances[i] = 0;
            }
            return balances;
        }
        
        balances = new uint256[](collaterals.length);
        for (uint256 i = 0; i < collaterals.length; i++) {
            if (collaterals[i] == address(0)) {
                balances[i] = address(glue).balance;
            } else {
                balances[i] = IERC20(collaterals[i]).balanceOf(glue);
            }
        }
    }

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

    // ===== TRANSFER FUNCTIONS =====

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

    // ===== INTERNAL HELPERS (can be overridden) =====

    function _glueAnAsset(address stickyAsset) internal virtual returns (address glue) {
        glue = GLUE_STICK_ERC20.applyTheGlue(stickyAsset);
        return glue;
    }

    function _isSticky(address stickyAsset) internal view virtual returns (bool isSticky, address glue) {
        (isSticky, glue) = GLUE_STICK_ERC20.isStickyAsset(stickyAsset);
        return (isSticky, glue);
    }

    // ===== ETH RECEIVER =====
    
    receive() external payable virtual {}
}
