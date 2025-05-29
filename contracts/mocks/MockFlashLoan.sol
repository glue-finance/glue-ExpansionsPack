// SPDX-License-Identifier: BUSL-1.1

/**

███╗   ███╗ ██████╗  ██████╗██╗  ██╗    ███████╗██╗      █████╗ ███████╗██╗  ██╗    ██╗      ██████╗  █████╗ ███╗   ██╗
████╗ ████║██╔═══██╗██╔════╝██║ ██╔╝    ██╔════╝██║     ██╔══██╗██╔════╝██║  ██║    ██║     ██╔═══██╗██╔══██╗████╗  ██║
██╔████╔██║██║   ██║██║     █████╔╝     █████╗  ██║     ███████║███████╗███████║    ██║     ██║   ██║███████║██╔██╗ ██║
██║╚██╔╝██║██║   ██║██║     ██╔═██╗     ██╔══╝  ██║     ██╔══██║╚════██║██╔══██║    ██║     ██║   ██║██╔══██║██║╚██╗██║
██║ ╚═╝ ██║╚██████╔╝╚██████╗██║  ██╗    ██║     ███████╗██║  ██║███████║██║  ██║    ███████╗╚██████╔╝██║  ██║██║ ╚████║
╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝    ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝

@title Mock Flash Loan - Ultra Simple Testing Mock
@author @BasedToschi
@notice Ultra-simple mock for testing flash loan functionality with manual parameter control
@dev This mock allows you to:
     1. Add collateral tokens (like a real glue would have)
     2. Call flashLoan() with the standard interface
     3. Your receiver contract gets the tokens
     4. Your receiver must repay (amount + fee) or the transaction reverts
     5. Perfect for testing IGluedLoanReceiver implementations

HOW TO USE:
1. Deploy this contract
2. Add collateral using addCollateral() or addETH()
3. Deploy your receiver contract implementing IGluedLoanReceiver
4. Call flashLoan() with standard interface
5. Your receiver executes, repays, and transaction succeeds!

EXAMPLE:
mockFlash.addCollateral(USDC, 10000e6); // Add 10k USDC liquidity
mockFlash.flashLoan(USDC, 1000e6, myReceiver, data); // Borrow 1k USDC
// myReceiver.executeOperation() gets called with 1k USDC
// myReceiver must repay 1000e6 + fee to mockFlash contract
*/

pragma solidity ^0.8.28;

import {IGlueERC20} from '../interfaces/IGlueERC20.sol';
import {IGluedLoanReceiver} from '../interfaces/IGluedLoanReceiver.sol';

/**
 * @title MockFlashLoan
 * @notice Ultra-simple mock for testing flash loan functionality
 * @dev No complex logic - just manual liquidity setup and standard interface
 * 
 * KEY FEATURES:
 * ✅ Standard IGlueERC20.flashLoan() interface
 * ✅ Manual liquidity management (add/remove tokens)
 * ✅ Real flash loan fee calculation (0.01%)
 * ✅ Automatic repayment verification
 * ✅ Support for both ERC20 tokens and ETH
 * ✅ Perfect for testing IGluedLoanReceiver implementations
 * ✅ Event emission for testing and debugging
 * ✅ Simple balance checks and error handling
 */
contract MockFlashLoan is IGlueERC20 {

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONFIGURATION STATE - YOU CONTROL THESE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice Available liquidity for flash loans
    /// @dev token address => available amount
    mapping(address => uint256) public availableLiquidity;
    
    /// @notice Flash loan fee percentage (0.01% = 1e14)
    uint256 public constant FLASH_LOAN_FEE = 1e14;
    
    /// @notice Precision for calculations (1e18 = 100%)
    uint256 public constant PRECISION = 1e18;

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // EVENTS FOR TESTING
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice Emitted when flash loan is executed (matches real protocol)
    event GlueLoan(address indexed collateral, uint256 amount, address indexed receiver);
    
    /// @notice Test setup events
    event LiquidityAdded(address indexed token, uint256 amount);
    event LiquidityRemoved(address indexed token, uint256 amount);

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════════════════

    constructor() {
        // Nothing to initialize - you add liquidity manually
    }

    /// @notice Allow contract to receive ETH for testing
    receive() external payable {
        availableLiquidity[address(0)] += msg.value;
        emit LiquidityAdded(address(0), msg.value);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // LIQUIDITY MANAGEMENT - CALL THESE TO SET UP YOUR TEST
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Add ERC20 token liquidity for flash loans
     * @param token Address of the token to add
     * @param amount Amount of tokens to add
     * 
     * EXAMPLES:
     * addLiquidity(USDC, 10000e6);    // Add 10k USDC
     * addLiquidity(WETH, 100e18);     // Add 100 WETH
     * addLiquidity(DAI, 50000e18);    // Add 50k DAI
     */
    function addLiquidity(address token, uint256 amount) external {
        require(token != address(0), "Use addETH() for ETH");
        require(amount > 0, "Amount must be positive");
        
        // Transfer tokens from caller to this contract
        (bool success, ) = token.call(
            abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), amount)
        );
        require(success, "Token transfer failed");
        
        availableLiquidity[token] += amount;
        emit LiquidityAdded(token, amount);
    }

    /**
     * @notice Add ETH liquidity for flash loans
     * 
     * EXAMPLE: addETH{value: 10e18}(); // Add 10 ETH
     */
    function addETH() external payable {
        require(msg.value > 0, "Must send ETH");
        availableLiquidity[address(0)] += msg.value;
        emit LiquidityAdded(address(0), msg.value);
    }

    /**
     * @notice Remove liquidity (for testing edge cases)
     * @param token Address of the token (address(0) for ETH)
     * @param amount Amount to remove
     */
    function removeLiquidity(address token, uint256 amount) external {
        require(availableLiquidity[token] >= amount, "Insufficient liquidity");
        
        availableLiquidity[token] -= amount;
        
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            (bool success, ) = token.call(
                abi.encodeWithSelector(0xa9059cbb, msg.sender, amount)
            );
            require(success, "Token transfer failed");
        }
        
        emit LiquidityRemoved(token, amount);
    }

    /**
     * @notice Check available liquidity for a token
     * @param token Token address (address(0) for ETH)
     * @return available Available amount for flash loans
     */
    function getAvailableLiquidity(address token) external view returns (uint256 available) {
        return availableLiquidity[token];
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // FLASH LOAN FUNCTIONS - STANDARD INTERFACE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Execute a flash loan (STANDARD INTERFACE)
     * @param collateral Token to borrow (address(0) for ETH)
     * @param amount Amount to borrow
     * @param receiver Contract implementing IGluedLoanReceiver
     * @param params Data to pass to receiver
     * @return success True if loan was successful
     * 
     * LOGIC:
     * 1. Check available liquidity
     * 2. Calculate fee (0.01%)
     * 3. Send tokens to receiver
     * 4. Call receiver.executeOperation()
     * 5. Verify repayment (original amount + fee)
     * 6. Emit event
     * 
     * EXAMPLE:
     * // Setup liquidity
     * mockFlash.addLiquidity(USDC, 10000e6);
     * 
     * // Execute flash loan
     * bytes memory data = abi.encode("arbitrage", targetDEX);
     * bool success = mockFlash.flashLoan(USDC, 1000e6, myReceiver, data);
     * 
     * // Your receiver gets 1000 USDC, must repay 1000e6 + fee
     */
    function flashLoan(
        address collateral,
        uint256 amount,
        address receiver,
        bytes calldata params
    ) external override returns (bool success) {
        require(receiver != address(0), "Invalid receiver");
        require(amount > 0, "Amount must be positive");
        
        // Check available liquidity
        uint256 available = availableLiquidity[collateral];
        require(available >= amount, "Insufficient liquidity");
        
        // Calculate fee
        uint256 fee = getFlashLoanFeeCalculated(amount);
        uint256 repayAmount = amount + fee;
        
        // Record balances before
        uint256 balanceBefore;
        if (collateral == address(0)) {
            balanceBefore = address(this).balance;
        } else {
            balanceBefore = _getTokenBalance(collateral);
        }
        
        // Send tokens to receiver
        if (collateral == address(0)) {
            payable(receiver).transfer(amount);
        } else {
            (bool transferSuccess, ) = collateral.call(
                abi.encodeWithSelector(0xa9059cbb, receiver, amount)
            );
            require(transferSuccess, "Token transfer failed");
        }
        
        // Update available liquidity
        availableLiquidity[collateral] -= amount;
        
        // Call receiver with loan info
        address[] memory glues = new address[](1);
        glues[0] = address(this);
        uint256[] memory expectedAmounts = new uint256[](1);
        expectedAmounts[0] = repayAmount;
        
        bool executionSuccess = IGluedLoanReceiver(receiver).executeOperation(
            glues,
            collateral,
            expectedAmounts,
            params
        );
        
        require(executionSuccess, "Receiver execution failed");
        
        // Verify repayment
        uint256 balanceAfter;
        if (collateral == address(0)) {
            balanceAfter = address(this).balance;
        } else {
            balanceAfter = _getTokenBalance(collateral);
        }
        
        require(balanceAfter >= balanceBefore + fee, "Insufficient repayment");
        
        // Update liquidity with fee earned
        availableLiquidity[collateral] = balanceAfter;
        
        emit GlueLoan(collateral, amount, receiver);
        return true;
    }

    /**
     * @notice Loan handler for cross-glue loans (STANDARD INTERFACE)
     * @param receiver Address to receive the tokens
     * @param collateral Token to send
     * @param amount Amount to send
     * @return success True if loan was sent successfully
     * 
     * NOTE: This is called by MockGluedLoan for cross-glue flash loans
     */
    function loanHandler(address receiver, address collateral, uint256 amount) external override returns (bool) {
        require(receiver != address(0), "Invalid receiver");
        require(amount > 0, "Amount must be positive");
        require(availableLiquidity[collateral] >= amount, "Insufficient liquidity");
        
        // Send tokens to receiver
        if (collateral == address(0)) {
            payable(receiver).transfer(amount);
        } else {
            (bool success, ) = collateral.call(
                abi.encodeWithSelector(0xa9059cbb, receiver, amount)
            );
            require(success, "Token transfer failed");
        }
        
        // Update available liquidity  
        availableLiquidity[collateral] -= amount;
        
        emit GlueLoan(collateral, amount, receiver);
        return true;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // HELPER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get ERC20 token balance of this contract
     * @param token Token address
     * @return balance Current balance
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

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS - MINIMAL IMPLEMENTATIONS FOR INTERFACE COMPLIANCE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    function getFlashLoanFee() external pure override returns (uint256) {
        return FLASH_LOAN_FEE;
    }

    function getFlashLoanFeeCalculated(uint256 amount) public pure override returns (uint256) {
        return (amount * FLASH_LOAN_FEE + PRECISION - 1) / PRECISION; // Round up
    }

    function getBalances(address[] calldata tokens) external view override returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = availableLiquidity[tokens[i]];
        }
        return balances;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // UNUSED INTERFACE FUNCTIONS - REVERT TO KEEP FOCUS ON FLASH LOAN TESTING
    // ═══════════════════════════════════════════════════════════════════════════════════════

    function unglue(address[] calldata, uint256, address) external pure override returns (uint256, uint256, uint256, uint256) {
        revert("Use MockUnglue for unglue testing");
    }

    // Minimal implementations for interface compliance
    function getSupplyDelta(uint256) public pure override returns (uint256) { return 0; }
    function getAdjustedTotalSupply() external pure override returns (uint256) { return 1000000e18; }
    function getProtocolFee() external pure override returns (uint256) { return 1e15; }
    function getTotalHookSize(address, uint256, uint256) public pure override returns (uint256) { return 0; }
    function collateralByAmount(uint256, address[] calldata) external pure override returns (uint256[] memory) { 
        revert("Use MockUnglue for collateral calculations"); 
    }
    function getStickySupplyStored() external pure override returns (uint256) { return 0; }
    function getSettings() external pure override returns (address) { return address(0); }
    function getGlueStick() external view override returns (address) { return address(this); }
    function getStickyAsset() external pure override returns (address) { return address(0); }
    function isExpanded() external pure override returns (BIO) { return BIO.NO_HOOK; }
    function getSelfLearning() external pure override returns (bool, bool, bool) { return (false, false, false); }
} 