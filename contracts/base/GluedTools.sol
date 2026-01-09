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
 * @dev **GluedTools is the FULL-FEATURED version for developers building ON TOP of Glue Protocol:**
 * 
 * 🎯 **Who Should Use GluedTools:**
 * - ✅ Building routers, aggregators, or trading interfaces for Glue Protocol
 * - ✅ Creating flash loan strategies and MEV bots
 * - ✅ Developing yield farming protocols that integrate with glued assets
 * - ✅ Building lending/borrowing platforms on top of Glue
 * - ✅ Any contract that INTERACTS with glued assets but is NOT a sticky asset itself
 * 
 * ❌ **Do NOT use GluedTools if:**
 * - You want to create a sticky asset → Use StickyAsset.sol or InitStickyAsset.sol instead
 * - You only need ERC20 support → Use GluedToolsERC20 for smaller bytecode
 * - You want minimal features → Use GluedToolsMin for ultra-lightweight integration
 * 
 * 🔧 **What GluedTools Adds (Beyond GluedToolsMin):**
 * - ✅ **GluedMath Integration**: High-precision calculations with 512-bit intermediate values
 * - ✅ **Decimal Adjustment**: Automatic conversion between different token decimals
 * - ✅ **Advanced Transfers**: Batch operations, checked transfers, and excess handling
 * - ✅ **Burn Functions**: Direct burning to glue contracts
 * - ✅ **Collateral Calculations**: Get exact collateral amounts for given sticky token amounts
 * - ✅ **Extended OpenZeppelin**: Full SafeERC20, Address, and IERC721Enumerable support
 * 
 * 📦 **Complete Feature Set:**
 * - Everything from GluedToolsMin (transfers, glue initialization, balance tracking)
 * - High-precision math operations (md512, md512Up)
 * - Decimal adjustment between any token pairs
 * - Batch transfer operations for multiple recipients
 * - Checked transfers with actual amount returned
 * - Burn functions (burnAsset, burnAssetFrom)
 * - Collateral-by-amount calculations
 * - NFT ownership and enumeration
 * - Automatic excess token handling
 * 
 * 💡 **Usage:**
 * Inherit from GluedTools to access the complete suite of helper functions. This provides
 * everything you need to build complex DeFi applications that interact with Glue Protocol.
 * 
 * 🆚 **Version Comparison:**
 * - **GluedToolsMin**: Minimal features, no GluedMath, smallest bytecode
 * - **GluedTools**: Full features, GluedMath included, supports ERC20 + ERC721
 * - **GluedToolsERC20**: Full features, GluedMath included, ERC20-only (medium size)
 * 
 * ⚠️ **Important:**
 * This is for building APPLICATIONS on top of Glue Protocol, not for creating sticky assets.
 * If you want to create a new token that integrates with Glue, use StickyAsset.sol instead.
 */

pragma solidity ^0.8.28;

// Base minimal glue tools (also brings in GluedConstants)
import {GluedToolsMin} from "../tools/GluedToolsMin.sol";
// Strategic import of proprietary mathematical operations library for precision calculations
import {GluedMath} from "../libraries/GluedMath.sol";
// Glue interfaces for extended operations
import {IGlueStickERC20, IGlueERC20} from "../interfaces/IGlueERC20.sol";
import {IGlueStickERC721, IGlueERC721} from "../interfaces/IGlueERC721.sol";
// OpenZeppelin imports for extended functionality
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


abstract contract GluedTools is GluedToolsMin {
    // SafeERC20 usage declaration for secure token transfer operations
    using SafeERC20 for IERC20;
    // Address usage declaration for secure ETH transfers with gas stipend protection
    using Address for address payable;
    // GluedMath usage declaration for precision calculations
    using GluedMath for uint256;

    // ===== CONSTANTS =====
    // Constants (PRECISION, ETH_ADDRESS, DEAD_ADDRESS, GLUE_STICK addresses) inherited from GluedToolsMin -> GluedConstants

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
    // initializeGlue, hasAGlue, getGlueBalances, getTotalSupply inherited from GluedToolsMin

    function _getGlue(address stickyAsset, bool fungible) internal returns (address glue, bool isSticky) {
        (isSticky, glue) = _isSticky(stickyAsset, fungible);
        if (!isSticky) {
            glue = _glueAnAsset(stickyAsset, fungible);
            isSticky = true;
        } else {
            glue = glue;
            isSticky = true;
        }
    }

    // getTotalSupply inherited from GluedToolsMin

    function _getCollateralbyAmount(address stickyAsset, uint256 amount, address[] memory collaterals, bool fungible) internal view returns (uint256[] memory balances) {
        (bool isSticky, address glue) = _isSticky(stickyAsset, fungible);
        if (!isSticky) {
            for (uint256 i = 0; i < collaterals.length; i++) {
                    balances[i] = 0;
            }

            return balances;
            
        } else {
            if (fungible) {
                balances = IGlueERC20(glue).collateralByAmount(amount, collaterals);
            } else {
                balances = IGlueERC721(glue).collateralByAmount(amount, collaterals);
            }
            
            return balances;
        }
        
    }

    // transferAsset inherited from GluedToolsMin

    /**
     * @notice Transfers an asset in a batch
     * @dev For ETH, validates msg.value and handles excess. For ERC20, uses safeTransferFrom
     * @param token Token address (address(0) for ETH)
     * @param to Recipient address
     * @param amounts Amounts to transfer
     * @param tokenIDs TokenIDs to transfer
     * @param fullAmount Full amount to transfer
     * @param fungible Whether the asset is fungible
     */

    function _batchTransferAsset(address token, address[] memory to, uint256[] memory amounts, uint256[] memory tokenIDs, uint256 fullAmount, bool fungible) internal {

        if (fungible) {

            if (fullAmount == 0) {
                revert("Full amount must be greater than 0");
            }

            if (amounts.length == 0) {
                revert("Amounts must be greater than 0");
            }

            if (tokenIDs.length > 0) {
                revert("TokenIDs must be empty");
            }

            if (amounts.length != to.length) {
                revert("Amounts and to must be the same length");
            }

            uint256 amountRemaining = fullAmount;

            if (amounts.length == 1) {
                // Use the same amount for all recipients
                uint256 amountPerRecipient = amounts[0];
                for (uint256 i = 0; i < to.length; i++) {
                    if (amountPerRecipient > amountRemaining) {
                        amountPerRecipient = amountRemaining;
                    }

                    _transferAsset(token, to[i], amountPerRecipient, new uint256[](0), true);
                    amountRemaining -= amountPerRecipient;
                }
            } else {
                for (uint256 i = 0; i < amounts.length; i++) {
                    if (amounts[i] > amountRemaining) {
                        amounts[i] = amountRemaining;
                    }

                    _transferAsset(token, to[i], amounts[i], new uint256[](0), true);
                    amountRemaining -= amounts[i];
                }
            }
        } else {

            if (amounts.length != 0) {
                revert("Amounts must be empty");
            }

            if (fullAmount != 0) {
                revert("Full amount must be 0");
            }

            if (tokenIDs.length == 0) {
                revert("TokenIDs must be empty");
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

    // transferFromAsset inherited from GluedToolsMin

    function _transferAssetChecked(address token, address to, uint256 amount, uint256[] memory tokenIDs, bool fungible) internal returns (uint256 actualAmount) {
        
        if (fungible && amount == 0) {
            return 0;
        } else if (!fungible && tokenIDs.length == 0) {
            return 0;
        }
        if (token == address(0)) {
            if (tokenIDs.length > 0) {
                revert("This asset does not support tokenIDs");
            }

            // Avoid wasteful self-transfer for ETH
            if (to != address(this)) {
                Address.sendValue(payable(to), amount);
            }
            actualAmount = amount;
        } else {
            if (fungible) {
                if (tokenIDs.length > 0) {
                    revert("This asset does not support tokenIDs");
                }

                // Handle ERC20 token transfer
                uint256 balanceBefore = _balanceOfAsset(token, to, fungible);
                IERC20(token).safeTransfer(to, amount);
                uint256 balanceAfter = _balanceOfAsset(token, to, fungible);

                require (balanceAfter > balanceBefore, "Transfer failed");

                actualAmount = balanceAfter - balanceBefore;
            } else {
                if (amount > 0) {
                    revert("This asset does not support amount");
                }

                for (uint256 i = 0; i < tokenIDs.length; i++) {
                    // Handle ERC721 token transfer
                    IERC721(token).transferFrom(address(this), to, tokenIDs[i]);
                }
                actualAmount = tokenIDs.length;
            }
        }
    }

    function _burnAsset(address token, uint256 amount, bool fungible, uint256[] memory tokenIDs) internal {
        
        address glue = _initializeGlue(token, fungible);
            
        _transferAsset(token, glue, amount, tokenIDs, fungible);
    }

    function _burnAssetFrom(address token, address from, uint256 amount, bool fungible, uint256[] memory tokenIDs) internal {

        address glue = _initializeGlue(token, fungible);

        _transferFromAsset(token, from, glue, amount, tokenIDs, fungible);
    }
    
    // ===== ADDITIONAL HELPER FUNCTIONS =====
    // These are GluedTools-specific functions not in GluedToolsMin

    function _getTokenDecimals(address token, bool fungible) internal view returns (uint8 decimals) {
        if (token == address(0)) {
            return 18;
        } else {
            if (fungible) { 
                return IERC20Metadata(token).decimals();
            } else {
                return 0;
            }
        }
    }
    
    /**
     * @notice Handles excess tokens/ETH by sending to glue contract
     * @param token Token address (address(0) for ETH)
     * @param amount Excess amount
     * @param glue Glue contract address
     */
    function _handleExcess(address token, uint256 amount, address glue) internal {
        if (amount > 0 && glue != address(0)) {
            _transferAsset(token, glue, amount, new uint256[](0), false);
        }
    }

    /**
     * @notice Adjusts decimals between tokens using GluedMath
     * @dev Utilizes the GluedMath library for precise decimal adjustment calculations
     * @param amount Amount to adjust for decimal difference
     * @param tokenIn Input token address for decimal lookup
     * @param tokenOut Output token address for decimal lookup
     * @return Adjusted amount accounting for decimal precision differences
     */
    function _adjustDecimals(uint256 amount, address tokenIn, address tokenOut) internal view returns (uint256) {
        // Delegate to GluedMath library for consistent decimal handling across all operations
        return GluedMath.adjustDecimals(amount, tokenIn, tokenOut);
    }

    /**
     * @notice Wrapper for GluedMath.md512 - multiply-divide with full precision
     * @dev Provides access to high-precision arithmetic without direct library coupling
     * @param a The multiplicand value
     * @param b The multiplier value
     * @param denominator The divisor value
     * @return result The result of (a * b) / denominator with full precision
     */
    function _md512(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        // Forward to GluedMath implementation for consistent precision handling
        return GluedMath.md512(a, b, denominator);
    }

    /**
     * @notice Wrapper for GluedMath.md512Up - multiply-divide with full precision (rounds up)
     * @dev Provides ceiling division for scenarios requiring conservative estimates
     * @param a The multiplicand value
     * @param b The multiplier value
     * @param denominator The divisor value
     * @return result The result of (a * b) / denominator rounded up to prevent underpayment
     */
    function _md512Up(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        // Forward to GluedMath implementation ensuring upward rounding for safety
        return GluedMath.md512Up(a, b, denominator);
    }

    // onERC721Received inherited from GluedToolsMin
    // All GluedToolsMin functions inherited: _initializeGlue, _hasAGlue, _getGlueBalances, _getTotalSupply, _transferAsset, _transferFromAsset, _balanceOfAsset, _getNFTOwner
}