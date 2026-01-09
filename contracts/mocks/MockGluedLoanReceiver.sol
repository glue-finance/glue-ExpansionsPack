// SPDX-License-Identifier: MIT

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

@title Mock Glued Loan Receiver Base Contract
@author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi
@notice Mock implementation for testing with configurable glue stick addresses
@dev Identical to GluedLoanReceiver.sol but allows custom glue stick addresses for testing

*/

pragma solidity ^0.8.28;

/**
@dev Interface for receiving flash loans from Glue Protocol
*/
import {IGluedLoanReceiver} from '../interfaces/IGluedLoanReceiver.sol';

/**
@dev Interfaces for GlueStickERC20 and GlueStickERC721 for proper type safety
*/
import {IGlueStickERC20, IGlueERC20} from '../interfaces/IGlueERC20.sol';
import {IGlueStickERC721, IGlueERC721} from '../interfaces/IGlueERC721.sol';

/**
@dev Library providing high-precision mathematical operations and utilities
*/
import {GluedMath} from '../libraries/GluedMath.sol';

/**
 * @title Mock Glued Loan Receiver Base Contract
 * @author Glue Protocol Team
 * @notice Mock implementation of flash loan receiver with configurable glue stick addresses
 * @dev Identical functionality to GluedLoanReceiver.sol but allows custom glue addresses for testing
 */
abstract contract MockGluedLoanReceiver is IGluedLoanReceiver {

/**
--------------------------------------------------------------------------------------------------------
 ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▖ ▗▖▗▄▄▖ 
▐▌   ▐▌     █  ▐▌ ▐▌▐▌ ▐▌
 ▝▀▚▖▐▛▀▀▘  █  ▐▌ ▐▌▐▛▀▘ 
▗▄▄▞▘▐▙▄▄▖  █  ▝▚▄▞▘▐▌                                               
01010011 01100101 01110100 
01110101 01110000 
*/

    // GluedMath for calculations
    using GluedMath for uint256;

    // █████╗ Core State and Constants
    // ╚════╝ All variables and constants are declared internal for derived contract access

    /// @notice Precision factor used for fractional calculations (10^18)
    uint256 internal constant PRECISION = 1e18;

    /// @notice Special address used to represent native ETH in the protocol
    address internal constant ETH_ADDRESS = address(0);

    /// @notice Mock glue stick addresses (configurable for testing)
    IGlueStickERC20 internal immutable MOCK_GLUE_STICK_ERC20;
    IGlueStickERC721 internal immutable MOCK_GLUE_STICK_ERC721;

    // █████╗ Flash Loan State
    // ╚════╝ State variables to track current flash loan execution

    /// @notice Array of glue contracts involved in the current flash loan
    address[] internal _currentGlues;

    /// @notice Address of the collateral token being borrowed
    address internal _currentCollateral;

    /// @notice Array of amounts expected to be repaid to each glue
    uint256[] internal _currentExpectedAmounts;

    /// @notice Total amount borrowed in the current flash loan
    uint256 internal _currentTotalBorrowed;

    /// @notice Flag indicating if a flash loan is currently being executed
    bool internal _flashLoanActive;

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Initialize the mock receiver with configurable glue stick addresses
     * @param mockGlueStickERC20 Mock ERC20 glue stick address for testing
     * @param mockGlueStickERC721 Mock ERC721 glue stick address for testing
     */
    constructor(
        address mockGlueStickERC20,
        address mockGlueStickERC721
    ) {
        require(mockGlueStickERC20 != address(0), "Mock glue stick ERC20 cannot be zero");
        require(mockGlueStickERC721 != address(0), "Mock glue stick ERC721 cannot be zero");
        
        MOCK_GLUE_STICK_ERC20 = IGlueStickERC20(mockGlueStickERC20);
        MOCK_GLUE_STICK_ERC721 = IGlueStickERC721(mockGlueStickERC721);
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
    * @notice Main entry point for flash loan execution from Glue Protocol
    * @dev This function is called by the Glue Protocol and manages the entire flash loan lifecycle
    * @param glues Array of glue contract addresses providing the loan
    * @param collateral Address of the borrowed token (address(0) for ETH)
    * @param expectedAmounts Array of amounts expected to be repaid to each glue contract
    * @param params Arbitrary data passed by the loan initiator for custom execution
    * @return loanSuccess Boolean indicating whether the operation was successful
    */
    function executeOperation(
        address[] memory glues,
        address collateral,
        uint256[] memory expectedAmounts,
        bytes memory params
    ) external override returns (bool loanSuccess) {
        
        // Store flash loan state
        _currentGlues = glues;
        _currentCollateral = collateral;
        _currentExpectedAmounts = expectedAmounts;
        _flashLoanActive = true;

        // Calculate total borrowed amount by checking actual balance received
        if (collateral == ETH_ADDRESS) {
            // For ETH, check contract balance
            _currentTotalBorrowed = address(this).balance;
        } else {
            // For ERC20, check token balance
            _currentTotalBorrowed = _getTokenBalance(collateral);
        }

        // Execute custom logic (implemented by derived contracts)
        bool success = _executeFlashLoanLogic(params);

        // Automatically repay all loans
        if (success) {
            success = _repayFlashLoan();
        }

        // Clean up state
        delete _currentGlues;
        _currentCollateral = address(0);
        delete _currentExpectedAmounts;
        _currentTotalBorrowed = 0;
        _flashLoanActive = false;

        return success;
    }

    /**
    * @notice Request a glued loan from GlueStick contracts (ERC20 or ERC721)
    * @dev Allows derived contracts to easily request cross-glue flash loans
    * @param useERC721 True to use GlueStickERC721, false to use GlueStickERC20
    * @param glues Array of glue contract addresses to borrow from
    * @param collateral Address of the token to borrow (address(0) for ETH)
    * @param loanAmount Total amount to borrow across all glues
    * @param params Arbitrary data to pass to executeOperation
    * @return success True if the loan was successfully initiated
    *
    * Use cases:
    * - Request cross-glue flash loans for arbitrage
    * - Borrow from multiple sources simultaneously
    * - Access liquidity across different sticky assets
    */
    function _requestGluedLoan(
        bool useERC721,
        address[] memory glues,
        address collateral,
        uint256 loanAmount,
        bytes memory params
    ) internal returns (bool success) {
        
        if (useERC721) {
            // Use ERC721 GlueStick with proper interface
            try MOCK_GLUE_STICK_ERC721.gluedLoan(glues, collateral, loanAmount, address(this), params) {
                success = true;
            } catch {
                success = false;
            }
        } else {
            // Use ERC20 GlueStick with proper interface
            try MOCK_GLUE_STICK_ERC20.gluedLoan(glues, collateral, loanAmount, address(this), params) {
                success = true;
            } catch {
                success = false;
            }
        }
        
        return success;
    }

    /**
    * @notice Request a flash loan from a specific glue contract
    * @dev Allows derived contracts to easily request single-glue flash loans
    * Uses IGlueERC20 interface since both ERC20 and ERC721 glues have identical flashLoan signatures
    * @param glue Address of the glue contract to borrow from (ERC20 or ERC721)
    * @param collateral Address of the token to borrow (address(0) for ETH)
    * @param amount Amount to borrow
    * @param params Arbitrary data to pass to executeOperation
    * @return success True if the loan was successfully initiated
    *
    * Use cases:
    * - Request flash loans from a specific glue
    * - Simple single-source borrowing
    * - Test loans from individual glues
    */
    function _requestFlashLoan(
        address glue,
        address collateral,
        uint256 amount,
        bytes memory params
    ) internal returns (bool success) {
        
        // Cast to IGlueERC20 interface - works for both ERC20 and ERC721 since flashLoan signature is identical
        try IGlueERC20(glue).flashLoan(collateral, amount, address(this), params) {
            success = true;
        } catch {
            success = false;
        }
        
        return success;
    }

    /**
    * @notice Internal function to get ERC20 token balance of this contract
    * @param token Address of the ERC20 token
    * @return balance The token balance of this contract
    */
    function _getTokenBalance(address token) internal view returns (uint256 balance) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(0x70a08231, address(this)) // balanceOf(address)
        );
        
        if (success && data.length >= 32) {
            balance = abi.decode(data, (uint256));
        }
        
        return balance;
    }

    /**
    * @notice Internal function to repay the flash loan to all glue contracts
    * @dev Automatically handles repayment to all glue contracts involved in the loan
    * @return success True if all repayments were successful
    */
    function _repayFlashLoan() internal returns (bool success) {
        
        // Repay each glue contract
        for (uint256 i = 0; i < _currentGlues.length; i++) {
            
            address glue = _currentGlues[i];
            uint256 repayAmount = _currentExpectedAmounts[i];

            if (_currentCollateral == ETH_ADDRESS) {
                // Repay ETH
                (bool sent, ) = glue.call{value: repayAmount}("");
                if (!sent) {
                    return false;
                }
            } else {
                // Repay ERC20
                (bool transferSuccess, bytes memory returnData) = _currentCollateral.call(
                    abi.encodeWithSelector(0xa9059cbb, glue, repayAmount)
                );
                
                if (!transferSuccess || (returnData.length > 0 && !abi.decode(returnData, (bool)))) {
                    return false;
                }
            }
        }
        
        return true;
    }

/**
--------------------------------------------------------------------------------------------------------
▗▖ ▗▖ ▗▄▖  ▗▄▖ ▗▖ ▗▖
▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌▗▞▘
▐▛▀▜▌▐▌ ▐▌▐▌ ▐▌▐▛▚▖ 
▐▌ ▐▌▝▚▄▞▘▝▚▄▞▘▐▌ ▐▌
01001000 01001111 
01001111 01001011                               
*/

    // █████╗ Override this function in derived contracts
    // ╚════╝ This is where your custom flash loan logic goes

    /**
    * @notice Internal function to be overridden by derived contracts
    * @dev Implement your custom flash loan logic in this function
    * @param params Arbitrary data passed from the flash loan initiator
    * @return success True if your logic executed successfully
    *
    * Use cases:
    * - Arbitrage operations
    * - Liquidations
    * - Collateral swaps
    * - Complex DeFi strategies
    */
    function _executeFlashLoanLogic(bytes memory params) internal virtual returns (bool success) {
        // Default implementation does nothing and returns true
        // Derived contracts MUST override this function
        params; // Silence unused parameter warning
        return true;
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

    // █████╗ Helper functions for derived contracts
    // ╚════╝ Use these in your custom logic implementation

    /**
    * @notice Get the total amount borrowed in the current flash loan
    * @return totalBorrowed The total amount of collateral borrowed
    *
    * Use case: Know how much capital you have available for your strategy
    */
    function getCurrentTotalBorrowed() external view override returns (uint256 totalBorrowed) {
        require(_flashLoanActive, "MockGluedLoanReceiver: No active flash loan");
        return _currentTotalBorrowed;
    }

    /**
    * @notice Get the address of the collateral token being borrowed
    * @return collateral The address of the borrowed token (address(0) for ETH)
    *
    * Use case: Know what token you're working with for your strategy
    */
    function getCurrentCollateral() external view override returns (address collateral) {
        require(_flashLoanActive, "MockGluedLoanReceiver: No active flash loan");
        return _currentCollateral;
    }

    /**
    * @notice Get the total amount that needs to be repaid (borrowed + fees)
    * @return totalRepayAmount The total amount to be repaid across all glues
    *
    * Use case: Calculate exact repayment needed for budget planning
    */
    function getCurrentTotalRepayAmount() external view override returns (uint256 totalRepayAmount) {
        require(_flashLoanActive, "MockGluedLoanReceiver: No active flash loan");
        
        totalRepayAmount = 0;
        for (uint256 i = 0; i < _currentExpectedAmounts.length; i++) {
            totalRepayAmount += _currentExpectedAmounts[i];
        }
        
        return totalRepayAmount;
    }

    /**
    * @notice Get the total fees for the current flash loan
    * @return totalFees The total fees across all glue contracts
    *
    * Use case: Calculate profit margins for arbitrage strategies
    */
    function getCurrentTotalFees() external view override returns (uint256 totalFees) {
        require(_flashLoanActive, "MockGluedLoanReceiver: No active flash loan");
        
        uint256 totalRepay = this.getCurrentTotalRepayAmount();
        return totalRepay > _currentTotalBorrowed ? totalRepay - _currentTotalBorrowed : 0;
    }

    /**
    * @notice Get detailed information about the current flash loan
    * @return glues Array of glue contract addresses
    * @return collateral Address of the borrowed token
    * @return expectedAmounts Array of repayment amounts
    * @return totalBorrowed Total amount borrowed
    * @return totalRepay Total amount to repay
    * @return totalFees Total fees
    *
    * Use case: Get complete loan information for complex strategies
    */
    function getCurrentLoanInfo() external view override returns (
        address[] memory glues,
        address collateral,
        uint256[] memory expectedAmounts,
        uint256 totalBorrowed,
        uint256 totalRepay,
        uint256 totalFees
    ) {
        require(_flashLoanActive, "MockGluedLoanReceiver: No active flash loan");
        
        glues = _currentGlues;
        collateral = _currentCollateral;
        expectedAmounts = _currentExpectedAmounts;
        totalBorrowed = _currentTotalBorrowed;
        totalRepay = this.getCurrentTotalRepayAmount();
        totalFees = this.getCurrentTotalFees();
    }

    /**
    * @notice Check if a flash loan is currently active
    * @return active True if a flash loan is being executed
    *
    * Use case: Safety checks in other contract functions
    */
    function isFlashLoanActive() external view override returns (bool active) {
        return _flashLoanActive;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // INTERNAL HELPER FUNCTIONS FOR BACKWARD COMPATIBILITY
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
    * @notice Internal helper to get total borrowed amount (backward compatibility)
    */
    function _getCurrentTotalBorrowed() internal view returns (uint256) {
        return this.getCurrentTotalBorrowed();
    }

    /**
    * @notice Internal helper to get collateral address (backward compatibility)
    */
    function _getCurrentCollateral() internal view returns (address) {
        return this.getCurrentCollateral();
    }

    /**
    * @notice Internal helper to get total repay amount (backward compatibility)
    */
    function _getCurrentTotalRepayAmount() internal view returns (uint256) {
        return this.getCurrentTotalRepayAmount();
    }

    /**
    * @notice Internal helper to get total fees (backward compatibility)
    */
    function _getCurrentTotalFees() internal view returns (uint256) {
        return this.getCurrentTotalFees();
    }

    /**
    * @notice Internal helper to check flash loan status (backward compatibility)
    */
    function _isFlashLoanActive() internal view returns (bool) {
        return this.isFlashLoanActive();
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // LOAN PLANNING HELPER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get maximum loan amount available from a specific glue for a collateral
     * @dev Works for both ERC20 and ERC721 glues since they have identical interfaces
     * @param glue Address of the glue contract (ERC20 or ERC721)
     * @param collateral Address of the collateral token to check
     * @return maxAmount Maximum amount available for flash loan
     *
     * Use Cases:
     * - Check available liquidity before requesting loans
     * - Plan loan amounts for arbitrage strategies
     * - Validate loan feasibility
     */
    function maxLoan(address glue, address collateral) external view override returns (uint256 maxAmount) {
        // Create single-element array for the collateral
        address[] memory collaterals = new address[](1);
        collaterals[0] = collateral;
        
        // Get balances using IGlueERC20 interface (works for both ERC20 and ERC721)
        uint256[] memory balances = IGlueERC20(glue).getBalances(collaterals);
        return balances[0];
    }

    /**
     * @notice Get maximum loan amounts available from multiple glues for a specific collateral
     * @dev For requesting one collateral type from multiple glues (cross-glue loans)
     * @param useERC721 True for ERC721 glues, false for ERC20 glues
     * @param glues Array of glue contract addresses
     * @param collateral Address of the collateral token to check
     * @return maxAmounts Array of maximum amounts available from each glue
     *
     * Use Cases:
     * - Plan cross-glue flash loans
     * - Find optimal glue combinations for large loans
     * - Assess total available liquidity across multiple sources
     */
    function multiMaxLoan(
        bool useERC721,
        address[] memory glues,
        address collateral
    ) external view override returns (uint256[] memory maxAmounts) {
        if (useERC721) {
            // Use ERC721 GlueStick
            return MOCK_GLUE_STICK_ERC721.getGluesBalance(glues, collateral);
        } else {
            // Use ERC20 GlueStick
            return MOCK_GLUE_STICK_ERC20.getGluesBalance(glues, collateral);
        }
    }

    /**
     * @notice Get the flash loan fee percentage
     * @dev Fixed fee rate across all glues (typically 0.001% = 1e14)
     * @param glue Address of any glue contract (ERC20 or ERC721)
     * @return feePercentage Fee percentage in PRECISION units (1e18 = 100%)
     *
     * Use Cases:
     * - Calculate minimum profit requirements
     * - Display fee information to users
     * - Plan strategy profitability
     */
    function getFlashLoanFee(address glue) external view override returns (uint256 feePercentage) {
        // Use IGlueERC20 interface (works for both ERC20 and ERC721)
        return IGlueERC20(glue).getFlashLoanFee();
    }

    /**
     * @notice Get calculated flash loan fee for a specific amount
     * @dev Calculates the exact fee amount for planning purposes
     * @param glue Address of any glue contract (ERC20 or ERC721)
     * @param amount Loan amount to calculate fee for
     * @return feeAmount Exact fee amount that will be charged
     *
     * Use Cases:
     * - Calculate exact repayment amounts
     * - Plan precise profit margins
     * - Budget for loan costs
     */
    function getFlashLoanFeeCalculated(address glue, uint256 amount) external view override returns (uint256 feeAmount) {
        // Use IGlueERC20 interface (works for both ERC20 and ERC721)
        return IGlueERC20(glue).getFlashLoanFeeCalculated(amount);
    }

    /**
     * @notice Get comprehensive loan information for planning
     * @dev Combines availability and fee information for complete loan planning
     * @param glue Address of the glue contract
     * @param collateral Address of the collateral token
     * @param desiredAmount Amount you want to borrow
     * @return available Maximum amount available for loan
     * @return feePercentage Fee percentage
     * @return calculatedFee Exact fee for desired amount
     * @return totalRepayment Total amount to repay (desired + fee)
     * @return canAfford True if the glue has enough liquidity for desired amount
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
    ) external view override returns (
        uint256 available,
        uint256 feePercentage,
        uint256 calculatedFee,
        uint256 totalRepayment,
        bool canAfford
    ) {
        // Get available amount
        available = this.maxLoan(glue, collateral);
        
        // Get fee information
        feePercentage = this.getFlashLoanFee(glue);
        calculatedFee = this.getFlashLoanFeeCalculated(glue, desiredAmount);
        
        // Calculate totals
        totalRepayment = desiredAmount + calculatedFee;
        canAfford = available >= desiredAmount;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // TESTING HELPER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get the mock glue stick addresses (for testing verification)
     * @return glueStick20 Mock ERC20 glue stick address
     * @return glueStick721 Mock ERC721 glue stick address
     */
    function getMockGlueStickAddresses() external view returns (address glueStick20, address glueStick721) {
        return (address(MOCK_GLUE_STICK_ERC20), address(MOCK_GLUE_STICK_ERC721));
    }

    /**
     * @notice Check if this is a mock contract
     * @return Always returns true to identify this as a mock
     */
    function isMockContract() external pure returns (bool) {
        return true;
    }

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▄▄▖ ▗▄▄▖  ▗▄▖ ▗▄▄▖  ▗▄▄▖
▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌   
▐▛▀▀▘▐▛▀▚▖▐▛▀▚▖▐▌ ▐▌▐▛▀▚▖ ▝▀▚▖
▐▙▄▄▖▐▌ ▐▌▐▌ ▐▌▝▚▄▞▘▐▌ ▐▌▗▄▄▞▘
01100101 01110010 01110010 
01101111 01110010 01110011
*/

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

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖▗▄▄▖
▐▌   ▐▌  ▐▌▐▌   ▐▛▚▖▐▌  █ ▐▌   
▐▛▀▀▘▐▌  ▐▌▐▛▀▀▘▐▌ ▝▜▌  █  ▝▀▚▖
▐▙▄▄▖ ▝▚▞▘ ▐▙▄▄▖▐▌  ▐▌  █ ▗▄▄▞▘
01000101 01010110 01000101 
01001110 01010100 01010011
*/

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

    // Allow contract to receive ETH
    receive() external payable {}
} 