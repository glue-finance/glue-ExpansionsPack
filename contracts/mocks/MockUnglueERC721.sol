// SPDX-License-Identifier: MIT

/**

███╗   ███╗ ██████╗  ██████╗██╗  ██╗    ██╗   ██╗███╗   ██╗ ██████╗ ██╗     ██╗   ██╗███████╗
████╗ ████║██╔═══██╗██╔════╝██║ ██╔╝    ██║   ██║████╗  ██║██╔════╝ ██║     ██║   ██║██╔════╝
██╔████╔██║██║   ██║██║     █████╔╝     ██║   ██║██╔██╗ ██║██║  ███╗██║     ██║   ██║█████╗  
██║╚██╔╝██║██║   ██║██║     ██╔═██╗     ██║   ██║██║╚██╗██║██║   ██║██║     ██║   ██║██╔══╝  
██║ ╚═╝ ██║╚██████╔╝╚██████╗██║  ██╗    ╚██████╔╝██║ ╚████║╚██████╔╝███████╗╚██████╔╝███████╗
╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝
                                   ███████╗██████╗  ██████╗███████╗██████╗  ██╗
                                   ██╔════╝██╔══██╗██╔════╝╚════██║╚════██╗███║
                                   █████╗  ██████╔╝██║         ██╔╝ █████╔╝╚██║
                                   ██╔══╝  ██╔══██╗██║        ██╔╝ ██╔═══╝  ██║
                                   ███████╗██║  ██║╚██████╗   ██║  ███████╗ ██║
                                   ╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝  ╚══════╝ ╚═╝

@title Mock Unglue ERC721 - Ultra Simple Testing Mock
@author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi
@notice Ultra-simple mock for testing IGlueERC721.unglue() functionality with NFT tokenIds parameter
@dev This mock implements the exact IGlueERC721.unglue() interface:
     - unglue(collaterals[], tokenIds[], recipient) - ERC721 style with tokenIds array parameter
     - Manual configuration of supply delta and collateral balances
     - Realistic fee calculation and event emission
     - ACCURATE hook simulation matching real GlueERC721.sol behavior
     - NFT count-based proportion calculation

ACCURATE HOOK SIMULATION:
This mock now implements the exact hook behavior from the real Glue Protocol for NFTs:

Phase 1: Sticky Asset Hooks (for NFTs)
         - Applied via tryHook(stickyAsset, uniqueCount, tokenIds)
         - Does NOT transfer any amount to sticky asset  
         - Still calls executeHook with NFT count and actual tokenIds array
         - Returns 0 (no amount reduction)
         - Used for tracking burned NFT IDs in expanded integrations

Phase 2: Collateral Hooks (for ERC20/ETH)
         - Applied via tryHook(collateral, netAmount, tokenIds)
         - Transfers hook amount to sticky asset (simulated)
         - Calls executeHook with hookAmount and tokenIds  
         - Returns netAmount - hookAmount
         - Same behavior as ERC20 ungluing

Hook Interface Simulation:
- hasHook() -> returns hooksEnabled && bio == 2
- hookSize(asset, amount) -> returns mockHookSizes[asset]
- executeHook(asset, amount, tokenIds) -> simulated execution with NFT tracking
- Proper BIO state management (0=UNCHECKED, 1=NO_HOOK, 2=HOOK)

HOW TO USE:
1. Deploy this contract
2. Call setStickyAsset() with your ERC721 collection address  
3. Call setMockTotalSupply() with total NFT count (e.g., 10000)
4. Call addCollateral() for each token you want to be available
5. Configure hooks with configureHooks() and setAssetHookSize()
6. Call unglue() with the IGlueERC721 interface: unglue(collaterals, tokenIds, recipient)

EXAMPLE WITH ACCURATE HOOKS:
mockUnglue.setStickyAsset(myNFTCollection);
mockUnglue.setMockTotalSupply(10000); // 10k NFT collection
mockUnglue.addCollateral(USDC, 100000e6); // 100k USDC available
mockUnglue.configureHooks(true, 0); // Enable hooks but no sticky hook economic impact
mockUnglue.setAssetHookSize(USDC, 2e16); // 2% USDC collateral hook
mockUnglue.unglue([USDC], [1, 2, 3], alice); // Burn 3 NFTs
// Phase 1: tryHook(myNFTCollection, 3, [1,2,3]) -> tracks NFT burns, returns 0
// Phase 2: tryHook(USDC, netAmount) -> transfers 2% to collection, Alice gets remainder
// Alice receives collateral based on 3/10000 = 0.03% minus USDC hooks and protocol fees
*/

pragma solidity ^0.8.28;

import {IGlueERC721} from '../interfaces/IGlueERC721.sol';

/**
 * @title MockUnglueERC721
 * @notice Ultra-simple mock for testing IGlueERC721.unglue() functionality
 * @dev Implements IGlueERC721.unglue() interface with tokenIds parameter (ERC721 style)
 * 
 * KEY FEATURES:
 * ✅ IGlueERC721.unglue(collaterals, tokenIds[], recipient) interface
 * ✅ Manual setup of all parameters
 * ✅ NFT count-based proportion calculation
 * ✅ Manual collateral balance management
 * ✅ Support for both ERC20 tokens and ETH
 * ✅ Realistic fee calculation (0.1% protocol fee)
 * ✅ Event emission matching real protocol
 * ✅ Hook simulation capabilities
 * ✅ Complete control over test scenarios
 */
contract MockUnglueERC721 is IGlueERC721 {

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONFIGURATION STATE - YOU CONTROL THESE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice The sticky asset address (ERC721 collection)
    address public stickyAsset;
    
    /// @notice Mock total supply of the NFT collection (for calculations)
    uint256 public mockTotalSupply = 10000; // 10k NFTs default
    
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
    
    /// @notice Track executeHook calls for testing verification
    mapping(address => uint256) public totalHookExecutions;
    
    /// @notice Struct to track executeHook call details
    struct ExecuteHookCall {
        address asset;
        uint256 amount;
        uint256[] tokenIds;
        uint256 timestamp;
    }
    
    /// @notice Last executeHook call details (for testing verification)
    ExecuteHookCall public lastExecuteHookCall;
    
    /// @notice Burned token IDs tracking (for testing)
    mapping(uint256 => bool) public burnedTokenIds;
    uint256[] public allBurnedTokenIds;
    
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
    event TotalSupplySet(uint256 totalSupply);
    event CollateralAdded(address indexed token, uint256 amount);
    event HooksConfigured(bool enabled, uint256 stickyHookSize);
    event TokenIdsBurned(uint256[] tokenIds);

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
     * @notice Set the sticky asset address for this mock (ERC721 collection)
     * @param asset Address of your ERC721 collection
     * 
     * EXAMPLE: setStickyAsset(0x1234...); // Your NFT collection address
     */
    function setStickyAsset(address asset) external {
        stickyAsset = asset;
        emit StickyAssetSet(asset);
    }

    /**
     * @notice Set the mock total supply for calculations (total NFT count)
     * @param totalSupply Total NFT count in the collection
     * 
     * EXAMPLES:
     * setMockTotalSupply(10000); // 10k NFT collection
     * setMockTotalSupply(5555);  // 5.5k NFT collection
     * setMockTotalSupply(1);     // 1/1 NFT
     */
    function setMockTotalSupply(uint256 totalSupply) external {
        require(totalSupply > 0, "Total supply must be positive");
        mockTotalSupply = totalSupply;
        emit TotalSupplySet(totalSupply);
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
    // MAIN UNGLUE FUNCTION - IGlueERC721 INTERFACE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Unglue sticky NFTs to receive collateral (IGlueERC721 INTERFACE)
     * @param collaterals Array of collateral addresses to withdraw
     * @param tokenIds Array of NFT token IDs to burn (ERC721 style)
     * @param recipient Address to receive the collateral
     * @return supplyDelta The calculated supply delta based on NFT count
     * @return realAmount The number of unique NFTs processed (after removing duplicates)
     * @return beforeTotalSupply Mock total supply
     * @return afterTotalSupply Mock total supply minus processed NFTs
     * 
     * LOGIC (MATCHES REAL PROTOCOL):
     * 1. Remove duplicates from tokenIds array
     * 2. Apply sticky asset hooks via tryHook(stickyAsset, uniqueCount, tokenIds)
     * 3. Calculate proportion based on uniqueCount / totalSupply  
     * 4. For each collateral: userShare = availableBalance * proportion
     * 5. Apply collateral hooks via tryHook(collateral, netAmount, tokenIds)
     * 6. Transfer final amount to recipient
     * 7. Emit standard unglued event
     * 
     * EXAMPLE:
     * mockUnglue.setStickyAsset(myNFTCollection);
     * mockUnglue.setMockTotalSupply(10000); // 10k NFT collection
     * mockUnglue.addCollateral(USDC, 100000e6); // 100k USDC
     * mockUnglue.configureHooks(true, 0); // Enable hooks but no sticky hook impact
     * mockUnglue.setAssetHookSize(USDC, 2e16); // 2% USDC hook
     * mockUnglue.unglue([USDC], [1, 2, 3], alice); // Burn 3 NFTs (0.03%)
     * // tryHook(myNFTCollection, 3, [1,2,3]) -> tracks NFT burns, returns 0
     * // Alice receives collateral based on 3/10000 = 0.03% (minus USDC hooks and fees)
     */
    function unglue(
        address[] calldata collaterals,
        uint256[] calldata tokenIds,
        address recipient
    ) external override returns (uint256, uint256, uint256, uint256) {
        require(stickyAsset != address(0), "Sticky asset not set");
        require(tokenIds.length > 0, "No token IDs provided");
        require(recipient != address(0), "Invalid recipient");
        require(collaterals.length > 0, "No collaterals specified");

        // Remove duplicates and count unique token IDs
        uint256 uniqueCount = _processTokenIds(tokenIds);
        require(uniqueCount > 0, "No valid token IDs");

        // Get processed token IDs for hook call
        uint256[] memory processedTokenIds = _getLastProcessedTokenIds(uniqueCount);

        // PHASE 1: Apply sticky asset hooks (matches real protocol)
        if (bio == 0 || bio == 2) { // UNCHECKED or HOOK
            tryHook(stickyAsset, uniqueCount, processedTokenIds);
            // Note: For NFTs, this returns 0 (no amount reduction)
        }

        // Calculate supply metrics for event
        uint256 beforeSupply = mockTotalSupply;
        uint256 afterSupply = beforeSupply - uniqueCount;
        
        // Calculate proportion: uniqueCount / totalSupply
        uint256 proportion = (uniqueCount * PRECISION) / beforeSupply;

        // PHASE 2: Process each collateral with hooks (matches real protocol)
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
                    netAmount = tryHook(collateral, netAmount, processedTokenIds);
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

        // Emit standard event
        emit unglued(recipient, uniqueCount, beforeSupply, afterSupply, proportion);
        
        return (proportion, uniqueCount, beforeSupply, afterSupply);
    }

    /**
     * @notice Process token IDs array, remove duplicates, and track burned tokens
     * @param tokenIds Array of token IDs to process
     * @return uniqueCount Number of unique token IDs processed
     */
    function _processTokenIds(uint256[] calldata tokenIds) internal returns (uint256 uniqueCount) {
        uint256[] memory uniqueTokenIds = new uint256[](tokenIds.length);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            // Skip if already burned
            if (burnedTokenIds[tokenId]) continue;
            
            // Check for duplicates in current batch
            bool isDuplicate = false;
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (uniqueTokenIds[j] == tokenId) {
                    isDuplicate = true;
                    break;
                }
            }
            
            if (!isDuplicate) {
                uniqueTokenIds[uniqueCount] = tokenId;
                burnedTokenIds[tokenId] = true;
                allBurnedTokenIds.push(tokenId);
                uniqueCount++;
            }
        }
        
        // Emit tracking event
        if (uniqueCount > 0) {
            uint256[] memory processed = new uint256[](uniqueCount);
            for (uint256 i = 0; i < uniqueCount; i++) {
                processed[i] = uniqueTokenIds[i];
            }
            emit TokenIdsBurned(processed);
        }
    }

    /**
     * @notice Get the last processed token IDs for hook calls
     * @param count Number of token IDs to get
     * @return Array of the last processed token IDs
     */
    function _getLastProcessedTokenIds(uint256 count) internal view returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](count);
        uint256 totalBurned = allBurnedTokenIds.length;
        
        for (uint256 i = 0; i < count && i < totalBurned; i++) {
            tokenIds[i] = allBurnedTokenIds[totalBurned - count + i];
        }
        
        return tokenIds;
    }

    /**
     * @notice Simulate the real protocol's tryHook function behavior for NFTs
     * @param asset The address of the asset being processed
     * @param amount The amount to process (number of NFTs or collateral amount)
     * @param tokenIds The token IDs array (for sticky asset hooks)
     * @return The amount remaining after hook processing
     * 
     * This function replicates the exact logic from GlueERC721.tryHook():
     * 
     * FOR STICKY ASSET (NFTs):
     * - Does NOT transfer any amount to sticky asset
     * - Still calls executeHook with amount (NFT count) and tokenIds
     * - Returns 0 (no amount reduction)
     * - Used for tracking burned NFT IDs in expanded integrations
     * 
     * FOR COLLATERALS (ERC20/ETH):
     * - Same as ERC20: transfers hook amount to sticky asset
     * - Calls executeHook with hookAmount and tokenIds
     * - Returns amount - hookAmount
     */
    function tryHook(address asset, uint256 amount, uint256[] memory tokenIds) internal returns (uint256) {
        // If hooks are disabled, return original amount
        if (!hooksEnabled) return amount;
        
        // FOR STICKY ASSET (NFTs) - matches real protocol special case
        if (asset == stickyAsset) {
            // This hook doesn't send amount to the sticky token, but is designed 
            // to track for expanded integration the burned IDs.
            if (bio == 0 || bio == 2) { // UNCHECKED or HOOK
                
                // Simulate hook status detection
                if (bio == 0) { // UNCHECKED
                    bio = hooksEnabled ? 2 : 1; // Set to HOOK or NO_HOOK
                }
                
                if (bio == 2) { // HOOK
                    // Track the executeHook call for testing (with tokenIds)
                    totalHookExecutions[asset]++;
                    lastExecuteHookCall = ExecuteHookCall({
                        asset: asset,
                        amount: amount,
                        tokenIds: tokenIds,
                        timestamp: block.timestamp
                    });
                    
                    // In real protocol: IGluedHooks(STICKY_ASSET).executeHook(asset, amount, tokenIds)
                    // No amount transfer, just tracking
                }
            }
            
            // Return 0 (no amount reduction for sticky asset hooks)
            return 0;
            
        } else {
            // FOR COLLATERALS (ERC20/ETH) - same as ERC20 behavior
            uint256 hookAmount = 0;

            // Simulate hook detection (matches real protocol's hasHook() check)
            if (bio == 0) { // UNCHECKED
                bio = hooksEnabled ? 2 : 1; // Set to HOOK or NO_HOOK
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
                totalHookAmountsTransferred[asset] += hookAmount;
            } else {
                // For ERC20, simulate transfer to sticky asset
                totalHookAmountsTransferred[asset] += hookAmount;
                
                // Reduce available collateral to simulate the transfer
                availableCollateral[asset] = availableCollateral[asset] >= hookAmount ? 
                    availableCollateral[asset] - hookAmount : 0;
            }
            
            // Track the executeHook call for testing
            totalHookExecutions[asset]++;
            lastExecuteHookCall = ExecuteHookCall({
                asset: asset,
                amount: hookAmount,
                tokenIds: tokenIds,
                timestamp: block.timestamp
            });
            
            // Simulate executeHook call (matches real protocol)
            // In real protocol: IGluedHooks(STICKY_ASSET).executeHook(asset, hookAmount, tokenIds)
            
            // Return amount minus hook amount (matches real protocol)
            return amount - hookAmount;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS - IGlueERC721 INTERFACE COMPLIANCE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Preview the two-phase hook calculation for NFT ungluing
     * @param tokenIds Array of token IDs to preview (checks for duplicates and burned status)
     * @param collateral Specific collateral to check
     * @return validNftCount Number of valid NFTs after removing duplicates and burned tokens
     * @param stickyHookAmount Always 0 for NFTs (hooks don't reduce amounts, just track IDs)
     * @param proportion Proportion of total supply (based on valid NFT count)
     * @param userShare Raw collateral share before collateral hooks
     * @param collateralHookAmount Amount taken by collateral hooks
     * @param protocolFee Protocol fee amount
     * @param finalAmount Final amount user receives
     * 
     * EXAMPLE:
     * (validCount, stickyHook, proportion, userShare, collateralHook, protocolFee, finalAmount) = 
     *   previewHookCalculation([1, 2, 3, 2], USDC);  // Token 2 is duplicate
     * // Returns: validCount=3, stickyHook=0, proportion based on 3 NFTs, etc.
     */
    function previewHookCalculation(
        uint256[] calldata tokenIds,
        address collateral
    ) external view returns (
        uint256 validNftCount,
        uint256 stickyHookAmount,
        uint256 proportion,
        uint256 userShare,
        uint256 collateralHookAmount,
        uint256 protocolFee,
        uint256 finalAmount
    ) {
        if (mockTotalSupply == 0 || tokenIds.length == 0) return (0, 0, 0, 0, 0, 0, 0);
        
        // Count valid NFTs (remove duplicates and burned tokens)
        validNftCount = _previewTokenIdValidation(tokenIds);
        if (validNftCount == 0) return (0, 0, 0, 0, 0, 0, 0);
        
        // PHASE 1: Sticky asset hooks (always 0 for NFTs)
        stickyHookAmount = 0; // NFT hooks don't reduce amounts, just track IDs
        
        // Calculate proportion based on valid NFT count
        proportion = (validNftCount * PRECISION) / mockTotalSupply;
        
        // PHASE 2: Collateral distribution
        uint256 available = availableCollateral[collateral];
        if (available == 0) return (validNftCount, 0, proportion, 0, 0, 0, 0);
        
        // Calculate user share
        userShare = (available * proportion) / PRECISION;
        
        // Apply protocol fee
        protocolFee = (userShare * PROTOCOL_FEE) / PRECISION;
        uint256 afterFee = userShare - protocolFee;
        
        // Apply collateral hooks if enabled
        if (hooksEnabled && bio == 2) {
            uint256 hookSize = mockHookSizes[collateral];
            if (hookSize > PRECISION) hookSize = PRECISION;
            collateralHookAmount = (userShare * hookSize) / PRECISION;
            finalAmount = afterFee > collateralHookAmount ? afterFee - collateralHookAmount : 0;
        } else {
            collateralHookAmount = 0;
            finalAmount = afterFee;
        }
    }

    /**
     * @notice Preview token ID validation without burning them
     * @param tokenIds Array of token IDs to validate
     * @return validCount Number of valid unique non-burned token IDs
     */
    function _previewTokenIdValidation(uint256[] calldata tokenIds) internal view returns (uint256 validCount) {
        uint256[] memory seenTokenIds = new uint256[](tokenIds.length);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            // Skip if already burned
            if (burnedTokenIds[tokenId]) continue;
            
            // Check for duplicates in current batch
            bool isDuplicate = false;
            for (uint256 j = 0; j < validCount; j++) {
                if (seenTokenIds[j] == tokenId) {
                    isDuplicate = true;
                    break;
                }
            }
            
            if (!isDuplicate) {
                seenTokenIds[validCount] = tokenId;
                validCount++;
            }
        }
    }

    /**
     * @notice Preview hook calculation with NFT count instead of token IDs
     * @param nftCount Number of NFTs to simulate burning
     * @param collateral Specific collateral to check
     * @return validNftCount Same as input (no validation needed)
     * @return stickyHookAmount Always 0 for NFTs
     * @return proportion Proportion of total supply
     * @return userShare Raw collateral share
     * @return collateralHookAmount Amount taken by collateral hooks
     * @return protocolFee Protocol fee amount
     * @return finalAmount Final amount user receives
     * 
     * EXAMPLE:
     * (count, stickyHook, proportion, userShare, collateralHook, protocolFee, finalAmount) = 
     *   previewHookCalculationByCount(5, USDC);  // Simulate burning 5 NFTs
     */
    function previewHookCalculationByCount(
        uint256 nftCount,
        address collateral
    ) external view returns (
        uint256 validNftCount,
        uint256 stickyHookAmount,
        uint256 proportion,
        uint256 userShare,
        uint256 collateralHookAmount,
        uint256 protocolFee,
        uint256 finalAmount
    ) {
        if (mockTotalSupply == 0 || nftCount == 0) return (0, 0, 0, 0, 0, 0, 0);
        
        validNftCount = nftCount;
        stickyHookAmount = 0; // Always 0 for NFTs
        
        // Calculate proportion
        proportion = (nftCount * PRECISION) / mockTotalSupply;
        
        // Calculate collateral amounts
        uint256 available = availableCollateral[collateral];
        if (available == 0) return (validNftCount, 0, proportion, 0, 0, 0, 0);
        
        userShare = (available * proportion) / PRECISION;
        protocolFee = (userShare * PROTOCOL_FEE) / PRECISION;
        uint256 afterFee = userShare - protocolFee;
        
        // Apply hooks if enabled
        if (hooksEnabled && bio == 2) {
            uint256 hookSize = mockHookSizes[collateral];
            if (hookSize > PRECISION) hookSize = PRECISION;
            collateralHookAmount = (userShare * hookSize) / PRECISION;
            finalAmount = afterFee > collateralHookAmount ? afterFee - collateralHookAmount : 0;
        } else {
            collateralHookAmount = 0;
            finalAmount = afterFee;
        }
    }

    function getSupplyDelta(uint256 stickyAmount) public view override returns (uint256) {
        if (mockTotalSupply == 0) return 0;
        return (stickyAmount * PRECISION) / mockTotalSupply;
    }

    function collateralByAmount(
        uint256 stickyAmount,
        address[] calldata collaterals
    ) external view override returns (uint256[] memory amounts) {
        amounts = new uint256[](collaterals.length);
        uint256 proportion = getSupplyDelta(stickyAmount);
        
        for (uint256 i = 0; i < collaterals.length; i++) {
            uint256 available = availableCollateral[collaterals[i]];
            uint256 userShare = (available * proportion) / PRECISION;
            uint256 protocolFee = (userShare * PROTOCOL_FEE) / PRECISION;
            uint256 netAmount = userShare - protocolFee;
            
            // Apply hooks if enabled
            if (hooksEnabled) {
                uint256 totalHookSize = _calculateTotalHookSize(collaterals[i], userShare, stickyAmount);
                uint256 hookAmount = (userShare * totalHookSize) / PRECISION;
                netAmount = netAmount > hookAmount ? netAmount - hookAmount : 0;
            }
            
            amounts[i] = netAmount;
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

    function getTotalHookSize(address collateral, uint256 collateralAmount) external view override returns (uint256) {
        return _calculateTotalHookSize(collateral, collateralAmount, 1); // Assume 1 NFT for view function
    }

    /**
     * @notice Get all burned token IDs (for testing)
     * @return Array of all burned token IDs
     */
    function getAllBurnedTokenIds() external view returns (uint256[] memory) {
        return allBurnedTokenIds;
    }

    /**
     * @notice Check if a token ID has been burned
     * @param tokenId Token ID to check
     * @return Whether the token ID has been burned
     */
    function isTokenIdBurned(uint256 tokenId) external view returns (bool) {
        return burnedTokenIds[tokenId];
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
     * @notice Get total number of executeHook calls for an asset
     * @param asset Address of the asset
     * @return totalExecutions Total number of hook executions
     */
    function getHookExecutionCount(address asset) external view returns (uint256 totalExecutions) {
        return totalHookExecutions[asset];
    }

    /**
     * @notice Get details of the last executeHook call
     * @return asset Address of the asset
     * @return amount Amount passed to executeHook
     * @return tokenIds Token IDs passed to executeHook
     * @return timestamp When the call was made
     */
    function getLastExecuteHookCall() external view returns (
        address asset,
        uint256 amount,
        uint256[] memory tokenIds,
        uint256 timestamp
    ) {
        ExecuteHookCall memory call = lastExecuteHookCall;
        return (call.asset, call.amount, call.tokenIds, call.timestamp);
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
    function getStickySupplyStored() external view override returns (uint256) { return allBurnedTokenIds.length; }
    function getSettings() external pure override returns (address) { return address(0); }
    function getGlueStick() external view override returns (address) { return address(this); }
    function isExpanded() external pure override returns (BIO) { return BIO.NO_HOOK; }
    function getSelfLearning() external pure override returns (bool, bool) { return (false, false); }

    /**
     * @notice Calculate total hook size for collateral and sticky NFTs (LEGACY)
     * @dev This function is deprecated but kept for backward compatibility
     * @param collateral Address of the collateral
     * @param collateralAmount Amount of collateral being processed
     * @param nftCount Number of NFTs being unglued
     * @return totalHookSize Combined hook size in PRECISION units
     */
    function _calculateTotalHookSize(
        address collateral,
        uint256 collateralAmount,
        uint256 nftCount
    ) internal view returns (uint256 totalHookSize) {
        if (!hooksEnabled || bio != 2) return 0;
        
        // Return the specific hook size for this collateral (matches real protocol)
        uint256 hookSize = mockHookSizes[collateral];
        return hookSize > PRECISION ? PRECISION : hookSize;
    }
} 