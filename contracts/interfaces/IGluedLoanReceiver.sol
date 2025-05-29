// SPDX-License-Identifier: MIT
/**

/**

 ██████╗ ██╗     ██╗   ██╗███████╗██████╗ ██╗      ██████╗  █████╗ ███╗   ██╗
██╔════╝ ██║     ██║   ██║██╔════╝██╔══██╗██║     ██╔═══██╗██╔══██╗████╗  ██║
██║  ███╗██║     ██║   ██║█████╗  ██║  ██║██║     ██║   ██║███████║██╔██╗ ██║
██║   ██║██║     ██║   ██║██╔══╝  ██║  ██║██║     ██║   ██║██╔══██║██║╚██╗██║
╚██████╔╝███████╗╚██████╔╝███████╗██████╔╝███████╗╚██████╔╝██║  ██║██║ ╚████║
 ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
██████╗ ███████╗ ██████╗███████╗██╗██╗   ██╗███████╗██████╗                  
██╔══██╗██╔════╝██╔════╝██╔════╝██║██║   ██║██╔════╝██╔══██╗                 
██████╔╝█████╗  ██║     █████╗  ██║██║   ██║█████╗  ██████╔╝                 
██╔══██╗██╔══╝  ██║     ██╔══╝  ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗                 
██║  ██║███████╗╚██████╗███████╗██║ ╚████╔╝ ███████╗██║  ██║                 
╚═╝  ╚═╝╚══════╝ ╚═════╝╚══════╝╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝                 
██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗       
██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝       
██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗         
██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝         
██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗       
╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝       

@title IGluedLoanReceiver - Enhanced Flash Loan Receiver Interface
@author @BasedToschi
@notice Comprehensive interface for flash loan receivers with the Glue Protocol
@dev This interface defines the complete standard for contracts that want to receive
flash loans from the Glue Protocol. It includes both the required executeOperation function
and optional helper functions for enhanced functionality and better developer experience.

Key Features:
- Required executeOperation function for flash loan execution
- Optional helper functions for loan state management
- Comprehensive loan information access
- State validation functions
- Event definitions for transparency

Implementation Notes:
- Only executeOperation is required to be implemented
- Helper functions are optional but recommended for full functionality
- GluedLoanReceiver base contract provides default implementations
- Custom implementations can override any function for specialized behavior

Use Cases:
- Arbitrage bots requiring detailed loan information
- Liquidation contracts needing precise fee calculations
- Multi-strategy contracts with complex loan management
- Educational contracts demonstrating flash loan patterns

 */
pragma solidity ^0.8.28;

/**
 * @title IGluedLoanReceiver
 * @notice Enhanced interface for receiving flash loans from Glue Protocol contracts
 * @dev Contracts implementing this interface can receive flash loans from both individual
 * Glue contracts and cross-glue loans from GlueStick factory contracts.
 */
interface IGluedLoanReceiver {

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // REQUIRED FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Main entry point for flash loan execution - REQUIRED IMPLEMENTATION
     * @dev This function MUST be implemented by all flash loan receivers
     * It is called by Glue contracts when executing flash loans
     * 
     * @param glues Array of glue contract addresses providing the loan
     * @param collateral Address of the borrowed token (address(0) for ETH)  
     * @param expectedAmounts Array of amounts expected to be repaid to each glue contract
     * @param params Arbitrary data passed by the loan initiator for custom execution
     * @return loanSuccess Boolean indicating whether the operation was successful
     *
     * Implementation Requirements:
     * - MUST implement custom loan logic
     * - MUST ensure sufficient funds for repayment
     * - MUST return true only if operation succeeded
     * - SHOULD use provided helper functions for loan management
     */
    function executeOperation(
        address[] memory glues,
        address collateral,
        uint256[] memory expectedAmounts,
        bytes memory params
    ) external returns (bool loanSuccess);

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // OPTIONAL HELPER FUNCTIONS  
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get the total amount borrowed in the current flash loan
     * @dev Optional helper function for enhanced loan management
     * @return totalBorrowed The total amount of collateral borrowed
     *
     * Use Cases:
     * - Calculate available capital for strategies
     * - Validate loan amounts in complex logic
     * - Display loan information in UI applications
     */
    function getCurrentTotalBorrowed() external view returns (uint256 totalBorrowed);

    /**
     * @notice Get the address of the collateral token being borrowed
     * @dev Optional helper function for token type identification
     * @return collateral The address of the borrowed token (address(0) for ETH)
     *
     * Use Cases:
     * - Determine token type for strategy selection
     * - Validate collateral compatibility
     * - Handle ETH vs ERC20 logic branches
     */
    function getCurrentCollateral() external view returns (address collateral);

    /**
     * @notice Get the total amount that needs to be repaid (borrowed + fees)
     * @dev Optional helper function for precise repayment calculations
     * @return totalRepayAmount The total amount to be repaid across all glues
     *
     * Use Cases:
     * - Calculate exact repayment requirements
     * - Budget planning for complex strategies
     * - Profit margin calculations
     */
    function getCurrentTotalRepayAmount() external view returns (uint256 totalRepayAmount);

    /**
     * @notice Get the total fees for the current flash loan
     * @dev Optional helper function for fee analysis and profit calculations
     * @return totalFees The total fees across all glue contracts
     *
     * Use Cases:
     * - Calculate minimum profit requirements
     * - Fee analysis and optimization
     * - Strategy profitability assessment
     */
    function getCurrentTotalFees() external view returns (uint256 totalFees);

    /**
     * @notice Get comprehensive information about the current flash loan
     * @dev Optional helper function providing complete loan state in one call
     * @return glues Array of glue contract addresses
     * @return collateral Address of the borrowed token
     * @return expectedAmounts Array of repayment amounts
     * @return totalBorrowed Total amount borrowed
     * @return totalRepay Total amount to repay
     * @return totalFees Total fees
     *
     * Use Cases:
     * - Complete loan state analysis
     * - Complex multi-parameter strategies
     * - Comprehensive logging and monitoring
     * - Single-call loan information retrieval
     */
    function getCurrentLoanInfo() external view returns (
        address[] memory glues,
        address collateral,
        uint256[] memory expectedAmounts,
        uint256 totalBorrowed,
        uint256 totalRepay,
        uint256 totalFees
    );

    /**
     * @notice Check if a flash loan is currently active
     * @dev Optional helper function for state validation and safety checks
     * @return active True if a flash loan is being executed
     *
     * Use Cases:
     * - Prevent reentrancy in other contract functions
     * - State validation in complex contracts
     * - Safety checks before external operations
     * - Debugging and monitoring loan state
     */
    function isFlashLoanActive() external view returns (bool active);

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // LOAN PLANNING HELPER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get maximum loan amount available from a specific glue for a collateral
     * @dev Optional helper for loan planning - works for both ERC20 and ERC721 glues
     * @param glue Address of the glue contract (ERC20 or ERC721)
     * @param collateral Address of the collateral token to check
     * @return maxAmount Maximum amount available for flash loan
     *
     * Use Cases:
     * - Check available liquidity before requesting loans
     * - Plan loan amounts for arbitrage strategies
     * - Validate loan feasibility
     */
    function maxLoan(address glue, address collateral) external view returns (uint256 maxAmount);

    /**
     * @notice Get maximum loan amounts from multiple glues for one collateral type
     * @dev Optional helper for cross-glue loan planning
     * @param useERC721 True for ERC721 glues, false for ERC20 glues
     * @param glues Array of glue contract addresses
     * @param collateral Address of the collateral token to check
     * @return maxAmounts Array of maximum amounts available from each glue
     *
     * Use Cases:
     * - Plan cross-glue flash loans
     * - Find optimal glue combinations for large loans
     * - Assess total liquidity across multiple sources
     */
    function multiMaxLoan(
        bool useERC721,
        address[] memory glues,
        address collateral
    ) external view returns (uint256[] memory maxAmounts);

    /**
     * @notice Get the flash loan fee percentage
     * @dev Optional helper for fee information (typically 0.001% = 1e14)
     * @param glue Address of any glue contract (ERC20 or ERC721)
     * @return feePercentage Fee percentage in PRECISION units (1e18 = 100%)
     *
     * Use Cases:
     * - Calculate minimum profit requirements
     * - Display fee information to users
     * - Plan strategy profitability
     */
    function getFlashLoanFee(address glue) external view returns (uint256 feePercentage);

    /**
     * @notice Get calculated flash loan fee for a specific amount
     * @dev Optional helper for precise fee calculation
     * @param glue Address of any glue contract (ERC20 or ERC721)
     * @param amount Loan amount to calculate fee for
     * @return feeAmount Exact fee amount that will be charged
     *
     * Use Cases:
     * - Calculate exact repayment amounts
     * - Plan precise profit margins
     * - Budget for loan costs
     */
    function getFlashLoanFeeCalculated(address glue, uint256 amount) external view returns (uint256 feeAmount);

    /**
     * @notice Get comprehensive loan information for planning
     * @dev Optional helper combining availability and fee info in one call
     * @param glue Address of the glue contract
     * @param collateral Address of the collateral token
     * @param desiredAmount Amount you want to borrow
     * @return available Maximum amount available for loan
     * @return feePercentage Fee percentage
     * @return calculatedFee Exact fee for desired amount
     * @return totalRepayment Total amount to repay (desired + fee)
     * @return canAfford True if glue has enough liquidity
     *
     * Use Cases:
     * - Complete loan feasibility analysis
     * - One-call loan planning
     * - Strategy validation before execution
     */
    function getLoanPlan(
        address glue,
        address collateral,
        uint256 desiredAmount
    ) external view returns (
        uint256 available,
        uint256 feePercentage,
        uint256 calculatedFee,
        uint256 totalRepayment,
        bool canAfford
    );

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Emitted when a flash loan is successfully executed
     * @param collateral Address of the borrowed token
     * @param totalBorrowed Total amount borrowed
     * @param totalRepaid Total amount repaid
     * @param totalFees Total fees paid
     */
    event FlashLoanExecuted(
        address indexed collateral,
        uint256 totalBorrowed,
        uint256 totalRepaid,
        uint256 totalFees
    );

    /**
     * @notice Emitted when flash loan logic execution starts
     * @param collateral Address of the borrowed token
     * @param totalBorrowed Total amount borrowed
     */
    event FlashLoanLogicStarted(
        address indexed collateral,
        uint256 totalBorrowed
    );

    /**
     * @notice Emitted when a loan request is initiated
     * @param loanType Type of loan requested ("gluedLoan" or "flashLoan")
     * @param collateral Address of the borrowed token
     * @param amount Amount requested
     */
    event LoanRequested(
        string indexed loanType,
        address indexed collateral,
        uint256 amount
    );

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // ERRORS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Thrown when trying to access flash loan data outside of active loan
     */
    error NoActiveFlashLoan();

    /**
     * @notice Thrown when flash loan repayment fails
     */
    error RepaymentFailed();

    /**
     * @notice Thrown when loan request fails
     */
    error LoanRequestFailed();
}