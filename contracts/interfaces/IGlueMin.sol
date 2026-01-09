// SPDX-License-Identifier: BUSL-1.1
// https://github.com/glue-finance/glue/blob/main/LICENCE.txt
/**

 ██████╗ ██╗     ██╗   ██╗███████╗                                    
██╔════╝ ██║     ██║   ██║██╔════╝                                    
██║  ███╗██║     ██║   ██║█████╗                                      
██║   ██║██║     ██║   ██║██╔══╝                                      
╚██████╔╝███████╗╚██████╔╝███████╗                                    
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝   
██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗
██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗  
██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝  
██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗
╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝       
*/

/**
 * @title IGlueMin
 * @author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi
 * @notice Common interface for functions shared between IGlueERC20 and IGlueERC721
 * @dev This interface contains all the functions, types, errors, and events that are 
 * identical across both ERC20 and ERC721 glue implementations
 */

pragma solidity ^0.8.28;

/**
 * @title IGlueStickMin
 * @notice Common factory interface for both ERC20 and ERC721 GlueStick implementations
 * @dev Contains all shared functionality between IGlueStickERC20 and IGlueStickERC721
 */
interface IGlueStickMin {
    
    // ===== COMMON TYPES =====
    
    /**
     * @dev Struct for managing flash loan data across multiple glue contracts
     * @notice Encapsulates all data required for multi-glue flash loan operations
     */
    struct LoanData {
        uint256 count;              /// @notice Number of glue contracts participating in the loan
        uint256[] toBorrow;         /// @notice Amount to borrow from each glue contract
        uint256[] expectedAmounts;  /// @notice Expected repayment amount for each loan (including fees)
        uint256[] expectedBalances; /// @notice Expected final balance in each glue after repayment
    }
    
    // ===== COMMON FUNCTIONS =====
    
    /**
     * @notice Creates a new Glue contract for the specified asset
     * @dev Creates a deterministic clone and initializes it with the asset address
     * @param asset The address of the asset (ERC20 token or ERC721 collection) to be glued
     * @return glueAddress The address of the newly created glue instance
     */
    function applyTheGlue(address asset) external returns (address glueAddress);
    
    /**
     * @notice Executes flash loans from multiple glue contracts
     * @dev Coordinates complex flash loan operations from multiple sources
     * @param glues Array of glue contract addresses to borrow from
     * @param collateral Address of the token to borrow (address(0) for ETH)
     * @param loanAmount Total amount of tokens to borrow across all glues
     * @param receiver Address of the contract implementing IGluedLoanReceiver
     * @param params Arbitrary data to be passed to the receiver
     */
    function gluedLoan(
        address[] calldata glues, 
        address collateral, 
        uint256 loanAmount, 
        address receiver, 
        bytes calldata params
    ) external;
    
    /**
     * @notice Validates if an asset can be glued
     * @dev Performs validation checks for asset compatibility
     * @param asset Address of the asset to validate
     * @return isValid Boolean indicating whether the asset passes validation checks
     */
    function checkAsset(address asset) external view returns (bool isValid);
    
    /**
     * @notice Deterministically predicts the address of a glue contract before creation
     * @dev Uses the Clones library to calculate the deployment address
     * @param asset Address of the asset to compute the glue address for
     * @return predictedGlueAddress The predicted address where the glue contract would be deployed
     */
    function computeGlueAddress(address asset) external view returns (address predictedGlueAddress);
    
    /**
     * @notice Checks if an asset has been glued and returns its glue address
     * @dev Utility function to verify asset status in the Glue protocol
     * @param asset Address of the asset to check
     * @return isSticky Indicates whether the asset is sticky (has been glued)
     * @return glueAddress The glue address for the asset if it's sticky, otherwise address(0)
     */
    function isStickyAsset(address asset) external view returns (bool isSticky, address glueAddress);
    
    /**
     * @notice Retrieves the balances of multiple collaterals across multiple glues
     * @dev Returns a 2D array where each row represents a glue and each column represents a collateral
     * @param glues The addresses of the glues to check
     * @param collaterals The addresses of the collaterals to check for each glue
     * @return balances a 2D array of balances [glueIndex][collateralIndex]
     */
    function getGluesBalances(
        address[] calldata glues, 
        address[] calldata collaterals
    ) external view returns (uint256[][] memory balances);
    
    /**
     * @notice Returns the total number of deployed glues
     * @return existingGlues The length of the allGlues array
     */
    function allGluesLength() external view returns (uint256 existingGlues);
    
    /**
     * @notice Retrieves the glue address for a given asset
     * @param asset The address of the asset to get the glue address for
     * @return glueAddress The glue address for the given asset, if it exists, otherwise address(0)
     */
    function getGlueAddress(address asset) external view returns (address glueAddress);
    
    /**
     * @notice Retrieves a glue address by its index in the registry
     * @param index The index in the allGlues array to query
     * @return glueAddress The address of the glue at the specified index
     */
    function getGlueAtIndex(uint256 index) external view returns (address glueAddress);
    
    // ===== COMMON ERRORS =====
    
    error InvalidAsset(address asset);
    error DuplicateGlue(address asset);
    error InvalidAddress();
    error InvalidInputs();
    error InvalidGlueBalance(address glue, uint256 balance, address collateral);
    error FlashLoanFailed();
    error RepaymentFailed(address glue);
    error FailedToDeployGlue();
    
    // ===== COMMON EVENTS =====
    
    /**
     * @notice Emitted when a new asset is glued
     * @param asset The address of the asset that was glued
     * @param glueAddress The address of the created glue contract
     * @param glueIndex The index of the glue in the allGlues array
     */
    event GlueAdded(address indexed asset, address glueAddress, uint256 glueIndex);
}

/**
 * @title IGlueMin
 * @notice Common interface for individual glue contracts (both ERC20 and ERC721)
 * @dev Contains all shared functionality between IGlueERC20 and IGlueERC721
 */
interface IGlueMin {
    
    // ===== COMMON TYPES =====
    
    /**
     * @notice Enum representing hook detection status
     * @dev Used to track if the asset implements and supports hooks
     */
    enum BIO {
        UNCHECKED,  /// The asset has not been checked for hooks yet
        NO_HOOK,    /// The asset does not implement hooks
        HOOK        /// The asset implements hooks
    }
    
    // ===== COMMON FUNCTIONS =====
    
    /**
     * @notice Initializes a newly deployed glue clone
     * @dev Called by the factory when creating a new glue instance
     * @param asset Address of the asset to be linked with this glue
     */
    function initialize(address asset) external;
    
    /**
     * @notice Initiates a flash loan
     * @param collateral The address of the collateral token
     * @param amount The amount of tokens to flash loan
     * @param receiver The address of the receiver
     * @param params The parameters for the flash loan
     * @return success boolean indicating success
     */
    function flashLoan(
        address collateral, 
        uint256 amount, 
        address receiver, 
        bytes calldata params
    ) external returns (bool success);
    
    /**
     * @notice Initiates a minimal flash loan (for GlueStick internal use)
     * @dev Only the GlueStick can call this function
     * @param receiver The address of the receiver
     * @param collateral The address of the token to flash loan
     * @param amount The amount of tokens to flash loan
     * @return loanSent boolean indicating success
     */
    function loanHandler(
        address receiver, 
        address collateral, 
        uint256 amount
    ) external returns (bool loanSent);
    
    /**
     * @notice Calculates the supply delta based on the sticky amount and total supply
     * @param stickyAmount The amount of sticky assets
     * @return supplyDelta The calculated supply delta
     */
    function getSupplyDelta(uint256 stickyAmount) external view returns (uint256 supplyDelta);
    
    /**
     * @notice Retrieves the adjusted total supply of the sticky asset
     * @return adjustedTotalSupply The adjusted and actual total supply
     */
    function getAdjustedTotalSupply() external view returns (uint256 adjustedTotalSupply);
    
    /**
     * @notice Retrieves the protocol fee percentage
     * @return protocolFee The protocol fee as a fixed-point number with 18 decimal places
     */
    function getProtocolFee() external pure returns (uint256 protocolFee);
    
    /**
     * @notice Retrieves the flash loan fee percentage
     * @return flashLoanFee The flash loan fee as a fixed-point number with 18 decimal places
     */
    function getFlashLoanFee() external pure returns (uint256 flashLoanFee);
    
    /**
     * @notice Retrieves the flash loan fee for a given amount
     * @param amount The amount to calculate the flash loan fee for
     * @return fee The flash loan fee applied to the given amount
     */
    function getFlashLoanFeeCalculated(uint256 amount) external pure returns (uint256 fee);
    
    /**
     * @notice Retrieves the total hook size for a specific collateral
     * @param collateral The address of the collateral token
     * @param collateralAmount The amount of collateral being processed
     * @return hookSize The total hook size
     */
    function getTotalHookSize(
        address collateral, 
        uint256 collateralAmount
    ) external view returns (uint256 hookSize);
    
    /**
     * @notice Calculates collateral amounts that can be unglued for a given sticky amount
     * @param stickyAmount The amount of sticky assets
     * @param collaterals An array of collateral token addresses
     * @return amounts An array containing the corresponding amounts that can be unglued
     */
    function collateralByAmount(
        uint256 stickyAmount, 
        address[] calldata collaterals
    ) external view returns (uint256[] memory amounts);
    
    /**
     * @notice Retrieves the balance of specified collateral tokens
     * @param collaterals An array of collateral token addresses
     * @return balances An array containing the corresponding balances
     */
    function getBalances(address[] calldata collaterals) external view returns (uint256[] memory balances);
    
    /**
     * @notice Retrieves the balance of the sticky asset stored in the glue
     * @return stickyAmount The balance of the sticky asset
     */
    function getStickySupplyStored() external view returns (uint256 stickyAmount);
    
    /**
     * @notice Retrieves the settings contract address
     * @return settings The address of the settings contract
     */
    function getSettings() external pure returns (address settings);
    
    /**
     * @notice Retrieves the address of the GlueStick factory contract
     * @return glueStick The address of the GlueStick factory contract
     */
    function getGlueStick() external view returns (address glueStick);
    
    /**
     * @notice Retrieves the address of the sticky asset
     * @return stickyAsset The address of the sticky asset
     */
    function getStickyAsset() external view returns (address stickyAsset);
    
    /**
     * @notice Retrieves if the glue is expanded with active Hooks
     * @return hooksStatus The BIO status of hooks
     */
    function isExpanded() external view returns (BIO hooksStatus);
    
    // ===== COMMON ERRORS =====
    
    error InvalidGlueStickAddress();
    error Unauthorized();
    error ZeroAmount();
    error InvalidAsset(address asset);
    error NoCollateralSelected();
    error NoAssetsTransferred();
    error NoAssetsSelected();
    
    // ===== COMMON EVENTS =====
    
    /**
     * @notice Emitted when a flash loan is executed
     * @param collateral The address of the borrowed asset
     * @param amount The amount that was borrowed
     * @param receiver The address that received the loan
     */
    event GlueLoan(address indexed collateral, uint256 amount, address receiver);
}
