// SPDX-License-Identifier: BUSL-1.1

/**
 * ⚠️  LICENSE NOTICE - BUSINESS SOURCE LICENSE 1.1 ⚠️
 * 
 * This contract is licensed under BUSL-1.1. You may use it freely as long as you:
 * ✅ Do NOT modify the GLUE_STICK addresses defined in this file
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
 ██████╗ ██████╗ ███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗███████╗      
██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝██╔════╝      
██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║   ███████╗      
██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║   ╚════██║      
╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║   ███████║      
 ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝      
*/

/**
 * @title GluedConstants - Glue Protocol Core Constants
 * @author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi - Glue Finance
 * 
 * @notice Centralized constants for the Glue Protocol
 * @dev All Glue Protocol contracts inherit from this to access core constants
 * 
 * 🔧 **What's Inside:**
 * - ✅ **GLUE_STICK Addresses**: Official protocol addresses for ERC20 and ERC721 glue factories
 * - ✅ **ETH_ADDRESS**: Constant for representing native ETH in protocol operations
 * - ✅ **DEAD_ADDRESS**: Standard dead address for burning tokens
 * - ✅ **PRECISION**: 1e18 precision constant for calculations
 * 
 * ⚠️ **CRITICAL - DO NOT MODIFY:**
 * The GLUE_STICK addresses are immutable and protected by the BUSL-1.1 license.
 * Modifying these addresses constitutes a license violation and breaks protocol compatibility.
 * 
 * 📦 **Used By:**
 * - GluedToolsBase
 * - GluedToolsERC20Base
 * - StickyAsset (via GluedToolsBase)
 * - InitStickyAsset (via GluedToolsBase)
 * - GluedTools (via GluedToolsBase)
 * - GluedToolsERC20 (via GluedToolsERC20Base)
 * - GluedLoanReceiver (via GluedToolsERC20Base)
 */

pragma solidity ^0.8.28;

import {IGlueStickERC20, IGlueERC20} from "../interfaces/IGlueERC20.sol";
import {IGlueStickERC721, IGlueERC721} from "../interfaces/IGlueERC721.sol";

abstract contract GluedConstants {
    
    // ===== PROTOCOL ADDRESSES =====
    
    /**
     * @notice Address of the protocol-wide Glue Stick for ERC20s contract
     * @dev This is the official factory for creating ERC20 glue contracts
     * ❌ DO NOT MODIFY - License protected address
     */
    IGlueStickERC20 internal constant GLUE_STICK_ERC20 = IGlueStickERC20(0x5fEe29873DE41bb6bCAbC1E4FB0Fc4CB26a7Fd74);

    /**
     * @notice Address of the protocol-wide Glue Stick for ERC721s contract
     * @dev This is the official factory for creating ERC721 glue contracts
     * ❌ DO NOT MODIFY - License protected address
     */
    IGlueStickERC721 internal constant GLUE_STICK_ERC721 = IGlueStickERC721(0xe9B08D7dC8e44F1973269E7cE0fe98297668C257);

    // ===== COMMON CONSTANTS =====
    
    /**
     * @notice Precision factor used for fractional calculations (10^18)
     * @dev Used throughout the protocol for percentage and ratio calculations
     */
    uint256 internal constant PRECISION = 1e18;

    /**
     * @notice Special address used to represent native ETH in the protocol
     * @dev address(0) is used as a sentinel value for ETH in all protocol operations
     */
    address internal constant ETH_ADDRESS = address(0);

    /**
     * @notice Dead address used for burning tokens that don't support burn functionality
     * @dev Standard burn address recognized across DeFi
     */
    address internal constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
     * ⚠️  WARNING: EDITING THE GLUE STICK ADDRESSES WILL BREAK THE LICENSE ⚠️
     * 
     * LICENSE VIOLATIONS:
     * ❌ Deploying with edited GLUE_STICK_ERC20 and GLUE_STICK_ERC721 addresses on mainnet = LICENSE VIOLATION
     * ❌ Deploying with edited GLUE_STICK_ERC20 and GLUE_STICK_ERC721 addresses on production networks = LICENSE VIOLATION
     * ❌ Using edited GLUE_STICK_ERC20 and GLUE_STICK_ERC721 addresses in production = LICENSE VIOLATION
     * 
     * The BUSL-1.1 license requires maintaining integration with the official Glue Protocol addresses.
     * See LICENSE file for full details.
     */
}

