// SPDX-License-Identifier: MIT

/**

███╗   ███╗ ██████╗  ██████╗██╗  ██╗    ██████╗  █████╗ ████████╗ ██████╗██╗  ██╗    ██╗   ██╗███╗   ██╗ ██████╗ ██╗     ██╗   ██╗███████╗
████╗ ████║██╔═══██╗██╔════╝██║ ██╔╝    ██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║  ██║    ██║   ██║████╗  ██║██╔════╝ ██║     ██║   ██║██╔════╝
██╔████╔██║██║   ██║██║     █████╔╝     ██████╔╝███████║   ██║   ██║     ███████║    ██║   ██║██╔██╗ ██║██║  ███╗██║     ██║   ██║█████╗  
██║╚██╔╝██║██║   ██║██║     ██╔═██╗     ██╔══██╗██╔══██║   ██║   ██║     ██╔══██║    ██║   ██║██║╚██╗██║██║   ██║██║     ██║   ██║██╔══╝  
██║ ╚═╝ ██║╚██████╔╝╚██████╗██║  ██╗    ██████╔╝██║  ██║   ██║   ╚██████╗██║  ██║    ╚██████╔╝██║ ╚████║╚██████╔╝███████╗╚██████╔╝███████╗
╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝
                                               ███████╗██████╗  ██████╗███████╗██████╗  ██╗
                                               ██╔════╝██╔══██╗██╔════╝╚════██║╚════██╗███║
                                               █████╗  ██████╔╝██║         ██╔╝ █████╔╝╚██║
                                               ██╔══╝  ██╔══██╗██║        ██╔╝ ██╔═══╝  ██║
                                               ███████╗██║  ██║╚██████╗   ██║  ███████╗ ██║
                                               ╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝  ╚══════╝ ╚═╝

@title Mock Batch Unglue ERC721 - Ultra Simple Testing Mock
@author @BasedToschi
@notice Ultra-simple mock for testing IGlueStickERC721.batchUnglue() functionality with NFT tokenIds parameter
@dev This mock implements the exact IGlueStickERC721.batchUnglue() interface:
     - batchUnglue(stickyAssets[], tokenIds[][], collaterals[], recipients[]) - ERC721 style with 2D tokenIds
     - Manual registration of multiple NFT collections with their glue addresses
     - Individual total supply configuration per collection
     - Manual collateral management per glue
     - Support for hook simulation (optional)
     - NFT count-based proportion calculation per collection

HOW TO USE:
1. Deploy this contract
2. Register NFT collections using registerStickyAsset()
3. Set total supplies for each collection using setMockTotalSupply()
4. Add collateral to each glue using addCollateralToGlue()
5. Call batchUnglue() with IGlueStickERC721 interface and receive tokens from all glues!

EXAMPLE:
mock.registerStickyAsset(collectionA, glueA);
mock.registerStickyAsset(collectionB, glueB);
mock.setMockTotalSupply(collectionA, 10000); // 10k NFT collection A
mock.setMockTotalSupply(collectionB, 5000);  // 5k NFT collection B
mock.addCollateralToGlue(glueA, USDC, 10000e6);
mock.addCollateralToGlue(glueB, USDC, 5000e6);
mock.batchUnglue([collectionA, collectionB], [[1, 2, 3], [100, 200]], [USDC], [alice]);
// Alice gets collateral based on 3/10000 from glueA + 2/5000 from glueB
*/

pragma solidity ^0.8.28;

import {IGlueStickERC721} from '../interfaces/IGlueERC721.sol';

/**
 * @title MockBatchUnglueERC721
 * @notice Ultra-simple mock for testing IGlueStickERC721.batchUnglue() functionality
 * @dev Implements IGlueStickERC721.batchUnglue() interface with 2D tokenIds parameter (ERC721 style)
 * 
 * KEY FEATURES:
 * ✅ IGlueStickERC721.batchUnglue(assets, tokenIds[][], collaterals, recipients) interface
 * ✅ Manual registration of NFT collections and their glues
 * ✅ Individual total supply configuration per collection
 * ✅ Manual collateral management per glue
 * ✅ Support for both single and multiple recipients
 * ✅ Realistic fee calculation (0.1% protocol fee)
 * ✅ Event emission for testing
 * ✅ Hook simulation capabilities
 * ✅ NFT duplicate removal and tracking
 * ✅ Perfect for testing multi-collection NFT strategies
 */
contract MockBatchUnglueERC721 is IGlueStickERC721 {

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONFIGURATION STATE - YOU CONTROL THESE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice Mapping from sticky asset to its mock glue address
    mapping(address => address) public stickyAssetToGlue;
    
    /// @notice Total supply for each NFT collection (asset => total supply)
    mapping(address => uint256) public mockTotalSupplies;
    
    /// @notice Collateral balances for each glue (glue => token => amount)
    mapping(address => mapping(address => uint256)) public glueCollateral;
    
    /// @notice Hook simulation settings per glue
    mapping(address => bool) public hooksEnabled;
    mapping(address => uint256) public stickyHookSizes;
    mapping(address => mapping(address => uint256)) public collateralHookSizes;
    
    /// @notice Burned token IDs tracking per collection (collection => tokenId => burned)
    mapping(address => mapping(uint256 => bool)) public burnedTokenIds;
    
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
        uint256[][] tokenIds,
        address[] collaterals,
        address[] recipients
    );
    
    /// @notice Test setup events
    event StickyAssetRegistered(address indexed asset, address indexed glue);
    event TotalSupplySet(address indexed asset, uint256 totalSupply);
    event CollateralAddedToGlue(address indexed glue, address indexed token, uint256 amount);
    event HooksConfiguredForGlue(address indexed glue, bool enabled, uint256 stickyHookSize);
    event TokenIdsBurnedForCollection(address indexed collection, uint256[] tokenIds);

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
     * @param stickyAsset Address of the ERC721 collection
     * @param glueAddress Address of the mock glue (can be another MockUnglueERC721 contract)
     * 
     * EXAMPLES:
     * registerStickyAsset(collectionA, mockGlueA);
     * registerStickyAsset(collectionB, mockGlueB);
     * registerStickyAsset(collectionC, mockGlueC);
     */
    function registerStickyAsset(address stickyAsset, address glueAddress) external {
        require(stickyAsset != address(0), "Invalid sticky asset");
        require(glueAddress != address(0), "Invalid glue address");
        
        stickyAssetToGlue[stickyAsset] = glueAddress;
        mockTotalSupplies[stickyAsset] = 10000; // Default 10k NFTs
        registeredAssets.push(stickyAsset);
        
        emit StickyAssetRegistered(stickyAsset, glueAddress);
    }

    /**
     * @notice Set total supply for a specific NFT collection
     * @param stickyAsset Address of the NFT collection
     * @param totalSupply Total NFT count in the collection
     * 
     * EXAMPLES:
     * setMockTotalSupply(collectionA, 10000); // 10k NFT collection
     * setMockTotalSupply(collectionB, 5555);  // 5.5k NFT collection
     * setMockTotalSupply(collectionC, 1);     // 1/1 NFT
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
     * @param stickyHook Hook size for sticky NFTs (in PRECISION units)
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
     * addCollateralToGlue(glueA, USDC, 10000e6); // Add 10k USDC to glue A
     * addCollateralToGlue(glueB, USDC, 5000e6);  // Add 5k USDC to glue B
     * addCollateralToGlue(glueA, WETH, 100e18);  // Add 100 WETH to glue A
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
     * EXAMPLE: addETHToGlue{value: 50e18}(glueA); // Add 50 ETH to glue A
     */
    function addETHToGlue(address glueAddress) external payable {
        require(msg.value > 0, "Must send ETH");
        
        glueCollateral[glueAddress][address(0)] += msg.value;
        emit CollateralAddedToGlue(glueAddress, address(0), msg.value);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // MAIN BATCH UNGLUE FUNCTION - IGlueStickERC721 INTERFACE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Batch unglue multiple sticky NFT collections (IGlueStickERC721 INTERFACE)
     * @param stickyAssets Array of NFT collection addresses
     * @param tokenIds 2D array of token IDs to unglue for each collection (ERC721 style)
     * @param collaterals Array of collateral addresses to withdraw
     * @param recipients Array of recipients (single recipient for all, or one per collection)
     * 
     * LOGIC:
     * 1. For each NFT collection:
     * 2. Remove duplicates from tokenIds array
     * 3. Calculate proportion = uniqueCount / totalSupply
     * 4. Get registered glue address
     * 5. For each collateral:
     * 6. Calculate user share = glueBalance * proportion
     * 7. Apply protocol fee (0.1%) and hooks if enabled
     * 8. Transfer net amount to recipient
     * 9. Emit standard event
     * 
     * EXAMPLE:
     * // Setup
     * mock.registerStickyAsset(collectionA, glueA);
     * mock.registerStickyAsset(collectionB, glueB);
     * mock.setMockTotalSupply(collectionA, 10000); // 10k NFTs
     * mock.setMockTotalSupply(collectionB, 5000);  // 5k NFTs
     * mock.addCollateralToGlue(glueA, USDC, 10000e6);
     * mock.addCollateralToGlue(glueB, USDC, 5000e6);
     * 
     * // Execute
     * uint256[][] memory tokenIds = new uint256[][](2);
     * tokenIds[0] = [1, 2, 3];    // 3 NFTs from collection A
     * tokenIds[1] = [100, 200];   // 2 NFTs from collection B
     * mock.batchUnglue([collectionA, collectionB], tokenIds, [USDC], [alice]);
     * // Alice gets 0.03% from glueA (3/10000) + 0.04% from glueB (2/5000) = 3 + 2 = 5 USDC (minus fees)
     */
    function batchUnglue(
        address[] calldata stickyAssets,
        uint256[][] calldata tokenIds,
        address[] calldata collaterals,
        address[] calldata recipients
    ) external override {
        require(stickyAssets.length > 0, "No assets specified");
        require(stickyAssets.length == tokenIds.length, "Assets/tokenIds mismatch");
        require(collaterals.length > 0, "No collaterals specified");
        require(recipients.length > 0, "No recipients specified");
        require(
            recipients.length == 1 || recipients.length == stickyAssets.length,
            "Invalid recipients count"
        );

        // Process each NFT collection
        for (uint256 i = 0; i < stickyAssets.length; i++) {
            address stickyAsset = stickyAssets[i];
            uint256[] calldata collectionTokenIds = tokenIds[i];
            address glueAddress = stickyAssetToGlue[stickyAsset];
            uint256 totalSupply = mockTotalSupplies[stickyAsset];
            
            require(glueAddress != address(0), "Asset not registered");
            require(collectionTokenIds.length > 0, "No token IDs for collection");
            require(totalSupply > 0, "Total supply not set");
            
            // Remove duplicates and count unique token IDs
            uint256 uniqueCount = _processTokenIdsForCollection(stickyAsset, collectionTokenIds);
            require(uniqueCount > 0, "No valid token IDs for collection");
            
            // Calculate proportion: uniqueCount / totalSupply
            uint256 proportion = (uniqueCount * PRECISION) / totalSupply;
            
            // Determine recipient for this collection
            address recipient = recipients.length == 1 ? recipients[0] : recipients[i];
            require(recipient != address(0), "Invalid recipient");
            
            // Process each collateral for this collection
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
                        uint256 totalHookSize = _calculateTotalHookSize(glueAddress, collateral, userShare, uniqueCount);
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
        emit BatchUnglueExecuted(stickyAssets, tokenIds, collaterals, recipients);
    }

    /**
     * @notice Process token IDs for a collection, remove duplicates, and track burned tokens
     * @param collection Address of the NFT collection
     * @param tokenIds Array of token IDs to process
     * @return uniqueCount Number of unique token IDs processed
     */
    function _processTokenIdsForCollection(
        address collection,
        uint256[] calldata tokenIds
    ) internal returns (uint256 uniqueCount) {
        uint256[] memory uniqueTokenIds = new uint256[](tokenIds.length);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            // Skip if already burned for this collection
            if (burnedTokenIds[collection][tokenId]) continue;
            
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
                burnedTokenIds[collection][tokenId] = true;
                uniqueCount++;
            }
        }
        
        // Emit tracking event
        if (uniqueCount > 0) {
            uint256[] memory processed = new uint256[](uniqueCount);
            for (uint256 i = 0; i < uniqueCount; i++) {
                processed[i] = uniqueTokenIds[i];
            }
            emit TokenIdsBurnedForCollection(collection, processed);
        }
    }

    /**
     * @notice Calculate total hook size for a specific glue
     * @param glueAddress Address of the glue
     * @param collateral Address of the collateral
     * @param collateralAmount Amount of collateral being processed
     * @param nftCount Number of NFTs being unglued
     * @return totalHookSize Combined hook size in PRECISION units
     */
    function _calculateTotalHookSize(
        address glueAddress,
        address collateral,
        uint256 collateralAmount,
        uint256 nftCount
    ) internal view returns (uint256 totalHookSize) {
        if (!hooksEnabled[glueAddress]) return 0;
        
        // Sticky hook based on NFT count
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
    // VIEW FUNCTIONS - IGlueStickERC721 INTERFACE COMPLIANCE
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get expected collateral amounts for batch unglue (IGlueStickERC721 INTERFACE)
     * @param stickyAssets Array of NFT collection addresses
     * @param stickyAmounts Array of NFT counts to simulate ungluing (number of NFTs, not IDs)
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
            uint256 nftCount = stickyAmounts[i];
            address glueAddress = stickyAssetToGlue[stickyAsset];
            uint256 totalSupply = mockTotalSupplies[stickyAsset];
            
            uint256[] memory assetAmounts = new uint256[](collaterals.length);
            
            if (glueAddress != address(0) && totalSupply > 0 && nftCount > 0) {
                uint256 proportion = (nftCount * PRECISION) / totalSupply;
                
                for (uint256 j = 0; j < collaterals.length; j++) {
                    uint256 available = glueCollateral[glueAddress][collaterals[j]];
                    uint256 userShare = (available * proportion) / PRECISION;
                    uint256 protocolFee = (userShare * PROTOCOL_FEE) / PRECISION;
                    uint256 netAmount = userShare - protocolFee;
                    
                    // Apply hooks if enabled
                    if (hooksEnabled[glueAddress]) {
                        uint256 totalHookSize = _calculateTotalHookSize(glueAddress, collaterals[j], userShare, nftCount);
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

    /**
     * @notice Check if a token ID has been burned for a specific collection
     * @param collection Address of the NFT collection
     * @param tokenId Token ID to check
     * @return Whether the token ID has been burned
     */
    function isTokenIdBurnedForCollection(address collection, uint256 tokenId) external view returns (bool) {
        return burnedTokenIds[collection][tokenId];
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
        return address(uint160(uint256(keccak256(abi.encodePacked("mock721", asset)))));
    }
    function getGluesBalances(address[] calldata, address[] calldata) external pure override returns (uint256[][] memory) {
        revert("Use specific glue contracts for balance queries");
    }
} 