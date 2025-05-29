// SPDX-License-Identifier: MIT

/**

███╗   ███╗ ██████╗  ██████╗██╗  ██╗    ██╗   ██╗███╗   ██╗ ██████╗ ██╗     ██╗   ██╗███████╗
████╗ ████║██╔═══██╗██╔════╝██║ ██╔╝    ██║   ██║████╗  ██║██╔════╝ ██║     ██║   ██║██╔════╝
██╔████╔██║██║   ██║██║     █████╔╝     ██║   ██║██╔██╗ ██║██║  ███╗██║     ██║   ██║█████╗  
██║╚██╔╝██║██║   ██║██║     ██╔═██╗     ██║   ██║██║╚██╗██║██║   ██║██║     ██║   ██║██╔══╝  
██║ ╚═╝ ██║╚██████╔╝╚██████╗██║  ██╗    ╚██████╔╝██║ ╚████║╚██████╔╝███████╗╚██████╔╝███████╗
╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝
                                    ███████╗██████╗  ██████╗██████╗  ██████╗ 
                                    ██╔════╝██╔══██╗██╔════╝╚════██╗██╔═████╗
                                    █████╗  ██████╔╝██║     █████╔╝██║██╔██║
                                    ██╔══╝  ██╔══██╗██║     ██╔═══╝ ████╔╝██║
                                    ███████╗██║  ██║╚██████╗███████╗╚██████╔╝
                                    ╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚═════╝ 

@title Mock Unglue ERC20 - Ultra Simple Testing Mock
@author @BasedToschi
@notice Ultra-simple mock for testing IGlueERC20.unglue() functionality with ERC20 amount parameter
@dev This mock implements the exact IGlueERC20.unglue() interface:
     - unglue(collaterals[], amount, recipient) - ERC20 style with amount parameter
     - Manual configuration of supply delta and collateral balances
     - Realistic fee calculation and event emission
     - ACCURATE hook simulation matching real GlueERC20.sol behavior

ACCURATE HOOK SIMULATION:
This mock now implements the exact hook behavior from the real Glue Protocol:

Phase 1: Sticky Asset Hooks (during initialization)
         - Applied via tryHook(stickyAsset, amount) 
         - Reduces effective amount used for proportion calculation
         - Hook amount transferred to sticky asset (simulated)
         - Matches GlueERC20.initialization() -> tryHook() flow

Phase 2: Collateral Hooks (during distribution)  
         - Applied via tryHook(collateral, netAmount) for each collateral
         - Reduces final amount received by user
         - Hook amount transferred to sticky asset (simulated)
         - Matches GlueERC20.computeCollateral() -> tryHook() flow

Hook Interface Simulation:
- hasHook() -> returns hooksEnabled && bio == 2
- hookSize(asset, amount) -> returns mockHookSizes[asset]
- executeHook(asset, hookAmount, tokenIds) -> simulated execution
- Proper BIO state management (0=UNCHECKED, 1=NO_HOOK, 2=HOOK)

HOW TO USE:
1. Deploy this contract
2. Call setStickyAsset() with your ERC20 token address  
3. Call setSupplyDelta() with desired percentage (e.g., 1e17 = 10%)
4. Call addCollateral() for each token you want to be available
5. Configure hooks with configureHooks() and setAssetHookSize()
6. Call unglue() with the IGlueERC20 interface: unglue(collaterals, amount, recipient)

EXAMPLE WITH ACCURATE HOOKS:
mockUnglue.setStickyAsset(myToken);
mockUnglue.setSupplyDelta(5e16); // 5% 
mockUnglue.addCollateral(USDC, 1000e6); // 1000 USDC available
mockUnglue.addCollateral(address(0), 1e18); // 1 ETH available
mockUnglue.configureHooks(true, 5e16); // Enable hooks, 5% sticky asset hook  
mockUnglue.setAssetHookSize(USDC, 2e16); // 2% USDC collateral hook
mockUnglue.unglue([USDC, address(0)], 100e18, alice);
// Phase 1: tryHook(myToken, 100e18) -> transfers 5 tokens to myToken, returns 95 effective
// Proportion: 95/1000 = 9.5%  
// Phase 2: For USDC: tryHook(USDC, netUSDC) -> transfers 2% to myToken, Alice gets remainder
//          For ETH: No hook set, Alice gets full proportion minus protocol fees
*/

pragma solidity ^0.8.28;

import {IGlueERC20} from '../interfaces/IGlueERC20.sol';

/**
 * @title MockUnglueERC20
 * @notice Ultra-simple mock for testing IGlueERC20.unglue() functionality
 * @dev Implements IGlueERC20.unglue() interface with amount parameter (ERC20 style)
 * 
 * KEY FEATURES:
 * ✅ IGlueERC20.unglue(collaterals, amount, recipient) interface
 * ✅ Manual setup of all parameters
 * ✅ Configurable supply delta (unglue percentage)
 * ✅ Manual collateral balance management
 * ✅ Support for both ERC20 tokens and ETH
 * ✅ Realistic fee calculation (0.1% protocol fee)
 * ✅ Event emission matching real protocol
 * ✅ Hook simulation capabilities
 * ✅ Complete control over test scenarios
 */
contract MockUnglueERC20 is IGlueERC20 {

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONFIGURATION STATE - YOU CONTROL THESE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice The sticky asset address (ERC20 token)
    address public stickyAsset;
    
    /// @notice Supply delta - percentage of total supply being unglued (in PRECISION units)
    /// @dev 1e18 = 100%, 1e17 = 10%, 5e16 = 5%, etc.
    uint256 public supplyDelta;
    
    /// @notice Mock total supply of the sticky asset (for calculations)
    uint256 public mockTotalSupply = 1000000e18; // 1M tokens default
    
    /// @notice Collateral balances available in this mock glue
    /// @dev token address => available amount
    mapping(address => uint256) public availableCollateral;
    
    /// @notice Hook simulation settings
    bool public hooksEnabled = false;
    
    /// @notice Mock hook sizes per asset (matches IGluedHooks.hookSize interface)
    /// @dev asset address => hook size in PRECISION units
    mapping(address => uint256) public mockHookSizes;
    
    /// @notice Tracks hook status (matches BIO enum from real protocol)
    /// @dev 0 = UNCHECKED, 1 = NO_HOOK, 2 = HOOK
    uint8 public bio = 0; // UNCHECKED
    
    /// @notice Track total hook amounts transferred for testing verification
    mapping(address => uint256) public totalHookAmountsTransferred;
    
    /// @notice Protocol fee percentage (0.1% = 1e15)
    uint256 public constant PROTOCOL_FEE = 1e15;
    
    /// @notice Precision for calculations (1e18 = 100%)
    uint256 public constant PRECISION = 1e18;

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // EVENTS FOR TESTING
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice Emitted when unglue is called (matches real protocol)
    event unglued(address indexed recipient, uint256 realAmount, uint256 beforeTotalSupply, uint256 afterTotalSupply, uint256 supplyDelta);
    
    /// @notice Test setup events
    event StickyAssetSet(address indexed asset);
    event SupplyDeltaSet(uint256 delta);
    event CollateralAdded(address indexed token, uint256 amount);
    event HooksConfigured(bool enabled, uint256 stickyHookSize);

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════════════════

    constructor() {
        // Nothing to initialize - you configure everything manually
    }

    /// @notice Allow contract to receive ETH for testing
    receive() external payable {
        availableCollateral[address(0)] += msg.value;
        emit CollateralAdded(address(0), msg.value);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // TEST CONFIGURATION FUNCTIONS - CALL THESE TO SET UP YOUR TEST
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Set the sticky asset address for this mock (ERC20 token)
     * @param asset Address of your ERC20 sticky token
     * 
     * EXAMPLE: setStickyAsset(0x1234...); // Your ERC20 token address
     */
    function setStickyAsset(address asset) external {
        stickyAsset = asset;
        emit StickyAssetSet(asset);
    }

    /**
     * @notice Set the supply delta (percentage of total supply being unglued)
     * @param delta Supply delta in PRECISION units
     * 
     * EXAMPLES:
     * setSupplyDelta(1e18);  // 100% - entire supply
     * setSupplyDelta(1e17);  // 10% - ten percent
     * setSupplyDelta(5e16);  // 5% - five percent  
     * setSupplyDelta(1e16);  // 1% - one percent
     */
    function setSupplyDelta(uint256 delta) external {
        require(delta <= PRECISION, "Delta cannot exceed 100%");
        supplyDelta = delta;
        emit SupplyDeltaSet(delta);
    }

    /**
     * @notice Set the mock total supply for calculations
     * @param totalSupply Total supply amount
     * 
     * EXAMPLE: setMockTotalSupply(1000000e18); // 1M tokens
     */
    function setMockTotalSupply(uint256 totalSupply) external {
        mockTotalSupply = totalSupply;
    }

    /**
     * @notice Configure hook simulation to match real protocol behavior
     * @param enabled Whether to enable hook simulation
     * @param stickyHook Hook size for sticky asset (in PRECISION units)
     * 
     * EXAMPLES:
     * configureHooks(true, 5e16); // Enable hooks, 5% sticky asset hook
     * configureHooks(false, 0);   // Disable hooks
     */
    function configureHooks(bool enabled, uint256 stickyHook) external {
        hooksEnabled = enabled;
        if (enabled) {
            bio = 2; // HOOK
        } else {
            bio = 1; // NO_HOOK
        }
        mockHookSizes[stickyAsset] = stickyHook;
        emit HooksConfigured(enabled, stickyHook);
    }

    /**
     * @notice Set hook size for a specific asset (matches IGluedHooks.hookSize interface)
     * @param asset Address of the asset (sticky asset or collateral)
     * @param hookSize Hook size in PRECISION units
     * 
     * EXAMPLE: setAssetHookSize(USDC, 2e16); // 2% hook on USDC
     */
    function setAssetHookSize(address asset, uint256 hookSize) external {
        mockHookSizes[asset] = hookSize;
    }

    /**
     * @notice Legacy function name for backward compatibility
     */
    function setCollateralHookSize(address collateral, uint256 hookSize) external {
        setAssetHookSize(collateral, hookSize);
    }

    /**
     * @notice Add collateral tokens to this mock (ERC20 tokens)
     * @param token Address of the collateral token
     * @param amount Amount of collateral to add
     * 
     * EXAMPLES:
     * addCollateral(USDC, 1000e6);    // Add 1000 USDC
     * addCollateral(WETH, 10e18);     // Add 10 WETH
     * addCollateral(DAI, 500e18);     // Add 500 DAI
     */
    function addCollateral(address token, uint256 amount) external {
        require(token != address(0), "Use addETH() for ETH");
        
        // Transfer tokens from caller to this contract
        (bool success, ) = token.call(
            abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), amount)
        );
        require(success, "Token transfer failed");
        
        availableCollateral[token] += amount;
        emit CollateralAdded(token, amount);
    }

    /**
     * @notice Add ETH collateral to this mock
     * 
     * EXAMPLE: addETH{value: 1e18}(); // Add 1 ETH
     */
    function addETH() external payable {
        require(msg.value > 0, "Must send ETH");
        availableCollateral[address(0)] += msg.value;
        emit CollateralAdded(address(0), msg.value);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // MAIN UNGLUE FUNCTION - IGlueERC20 INTERFACE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Unglue sticky tokens to receive collateral (IGlueERC20 INTERFACE)
     * @param collaterals Array of collateral addresses to withdraw
     * @param amount Amount of sticky tokens to unglue (ERC20 style)
     * @param recipient Address to receive the collateral
     * @return supplyDelta The configured supply delta
     * @return realAmount The effective amount after sticky hooks
     * @return beforeTotalSupply Mock total supply
     * @return afterTotalSupply Mock total supply minus effective amount
     * 
     * LOGIC (MATCHES REAL PROTOCOL):
     * 1. Apply sticky asset hooks first (reduces effective amount)
     * 2. Calculate proportion based on effective amount vs total supply
     * 3. For each collateral: userShare = availableBalance * proportion
     * 4. Apply collateral hooks and protocol fee during distribution
     * 5. Transfer net amount to recipient
     * 6. Emit standard unglued event
     * 
     * EXAMPLE:
     * mockUnglue.setStickyAsset(myToken);
     * mockUnglue.setMockTotalSupply(1000e18); // 1000 total supply
     * mockUnglue.addCollateral(USDC, 1000e6); // 1000 USDC
     * mockUnglue.configureHooks(true, 5e16); // 5% sticky asset hook
     * mockUnglue.setAssetHookSize(USDC, 2e16); // 2% USDC hook
     * mockUnglue.unglue([USDC], 100e18, alice); // Burn 100 tokens
     * // Effective amount after sticky hook: tryHook(stickyAsset, 100) = ~95 tokens
     * // Alice receives collateral based on 95/1000 = 9.5% (minus collateral hooks and fees)
     */
    function unglue(
        address[] calldata collaterals,
        uint256 amount,
        address recipient
    ) external override returns (uint256, uint256, uint256, uint256) {
        require(stickyAsset != address(0), "Sticky asset not set");
        require(amount > 0, "Amount must be positive");
        require(recipient != address(0), "Invalid recipient");
        require(collaterals.length > 0, "No collaterals specified");

        // PHASE 1: Apply sticky asset hooks (matches real protocol initialization)
        uint256 effectiveAmount = amount;
        if (bio == 0 || bio == 2) { // UNCHECKED or HOOK
            effectiveAmount = tryHook(stickyAsset, amount);
        }

        // Calculate supply metrics for event (use effective amount)
        uint256 beforeSupply = mockTotalSupply;
        uint256 afterSupply = beforeSupply - effectiveAmount;
        
        // Calculate proportion: effectiveAmount / totalSupply
        uint256 proportion = (effectiveAmount * PRECISION) / beforeSupply;

        // PHASE 2: Process each collateral with hooks (matches real protocol computeCollateral)
        for (uint256 i = 0; i < collaterals.length; i++) {
            address collateral = collaterals[i];
            uint256 available = availableCollateral[collateral];
            
            if (available > 0) {
                // Calculate user share based on proportion
                uint256 userShare = (available * proportion) / PRECISION;
                
                // Apply protocol fee (0.1%)
                uint256 protocolFee = (userShare * PROTOCOL_FEE) / PRECISION;
                uint256 netAmount = userShare - protocolFee;
                
                // Apply collateral hooks if enabled (matches real protocol)
                if (bio == 2) { // HOOK
                    netAmount = tryHook(collateral, netAmount);
                }
                
                // Transfer to recipient
                if (netAmount > 0) {
                    if (collateral == address(0)) {
                        // Transfer ETH
                        payable(recipient).transfer(netAmount);
                    } else {
                        // Transfer ERC20
                        (bool success, ) = collateral.call(
                            abi.encodeWithSelector(0xa9059cbb, recipient, netAmount)
                        );
                        require(success, "Token transfer failed");
                    }
                }
                
                // Update available balance (use userShare, not netAmount, like real protocol)
                availableCollateral[collateral] -= userShare;
            }
        }

        // Emit standard event (use effective amount as realAmount)
        emit unglued(recipient, effectiveAmount, beforeSupply, afterSupply, proportion);
        
        return (proportion, effectiveAmount, beforeSupply, afterSupply);
    }

    /**
     * @notice Calculate total hook size for collateral and sticky token (DEPRECATED)
     * @dev This function is kept for backward compatibility but is no longer used internally
     * @param collateral Address of the collateral
     * @param collateralAmount Amount of collateral being processed
     * @param stickyAmount Amount of sticky tokens being unglued
     * @return totalHookSize Combined hook size in PRECISION units
     */
    function _calculateTotalHookSize(
        address collateral,
        uint256 collateralAmount,
        uint256 stickyAmount
    ) internal view returns (uint256 totalHookSize) {
        if (!hooksEnabled) return 0;
        
        // Legacy calculation - now hooks are applied separately
        uint256 stickyHook = mockHookSizes[stickyAsset];
        uint256 collateralHook = mockHookSizes[collateral];
        
        totalHookSize = stickyHook + collateralHook;
        
        if (totalHookSize > PRECISION) {
            totalHookSize = PRECISION;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // HOOK SIMULATION HELPER FUNCTIONS FOR TESTING
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get the current hook status (matches real protocol's BIO enum)
     * @return status 0 = UNCHECKED, 1 = NO_HOOK, 2 = HOOK
     */
    function getHookStatus() external view returns (uint8 status) {
        return bio;
    }

    /**
     * @notice Get hook size for a specific asset
     * @param asset Address of the asset (sticky asset or collateral)
     * @return hookSize Hook size in PRECISION units
     */
    function getAssetHookSize(address asset) external view returns (uint256 hookSize) {
        return mockHookSizes[asset];
    }

    /**
     * @notice Get total amount transferred to sticky asset via hooks
     * @param asset Address of the asset
     * @return totalTransferred Total amount transferred via hooks
     */
    function getHookAmountTransferred(address asset) external view returns (uint256 totalTransferred) {
        return totalHookAmountsTransferred[asset];
    }

    /**
     * @notice Simulate IGluedHooks.hasHook() interface
     * @return hasHook Whether hooks are enabled
     */
    function hasHook() external view returns (bool hasHook) {
        return hooksEnabled && bio == 2;
    }

    /**
     * @notice Simulate IGluedHooks.hookSize() interface
     * @param asset Address of the asset
     * @param amount Amount being processed (unused in this mock)
     * @return hookSize Hook size for the asset in PRECISION units
     */
    function hookSize(address asset, uint256 amount) external view returns (uint256 hookSize) {
        amount; // Silence unused parameter warning
        if (bio != 2) return 0;
        return mockHookSizes[asset];
    }

    /**
     * @notice Simulate IGluedHooks.hooksImpact() interface for view functions
     * @param collateral Address of the collateral
     * @param collateralAmount Amount of collateral (unused in this mock)
     * @param stickyAmount Amount of sticky tokens (unused in this mock)
     * @return impact Hook impact size in PRECISION units
     */
    function hooksImpact(address collateral, uint256 collateralAmount, uint256 stickyAmount) external view returns (uint256 impact) {
        collateralAmount; // Silence unused parameter warning
        stickyAmount; // Silence unused parameter warning
        if (bio != 2) return 0;
        return mockHookSizes[collateral];
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS - IGlueERC20 INTERFACE COMPLIANCE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Preview the two-phase hook calculation for testing
     * @param amount Amount of sticky tokens to unglue
     * @param collateral Specific collateral to check
     * @return effectiveAmount Amount after sticky hooks
     * @param stickyHookAmount Amount taken by sticky hooks
     * @param proportion Proportion of total supply (after sticky hooks)
     * @param userShare Raw collateral share before collateral hooks
     * @param collateralHookAmount Amount taken by collateral hooks
     * @param protocolFee Protocol fee amount
     * @param finalAmount Final amount user receives
     * 
     * EXAMPLE:
     * (effectiveAmount, stickyHook, proportion, userShare, collateralHook, protocolFee, finalAmount) = 
     *   previewHookCalculation(100e18, USDC);
     */
    function previewHookCalculation(
        uint256 amount,
        address collateral
    ) external view returns (
        uint256 effectiveAmount,
        uint256 stickyHookAmount,
        uint256 proportion,
        uint256 userShare,
        uint256 collateralHookAmount,
        uint256 protocolFee,
        uint256 finalAmount
    ) {
        if (mockTotalSupply == 0 || amount == 0) return (0, 0, 0, 0, 0, 0, 0);
        
        // PHASE 1: Sticky asset hooks
        effectiveAmount = amount;
        if (hooksEnabled && mockHookSizes[amount] > 0) {
            stickyHookAmount = (amount * mockHookSizes[amount]) / PRECISION;
            effectiveAmount = amount - stickyHookAmount;
        }
        
        // Calculate proportion
        proportion = (effectiveAmount * PRECISION) / mockTotalSupply;
        
        // PHASE 2: Collateral calculation
        uint256 available = availableCollateral[collateral];
        if (available > 0) {
            userShare = (available * proportion) / PRECISION;
            protocolFee = (userShare * PROTOCOL_FEE) / PRECISION;
            finalAmount = userShare - protocolFee;
            
            // Apply collateral hooks
            if (hooksEnabled) {
                uint256 collateralHookSize = mockHookSizes[collateral];
                if (collateralHookSize > 0) {
                    collateralHookAmount = (userShare * collateralHookSize) / PRECISION;
                    finalAmount = finalAmount > collateralHookAmount ? finalAmount - collateralHookAmount : 0;
                }
            }
        }
    }

    function getSupplyDelta(uint256 amount) public view override returns (uint256) {
        if (mockTotalSupply == 0) return 0;
        
        // Apply sticky asset hooks to get effective amount (simulate for view)
        uint256 effectiveAmount = amount;
        if (bio == 2 && mockHookSizes[stickyAsset] > 0) { // HOOK enabled
            uint256 hookSize = mockHookSizes[stickyAsset];
            if (hookSize > PRECISION) hookSize = PRECISION;
            uint256 hookAmount = (amount * hookSize) / PRECISION;
            effectiveAmount = amount - hookAmount;
        }
        
        return (effectiveAmount * PRECISION) / mockTotalSupply;
    }

    function collateralByAmount(
        uint256 amount,
        address[] calldata collaterals
    ) external view override returns (uint256[] memory amounts) {
        amounts = new uint256[](collaterals.length);
        
        if (mockTotalSupply == 0 || amount == 0) return amounts;
        
        // PHASE 1: Apply sticky asset hooks first (simulate tryHook for view)
        uint256 effectiveAmount = amount;
        if (bio == 2 && mockHookSizes[stickyAsset] > 0) { // HOOK enabled
            uint256 hookSize = mockHookSizes[stickyAsset];
            if (hookSize > PRECISION) hookSize = PRECISION;
            uint256 hookAmount = (amount * hookSize) / PRECISION;
            effectiveAmount = amount - hookAmount;
        }
        
        // Calculate proportion based on effective amount
        uint256 proportion = (effectiveAmount * PRECISION) / mockTotalSupply;
        
        // PHASE 2: Calculate collateral amounts with collateral hooks
        for (uint256 i = 0; i < collaterals.length; i++) {
            uint256 available = availableCollateral[collaterals[i]];
            if (available > 0) {
                uint256 userShare = (available * proportion) / PRECISION;
                uint256 protocolFee = (userShare * PROTOCOL_FEE) / PRECISION;
                uint256 netAmount = userShare - protocolFee;
                
                // Apply collateral hooks if enabled (simulate tryHook for view)
                if (bio == 2 && mockHookSizes[collaterals[i]] > 0) { // HOOK enabled
                    uint256 hookSize = mockHookSizes[collaterals[i]];
                    if (hookSize > PRECISION) hookSize = PRECISION;
                    uint256 hookAmount = (netAmount * hookSize) / PRECISION;
                    netAmount = netAmount > hookAmount ? netAmount - hookAmount : 0;
                }
                
                amounts[i] = netAmount;
            }
        }
    }

    function getBalances(address[] calldata collaterals) external view override returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](collaterals.length);
        for (uint256 i = 0; i < collaterals.length; i++) {
            balances[i] = availableCollateral[collaterals[i]];
        }
        return balances;
    }

    function getStickyAsset() external view override returns (address) {
        return stickyAsset;
    }

    function getTotalHookSize(address collateral, uint256 collateralAmount, uint256 stickyAmount) public view override returns (uint256) {
        if (bio != 2) return 0; // No hooks if not in HOOK state
        
        // Return the specific hook size for this asset (matches real protocol's hookSize interface)
        uint256 hookSize = mockHookSizes[collateral];
        return hookSize > PRECISION ? PRECISION : hookSize;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // UNUSED INTERFACE FUNCTIONS - REVERT TO KEEP FOCUS ON UNGLUE TESTING
    // ═══════════════════════════════════════════════════════════════════════════════════════

    function initialize(address) external pure override {
        revert("Use setStickyAsset() for mock setup");
    }

    function flashLoan(address, uint256, address, bytes calldata) external pure override returns (bool) {
        revert("Use MockFlashLoan for flash loan testing");
    }

    function loanHandler(address, address, uint256) external pure override returns (bool) {
        revert("Use MockFlashLoan for loan handler testing");
    }

    // Minimal implementations for interface compliance
    function getAdjustedTotalSupply() external view override returns (uint256) { return mockTotalSupply; }
    function getProtocolFee() external pure override returns (uint256) { return PROTOCOL_FEE; }
    function getFlashLoanFee() external pure override returns (uint256) { return 1e14; }
    function getFlashLoanFeeCalculated(uint256) external pure override returns (uint256) { return 0; }
    function getStickySupplyStored() external pure override returns (uint256) { return 0; }
    function getSettings() external pure override returns (address) { return address(0); }
    function getGlueStick() external view override returns (address) { return address(this); }
    function isExpanded() external pure override returns (BIO) { return BIO.NO_HOOK; }
    function getSelfLearning() external pure override returns (bool, bool, bool) { return (false, false, false); }

    /**
     * @notice Simulate the real protocol's tryHook function behavior
     * @param asset The address of the asset being processed
     * @param amount The amount to process
     * @return The amount remaining after hook processing
     * 
     * This function replicates the exact logic from GlueERC20.tryHook():
     * 1. Check hook status and update bio if needed
     * 2. Get hook size from mock interface
     * 3. Calculate hook amount using GluedMath.md512
     * 4. Transfer hook amount to sticky asset
     * 5. Execute hook (simulated)
     * 6. Return remaining amount
     */
    function tryHook(address asset, uint256 amount) internal returns (uint256) {
        // If hooks are disabled, return original amount
        if (!hooksEnabled) return amount;
        
        uint256 hookAmount = 0;

        // Simulate hook detection (matches real protocol's hasHook() check)
        if (bio == 0) { // UNCHECKED
            if (hooksEnabled) {
                bio = 2; // HOOK
            } else {
                bio = 1; // NO_HOOK
                return amount;
            }
        }
        
        // If no hooks enabled, return original amount
        if (bio == 1) { // NO_HOOK
            return amount;
        }
        
        // Get hook size for this asset (matches IGluedHooks.hookSize interface)
        uint256 hookSize = mockHookSizes[asset];
        if (hookSize == 0) return amount;
        
        // Cap hook size at 100% (matches real protocol)
        if (hookSize > PRECISION) {
            hookSize = PRECISION;
        }
        
        // Calculate hook amount using same math as real protocol
        hookAmount = (amount * hookSize) / PRECISION;
        
        // Ensure hook amount doesn't exceed available amount
        if (hookAmount > amount) {
            hookAmount = amount;
        }
        
        if (hookAmount == 0) return amount;
        
        // Simulate transferring hook amount to sticky asset (matches real protocol)
        if (asset == address(0)) {
            // For ETH, simulate sending to sticky asset
            // In real protocol: payable(STICKY_ASSET).sendValue(hookAmount);
            totalHookAmountsTransferred[asset] += hookAmount;
        } else {
            // For ERC20, simulate transfer to sticky asset
            // In real protocol: IERC20(asset).safeTransfer(STICKY_ASSET, hookAmount);
            totalHookAmountsTransferred[asset] += hookAmount;
            
            // Reduce available collateral to simulate the transfer
            availableCollateral[asset] = availableCollateral[asset] >= hookAmount ? 
                availableCollateral[asset] - hookAmount : 0;
        }
        
        // Simulate executeHook call (matches real protocol)
        // In real protocol: IGluedHooks(STICKY_ASSET).executeHook(asset, hookAmount, new uint256[](0))
        
        // Return amount minus hook amount (matches real protocol)
        return amount - hookAmount;
    }
} 