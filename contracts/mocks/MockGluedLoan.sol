// SPDX-License-Identifier: BUSL-1.1

/**

███╗   ███╗ ██████╗  ██████╗██╗  ██╗     ██████╗ ██╗     ██╗   ██╗███████╗██████╗     ██╗      ██████╗  █████╗ ███╗   ██╗
████╗ ████║██╔═══██╗██╔════╝██║ ██╔╝    ██╔════╝ ██║     ██║   ██║██╔════╝██╔══██╗    ██║     ██╔═══██╗██╔══██╗████╗  ██║
██╔████╔██║██║   ██║██║     █████╔╝     ██║  ███╗██║     ██║   ██║█████╗  ██║  ██║    ██║     ██║   ██║███████║██╔██╗ ██║
██║╚██╔╝██║██║   ██║██║     ██╔═██╗     ██║   ██║██║     ██║   ██║██╔══╝  ██║  ██║    ██║     ██║   ██║██╔══██║██║╚██╗██║
██║ ╚═╝ ██║╚██████╔╝╚██████╗██║  ██╗    ╚██████╔╝███████╗╚██████╔╝███████╗██████╔╝    ███████╗╚██████╔╝██║  ██║██║ ╚████║
╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝

@title Mock Glued Loan - Ultra Simple Testing Mock
@author @BasedToschi
@notice Ultra-simple mock for testing cross-glue flash loan functionality with manual parameter control
@dev This mock allows you to:
     1. Register multiple glue contracts (can be MockFlashLoan contracts)
     2. Call gluedLoan() with the standard interface
     3. Your receiver contract gets tokens from multiple glues
     4. Your receiver must repay (amount + fee) to each glue
     5. Perfect for testing complex multi-glue arbitrage strategies

HOW TO USE:
1. Deploy this contract
2. Deploy multiple MockFlashLoan contracts as individual glues
3. Add liquidity to each glue using their addLiquidity() functions
4. Register glues using registerGlue()
5. Deploy your receiver contract implementing IGluedLoanReceiver
6. Call gluedLoan() and receive tokens from multiple glues simultaneously!

EXAMPLE:
glueA.addLiquidity(USDC, 5000e6);   // Add liquidity to glue A
glueB.addLiquidity(USDC, 8000e6);   // Add liquidity to glue B
mock.registerGlue(glueA);           // Register glue A
mock.registerGlue(glueB);           // Register glue B
mock.gluedLoan([glueA, glueB], USDC, 10000e6, myReceiver, data);
// Borrow 5k from glueA + 5k from glueB = 10k total USDC to myReceiver
*/

pragma solidity ^0.8.28;

import {IGlueStickERC20, IGlueERC20} from '../interfaces/IGlueERC20.sol';
import {IGluedLoanReceiver} from '../interfaces/IGluedLoanReceiver.sol';

/**
 * @title MockGluedLoan
 * @notice Ultra-simple mock for testing cross-glue flash loan functionality
 * @dev No complex logic - just coordinates loans across multiple registered glues
 * 
 * KEY FEATURES:
 * ✅ Standard IGlueStickERC20.gluedLoan() interface
 * ✅ Manual registration of glue contracts
 * ✅ Automatic loan distribution across multiple glues
 * ✅ Real fee calculation (0.01% per glue)
 * ✅ Automatic repayment verification
 * ✅ Support for both ERC20 tokens and ETH
 * ✅ Perfect for testing IGluedLoanReceiver implementations
 * ✅ Event emission for testing and debugging
 * ✅ Works with any contracts implementing IGlueERC20 interface
 */
contract MockGluedLoan is IGlueStickERC20 {

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONFIGURATION STATE - YOU CONTROL THESE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice Array of registered glue contracts
    address[] public registeredGlues;
    
    /// @notice Mapping to check if a glue is registered
    mapping(address => bool) public isGlueRegistered;
    
    /// @notice Flash loan fee percentage (0.01% = 1e14)
    uint256 public constant FLASH_LOAN_FEE = 1e14;
    
    /// @notice Precision for calculations (1e18 = 100%)
    uint256 public constant PRECISION = 1e18;

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // EVENTS FOR TESTING
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice Emitted when glued loan fails due to insufficient liquidity
    event InsufficientLiquidity(uint256 totalCollected, uint256 loanAmount);
    
    /// @notice Emitted when flash loan execution fails
    event FlashLoanFailed();
    
    /// @notice Emitted when repayment verification fails
    event RepaymentFailed(address indexed glue);
    
    /// @notice Test setup events
    event GlueRegistered(address indexed glue);
    event GlueRemoved(address indexed glue);

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════════════════

    constructor() {
        // Nothing to initialize - you register glues manually
    }

    /// @notice Allow contract to receive ETH for testing
    receive() external payable {}

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // GLUE MANAGEMENT - CALL THESE TO SET UP YOUR TEST
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Register a glue contract for cross-glue loans
     * @param glue Address of the glue contract (must implement IGlueERC20)
     * 
     * EXAMPLES:
     * registerGlue(mockFlashLoanA);  // Register mock glue A
     * registerGlue(mockFlashLoanB);  // Register mock glue B
     * registerGlue(mockFlashLoanC);  // Register mock glue C
     */
    function registerGlue(address glue) external {
        require(glue != address(0), "Invalid glue address");
        require(!isGlueRegistered[glue], "Glue already registered");
        
        registeredGlues.push(glue);
        isGlueRegistered[glue] = true;
        
        emit GlueRegistered(glue);
    }

    /**
     * @notice Remove a glue from registration (for testing edge cases)
     * @param glue Address of the glue to remove
     */
    function removeGlue(address glue) external {
        require(isGlueRegistered[glue], "Glue not registered");
        
        // Find and remove from array
        for (uint256 i = 0; i < registeredGlues.length; i++) {
            if (registeredGlues[i] == glue) {
                registeredGlues[i] = registeredGlues[registeredGlues.length - 1];
                registeredGlues.pop();
                break;
            }
        }
        
        isGlueRegistered[glue] = false;
        emit GlueRemoved(glue);
    }

    /**
     * @notice Get list of all registered glues
     * @return glues Array of registered glue addresses
     */
    function getRegisteredGlues() external view returns (address[] memory glues) {
        return registeredGlues;
    }

    /**
     * @notice Check available liquidity across all registered glues for a token
     * @param token Token address (address(0) for ETH)
     * @return totalLiquidity Total available liquidity across all glues
     */
    function getTotalLiquidity(address token) external view returns (uint256 totalLiquidity) {
        for (uint256 i = 0; i < registeredGlues.length; i++) {
            uint256 glueBalance = _getGlueBalance(registeredGlues[i], token);
            totalLiquidity += glueBalance;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // MAIN GLUED LOAN FUNCTION - STANDARD INTERFACE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Execute a cross-glue flash loan (STANDARD INTERFACE)
     * @param glues Array of glue addresses to borrow from
     * @param collateral Token to borrow (address(0) for ETH)
     * @param loanAmount Total amount to borrow across all glues
     * @param receiver Contract implementing IGluedLoanReceiver
     * @param params Data to pass to receiver
     * 
     * LOGIC:
     * 1. Validate inputs and check glue registration
     * 2. Calculate loan distribution across glues
     * 3. Execute loanHandler() on each glue to send tokens
     * 4. Call receiver.executeOperation() with loan details
     * 5. Verify repayment to each glue (original amount + fee)
     * 6. Emit events on success/failure
     * 
     * EXAMPLE:
     * // Setup glues with liquidity
     * glueA.addLiquidity(USDC, 5000e6);
     * glueB.addLiquidity(USDC, 8000e6);
     * mock.registerGlue(glueA);
     * mock.registerGlue(glueB);
     * 
     * // Execute cross-glue loan
     * address[] memory glues = new address[](2);
     * glues[0] = glueA; glues[1] = glueB;
     * bytes memory data = abi.encode("arbitrage", targetDEX);
     * mock.gluedLoan(glues, USDC, 10000e6, myReceiver, data);
     * 
     * // Your receiver gets 5k from glueA + 5k from glueB = 10k total
     * // Must repay each glue (amount + 0.01% fee)
     */
    function gluedLoan(
        address[] calldata glues,
        address collateral,
        uint256 loanAmount,
        address receiver,
        bytes calldata params
    ) external override {
        require(glues.length > 0, "No glues specified");
        require(receiver != address(0), "Invalid receiver");
        require(loanAmount > 0, "Amount must be positive");

        // Validate all glues are registered
        for (uint256 i = 0; i < glues.length; i++) {
            require(isGlueRegistered[glues[i]], "Glue not registered");
        }

        // Calculate loan distribution
        LoanData memory loanData = _calculateLoans(glues, collateral, loanAmount);

        // Execute loans from each glue
        _executeLoans(loanData, glues, collateral, receiver);

        // Call receiver with loan details
        bool success = IGluedLoanReceiver(receiver).executeOperation(
            glues[0:loanData.count],
            collateral,
            loanData.expectedAmounts,
            params
        );

        if (!success) {
            emit FlashLoanFailed();
            revert("Flash loan execution failed");
        }

        // Verify repayments
        _verifyBalances(loanData, glues, collateral);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // INTERNAL FUNCTIONS - LOAN COORDINATION LOGIC
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Calculate loan distribution across glues
     * @param glues Array of glue addresses
     * @param collateral Token to borrow
     * @param loanAmount Total amount to borrow
     * @return loanData Calculated loan distribution data
     */
    function _calculateLoans(
        address[] calldata glues,
        address collateral,
        uint256 loanAmount
    ) internal view returns (LoanData memory loanData) {
        
        loanData.toBorrow = new uint256[](glues.length);
        loanData.expectedAmounts = new uint256[](glues.length);
        loanData.expectedBalances = new uint256[](glues.length);
        
        uint256 totalCollected;
        uint256 j;

        // Process each glue
        for (uint256 i = 0; i < glues.length; i++) {
            if (totalCollected >= loanAmount) break;
            
            address glue = glues[i];
            uint256 available = _getGlueBalance(glue, collateral);
            
            if (available > 0) {
                uint256 toBorrow = loanAmount - totalCollected;
                if (toBorrow > available) toBorrow = available;
                
                if (toBorrow > 0) {
                    uint256 fee = _calculateFee(toBorrow);
                    
                    loanData.toBorrow[j] = toBorrow;
                    loanData.expectedAmounts[j] = toBorrow + fee;
                    loanData.expectedBalances[j] = available + fee;
                    totalCollected += toBorrow;
                    j++;
                }
            }
        }

        loanData.count = j;

        if (totalCollected < loanAmount) {
            emit InsufficientLiquidity(totalCollected, loanAmount);
            revert("Insufficient liquidity across glues");
        }

        return loanData;
    }

    /**
     * @notice Execute loans from each glue
     * @param loanData Loan distribution data
     * @param glues Array of glue addresses
     * @param collateral Token to borrow
     * @param receiver Address to receive tokens
     */
    function _executeLoans(
        LoanData memory loanData,
        address[] calldata glues,
        address collateral,
        address receiver
    ) internal {
        
        for (uint256 i = 0; i < loanData.count; i++) {
            bool success = IGlueERC20(glues[i]).loanHandler(
                receiver,
                collateral,
                loanData.toBorrow[i]
            );
            
            require(success, "Loan handler failed");
        }
    }

    /**
     * @notice Verify repayments to all glues
     * @param loanData Loan distribution data
     * @param glues Array of glue addresses
     * @param collateral Token that was borrowed
     */
    function _verifyBalances(
        LoanData memory loanData,
        address[] calldata glues,
        address collateral
    ) internal view {
        
        for (uint256 i = 0; i < loanData.count; i++) {
            address glue = glues[i];
            uint256 currentBalance = _getGlueBalance(glue, collateral);
            
            if (currentBalance < loanData.expectedBalances[i]) {
                emit RepaymentFailed(glue);
                revert("Insufficient repayment to glue");
            }
        }
    }

    /**
     * @notice Get balance of a token in a glue contract
     * @param glue Address of the glue contract
     * @param token Token address (address(0) for ETH)
     * @return balance Current balance
     */
    function _getGlueBalance(address glue, address token) internal view returns (uint256 balance) {
        if (token == address(0)) {
            return glue.balance;
        } else {
            (bool success, bytes memory data) = token.staticcall(
                abi.encodeWithSelector(0x70a08231, glue) // balanceOf(address)
            );
            return success && data.length >= 32 ? abi.decode(data, (uint256)) : 0;
        }
    }

    /**
     * @notice Calculate fee for a loan amount
     * @param amount Loan amount
     * @return fee Calculated fee (rounded up)
     */
    function _calculateFee(uint256 amount) internal pure returns (uint256 fee) {
        return (amount * FLASH_LOAN_FEE + PRECISION - 1) / PRECISION; // Round up
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // LOAN DATA STRUCTURE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice Structure to hold loan calculation data
    struct LoanData {
        uint256[] toBorrow;          // Amount to borrow from each glue
        uint256[] expectedAmounts;   // Amount expected to be repaid to each glue
        uint256[] expectedBalances;  // Expected final balance of each glue
        uint256 count;               // Number of glues actually used
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS - FOR TESTING AND INTERFACE COMPLIANCE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    function getGluesBalances(
        address[] calldata glues,
        address[] calldata collaterals
    ) external view override returns (uint256[][] memory balances) {
        balances = new uint256[][](glues.length);
        
        for (uint256 i = 0; i < glues.length; i++) {
            balances[i] = new uint256[](collaterals.length);
            for (uint256 j = 0; j < collaterals.length; j++) {
                balances[i][j] = _getGlueBalance(glues[i], collaterals[j]);
            }
        }
    }

    function allGluesLength() external view override returns (uint256) {
        return registeredGlues.length;
    }

    function getGlueAtIndex(uint256 index) external view override returns (address) {
        return index < registeredGlues.length ? registeredGlues[index] : address(0);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // UNUSED INTERFACE FUNCTIONS - REVERT TO KEEP FOCUS ON GLUED LOAN TESTING
    // ═══════════════════════════════════════════════════════════════════════════════════════

    function applyTheGlue(address) external pure override returns (address) {
        revert("Use registerGlue() for mock setup");
    }

    function batchUnglue(address[] calldata, uint256[] calldata, address[] calldata, address[] calldata) external pure override {
        revert("Use MockBatchUnglue for batch unglue testing");
    }

    // Minimal implementations for interface compliance
    function getBatchCollaterals(address[] calldata, uint256[] calldata, address[] calldata) external pure override returns (uint256[][] memory) {
        revert("Use MockBatchUnglue for batch collateral calculations");
    }
    function checkAsset(address) public pure override returns (bool) { return true; }
    function computeGlueAddress(address asset) external pure override returns (address) { 
        return address(uint160(uint256(keccak256(abi.encodePacked("mock", asset)))));
    }
    function isStickyAsset(address) external pure override returns (bool, address) { return (false, address(0)); }
    function getGlueAddress(address) external pure override returns (address) { return address(0); }
} 