// SPDX-License-Identifier: MIT
/**

/**

 █████╗ ██████╗ ██╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗██████╗     
██╔══██╗██╔══██╗██║   ██║██╔══██╗████╗  ██║██╔════╝██╔════╝██╔══██╗    
███████║██║  ██║██║   ██║███████║██╔██╗ ██║██║     █████╗  ██║  ██║    
██╔══██║██║  ██║╚██╗ ██╔╝██╔══██║██║╚██╗██║██║     ██╔══╝  ██║  ██║    
██║  ██║██████╔╝ ╚████╔╝ ██║  ██║██║ ╚████║╚██████╗███████╗██████╔╝    
╚═╝  ╚═╝╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═════╝     
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

@title Advanced Sticky Token - Full-Featured Implementation Example
@author @BasedToschi
@notice Comprehensive implementation of the StickyAsset with owner fee using GluedHooks
@dev This contract demonstrates a sophisticated sticky token implementation with extensive configuration
options, fee management, governance controls, and compliance features. It showcases the full potential
of the Glue Protocol ecosystem integration with enterprise-grade functionality.

Key Features:
- Complete ERC20 functionality with burning and ownership
- Advanced fee collection mechanisms (from sticky tokens and/or collateral)
- Configurable maximum supply controls
- Blacklist integration for compliance
- Granular permission system with owner and collateral manager roles
- Permanent locking capabilities for critical parameters
- Sophisticated hook system for revenue generation
- ERC-7572 compliant metadata with updatable URI
- Emergency controls and governance features

Architecture Complexity:
- Multiple inheritance: ERC20 + ERC20Burnable + Ownable + StickyAsset
- Hook-based fee collection system with configurable sources
- Role-based access control with separation of concerns
- Immutable constants with runtime configuration
- Locking mechanisms for parameter finalization
- Event-driven architecture for transparency

Use Cases:
- Enterprise tokens requiring compliance and governance
- Revenue-generating backed tokens with sophisticated tokenomics
- DAO tokens with treasury management through fees
- Stablecoins with backing asset management
- Gaming tokens with in-game asset backing
- DeFi protocol tokens with yield generation mechanisms

Configuration Matrix:
Fee Sources: NO_FEE | FROM_STICKY | FROM_COLLATERAL | FROM_BOTH
Locking: Individual parameter locks + emergency governance locks
Roles: Owner (governance) + Collateral Manager (operational) + Fee Receiver
Compliance: Optional blacklist integration with external contract

This implementation serves as a template for complex token deployments requiring
maximum flexibility, governance, and integration with the Glue Protocol ecosystem.
*/

pragma solidity ^0.8.28;

/**
* @dev Imports standard OpenZeppelin implementation, interfaces, and extensions for secure functionalities
* These provide enterprise-grade token functionality with access control and security features
*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev StickyAsset base contract and interface for Glue Protocol integration
 * Provides the foundation for collateral backing and advanced protocol features
 */
import {StickyAsset} from "../base/StickyAsset.sol";
import {IStickyAsset} from "../interfaces/IStickyAsset.sol";

/**
 * @dev Interface for external blacklist contract integration
 * Enables compliance features and restricted transfer functionality
 */
interface IBlacklist {
    /**
    * @notice Checks if an address is blacklisted
    * @param account Address to check
    * @return true if the address is blacklisted, false otherwise
    */
    function isBlacklisted(address account) external view returns (bool);
}

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
* @title AdvancedStickyToken - Enterprise-Grade Sticky Token Implementation
* @notice Advanced implementation of the StickyAsset standard for ERC20 tokens with comprehensive governance
* @dev This contract extends the basic sticky token concept with sophisticated fee management, governance
* controls, compliance features, and operational flexibility. It represents the full potential of what
* can be built on top of the Glue Protocol infrastructure.
*
* The contract implements a multi-layered architecture:
* 1. Base Layer: Standard ERC20 functionality with burning capabilities
* 2. Access Layer: Ownable pattern with additional role-based permissions
* 3. Compliance Layer: Optional blacklist integration for regulatory compliance
* 4. Economic Layer: Sophisticated fee collection from multiple sources
* 5. Governance Layer: Parameter locking and emergency controls
* 6. Integration Layer: Full StickyAsset implementation with hooks
*
* Fee Collection Mechanisms:
* - FROM_STICKY: Fees collected when tokens are burned during ungluing
* - FROM_COLLATERAL: Fees collected from withdrawn collateral during ungluing
* - FROM_BOTH: Split fees between both sources for balanced revenue generation
* - NO_FEE: Disabled fee collection for pure utility tokens
*
* Permission Structure:
* - Owner: Governance-level control over fee rates, blacklist, and locking mechanisms
* - Collateral Manager: Operational control over supply management and minting
* - Fee Receiver: Revenue management with ability to update receiver address
*
* Locking Mechanisms:
* Each critical parameter can be permanently locked to prevent future modifications,
* providing security guarantees to token holders about immutable tokenomics.
*/
contract AdvancedStickyToken is ERC20, ERC20Burnable, Ownable, StickyAsset {
    using SafeERC20 for IERC20;

// █████╗ Constants
// ╚════╝ 

    /**
     * @notice Maximum fee percentage that can be set by the owner
     * @dev Immutable constant set at deployment to provide upper bound guarantees
     * Prevents owner from setting excessive fees that could harm token holders
     */
    uint256 private immutable MAX_OWNER_FEE;

    /**
     * @notice Enumeration defining the source of fee collection during ungluing operations
     * @dev This enum determines where fees are collected from when users unglue their tokens
     * The choice affects the token economics and user experience significantly
     */
    enum FeeSource {
        NO_FEE,         // No fees collected - pure utility token mode
        FROM_STICKY,    // Fees taken only from burned sticky tokens
        FROM_COLLATERAL,// Fees taken only from withdrawn collateral
        FROM_BOTH       // Fees taken from both sources (50% split)
    }

// █████╗ State Variables
// ╚════╝ 

    /// @notice Current fee percentage applied during ungluing operations
    uint256 private owner_fee;

    /// @notice Maximum token supply limit (0 = unlimited)
    uint256 private max_supply;

    /// @notice Current fee collection strategy
    FeeSource private feeSource;

    /// @notice Address that receives collected fees
    address private fee_receiver;

    /// @notice External blacklist contract for compliance (optional)
    address private blacklist;

    /// @notice Address with operational control over supply management
    address private collateral_manager;

    /// @notice Override token name for dynamic updates
    string private _name;

    /// @notice Override token symbol for dynamic updates  
    string private _symbol;

// █████╗ Locking Variables
// ╚════╝ 

    /// @notice Prevents changes to owner fee when true
    bool private owner_fee_locked;

    /// @notice Prevents changes to maximum supply when true  
    bool private max_supply_locked;

    /// @notice Prevents changes to fee source when true
    bool private fee_source_locked;

    /// @notice Prevents changes to contract URI when true
    bool private contract_uri_locked;

    /// @notice Prevents changes to name and symbol when true
    bool private name_symbol_locked;

    /// @notice Prevents changes to blacklist when true
    bool private blacklist_locked;

    /// @notice Prevents changes to collateral manager when true
    bool private collateral_manager_locked;

    /// @notice Prevents new token minting when true
    bool private mint_locked;

    /**
     * @notice Comprehensive constructor for advanced sticky token deployment
     * @dev Initializes the token with complete configuration including governance, fees, compliance,
     * and operational parameters. This constructor provides maximum flexibility for enterprise deployments
     * while maintaining security through validation and locking mechanisms.
     * 
     * @param assetInfo Token metadata and identification [contractURI, name, symbol]
     * - assetInfo[0]: contractURI - ERC-7572 compliant metadata URI for off-chain token information
     * - assetInfo[1]: name - Human-readable token name displayed in wallets and interfaces
     * - assetInfo[2]: symbol - Token ticker symbol for trading and identification
     * 
     * @param tokenomics Economic parameters [maxOwnerFee, ownerFee, maxSupply, feeSource, initialSupply]
     * - tokenomics[0]: maxOwnerFee - Upper bound for fee percentage (immutable security guarantee)
     * - tokenomics[1]: ownerFee - Initial fee percentage for ungluing operations
     * - tokenomics[2]: maxSupply - Maximum tokens that can exist (0 = unlimited)
     * - tokenomics[3]: feeSource - Fee collection strategy (0=NO_FEE, 1=FROM_STICKY, 2=FROM_COLLATERAL, 3=FROM_BOTH)
     * - tokenomics[4]: initialSupply - Tokens minted to deployer on creation
     * 
     * @param managers Role assignments [owner, feeReceiver, blacklist, collateralManager]
     * - managers[0]: owner - Governance control (uses deployer if address(0))
     * - managers[1]: feeReceiver - Revenue recipient (uses deployer if address(0))
     * - managers[2]: blacklist - Compliance contract (optional, can be address(0))
     * - managers[3]: collateralManager - Operational control (uses deployer if address(0))
     * 
     * @param initialLocks Parameter locking configuration [ownerFee, maxSupply, feeSource, contractURI, nameSymbol, blacklist, collateralManager, mint]
     * - initialLocks[0]: ownerFee - Lock fee percentage changes
     * - initialLocks[1]: maxSupply - Lock supply limit changes
     * - initialLocks[2]: feeSource - Lock fee collection strategy changes
     * - initialLocks[3]: contractURI - Lock metadata URI changes
     * - initialLocks[4]: nameSymbol - Lock name and symbol changes
     * - initialLocks[5]: blacklist - Lock compliance contract changes
     * - initialLocks[6]: collateralManager - Lock operational role changes
     * - initialLocks[7]: mint - Lock minting capability
     *
     * Constructor Flow:
     * 1. Validates all parameters for security and consistency
     * 2. Initializes ERC20 with empty name/symbol (overridden later)
     * 3. Sets up ownership with specified or default owner
     * 4. Creates StickyAsset integration with Glue Protocol
     * 5. Configures all economic and governance parameters
     * 6. Assigns roles and permissions
     * 7. Applies initial locking configuration
     * 8. Mints initial token supply if specified
     *
     * Security Considerations:
     * - MAX_OWNER_FEE provides immutable fee upper bound
     * - Initial locks can be set to prevent future governance changes
     * - Role separation ensures operational security
     * - Parameter validation prevents invalid configurations
     */
    constructor(
        string[3] memory assetInfo, // [contractURI, name, symbol]
        uint256[5] memory tokenomics, // [maxOwnerFee, ownerFee, maxSupply, feeSource, initialSupply]
        address[4] memory managers, // [owner, feeReceiver, blacklist, collateralManager]
        bool[8] memory initialLocks  // [ownerFee, maxSupply, feeSource, contractURI, nameSymbol, blacklist, collateralManager, mint]
    ) 
        ERC20("", "") // Initialize with empty strings, overridden by _name and _symbol
        Ownable(managers[0] == address(0) ? msg.sender : managers[0]) // Set owner or use deployer
        StickyAsset(assetInfo[0], [true, true]) // Initialize as fungible token with hooks enabled
    {
        /**
         * Token Information Setup
         */
        _name = assetInfo[1];
        _symbol = assetInfo[2];

        /**
         * Economic Parameter Configuration
         */
        require(tokenomics[0] <= PRECISION, "Maximum owner fee must be less than or equal to 100%");
        MAX_OWNER_FEE = tokenomics[0];

        require(tokenomics[1] <= MAX_OWNER_FEE, "Owner fee must be less than or equal to Max Owner Fee");
        owner_fee = tokenomics[1];

        max_supply = tokenomics[2]; // 0 = unlimited supply

        require(tokenomics[3] <= 3, "Invalid fee source value");
        feeSource = FeeSource(tokenomics[3]);

        /**
         * Role and Permission Assignment
         */
        fee_receiver = managers[1] != address(0) ? managers[1] : msg.sender;
        blacklist = managers[2]; // Can be address(0) for no blacklist
        collateral_manager = managers[3] != address(0) ? managers[3] : msg.sender;

        /**
         * Initial Locking Configuration
         */
        owner_fee_locked = initialLocks[0];
        max_supply_locked = initialLocks[1];
        fee_source_locked = initialLocks[2];
        contract_uri_locked = initialLocks[3];
        name_symbol_locked = initialLocks[4];
        blacklist_locked = initialLocks[5];
        collateral_manager_locked = initialLocks[6];
        mint_locked = initialLocks[7];

        /**
         * Initial Token Distribution
         */
        if (tokenomics[4] > 0) {
            _mint(msg.sender, tokenomics[4]);
        }
    }

    /**
     * @notice Restricts function access to collateral manager only
     * @dev Used for operational functions that should not require full governance approval
     * but need elevated permissions beyond regular users
     */
    modifier onlyCollateralManager() {
        require(msg.sender == collateral_manager, "Only collateral manager can call this function");
        _;
    }
    
/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▄▖  ▗▄▖ ▗▖    ▗▄▄▖
  █ ▐▌ ▐▌▐▌ ▐▌▐▌   ▐▌   
  █ ▐▌ ▐▌▐▌ ▐▌▐▌    ▝▀▚▖
  █ ▝▚▄▞▘▝▚▄▞▘▐▙▄▄▖▗▄▄▞▘
01010100 01101111 01101111 
01101100 01110011
*/

    /**
     * @notice Override ERC20 _update to include blacklist checks
     * @dev Adds compliance layer to standard ERC20 transfers by checking blacklist status
     * This function is called for all transfers, mints, and burns
     * 
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to  
     * @param value The amount of tokens being transferred
     */
    function _update(address from, address to, uint256 value) internal virtual override(ERC20) {
        // If blacklist is configured, check sender compliance
        if (blacklist != address(0)) {
            require(!IBlacklist(blacklist).isBlacklisted(from), "Sender is blacklisted");
        }

        // Execute standard ERC20 update with compliance check passed
        super._update(from, to, value);
    }

    /**
     * @notice Enables contract to receive ETH for collateral backing
     * @dev Required for ETH-based fee collection and collateral operations
     */
    receive() external payable {}

/**
--------------------------------------------------------------------------------------------------------
▗▖ ▗▖ ▗▄▖  ▗▄▖ ▗▖ ▗▖
▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌▗▞▘
▐▛▀▜▌▐▌ ▐▌▐▌ ▐▌▐▛▚▖ 
▐▌ ▐▌▝▚▄▞▘▝▚▄▞▘▐▌ ▐▌
01001000 01001111 
01001111 01001011                               
*/


    /**
    * @notice Calculates the fee percentage to be taken from burned sticky tokens during ungluing
    * @dev Override of StickyAsset's _calculateStickyHookSize to implement configurable fee collection
    * This function determines what percentage of burned tokens should be redirected to the fee receiver
    * based on the configured fee source setting.
    * 
    * @param amount The amount of sticky tokens being burned during ungluing operation
    * @return The percentage of tokens to redirect as fees (in PRECISION units, where 1e18 = 100%)
    * 
    * Fee Source Logic:
    * - FROM_STICKY: Full fee percentage applied to sticky tokens
    * - FROM_COLLATERAL: No fees from sticky tokens (returns 0)
    * - FROM_BOTH: Half fee percentage applied to sticky tokens (split approach)
    * - NO_FEE: No fees collected (returns 0)
    *
    * Use Cases:
    * - Protocol revenue generation from token circulation reduction
    * - Treasury funding mechanisms for DAOs and protocols
    * - Deflationary tokenomics with revenue capture
    * - Balanced fee collection across different asset types
    */
    function _calculateStickyHookSize(uint256 amount) internal view override returns (uint256) {
        // Only apply hook if fee source includes sticky token fees
        if (feeSource == FeeSource.FROM_STICKY || feeSource == FeeSource.FROM_BOTH) {
            // If fee source is FROM_BOTH, take only half of the fee from sticky tokens
            uint256 feeRatio = feeSource == FeeSource.FROM_BOTH ? 
                _md512(owner_fee, PRECISION / 2, PRECISION) : owner_fee;
            return feeRatio;
        }
        return 0; // No fees from sticky tokens for other fee sources
    }

    /**
    * @notice Calculates the fee percentage to be taken from withdrawn collateral during ungluing
    * @dev Override of StickyAsset's _calculateCollateralHookSize to implement configurable fee collection
    * This function determines what percentage of collateral should be redirected to the fee receiver
    * based on the configured fee source setting.
    * 
    * @param asset The address of the collateral token being withdrawn (unused in basic implementation)
    * @param amount The amount of collateral tokens being withdrawn during ungluing
    * @return The percentage of collateral to redirect as fees (in PRECISION units)
    * 
    * Fee Source Logic:
    * - FROM_COLLATERAL: Full fee percentage applied to collateral
    * - FROM_STICKY: No fees from collateral (returns 0)
    * - FROM_BOTH: Half fee percentage applied to collateral (split approach)
    * - NO_FEE: No fees collected (returns 0)
    *
    * Use Cases:
    * - Revenue generation from diverse collateral backing assets
    * - Multi-token treasury funding strategies
    * - Sustainable fee collection from high-value backing assets
    * - Flexible monetization of protocol usage
    */
    function _calculateCollateralHookSize(address asset, uint256 amount) internal view override returns (uint256) {
        // Only apply hook if fee source includes collateral fees
        if (feeSource == FeeSource.FROM_COLLATERAL || feeSource == FeeSource.FROM_BOTH) {
            // If fee source is FROM_BOTH, take only half of the fee from collateral
            uint256 feeRatio = feeSource == FeeSource.FROM_BOTH ? 
                _md512(owner_fee, PRECISION / 2, PRECISION) : owner_fee;
            return feeRatio;
        }
        return 0; // No fees from collateral for other fee sources
    }

    /**
    * @notice Processes fees collected from burned sticky tokens
    * @dev Override of StickyAsset's _processStickyHook to handle sticky token fee transfers
    * This function is automatically called during the ungluing process after sticky tokens
    * have been sent to this contract but before they are burned.
    * 
    * @param amount The amount of sticky tokens to process as fees
    * @param tokenIds Not used for ERC20 tokens (included for ERC721 compatibility)
    * @param recipient The address of the recipient of the unglue operation
    * 
    * Process Flow:
    * 1. Validate fee amount and receiver address
    * 2. Transfer tokens from this contract to fee receiver
    * 3. Tokens are effectively redirected from burning to fee collection
    *
    * Use Cases:
    * - Creating revenue streams from token deflationary mechanics
    * - Funding protocol development and maintenance
    * - Supporting DAO treasuries through token economics
    * - Balancing deflationary pressure with revenue generation
    */
    function _processStickyHook(uint256 amount, uint256[] memory tokenIds, address recipient) internal override {
        // Process sticky token fees by transferring to fee receiver
        if (amount > 0 && fee_receiver != address(0)) {
            // Transfer the fee amount to the designated fee receiver
            // These tokens are redirected from burning to fee collection
            _transfer(address(this), fee_receiver, amount);
        }
    }

    /**
    * @notice Processes fees collected from withdrawn collateral tokens
    * @dev Override of StickyAsset's _processCollateralHook to handle collateral fee transfers
    * This function manages the transfer of collected fees to the designated fee receiver,
    * supporting both ERC20 tokens and native ETH collateral types.
    * 
    * @param asset The address of the collateral token (address(0) for ETH)
    * @param amount The amount of collateral to transfer as fees
    * @param isETH Boolean flag indicating whether the collateral is native ETH
    * @param recipient The address of the recipient of the unglue operation
    * 
    * Transfer Logic:
    * - ETH: Direct value transfer to fee receiver with error handling
    * - ERC20: SafeERC20 transfer with comprehensive error checking
    * - Validation: Ensures non-zero amounts and valid fee receiver
    *
    * Use Cases:
    * - Generating protocol revenue from diverse backing asset types
    * - Creating sustainable funding mechanisms for protocol operations
    * - Implementing dynamic fee collection strategies
    * - Supporting multi-asset treasury management
    */
    function _processCollateralHook(address asset, uint256 amount, bool isETH, address recipient) internal override {
        // Process collateral fees by transferring to fee receiver
        if (amount > 0 && fee_receiver != address(0)) {
            if (isETH) {
                // Transfer ETH to fee receiver with proper error handling
                (bool success, ) = fee_receiver.call{value: amount}("");
                require(success, "ETH transfer to fee receiver failed");
            } else {
                // Transfer ERC20 token to fee receiver using SafeERC20
                IERC20(asset).safeTransfer(fee_receiver, amount);
            }
        }
    }

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▖ ▗▖▗▖  ▗▖ ▗▄▄▖▗▄▄▄▖▗▄▄▄▖ ▗▄▖ ▗▖  ▗▖ ▗▄▄▖
▐▌   ▐▌ ▐▌▐▛▚▖▐▌▐▌     █    █  ▐▌ ▐▌▐▛▚▖▐▌▐▌   
▐▛▀▀▘▐▌ ▐▌▐▌ ▝▜▌▐▌     █    █  ▐▌ ▐▌▐▌ ▝▜▌ ▝▀▚▖
▐▌   ▝▚▄▞▘▐▌  ▐▌▝▚▄▄▖  █  ▗▄█▄▖▝▚▄▞▘▐▌  ▐▌▗▄▄▞▘
01000110 01110101 01101110 01100011 01110100 
01101001 01101111 01101110 01110011                               
*/

    /**
     * @notice Mints new tokens to specified address with supply controls
     * @dev Allows collateral manager to create new tokens within max supply constraints
     * 
     * @param to Recipient address for newly minted tokens
     * @param amount Quantity of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyCollateralManager {
        require(!mint_locked, "Mint is locked");
        if (max_supply != 0) {
            require(totalSupply() + amount <= max_supply, "Max supply exceeded");
        }
        _mint(to, amount);
    }

    /**
     * @notice Updates the fee receiver address
     * @dev Only current fee receiver can update to prevent unauthorized changes
     * 
     * @param _feeReceiver New address to receive collected fees
     */
    function setFeeReceiver(address _feeReceiver) external {
        require(msg.sender == fee_receiver, "Only fee receiver can set fee receiver");
        fee_receiver = _feeReceiver;
        emit FeeReceiverUpdated(_feeReceiver);
    }

    /**
     * @notice Updates owner fee percentage
     * @dev Only owner can modify when not locked, subject to maximum fee constraint
     * 
     * @param _ownerFee New fee percentage (must be <= MAX_OWNER_FEE)
     */
    function setOwnerFee(uint256 _ownerFee) external onlyOwner {
        require(!owner_fee_locked, "Owner fee is already locked");
        require(_ownerFee <= MAX_OWNER_FEE, "Owner fee is too high");
        owner_fee = _ownerFee;
        emit OwnerFeeChanged(_ownerFee);
    }

    /**
     * @notice Permanently locks the owner fee to prevent future changes
     * @dev One-way operation that cannot be reversed, providing security guarantees
     */
    function lockOwnerFee() external onlyOwner {
        require(!owner_fee_locked, "Owner fee is already locked");
        owner_fee_locked = true;
        emit OwnerFeeLocked();
    }

    /**
     * @notice Updates the fee collection strategy
     * @dev Changes where fees are collected from during ungluing operations
     * 
     * @param _newFeeSource New fee source strategy (0-3 corresponding to FeeSource enum)
     */
    function setFeeSource(FeeSource _newFeeSource) external onlyOwner {
        require(!fee_source_locked, "Fee source is locked");
        feeSource = _newFeeSource;
        emit FeeSourceUpdated(_newFeeSource);
    }

    /**
     * @notice Permanently locks the fee source to prevent future changes
     * @dev Provides immutability guarantee for fee collection strategy
     */
    function lockFeeSource() external onlyOwner {
        require(!fee_source_locked, "Fee source already locked");
        fee_source_locked = true;
        emit FeeSourceLocked();
    }

    /**
     * @notice Updates the contract metadata URI
     * @dev Allows updating ERC-7572 compliant metadata when not locked
     * 
     * @param newURI New metadata URI pointing to JSON metadata file
     */
    function setContractURI(string memory newURI) external onlyOwner {
        require(!contract_uri_locked, "Contract URI is already locked");
        _updateContractURI(newURI);
        emit ContractURIUpdated();
    }

    /**
     * @notice Permanently locks the contract URI to prevent future changes
     * @dev Ensures metadata immutability when required
     */
    function lockContractURI() external onlyOwner {
        require(!contract_uri_locked, "Contract URI is already locked");
        contract_uri_locked = true;
        emit ContractURILocked();
    }

    /**
     * @notice Updates token name and symbol
     * @dev Allows rebranding when not locked
     * 
     * @param newName New human-readable token name
     * @param newSymbol New token ticker symbol
     */
    function setNameAndSymbol(string memory newName, string memory newSymbol) external onlyOwner {
        require(!name_symbol_locked, "Name and symbol are locked");
        require(bytes(newName).length > 0, "Name cannot be empty");
        require(bytes(newSymbol).length > 0, "Symbol cannot be empty");
        _name = newName;
        _symbol = newSymbol;
        emit NameSymbolUpdated(newName, newSymbol);
    }

    /**
     * @notice Permanently locks name and symbol changes
     * @dev Prevents future rebranding for stability
     */
    function lockNameAndSymbol() external onlyOwner {
        require(!name_symbol_locked, "Already locked");
        name_symbol_locked = true;
        emit NameSymbolLocked();
    }

    /**
     * @notice Updates the compliance blacklist contract
     * @dev Sets external contract for transfer restrictions
     * 
     * @param _blacklistAddress Address of blacklist contract (or address(0) to disable)
     */
    function setBlacklist(address _blacklistAddress) external onlyOwner {
        require(!blacklist_locked, "Blacklist is locked");
        blacklist = _blacklistAddress;
        emit BlacklistUpdated(_blacklistAddress);
    }

    /**
     * @notice Permanently locks blacklist configuration
     * @dev Ensures compliance setup cannot be changed
     */
    function lockBlacklist() external onlyOwner {
        require(!blacklist_locked, "Blacklist is already locked");
        blacklist_locked = true;
        emit BlacklistLocked();
    }

    /**
     * @notice Updates the collateral manager address
     * @dev Changes operational control assignment
     * 
     * @param _collateralManager New address for operational control
     */
    function setCollateralManager(address _collateralManager) external onlyOwner {
        require(!collateral_manager_locked, "Collateral manager is locked");
        collateral_manager = _collateralManager;
        emit CollateralManagerUpdated(_collateralManager);
    }

    /**
     * @notice Permanently locks collateral manager changes
     * @dev Ensures operational role stability
     */
    function lockCollateralManager() external onlyOwner {
        require(!collateral_manager_locked, "Collateral manager is already locked");
        collateral_manager_locked = true;
        emit CollateralManagerLocked();
    }

    /**
     * @notice Updates maximum token supply limit
     * @dev Collateral manager can adjust supply constraints
     * 
     * @param _maxSupply New supply limit (0 = unlimited)
     */
    function setMaxSupply(uint256 _maxSupply) external onlyCollateralManager {
        require(!max_supply_locked, "Maximum supply is already locked");
        max_supply = _maxSupply;
        emit MaxSupplyChanged(_maxSupply);
    }

    /**
     * @notice Permanently locks maximum supply setting
     * @dev Provides supply constraint immutability
     */
    function lockMaxSupply() external onlyCollateralManager {
        require(!max_supply_locked, "Maximum supply is already locked");
        max_supply_locked = true;
        emit MaxSupplyLocked();
    }

    /**
     * @notice Permanently disables minting capability
     * @dev One-way operation to finalize token supply
     */
    function lockMint() external onlyCollateralManager {
        require(!mint_locked, "Minting is already locked");
        mint_locked = true;
        emit MintLocked();
    }
    

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▖ ▗▄▄▄▖ ▗▄▖ ▗▄▄▄ 
▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌  █
▐▛▀▚▖▐▛▀▀▘▐▛▀▜▌▐▌  █
▐▌ ▐▌▐▙▄▄▖▐▌ ▐▌▐▙▄▄▀
01010010 01100101 
01100001 01100100                         
*/

    /**
     * @notice Override ERC20 name function to return dynamic value
     * @dev Returns the configurable token name instead of the immutable ERC20 name
     * This allows for name updates when not locked
     * 
     * @return The current token name
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @notice Override ERC20 symbol function to return dynamic value  
     * @dev Returns the configurable token symbol instead of the immutable ERC20 symbol
     * This allows for symbol updates when not locked
     * 
     * @return The current token symbol
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Retrieves the current fee collection strategy configuration
     * @dev External view function providing transparency about where fees are collected from
     * 
     * @return The currently active FeeSource enum value indicating fee collection strategy
     */
    function getFeeSource() external view returns (FeeSource) {
        return feeSource;
    }

    /**
     * @notice Calculates fee amount and net amount after fees for a given input amount
     * @dev Utility function to predict fee impacts before executing transactions
     * Takes into account the current fee source setting to determine fee application
     * 
     * @param _amount The gross amount to calculate fees for
     * @return netAmount The amount remaining after fee deduction
     * @return feeAmount The amount taken as fees
     */
    function calculateFee(uint256 _amount) public view returns (uint256, uint256) {
        // Calculate fee ratio based on fee source configuration
        uint256 feeRatio = feeSource == FeeSource.FROM_BOTH ? 
            _md512(owner_fee, PRECISION / 2, PRECISION) : owner_fee;

        // Calculate the fee amount
        uint256 fee = _md512(_amount, feeRatio, PRECISION);

        // Return net amount and fee amount
        return (_amount - fee, fee);
    }

    /**
     * @notice Retrieves the current lock status of various ownership-related settings
     * @dev Provides a comprehensive view of the contract's immutability guarantees
     * 
     * @return ownerFeeLocked Whether owner fee is permanently locked
     * @return maxSupplyLocked Whether maximum supply is permanently locked
     * @return feeSourceLocked Whether fee source is permanently locked
     * @return contractUriLocked Whether contract URI is permanently locked
     * @return nameSymbolLocked Whether name and symbol are permanently locked
     * @return blacklistLocked Whether blacklist is permanently locked
     * @return collateralManagerLocked Whether collateral manager is permanently locked
     * @return mintLocked Whether minting is permanently locked
     * @return feeReceiverLocked Whether fee receiver is permanently locked
     * @return ownerLocked Whether owner is permanently locked
     */
    function getOwnershipLockStatus() external view returns (bool ownerFeeLocked, bool maxSupplyLocked, bool feeSourceLocked, bool contractUriLocked, bool nameSymbolLocked, bool blacklistLocked, bool collateralManagerLocked, bool mintLocked, bool feeReceiverLocked, bool ownerLocked) {
        return (owner_fee_locked, max_supply_locked, fee_source_locked, contract_uri_locked, name_symbol_locked, blacklist_locked, collateral_manager_locked, mint_locked, fee_receiver_locked, owner_locked);
    }



        /**
    --------------------------------------------------------------------------------------------------------
     ▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖ ▗▄▄▖
     ▐▌   ▐▌  ▐▌▐▌   ▐▛▚▖▐▌  █ ▐▌   
     ▐▛▀▀▘▐▌  ▐▌▐▛▀▀▘▐▌ ▝▜▌  █  ▝▀▚▖
     ▐▙▄▄▖ ▝▚▞▘ ▐▙▄▄▖▐▌  ▐▌  █ ▗▄▄▞▘
    01000101 01110110 01100101 01101110 01110100 01110011
    */

    // State change events for transparency and monitoring
    event OwnerFeeChanged(uint256 ownerFee);
    event MaxSupplyChanged(uint256 maxSupply);
    event FeeSourceUpdated(FeeSource newFeeSource);
    event ContractURIUpdated();
    event NameSymbolUpdated(string name, string symbol);
    event FeeReceiverUpdated(address newFeeReceiver);
    event CollateralManagerUpdated(address newCollateralManager);
    event BlacklistUpdated(address newBlacklist);
    
    // Locking events for immutability guarantees
    event OwnerFeeLocked();
    event MaxSupplyLocked();
    event FeeSourceLocked();
    event ContractURILocked();
    event NameSymbolLocked();
    event BlacklistLocked();
    event CollateralManagerLocked();
    event MintLocked();
    event OwnershipRenounced();
} 