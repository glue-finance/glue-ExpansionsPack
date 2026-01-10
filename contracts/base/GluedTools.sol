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
████████╗ ██████╗  ██████╗ ██╗     ███████╗                                           
╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝                                           
   ██║   ██║   ██║██║   ██║██║     ███████╗                                           
   ██║   ██║   ██║██║   ██║██║     ╚════██║                                           
   ██║   ╚██████╔╝╚██████╔╝███████╗███████║                                           
   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝                                           
*/

/**
 * @title GluedTools - Advanced Glue Protocol Development Kit
 * @author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi - Glue Finance
 * 
 * @notice The complete advanced toolkit for building sophisticated DeFi applications on top of Glue Protocol
 * 
 * @dev **GluedTools extends GluedToolsBase with advanced batch operations:**
 * 
 * 🎯 **Who Should Use GluedTools:**
 * - ✅ Building routers, aggregators, or trading interfaces for Glue Protocol
 * - ✅ Creating flash loan strategies and MEV bots
 * - ✅ Developing yield farming protocols that integrate with glued assets
 * - ✅ Building lending/borrowing platforms on top of Glue
 * - ✅ Any contract that needs batch transfer operations
 * 
 * ❌ **Do NOT use GluedTools if:**
 * - You want to create a sticky asset → Use StickyAsset.sol or InitStickyAsset.sol
 * - You only need ERC20 support → Use GluedToolsERC20 for smaller bytecode
 * - You don't need batch operations → Use GluedToolsBase directly
 * 
 * 🔧 **What GluedTools Adds (Beyond GluedToolsBase):**
 * - ✅ **Batch Transfer Operations**: Transfer to multiple recipients in one call
 * - ✅ **Excess Handling**: Automatic handling of excess tokens to glue contracts
 * 
 * 📦 **Inherited from GluedToolsBase:**
 * - Reentrancy guard (nnrtnt modifier)
 * - Glue operations (_initializeGlue, _getGlue, _hasAGlue, _getGlueBalances, etc.)
 * - Transfer operations (_transferAsset, _transferFromAsset, _transferAssetChecked)
 * - Burn operations (_burnAsset, _burnAssetFrom)
 * - Math operations (_md512, _md512Up, _adjustDecimals)
 * - Read operations (_balanceOfAsset, _getTotalSupply, _getTokenDecimals, _getCollateralbyAmount)
 * - NFT operations (_getNFTOwner, onERC721Received)
 * 
 * 💡 **Usage:**
 * Inherit from GluedTools when you need batch transfer capabilities.
 * For most use cases, GluedToolsBase is sufficient.
 */

pragma solidity ^0.8.28;

// Base complete glue tools (includes GluedConstants, GluedMath, all helper functions)
import {GluedToolsBase} from "../tools/GluedToolsBase.sol";

abstract contract GluedTools is GluedToolsBase {

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // BATCH TRANSFER OPERATIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Transfers an asset to multiple recipients in a batch
     * @dev For ETH/ERC20, validates amounts and handles partial transfers if fullAmount runs out.
     *      For NFTs, transfers one token per recipient.
     * @param token Token address (address(0) for ETH)
     * @param to Array of recipient addresses
     * @param amounts Array of amounts to transfer (for fungible) or single amount repeated
     * @param tokenIDs Array of token IDs to transfer (for NFTs)
     * @param fullAmount Full amount available for distribution (for fungible)
     * @param fungible Whether the asset is fungible
     */
    function _batchTransferAsset(
        address token, 
        address[] memory to, 
        uint256[] memory amounts, 
        uint256[] memory tokenIDs, 
        uint256 fullAmount, 
        bool fungible
    ) internal {
        if (fungible) {
            if (fullAmount == 0) {
                revert("Full amount must be greater than 0");
            }

            if (amounts.length == 0) {
                revert("Amounts must be greater than 0");
            }

            if (tokenIDs.length > 0) {
                revert("TokenIDs must be empty for fungible");
            }

            if (amounts.length != to.length && amounts.length != 1) {
                revert("Amounts and to must be the same length or amounts.length == 1");
            }

            uint256 amountRemaining = fullAmount;

            if (amounts.length == 1) {
                // Use the same amount for all recipients
                uint256 amountPerRecipient = amounts[0];
                for (uint256 i = 0; i < to.length; i++) {
                    uint256 sendAmount = amountPerRecipient;
                    if (sendAmount > amountRemaining) {
                        sendAmount = amountRemaining;
                    }

                    _transferAsset(token, to[i], sendAmount, new uint256[](0), true);
                    amountRemaining -= sendAmount;
                    
                    if (amountRemaining == 0) break;
                }
            } else {
                for (uint256 i = 0; i < amounts.length; i++) {
                    uint256 sendAmount = amounts[i];
                    if (sendAmount > amountRemaining) {
                        sendAmount = amountRemaining;
                    }

                    _transferAsset(token, to[i], sendAmount, new uint256[](0), true);
                    amountRemaining -= sendAmount;
                    
                    if (amountRemaining == 0) break;
                }
            }
        } else {
            if (amounts.length != 0) {
                revert("Amounts must be empty for NFTs");
            }

            if (fullAmount != 0) {
                revert("Full amount must be 0 for NFTs");
            }

            if (tokenIDs.length == 0) {
                revert("TokenIDs must not be empty");
            }

            if (tokenIDs.length != to.length) {
                revert("TokenIDs and to must be the same length");
            }

            for (uint256 i = 0; i < tokenIDs.length; i++) {
                uint256[] memory singleTokenId = new uint256[](1);
                singleTokenId[0] = tokenIDs[i];
                _transferAsset(token, to[i], 0, singleTokenId, false);
            }
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
            _transferAsset(token, glue, amount, new uint256[](0), true);
        }
    }
}
