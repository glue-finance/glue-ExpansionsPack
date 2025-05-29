// SPDX-License-Identifier: MIT

/**

███╗   ███╗ ██████╗  ██████╗██╗  ██╗    ██████╗  █████╗ ████████╗ ██████╗██╗  ██╗    ██╗   ██╗███╗   ██╗ ██████╗ ██╗     ██╗   ██╗███████╗
████╗ ████║██╔═══██╗██╔════╝██║ ██╔╝    ██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║  ██║    ██║   ██║████╗  ██║██╔════╝ ██║     ██║   ██║██╔════╝
██╔████╔██║██║   ██║██║     █████╔╝     ██████╔╝███████║   ██║   ██║     ███████║    ██║   ██║██╔██╗ ██║██║  ███╗██║     ██║   ██║█████╗  
██║╚██╔╝██║██║   ██║██║     ██╔═██╗     ██╔══██╗██╔══██║   ██║   ██║     ██╔══██║    ██║   ██║██║╚██╗██║██║   ██║██║     ██║   ██║██╔══╝  
██║ ╚═╝ ██║╚██████╔╝╚██████╗██║  ██╗    ██████╔╝██║  ██║   ██║   ╚██████╗██║  ██║    ╚██████╔╝██║ ╚████║╚██████╔╝███████╗╚██████╔╝███████╗
╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝
                                                       ███████╗██████╗  ██████╗██████╗  ██████╗ 
                                                       ██╔════╝██╔══██╗██╔════╝╚════██╗██╔═████╗
                                                       █████╗  ██████╔╝██║      █████╔╝██║██╔██║
                                                       ██╔══╝  ██╔══██╗██║     ██╔═══╝ ████╔╝██║
                                                       ███████╗██║  ██║╚██████╗███████╗╚██████╔╝
                                                       ╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚═════╝ 

@title Mock Batch Unglue ERC20 - Ultra Simple Testing Mock
@author @BasedToschi
@notice Ultra-simple mock for testing IGlueStickERC20.batchUnglue() functionality with ERC20 amounts
@dev This mock implements the exact IGlueStickERC20.batchUnglue() interface:
     - batchUnglue(stickyAssets[], stickyAmounts[], collaterals[], recipients[]) - ERC20 style with amounts
     - Manual registration of multiple sticky assets with their glue addresses
     - Individual supply delta configuration per asset
     - Manual collateral management per glue
     - Support for hook simulation (optional)

HOW TO USE:
1. Deploy this contract
2. Register sticky assets using registerStickyAsset()
3. Set supply deltas for each asset using setSupplyDelta()
4. Add collateral to each glue using addCollateralToGlue()
5. Call batchUnglue() with IGlueStickERC20 interface and receive tokens from all glues!

EXAMPLE:
mock.registerStickyAsset(tokenA, glueA);
mock.registerStickyAsset(tokenB, glueB);
mock.setMockTotalSupply(tokenA, 1000e18); // 1000 total supply for token A
mock.setMockTotalSupply(tokenB, 2000e18); // 2000 total supply for token B
mock.addCollateralToGlue(glueA, USDC, 1000e6);
mock.addCollateralToGlue(glueB, USDC, 2000e6);
mock.batchUnglue([tokenA, tokenB], [100e18, 200e18], [USDC], [alice]);
// Alice gets collateral based on 100/1000 from glueA + 200/2000 from glueB
*/

pragma solidity ^0.8.28;

import {IGlueStickERC20} from '../interfaces/IGlueERC20.sol';

/**
 * @title MockBatchUnglueERC20
 * @notice Ultra-simple mock for testing IGlueStickERC20.batchUnglue() functionality
 * @dev Implements IGlueStickERC20.batchUnglue() interface with amounts parameter (ERC20 style)
 * 
 * KEY FEATURES:
 * ✅ IGlueStickERC20.batchUnglue(assets, amounts[], collaterals, recipients) interface
 * ✅ Manual registration of sticky assets and their glues
 * ✅ Individual total supply configuration per asset
 * ✅ Manual collateral management per glue
 * ✅ Support for both single and multiple recipients
 * ✅ Realistic fee calculation (0.1% protocol fee)
 * ✅ Event emission for testing
 * ✅ Hook simulation capabilities
 * ✅ Perfect for testing multi-asset ERC20 strategies
 */
contract MockBatchUnglueERC20 is IGlueStickERC20 {

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONFIGURATION STATE - YOU CONTROL THESE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice Mapping from sticky asset to its mock glue address
    mapping(address => address) public stickyAssetToGlue;
    
    /// @notice Total supply for each sticky asset (asset => total supply)
    mapping(address => uint256) public mockTotalSupplies;
    
    /// @notice Collateral balances for each glue (glue => token => amount)
    mapping(address => mapping(address => uint256)) public glueCollateral;
    
    /// @notice Hook simulation settings per glue
    mapping(address => bool) public hooksEnabled;
    mapping(address => uint256) public stickyHookSizes;
    mapping(address => mapping(address => uint256)) public collateralHookSizes;
    
    /// @notice Array of registered sticky assets
    address[] public registeredAssets;
    
    /// @notice Protocol fee percentage (0.1% = 1e15)
    uint256 public constant PROTOCOL_FEE = 1e15;
    
    /// @notice Precision for calculations (1e18 = 100%)
    uint256 public constant PRECISION = 1e18;

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // EVENTS FOR TESTING
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice Emitted when batch unglue is executed (matches real protocol)
    event BatchUnglueExecuted(
        address[] stickyAssets,
        uint256[] stickyAmounts,
        address[] collaterals,
        address[] recipients
    );
    
    /// @notice Test setup events
    event StickyAssetRegistered(address indexed asset, address indexed glue);
    event TotalSupplySet(address indexed asset, uint256 totalSupply);
    event CollateralAddedToGlue(address indexed glue, address indexed token, uint256 amount);
    event HooksConfiguredForGlue(address indexed glue, bool enabled, uint256 stickyHookSize);

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════════════════

    constructor() {
        // Nothing to initialize - you configure everything manually
    }

    /// @notice Allow contract to receive ETH for testing
    receive() external payable {}

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // TEST CONFIGURATION FUNCTIONS - CALL THESE TO SET UP YOUR TEST
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Register a sticky asset with its mock glue address
     * @param stickyAsset Address of the ERC20 sticky token
     * @param glueAddress Address of the mock glue (can be another MockUnglueERC20 contract)
     * 
     * EXAMPLES:
     * registerStickyAsset(tokenA, mockGlueA);
     * registerStickyAsset(tokenB, mockGlueB);
     * registerStickyAsset(tokenC, mockGlueC);
     */
    function registerStickyAsset(address stickyAsset, address glueAddress) external {
        require(stickyAsset != address(0), "Invalid sticky asset");
        require(glueAddress != address(0), "Invalid glue address");
        
        stickyAssetToGlue[stickyAsset] = glueAddress;
        mockTotalSupplies[stickyAsset] = 1000000e18; // Default 1M tokens
        registeredAssets.push(stickyAsset);
        
        emit StickyAssetRegistered(stickyAsset, glueAddress);
    }

    /**
     * @notice Set total supply for a specific sticky asset
     * @param stickyAsset Address of the sticky asset
     * @param totalSupply Total supply amount
     * 
     * EXAMPLES:
     * setMockTotalSupply(tokenA, 1000e18);   // 1000 tokens for A
     * setMockTotalSupply(tokenB, 500000e6);  // 500k USDC-like tokens for B
     * setMockTotalSupply(tokenC, 1e30);      // Very large supply for C
     */
    function setMockTotalSupply(address stickyAsset, uint256 totalSupply) external {
        require(stickyAssetToGlue[stickyAsset] != address(0), "Asset not registered");
        require(totalSupply > 0, "Total supply must be positive");
        
        mockTotalSupplies[stickyAsset] = totalSupply;
        emit TotalSupplySet(stickyAsset, totalSupply);
    }

    /**
     * @notice Configure hook simulation for a specific glue
     * @param glueAddress Address of the glue
     * @param enabled Whether to simulate hooks
     * @param stickyHook Hook size for sticky tokens (in PRECISION units)
     * 
     * EXAMPLES:
     * configureHooksForGlue(glueA, true, 5e16);  // Enable hooks, 5% sticky hook for glue A
     * configureHooksForGlue(glueB, false, 0);    // Disable hooks for glue B
     */
    function configureHooksForGlue(address glueAddress, bool enabled, uint256 stickyHook) external {
        hooksEnabled[glueAddress] = enabled;
        stickyHookSizes[glueAddress] = stickyHook;
        emit HooksConfiguredForGlue(glueAddress, enabled, stickyHook);
    }

    /**
     * @notice Set hook size for a specific collateral in a specific glue
     * @param glueAddress Address of the glue
     * @param collateral Address of the collateral token
     * @param hookSize Hook size in PRECISION units
     * 
     * EXAMPLE: setCollateralHookSizeForGlue(glueA, USDC, 2e16); // 2% hook on USDC for glue A
     */
    function setCollateralHookSizeForGlue(address glueAddress, address collateral, uint256 hookSize) external {
        collateralHookSizes[glueAddress][collateral] = hookSize;
    }

    /**
     * @notice Add collateral to a specific glue (ERC20 tokens)
     * @param glueAddress Address of the glue
     * @param token Address of the collateral token
     * @param amount Amount to add
     * 
     * EXAMPLES:
     * addCollateralToGlue(glueA, USDC, 1000e6);  // Add 1000 USDC to glue A
     * addCollateralToGlue(glueB, USDC, 2000e6);  // Add 2000 USDC to glue B
     * addCollateralToGlue(glueA, WETH, 10e18);   // Add 10 WETH to glue A
     */
    function addCollateralToGlue(address glueAddress, address token, uint256 amount) external {
        require(token != address(0), "Use addETHToGlue() for ETH");
        require(amount > 0, "Amount must be positive");
        
        // Transfer tokens from caller to this contract
        (bool success, ) = token.call(
            abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), amount)
        );
        require(success, "Token transfer failed");
        
        glueCollateral[glueAddress][token] += amount;
        emit CollateralAddedToGlue(glueAddress, token, amount);
    }

    /**
     * @notice Add ETH collateral to a specific glue
     * @param glueAddress Address of the glue
     * 
     * EXAMPLE: addETHToGlue{value: 5e18}(glueA); // Add 5 ETH to glue A
     */
    function addETHToGlue(address glueAddress) external payable {
        require(msg.value > 0, "Must send ETH");
        
        glueCollateral[glueAddress][address(0)] += msg.value;
        emit CollateralAddedToGlue(glueAddress, address(0), msg.value);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // MAIN BATCH UNGLUE FUNCTION - IGlueStickERC20 INTERFACE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Batch unglue multiple sticky ERC20 tokens (IGlueStickERC20 INTERFACE)
     * @param stickyAssets Array of sticky asset addresses
     * @param stickyAmounts Array of amounts to unglue for each asset (ERC20 style)
     * @param collaterals Array of collateral addresses to withdraw
     * @param recipients Array of recipients (single recipient for all, or one per asset)
     * 
     * LOGIC:
     * 1. For each sticky asset:
     * 2. Calculate proportion = amount / totalSupply
     * 3. Get registered glue address
     * 4. For each collateral:
     * 5. Calculate user share = glueBalance * proportion
     * 6. Apply protocol fee (0.1%) and hooks if enabled
     * 7. Transfer net amount to recipient
     * 8. Emit standard event
     * 
     * EXAMPLE:
     * // Setup
     * mock.registerStickyAsset(tokenA, glueA);
     * mock.registerStickyAsset(tokenB, glueB);
     * mock.setMockTotalSupply(tokenA, 1000e18); // 1000 total
     * mock.setMockTotalSupply(tokenB, 2000e18); // 2000 total
     * mock.addCollateralToGlue(glueA, USDC, 1000e6);
     * mock.addCollateralToGlue(glueB, USDC, 2000e6);
     * 
     * // Execute
     * mock.batchUnglue([tokenA, tokenB], [100e18, 200e18], [USDC], [alice]);
     * // Alice gets 10% from glueA (100/1000) + 10% from glueB (200/2000) = 100 + 200 = 300 USDC (minus fees)
     */
    function batchUnglue(
        address[] calldata stickyAssets,
        uint256[] calldata stickyAmounts,
        address[] calldata collaterals,
        address[] calldata recipients
    ) external override {
        require(stickyAssets.length > 0, "No assets specified");
        require(stickyAssets.length == stickyAmounts.length, "Assets/amounts mismatch");
        require(collaterals.length > 0, "No collaterals specified");
        require(recipients.length > 0, "No recipients specified");
        require(
            recipients.length == 1 || recipients.length == stickyAssets.length,
            "Invalid recipients count"
        );

        // Process each sticky asset
        for (uint256 i = 0; i < stickyAssets.length; i++) {
            address stickyAsset = stickyAssets[i];
            uint256 stickyAmount = stickyAmounts[i];
            address glueAddress = stickyAssetToGlue[stickyAsset];
            uint256 totalSupply = mockTotalSupplies[stickyAsset];
            
            require(glueAddress != address(0), "Asset not registered");
            require(stickyAmount > 0, "Amount must be positive");
            require(totalSupply > 0, "Total supply not set");
            
            // Calculate proportion: amount / totalSupply
            uint256 proportion = (stickyAmount * PRECISION) / totalSupply;
            
            // Determine recipient for this asset
            address recipient = recipients.length == 1 ? recipients[0] : recipients[i];
            require(recipient != address(0), "Invalid recipient");
            
            // Process each collateral for this asset
            for (uint256 j = 0; j < collaterals.length; j++) {
                address collateral = collaterals[j];
                uint256 available = glueCollateral[glueAddress][collateral];
                
                if (available > 0) {
                    // Calculate user share based on proportion
                    uint256 userShare = (available * proportion) / PRECISION;
                    
                    // Apply protocol fee (0.1%)
                    uint256 protocolFee = (userShare * PROTOCOL_FEE) / PRECISION;
                    uint256 netAmount = userShare - protocolFee;
                    
                    // Apply hooks if enabled for this glue
                    if (hooksEnabled[glueAddress]) {
                        uint256 totalHookSize = _calculateTotalHookSize(glueAddress, collateral, userShare, stickyAmount);
                        uint256 hookAmount = (userShare * totalHookSize) / PRECISION;
                        netAmount = netAmount > hookAmount ? netAmount - hookAmount : 0;
                    }
                    
                    if (netAmount > 0) {
                        // Transfer to recipient
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
                        
                        // Update available balance
                        glueCollateral[glueAddress][collateral] -= userShare;
                    }
                }
            }
        }

        // Emit standard event
        emit BatchUnglueExecuted(stickyAssets, stickyAmounts, collaterals, recipients);
    }

    /**
     * @notice Calculate total hook size for a specific glue
     * @param glueAddress Address of the glue
     * @param collateral Address of the collateral
     * @param collateralAmount Amount of collateral being processed
     * @param stickyAmount Amount of sticky tokens being unglued
     * @return totalHookSize Combined hook size in PRECISION units
     */
    function _calculateTotalHookSize(
        address glueAddress,
        address collateral,
        uint256 collateralAmount,
        uint256 stickyAmount
    ) internal view returns (uint256 totalHookSize) {
        if (!hooksEnabled[glueAddress]) return 0;
        
        // Sticky hook based on sticky amount
        uint256 stickyHook = stickyHookSizes[glueAddress];
        
        // Collateral hook based on collateral amount
        uint256 collateralHook = collateralHookSizes[glueAddress][collateral];
        
        // Combine hooks (simple addition, could be more complex)
        totalHookSize = stickyHook + collateralHook;
        
        // Cap at 100%
        if (totalHookSize > PRECISION) {
            totalHookSize = PRECISION;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS - IGlueStickERC20 INTERFACE COMPLIANCE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get expected collateral amounts for batch unglue (IGlueStickERC20 INTERFACE)
     * @param stickyAssets Array of sticky asset addresses
     * @param stickyAmounts Array of amounts to simulate ungluing
     * @param collaterals Array of collateral addresses
     * @return collateralAmounts 2D array of expected amounts
     */
    function getBatchCollaterals(
        address[] calldata stickyAssets,
        uint256[] calldata stickyAmounts,
        address[] calldata collaterals
    ) external view override returns (uint256[][] memory collateralAmounts) {
        collateralAmounts = new uint256[][](stickyAssets.length);
        
        for (uint256 i = 0; i < stickyAssets.length; i++) {
            address stickyAsset = stickyAssets[i];
            uint256 stickyAmount = stickyAmounts[i];
            address glueAddress = stickyAssetToGlue[stickyAsset];
            uint256 totalSupply = mockTotalSupplies[stickyAsset];
            
            uint256[] memory assetAmounts = new uint256[](collaterals.length);
            
            if (glueAddress != address(0) && totalSupply > 0 && stickyAmount > 0) {
                uint256 proportion = (stickyAmount * PRECISION) / totalSupply;
                
                for (uint256 j = 0; j < collaterals.length; j++) {
                    uint256 available = glueCollateral[glueAddress][collaterals[j]];
                    uint256 userShare = (available * proportion) / PRECISION;
                    uint256 protocolFee = (userShare * PROTOCOL_FEE) / PRECISION;
                    uint256 netAmount = userShare - protocolFee;
                    
                    // Apply hooks if enabled
                    if (hooksEnabled[glueAddress]) {
                        uint256 totalHookSize = _calculateTotalHookSize(glueAddress, collaterals[j], userShare, stickyAmount);
                        uint256 hookAmount = (userShare * totalHookSize) / PRECISION;
                        netAmount = netAmount > hookAmount ? netAmount - hookAmount : 0;
                    }
                    
                    assetAmounts[j] = netAmount;
                }
            }
            
            collateralAmounts[i] = assetAmounts;
        }
    }

    function getGlueAddress(address asset) external view override returns (address) {
        return stickyAssetToGlue[asset];
    }

    function isStickyAsset(address asset) external view override returns (bool isSticky, address glueAddress) {
        glueAddress = stickyAssetToGlue[asset];
        isSticky = glueAddress != address(0);
    }

    function allGluesLength() external view override returns (uint256) {
        return registeredAssets.length;
    }

    function getGlueAtIndex(uint256 index) external view override returns (address) {
        return index < registeredAssets.length ? stickyAssetToGlue[registeredAssets[index]] : address(0);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // UNUSED INTERFACE FUNCTIONS - REVERT TO KEEP FOCUS ON BATCH UNGLUE TESTING
    // ═══════════════════════════════════════════════════════════════════════════════════════

    function applyTheGlue(address) external pure override returns (address) {
        revert("Use registerStickyAsset() for mock setup");
    }

    function gluedLoan(address[] calldata, address, uint256, address, bytes calldata) external pure override {
        revert("Use MockGluedLoan for cross-glue loan testing");
    }

    // Minimal implementations for interface compliance
    function checkAsset(address) public pure override returns (bool) { return true; }
    function computeGlueAddress(address asset) external pure override returns (address) { 
        return address(uint160(uint256(keccak256(abi.encodePacked("mock", asset)))));
    }
    function getGluesBalances(address[] calldata, address[] calldata) external pure override returns (uint256[][] memory) {
        revert("Use specific glue contracts for balance queries");
    }
} 