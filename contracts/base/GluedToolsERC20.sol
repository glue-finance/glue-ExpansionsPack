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
 * @title GluedToolsERC20 - Advanced ERC20-Only Glue Protocol Development Kit  
 * @author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi - Glue Finance
 * 
 * @notice The complete advanced toolkit for building ERC20-focused DeFi applications on top of Glue Protocol
 * 
 * @dev **GluedToolsERC20 extends GluedToolsERC20Base with advanced batch operations:**
 * 
 * 🎯 **Who Should Use GluedToolsERC20:**
 * - ✅ Building ERC20-only routers and aggregators for Glue Protocol
 * - ✅ Creating flash loan arbitrage strategies  
 * - ✅ Developing yield farming protocols for fungible glued assets
 * - ✅ Building lending/borrowing platforms (ERC20-only)
 * - ✅ Any contract that needs batch transfer operations for ERC20/ETH
 * 
 * ❌ **Do NOT use GluedToolsERC20 if:**
 * - You want to create a sticky asset → Use StickyAsset.sol or InitStickyAsset.sol
 * - You need ERC721 support → Use GluedTools for full ERC20 + ERC721 support
 * - You don't need batch operations → Use GluedToolsERC20Base directly
 * 
 * 🔧 **What GluedToolsERC20 Adds (Beyond GluedToolsERC20Base):**
 * - ✅ **Batch Transfer Operations**: Transfer to multiple recipients in one call
 * - ✅ **Excess Handling**: Automatic handling of excess tokens to glue contracts
 * 
 * 📦 **Inherited from GluedToolsERC20Base:**
 * - Reentrancy guard (nnrtnt modifier)
 * - Glue operations (_initializeGlue, _getGlue, _hasAGlue, _getGlueBalances, etc.)
 * - Transfer operations (_transferAsset, _transferFromAsset, _transferAssetChecked)
 * - Burn operations (_burnAsset, _burnAssetFrom)
 * - Approval operations (_approveAsset, _unglueAsset)
 * - Math operations (_md512, _md512Up, _adjustDecimals)
 * - Read operations (_balanceOfAsset, _getTotalSupply, _getTokenDecimals, _getCollateralbyAmount)
 * 
 * 💡 **Usage:**
 * Inherit from GluedToolsERC20 when you need batch transfer capabilities for ERC20/ETH.
 * For most use cases, GluedToolsERC20Base is sufficient.
 * 
 * 💪 **Gas Optimization:**
 * GluedToolsERC20 is smaller than GluedTools because it excludes all ERC721 functionality.
 * If you only work with fungible tokens, this is the optimal choice.
 */

pragma solidity ^0.8.28;

// Base complete ERC20 glue tools (includes GluedConstants, GluedMath, all helper functions)
import {GluedToolsERC20Base} from "../tools/GluedToolsERC20Base.sol";

abstract contract GluedToolsERC20 is GluedToolsERC20Base {

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // BATCH TRANSFER OPERATIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Transfers an ERC20/ETH to multiple recipients in a batch
     * @dev Validates amounts and handles partial transfers if fullAmount runs out.
     * @param token Token address (address(0) for ETH)
     * @param to Array of recipient addresses
     * @param amounts Array of amounts to transfer (must match to.length)
     * @param fullAmount Full amount available for distribution
     */
    function _batchTransferAsset(
        address token, 
        address[] memory to, 
        uint256[] memory amounts, 
        uint256 fullAmount
    ) internal {
        if (fullAmount == 0) {
            revert("Full amount must be greater than 0");
        }

        if (amounts.length == 0 || amounts.length != to.length) {
            revert("Amounts and to must be the same length");
        }

        uint256 amountRemaining = fullAmount;

        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 sendAmount = amounts[i];
            if (sendAmount > amountRemaining) {
                sendAmount = amountRemaining;
            }

            _transferAsset(token, to[i], sendAmount);
            amountRemaining -= sendAmount;
            
            if (amountRemaining == 0) break;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Handles excess tokens/ETH by sending to glue contract
     * @dev Useful for handling dust or excess from swaps/calculations
     * @param token Token address (address(0) for ETH)
     * @param amount Excess amount to send
     * @param glue Glue contract address to receive the excess
     */
    function _handleExcess(address token, uint256 amount, address glue) internal {
        if (amount > 0 && glue != address(0)) {
            _transferAsset(token, glue, amount);
        }
    }
}
