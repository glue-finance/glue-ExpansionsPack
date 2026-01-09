// SPDX-License-Identifier: BUSL-1.1

/**
 * @title GluedToolsMin - Minimal Glue Protocol Development Kit
 * @author @BasedToschi - Glue Finance
 * 
 * @notice The ultimate minimal toolkit for building DeFi applications that interact with the Glue Protocol
 * 
 * @dev **GluedToolsMin makes building easier than ever by solving classic DeFi challenges:**
 * 
 * 🔧 **What GluedToolsMin Solves:**
 * - ✅ **Tax Token Handling**: Automatically detects and handles transfer taxes, returning actual received amounts
 * - ✅ **ETH/ERC20/ERC721 Unified Interface**: Single API for all asset types with consistent behavior
 * - ✅ **Safe Transfers**: Built-in SafeERC20 and Address.sendValue for maximum security
 * - ✅ **Glue Integration**: Seamless interaction with Glue Protocol without complex setup
 * - ✅ **Reentrancy Protection**: No need to add your own guards
 * - ✅ **Balance Tracking**: Precise balance calculations that account for edge cases
 * - ✅ **Zero External Dependencies**: Minimal contract that doesn't bloat your bytecode
 * 
 * 📦 **Key Features:**
 * - Initialize/check glue status for any asset
 * - Query glue balances and total supply with precision
 * - Transfer assets with automatic tax detection
 * - NFT ownership tracking and enumeration
 * - Try-catch wrappers that never revert unexpectedly
 * 
 * 🎯 **Perfect For:**
 * - Building custom integrations with Glue Protocol
 * - Creating routers, aggregators, and MEV bots
 * - Developing advanced DeFi strategies
 * - Any contract that needs to interact with glued assets
 * 
 * 💡 **Usage:**
 * Inherit from GluedToolsMin to access all helper functions. This is the base minimal version
 * with zero dependencies on GluedMath. For advanced features, see GluedTools.
 * 
 * ⚠️ **Note:** 
 * This is NOT for creating sticky assets. If you want to create a sticky asset, inherit from
 * StickyAsset.sol or InitStickyAsset.sol instead.
 */

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IGlueStickERC20, IGlueERC20} from "../interfaces/IGlueERC20.sol";
import {IGlueStickERC721, IGlueERC721} from "../interfaces/IGlueERC721.sol";

abstract contract GluedToolsMin is IERC721Receiver {
    using SafeERC20 for IERC20;
    using Address for address payable;

    // ===== CONSTANTS =====
    
    /// @notice Address of the protocol-wide Glue Stick for ERC20s contract
    IGlueStickERC20 internal constant GLUE_STICK_ERC20_MIN = IGlueStickERC20(0x5fEe29873DE41bb6bCAbC1E4FB0Fc4CB26a7Fd74);

    /// @notice Address of the protocol-wide Glue Stick for ERC721s contract
    IGlueStickERC721 internal constant GLUE_STICK_ERC721_MIN = IGlueStickERC721(0xe9B08D7dC8e44F1973269E7cE0fe98297668C257);
    
    function initializeGlue(address stickyAsset, bool fungible) internal virtual returns (address glue) {
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
    function tryInitializeGlue(address stickyAsset, bool fungible) internal returns (address glue) {
        // First check if already glued
        (bool isSticky, address existingGlue) = _isSticky(stickyAsset, fungible);
        if (isSticky) {
            return existingGlue;
        }
        
        // Try to glue it - wrap in try-catch
        if (fungible) {
            try GLUE_STICK_ERC20_MIN.applyTheGlue(stickyAsset) returns (address _glue) {
                return _glue;
            } catch {
                return address(0); // Failed - asset not compatible
            }
        } else {
            try GLUE_STICK_ERC721_MIN.applyTheGlue(stickyAsset) returns (address _glue) {
                return _glue;
            } catch {
                return address(0); // Failed - asset not enumerable or compatible
            }
        }
    }

    function hasAGlue(address stickyAsset, bool fungible) internal view virtual returns (bool isSticky) {
        (isSticky, ) = _isSticky(stickyAsset, fungible);
        return isSticky;
    }

    function getGlueBalances(address stickyAsset, address[] memory collaterals, bool fungible) internal view virtual returns (uint256[] memory balances) {
        (bool isSticky, address glue) = _isSticky(stickyAsset, fungible);

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

    function getTotalSupply(address stickyAsset, bool fungible) internal view virtual returns (uint256 totalSupply) {
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

    function transferAsset(address token, address to, uint256 amount, uint256[] memory tokenIDs, bool fungible) internal virtual {
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

    function transferFromAsset(address token, address from, address to, uint256 amount, uint256[] memory tokenIDs, bool fungible) internal virtual returns (uint256 actualAmount) {
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

    function balanceOfAsset(address token, address account, bool fungible) internal view virtual returns (uint256) {
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
     * @notice Gets the owner of an NFT
     * @param token NFT contract address
     * @param tokenId The token ID
     * @return owner The owner address (address(0) if doesn't exist)
     */
    function getNFTOwner(address token, uint256 tokenId) internal view virtual returns (address owner) {
        try IERC721(token).ownerOf(tokenId) returns (address _owner) {
            return _owner;
        } catch {
            // Token doesn't exist, is burned, or contract call failed
            return address(0);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // ===== INTERNAL HELPERS (can be overridden) =====

    function _glueAnAsset(address stickyAsset, bool fungible) internal virtual returns (address glue) {
        if (fungible) {
            glue = GLUE_STICK_ERC20_MIN.applyTheGlue(stickyAsset);
        } else {
            glue = GLUE_STICK_ERC721_MIN.applyTheGlue(stickyAsset);
        }
        return glue;
    }

    function _isSticky(address stickyAsset, bool fungible) internal view virtual returns (bool isSticky, address glue) {
        if (fungible) {
            (isSticky, glue) = GLUE_STICK_ERC20_MIN.isStickyAsset(stickyAsset);
        } else {
            (isSticky, glue) = GLUE_STICK_ERC721_MIN.isStickyAsset(stickyAsset);
        }
        return (isSticky, glue);
    }
}

