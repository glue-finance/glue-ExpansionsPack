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
████████╗ ██████╗  ██████╗ ██╗     ███████╗    ██████╗  █████╗ ███████╗███████╗
╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝    ██╔══██╗██╔══██╗██╔════╝██╔════╝
   ██║   ██║   ██║██║   ██║██║     ███████╗    ██████╔╝███████║███████╗█████╗  
   ██║   ██║   ██║██║   ██║██║     ╚════██║    ██╔══██╗██╔══██║╚════██║██╔══╝  
   ██║   ╚██████╔╝╚██████╔╝███████╗███████║    ██████╔╝██║  ██║███████║███████╗
   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
*/

/**
 * @title GluedToolsBase - Complete Base Glue Protocol Development Kit
 * @author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi - Glue Finance
 * 
 * @notice The complete base toolkit for building DeFi applications that interact with the Glue Protocol
 * 
 * @dev **GluedToolsBase provides everything you need to build on Glue Protocol:**
 * 
 * 🔧 **What GluedToolsBase Solves:**
 * - ✅ **Tax Token Handling**: Automatically detects and handles transfer taxes, returning actual received amounts
 * - ✅ **ETH/ERC20/ERC721 Unified Interface**: Single API for all asset types with consistent behavior
 * - ✅ **Safe Transfers**: Built-in SafeERC20 and Address.sendValue for maximum security
 * - ✅ **Glue Integration**: Seamless interaction with Glue Protocol without complex setup
 * - ✅ **Reentrancy Protection**: Built-in EIP-1153 transient storage guard
 * - ✅ **High-Precision Math**: GluedMath integration for 512-bit intermediate calculations
 * - ✅ **Burn Functions**: Direct burning to glue contracts
 * - ✅ **Balance Tracking**: Precise balance calculations that account for edge cases
 * 
 * 📦 **Key Features:**
 * - Initialize/check glue status for any asset
 * - Query glue balances and total supply with precision
 * - Transfer assets with automatic tax detection
 * - Burn assets to glue contracts
 * - High-precision math (md512, md512Up, adjustDecimals)
 * - NFT ownership tracking and enumeration
 * - Try-catch wrappers that never revert unexpectedly
 * 
 * 🎯 **Perfect For:**
 * - Building custom integrations with Glue Protocol
 * - Creating routers, aggregators, and MEV bots
 * - Developing advanced DeFi strategies
 * - Creating sticky assets (StickyAsset, InitStickyAsset inherit this)
 * - Any contract that needs to interact with glued assets
 * 
 * 💡 **Usage:**
 * Inherit from GluedToolsBase to access all helper functions. This is the complete base
 * for ERC20 + ERC721 support. For ERC20-only, use GluedToolsERC20Base.
 * 
 * 🆚 **Version Comparison:**
 * - **GluedToolsBase**: Complete base with ERC20 + ERC721 support
 * - **GluedToolsERC20Base**: Complete base with ERC20-only (smaller bytecode)
 * - **GluedTools**: Extends GluedToolsBase with batch operations
 * - **GluedToolsERC20**: Extends GluedToolsERC20Base with batch operations
 */

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IGlueStickERC20, IGlueERC20} from "../interfaces/IGlueERC20.sol";
import {IGlueStickERC721, IGlueERC721} from "../interfaces/IGlueERC721.sol";
import {GluedConstants} from "../libraries/GluedConstants.sol";
import {GluedMath} from "../libraries/GluedMath.sol";

abstract contract GluedToolsBase is IERC721Receiver, GluedConstants {
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
     * @notice Initialize glue for an asset, creating it if it doesn't exist
     * @param stickyAsset The asset to glue
     * @param fungible Whether the asset is fungible (ERC20) or not (ERC721)
     * @return glue The glue contract address
     */
    function _initializeGlue(address stickyAsset, bool fungible) internal virtual returns (address glue) {
        (bool isSticky, address existingGlue) = _isSticky(stickyAsset, fungible);
        if (!isSticky) {
            glue = _glueAnAsset(stickyAsset, fungible);
        } else {
            glue = existingGlue;
        }
    }

    /**
     * @notice Safe version of initializeGlue that doesn't revert on failure
     * @dev Returns address(0) if glue creation fails (e.g., non-enumerable NFTs)
     * @param stickyAsset The asset to glue
     * @param fungible Whether the asset is fungible
     * @return glue The glue address, or address(0) if failed
     */
    function _tryInitializeGlue(address stickyAsset, bool fungible) internal returns (address glue) {
        (bool isSticky, address existingGlue) = _isSticky(stickyAsset, fungible);
        if (isSticky) {
            return existingGlue;
        }
        
        if (fungible) {
            try GLUE_STICK_ERC20.applyTheGlue(stickyAsset) returns (address _glue) {
                return _glue;
            } catch {
                return address(0);
            }
        } else {
            try GLUE_STICK_ERC721.applyTheGlue(stickyAsset) returns (address _glue) {
                return _glue;
            } catch {
                return address(0);
            }
        }
    }

    /**
     * @notice Get glue address, initializing if needed
     * @param stickyAsset The asset to check/glue
     * @param fungible Whether the asset is fungible
     * @return glue The glue contract address
     * @return isSticky Whether the asset was already sticky
     */
    function _getGlue(address stickyAsset, bool fungible) internal returns (address glue, bool isSticky) {
        (isSticky, glue) = _isSticky(stickyAsset, fungible);
        if (!isSticky) {
            glue = _glueAnAsset(stickyAsset, fungible);
            isSticky = true;
        }
    }

    /**
     * @notice Check if an asset has a glue
     * @param stickyAsset The asset to check
     * @param fungible Whether the asset is fungible
     * @return isSticky Whether the asset has a glue
     */
    function _hasAGlue(address stickyAsset, bool fungible) internal view virtual returns (bool isSticky) {
        (isSticky, ) = _isSticky(stickyAsset, fungible);
        return isSticky;
    }

    /**
     * @notice Get collateral balances in a glue contract
     * @param stickyAsset The sticky asset
     * @param collaterals Array of collateral addresses to check
     * @param fungible Whether the asset is fungible
     * @return balances Array of collateral balances
     */
    function _getGlueBalances(address stickyAsset, address[] memory collaterals, bool fungible) internal view virtual returns (uint256[] memory balances) {
        (bool isSticky, address glue) = _isSticky(stickyAsset, fungible);

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
     * @param fungible Whether the asset is fungible
     * @return totalSupply The total supply
     */
    function _getTotalSupply(address stickyAsset, bool fungible) internal view virtual returns (uint256 totalSupply) {
        if (stickyAsset == address(0)) {
            return type(uint256).max;
        }
        
        (bool isSticky, address glue) = _isSticky(stickyAsset, fungible);

        if (!isSticky) {
            if (fungible) {
                return IERC20(stickyAsset).totalSupply();
            } else {
                try IERC721Enumerable(stickyAsset).totalSupply() returns (uint256 NFTsTotalSupply) {
                    return NFTsTotalSupply;
                } catch {
                    return 0;
                }
            }
        } else {
            if (fungible) {
                return IGlueERC20(glue).getAdjustedTotalSupply();
            } else {
                return IGlueERC721(glue).getAdjustedTotalSupply();
            }
        }
    }

    /**
     * @notice Get collateral amounts for a given sticky token amount
     * @param stickyAsset The sticky asset
     * @param amount Amount of sticky tokens
     * @param collaterals Array of collateral addresses
     * @param fungible Whether the asset is fungible
     * @return balances Array of collateral amounts
     */
    function _getCollateralbyAmount(address stickyAsset, uint256 amount, address[] memory collaterals, bool fungible) internal view returns (uint256[] memory balances) {
        (bool isSticky, address glue) = _isSticky(stickyAsset, fungible);
        
        balances = new uint256[](collaterals.length);
        
        if (!isSticky) {
            for (uint256 i = 0; i < collaterals.length; i++) {
                balances[i] = 0;
            }
            return balances;
        }
        
        if (fungible) {
            balances = IGlueERC20(glue).collateralByAmount(amount, collaterals);
        } else {
            balances = IGlueERC721(glue).collateralByAmount(amount, collaterals);
        }
        
        return balances;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // TRANSFER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Transfer an asset (ETH, ERC20, or ERC721)
     * @param token Token address (address(0) for ETH)
     * @param to Recipient address
     * @param amount Amount to transfer (for fungible)
     * @param tokenIDs Token IDs to transfer (for NFTs)
     * @param fungible Whether the asset is fungible
     */
    function _transferAsset(address token, address to, uint256 amount, uint256[] memory tokenIDs, bool fungible) internal virtual {
        if (fungible && amount == 0) {
            return;
        } else if (!fungible && tokenIDs.length == 0) {
            return;
        }
        
        if (token == address(0)) {
            if (tokenIDs.length > 0) {
                revert("This asset does not support tokenIDs");
            }

            if (to == address(this)) {
                return;
            }

            Address.sendValue(payable(to), amount);
        } else {
            if (fungible) {
                if (tokenIDs.length > 0) {
                    revert("This asset does not support tokenIDs");
                }

                IERC20(token).safeTransfer(to, amount);
            } else {
                if (amount > 0) {
                    revert("This asset does not support amount");
                }

                for (uint256 i = 0; i < tokenIDs.length; i++) {
                    IERC721(token).transferFrom(address(this), to, tokenIDs[i]);
                }
            }
        }
    }

    /**
     * @notice Transfer an asset from one address to another
     * @param token Token address (address(0) for ETH)
     * @param from Source address
     * @param to Destination address
     * @param amount Amount to transfer
     * @param tokenIDs Token IDs (for NFTs)
     * @param fungible Whether the asset is fungible
     * @return actualAmount The actual amount received (handles tax tokens)
     */
    function _transferFromAsset(address token, address from, address to, uint256 amount, uint256[] memory tokenIDs, bool fungible) internal virtual returns (uint256 actualAmount) {
        if (fungible && amount == 0) {
            return 0;
        } else if (!fungible && tokenIDs.length == 0) {
            return 0;
        }
        
        if (token == address(0)) {
            if (tokenIDs.length > 0) {
                revert("This asset does not support tokenIDs");
            }
            
            require(msg.value >= amount, "Insufficient ETH sent");
            
            if (to != address(this)) {
                Address.sendValue(payable(to), amount);
            }
            
            if (msg.value > amount) {
                Address.sendValue(payable(msg.sender), msg.value - amount);
            }
            
            return amount;
        } else {
            if (fungible) {
                if (tokenIDs.length > 0) {
                    revert("This asset does not support tokenIDs");
                }

                uint256 balanceBefore = IERC20(token).balanceOf(to);
                IERC20(token).safeTransferFrom(from, to, amount);
                uint256 balanceAfter = IERC20(token).balanceOf(to);

                if (balanceAfter <= balanceBefore) {
                    return 0;
                } else {
                    return balanceAfter - balanceBefore;
                }
            } else {
                if (amount > 0) {
                    revert("This asset does not support amount");
                }

                for (uint256 i = 0; i < tokenIDs.length; i++) {
                    IERC721(token).transferFrom(from, to, tokenIDs[i]);
                }
                return tokenIDs.length;
            }
        }
    }

    /**
     * @notice Transfer with balance check (returns actual amount for tax tokens)
     * @param token Token address (address(0) for ETH)
     * @param to Recipient address
     * @param amount Amount to transfer
     * @param tokenIDs Token IDs (for NFTs)
     * @param fungible Whether the asset is fungible
     * @return actualAmount The actual amount received
     */
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

            if (to != address(this)) {
                Address.sendValue(payable(to), amount);
            }
            actualAmount = amount;
        } else {
            if (fungible) {
                if (tokenIDs.length > 0) {
                    revert("This asset does not support tokenIDs");
                }

                uint256 balanceBefore = _balanceOfAsset(token, to, fungible);
                IERC20(token).safeTransfer(to, amount);
                uint256 balanceAfter = _balanceOfAsset(token, to, fungible);

                require(balanceAfter > balanceBefore, "Transfer failed");

                actualAmount = balanceAfter - balanceBefore;
            } else {
                if (amount > 0) {
                    revert("This asset does not support amount");
                }

                for (uint256 i = 0; i < tokenIDs.length; i++) {
                    IERC721(token).transferFrom(address(this), to, tokenIDs[i]);
                }
                actualAmount = tokenIDs.length;
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // BURN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Burn an asset by sending it to its glue contract
     * @param token Token address
     * @param amount Amount to burn (for fungible)
     * @param fungible Whether the asset is fungible
     * @param tokenIDs Token IDs to burn (for NFTs)
     */
    function _burnAsset(address token, uint256 amount, bool fungible, uint256[] memory tokenIDs) internal {
        address glue = _initializeGlue(token, fungible);
        _transferAsset(token, glue, amount, tokenIDs, fungible);
    }

    /**
     * @notice Burn an asset from a user by sending it to its glue contract
     * @param token Token address
     * @param from User address
     * @param amount Amount to burn (for fungible)
     * @param fungible Whether the asset is fungible
     * @param tokenIDs Token IDs to burn (for NFTs)
     */
    function _burnAssetFrom(address token, address from, uint256 amount, bool fungible, uint256[] memory tokenIDs) internal {
        address glue = _initializeGlue(token, fungible);
        _transferFromAsset(token, from, glue, amount, tokenIDs, fungible);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // BALANCE & READ FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get balance of an asset
     * @param token Token address (address(0) for ETH)
     * @param account Account to check
     * @param fungible Whether the asset is fungible
     * @return Balance of the asset
     */
    function _balanceOfAsset(address token, address account, bool fungible) internal view virtual returns (uint256) {
        if (token == address(0)) {
            return account.balance;
        } else {
            if (fungible) {
                return IERC20(token).balanceOf(account);
            } else {
                try IERC721Enumerable(token).balanceOf(account) returns (uint256 balance) {
                    return balance;
                } catch {
                    return 0;
                }
            }
        }
    }

    /**
     * @notice Get the owner of an NFT
     * @param token NFT contract address
     * @param tokenId The token ID
     * @return owner The owner address (address(0) if doesn't exist)
     */
    function _getNFTOwner(address token, uint256 tokenId) internal view virtual returns (address owner) {
        try IERC721(token).ownerOf(tokenId) returns (address _owner) {
            return _owner;
        } catch {
            return address(0);
        }
    }

    /**
     * @notice Get decimals of a token
     * @param token Token address (address(0) for ETH = 18)
     * @param fungible Whether the asset is fungible
     * @return decimals The token decimals
     */
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
    // ERC721 RECEIVER
    // ═══════════════════════════════════════════════════════════════════════════════════════

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // INTERNAL HELPERS (can be overridden)
    // ═══════════════════════════════════════════════════════════════════════════════════════

    function _glueAnAsset(address stickyAsset, bool fungible) internal virtual returns (address glue) {
        if (fungible) {
            glue = GLUE_STICK_ERC20.applyTheGlue(stickyAsset);
        } else {
            glue = GLUE_STICK_ERC721.applyTheGlue(stickyAsset);
        }
        return glue;
    }

    function _isSticky(address stickyAsset, bool fungible) internal view virtual returns (bool isSticky, address glue) {
        if (fungible) {
            (isSticky, glue) = GLUE_STICK_ERC20.isStickyAsset(stickyAsset);
        } else {
            (isSticky, glue) = GLUE_STICK_ERC721.isStickyAsset(stickyAsset);
        }
        return (isSticky, glue);
    }
}
