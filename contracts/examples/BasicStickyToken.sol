// SPDX-License-Identifier: MIT
/**

██████╗  █████╗ ███████╗██╗ ██████╗          
██╔══██╗██╔══██╗██╔════╝██║██╔════╝          
██████╔╝███████║███████╗██║██║               
██╔══██╗██╔══██║╚════██║██║██║               
██████╔╝██║  ██║███████║██║╚██████╗          
╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝          
███████╗████████╗██╗ ██████╗██╗  ██╗██╗   ██╗
██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝╚██╗ ██╔╝
███████╗   ██║   ██║██║     █████╔╝  ╚████╔╝ 
╚════██║   ██║   ██║██║     ██╔═██╗   ╚██╔╝  
███████║   ██║   ██║╚██████╗██║  ██╗   ██║   
╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   
████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗ 
╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║ 
   ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║ 
   ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║ 
   ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║ 
   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ 

@title Basic Sticky Token - Minimal Implementation Example
@author @BasedToschi
@notice Example implementation of a simple ERC20 token with StickyAsset integration
@dev This contract demonstrates the minimal setup required to create a sticky token
that integrates with the Glue Protocol ecosystem. It combines standard ERC20 functionality
with the StickyAsset base contract to enable collateral backing and ungluing capabilities.

Key Features:
- Standard ERC20 token functionality (transfer, approve, burn)
- Automatic Glue Protocol integration via StickyAsset
- ERC-7572 compliant metadata URI
- Minimal configuration for quick deployment
- Built-in collateral management through the Glue Protocol

Architecture:
- Inherits from ERC20 for standard token functionality
- Inherits from ERC20Burnable for token burning capabilities
- Inherits from StickyAsset for Glue Protocol integration
- Automatically deploys and configures a Glue contract on construction
- No additional hooks or custom logic (pure pass-through)

Use Cases:
- Simple backed tokens without complex tokenomics
- Community tokens that want basic collateral backing
- Proof-of-concept implementations
- Educational examples for Glue Protocol integration
- Foundation for more complex sticky token implementations

Deployment Flow:
1. Constructor deploys the token with basic parameters
2. StickyAsset constructor automatically creates and configures Glue contract
3. Token is immediately ready for minting, transferring, and ungluing
4. Users can add collateral to the Glue and unglue tokens to withdraw proportional amounts

This implementation provides the foundation for any ERC20 token that wants to be
"sticky" and backed by collateral through the Glue Protocol infrastructure.
*/

pragma solidity ^0.8.28;

/**
* @dev Imports standard OpenZeppelin ERC20 implementation, interfaces, and extensions for secure token functionality
* These imports provide the core ERC20 token mechanics including transfers, approvals, and burning
*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
* @dev Imports StickyAsset base contract and interface to enable Glue Protocol integration and collateral management
* StickyAsset provides the core functionality for interacting with Glue contracts and managing collateral
*/
import {StickyAsset} from "../base/StickyAsset.sol";
import {IStickyAsset} from "../interfaces/IStickyAsset.sol";

/**
--------------------------------------------------------------------------------------------------------
 ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▖ ▗▖▗▄▄▖ 
▐▌   ▐▌     █  ▐▌ ▐▌▐▌ ▐▌
 ▝▀▚▖▐▛▀▀▘  █  ▐▌ ▐▌▐▛▀▘ 
▗▄▄▞▘▐▙▄▄▖  █  ▝▚▄▞▘▐▌                                               
01010011 01100101 01110100 
01110101 01110000 
*/

/**
* @title BasicStickyToken (BST) - A Minimal Sticky ERC20 Token Implementation
* @notice Simple ERC20 token that implements StickyAsset standard for seamless Glue Protocol integration
* @dev This contract provides the most basic implementation of a sticky token with minimal configuration.
* It inherits standard ERC20 functionality while adding StickyAsset capabilities through multiple inheritance.
* 
* The contract automatically:
* - Creates and configures a Glue contract on deployment
* - Enables collateral backing through the Glue Protocol
* - Provides ungluing functionality to redeem collateral
* - Supports ERC-7572 metadata standards
* - Handles all necessary approvals and integrations
*
* Contract Inheritance Chain:
* BasicStickyToken → ERC20 (standard token) + ERC20Burnable (burning) + StickyAsset (glue integration)
*
* Key Parameters in Constructor:
* - tokenInfo[0]: contractURI - ERC-7572 compliant metadata URI
* - tokenInfo[1]: name - Human-readable token name
* - tokenInfo[2]: symbol - Token ticker symbol
* - initialSupply: Amount of tokens to mint to deployer on construction
*
* Deployment Considerations:
* - Gas cost includes Glue contract deployment and configuration
* - Deployer receives initial token supply and becomes default collateral manager
* - Token is immediately functional for all standard ERC20 and StickyAsset operations
* - No additional configuration required post-deployment
*/
contract BasicStickyToken is ERC20, ERC20Burnable, StickyAsset {
    
    /**
    * @notice Constructor that deploys a complete sticky token with automatic Glue Protocol integration
    * @dev Initializes the token with standard ERC20 parameters while automatically creating and configuring
    * the associated Glue contract through the StickyAsset inheritance. The token becomes immediately
    * functional for all standard operations plus collateral backing and ungluing.
    * 
    * @param tokenInfo Array containing token metadata and identification:
    * - tokenInfo[0]: contractURI - URI pointing to ERC-7572 compliant JSON metadata file
    * - tokenInfo[1]: name - Human-readable token name (e.g., "My Sticky Token")
    * - tokenInfo[2]: symbol - Token ticker symbol (e.g., "MST")
    * 
    * @param initialSupply Amount of tokens to mint to the deployer on construction
    * Set to 0 if no initial supply is desired (tokens can be minted later if minting is enabled)
    * 
    * Constructor Flow:
    * 1. ERC20 constructor sets up basic token functionality with name and symbol
    * 2. StickyAsset constructor creates Glue contract and configures integration
    * 3. If initialSupply > 0, mints tokens to msg.sender
    * 4. Token is ready for immediate use with full sticky functionality
    *
    * Gas Considerations:
    * - High initial gas cost due to Glue contract deployment
    * - Subsequent operations use standard ERC20 gas costs
    * - Ungluing operations have additional gas overhead for collateral distribution
    *
    * Use Cases:
    * - Simple community tokens backed by ETH or other tokens
    * - Educational implementations for learning Glue Protocol
    * - Foundation tokens that may add complexity later
    * - Proof-of-concept backed tokens for testing
    */
    constructor(
        // Initialize ERC20 with name and symbol
        // Initialize StickyAsset with URI and [isFungible=true, hasHooks=false]
        string[3] memory tokenInfo, // [contractURI, name, symbol]
        uint256 initialSupply // Initial token supply to mint
    ) 
        ERC20(tokenInfo[1], tokenInfo[2])
        StickyAsset(tokenInfo[0], [true, false])
    {
        // Mint initial supply to the deployer if specified
        // This creates the initial token distribution which can then be
        // transferred, traded, or used as collateral backing
        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply);
        }
        
        // At this point:
        // - Token is fully functional as an ERC20
        // - Glue contract is deployed and configured
        // - Token is approved for the Glue contract to spend
        // - Users can start adding collateral to the Glue
        // - Ungluing functionality is immediately available
        // - Flash loan capabilities are enabled through the Glue
    }

    /**
    * @notice Demonstrates how derived contracts can access inherited StickyAsset functionality
    * @dev This function shows how to interact with the underlying Glue contract and protocol
    * while maintaining the simplicity of the basic implementation
    * 
    * @return glueAddress The address of the associated Glue contract
    * @return isSticky Always returns true since this is a sticky token
    * @return totalSupplyAdjusted The adjusted total supply excluding burned/dead tokens
    *
    * Use Cases:
    * - Client applications displaying token status
    * - Integration verification
    * - Debugging and monitoring
    * - Building more complex derived contracts
    */
    function getTokenInfo() external view returns (address glueAddress, bool isSticky, uint256 totalSupplyAdjusted) {
        return (
            getGlue(), // Address of the associated Glue contract
            true, // This token is always sticky
            getAdjustedTotalSupply() // Total supply adjusted for burned/dead tokens
        );
    }

    /**
    * @notice Example function showing how to calculate potential unglue returns
    * @dev Demonstrates integration with the StickyAsset's collateral calculation functions
    * This helps users understand what they would receive before executing an unglue operation
    * 
    * @param amount Amount of tokens to simulate ungluing
    * @param collaterals Array of collateral token addresses to check
    * @return amounts Array of amounts that would be received for each collateral
    *
    * Use Cases:
    * - Front-end applications showing potential returns
    * - Smart contract integrations calculating slippage
    * - User interfaces displaying real-time redemption values
    * - Strategy contracts evaluating arbitrage opportunities
    */
    function simulateUnglue(uint256 amount, address[] calldata collaterals) 
        external 
        view 
        returns (uint256[] memory amounts) 
    {
        // Leverage the inherited StickyAsset functionality to calculate
        // potential returns without actually executing the unglue operation
        return getcollateralByAmount(amount, collaterals);
    }

    /**
    * @notice Example function showing how to check collateral balances in the Glue
    * @dev Demonstrates how to query the current collateral holdings in the associated Glue contract
    * 
    * @param collaterals Array of collateral token addresses to check
    * @return balances Array of current balances for each collateral in the Glue
    *
    * Use Cases:
    * - Portfolio tracking applications
    * - Collateral monitoring dashboards
    * - Risk management systems
    * - Yield farming strategy evaluation
    */
    function getCollateralBalances(address[] calldata collaterals) 
        external 
        view 
        returns (uint256[] memory balances) 
    {
        // Query the current collateral balances in the Glue contract
        // This shows what backing assets are currently available
        return getBalances(collaterals);
    }

    /**
    * @notice Override required by Solidity for multiple inheritance
    * @dev This function resolves the inheritance ambiguity between ERC20 and StickyAsset
    * No additional logic needed as both parent contracts handle their specific requirements
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // For basic implementation, we rely on the inherited implementations
        // More complex contracts might implement additional interface checks here
        return super.supportsInterface(interfaceId);
    }
} 