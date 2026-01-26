// SPDX-License-Identifier: MIT
/**
 * ═══════════════════════════════════════════════════════════════════════════════
 *
 *    ██╗███████╗██████╗  ██████╗███████╗██████╗  ██╗ ██████╗
 *    ██║██╔════╝██╔══██╗██╔════╝╚════██║╚════██╗███║██╔════╝
 *    ██║█████╗  ██████╔╝██║         ██╔╝ █████╔╝╚██║██║  ███╗
 *    ██║██╔══╝  ██╔══██╗██║        ██╔╝ ██╔═══╝  ██║██║   ██║
 *    ██║███████╗██║  ██║╚██████╗   ██║  ███████╗ ██║╚██████╔╝
 *    ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝  ╚══════╝ ╚═╝ ╚═════╝
 *
 *    Interface for the ERC721 Glue Standard with On-Chain Royalty Enforcement
 *
 * ═══════════════════════════════════════════════════════════════════════════════
 *
 * @title IERC721G - Interface for ERC721 Glue Standard
 * @author Glue Protocol
 * @notice Interface for NFT collections implementing on-chain royalty enforcement.
 *         Supports deferred payments, token locking, and approval seizure.
 *
 * @dev Key features exposed through this interface:
 *      
 *      ROYALTY ENFORCEMENT:
 *      - Items can be "locked" if royalties aren't paid during transfer
 *      - Locked items cannot be transferred until royalties are cleared
 *      - Approval seizure prevents listing locked items on marketplaces
 *      
 *      PAYMENT PROCESSING:
 *      - processRoyalties(): Distribute accumulated royalties to receivers
 *      - unlockItems(): Pay royalties to unlock specific items
 *      
 *      QUERY FUNCTIONS:
 *      - isItemLocked(): Check if a specific item is locked
 *      - getRoyaltyOwed(): Get locked items and payment amount from a list of IDs
 *
 */

pragma solidity ^0.8.28;

interface IERC721G {

    // ═══════════════════════════════════════════════════════════════════════════
    // EVENTS - Royalty Configuration Changes
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice Unified event for all royalty configuration changes
    /// @dev Covers: add receiver (oldShare=0), update share, remove receiver (newShare=0),
    ///      toggle enforcement (receiver=address(0), oldShare=0, newShare=0)
    /// @param receiver Address of receiver (address(0) for toggle-only)
    /// @param oldShare Previous BPS share (0 for add/toggle)
    /// @param newShare New BPS share (0 for remove/toggle)
    /// @param totalRoyalty Current total royalty BPS after change
    /// @param active Current enforcement status
    event RoyaltiesUpdated(
        address indexed receiver,
        uint256 oldShare,
        uint256 newShare,
        uint256 totalRoyalty,
        bool active
    );

    /// @notice Emitted once at deployment with initial configuration
    /// @param contractURI ERC-7572 contract metadata URI
    /// @param receivers All royalty receivers (index 0 is GLUE)
    /// @param sharesBps Corresponding shares in BPS for each receiver
    /// @param totalRoyaltyBps Total royalty percentage
    /// @param royaltyActive Whether enforcement is initially active
    event ERC721GInitialized(
        string contractURI,
        address[] receivers,
        uint256[] sharesBps,
        uint256 totalRoyaltyBps,
        bool royaltyActive
    );

    /// @notice Emitted when an address's exemption status changes
    /// @dev Exempt addresses can transfer locked items without paying royalties
    /// @param addr Address whose status changed
    /// @param exempt True if now exempt, false if revoked
    event ExemptAddressUpdated(address indexed addr, bool exempt);

    // ═══════════════════════════════════════════════════════════════════════════
    // EVENTS - Royalty Payments and Token Locking
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice Emitted when royalty processing occurs (in _processRoyaltySplit)
    /// @dev Single consolidated event for all royalty processing - easier to index off-chain
    /// @param executorReward The 0.05% reward for the triggering party
    /// @param itemsUnlocked Number of items unlocked during this processing
    /// @param collateralValue Current ETH+WETH collateral per NFT from GLUE
    /// @param totalSupply Current total supply at time of processing
    event RoyaltyProcessed(uint256 executorReward, uint256 itemsUnlocked, uint256 collateralValue, uint256 totalSupply);

    /// @notice Emitted when an item becomes locked (unpaid royalty)
    /// @param itemId ID of the locked item
    event ItemLocked(uint256 indexed itemId);

    /// @notice Emitted when an item is unlocked (royalty paid)
    /// @param itemId ID of the unlocked item
    event ItemUnlocked(uint256 indexed itemId);

    /// @notice Emitted when approve2 allowance is set
    /// @param owner Token owner granting approval
    /// @param operator Address being approved
    /// @param amount Number of items approved (type(uint256).max for unlimited)
    event Approval2(address indexed owner, address indexed operator, uint256 amount);

    // ═══════════════════════════════════════════════════════════════════════════
    // ERRORS (Single error for gas efficiency)
    // ═══════════════════════════════════════════════════════════════════════════

    /// @notice Operation not allowed
    /// @dev Covers: invalid input, insufficient funds, unauthorized access,
    ///      token locked, zero addresses, mismatched arrays, etc.
    error Unauthorized();

    // ═══════════════════════════════════════════════════════════════════════════
    // PAYMENT FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Split and distribute all accumulated royalties to receivers
     * @dev Anyone can call this (permissionless). Caller receives small reward.
     *      Flow:
     *      1. Unwraps all WETH to ETH
     *      2. Calculates executor reward (0.05%)
     *      3. Distributes remaining ETH to receivers proportional to shares
     *      4. Unlocks items and returns count
     * @return itemsUnlocked Number of items unlocked
     */
    function processRoyalties() external returns (uint256 itemsUnlocked);

    /**
     * @notice Unlock items by paying their royalties
     * @dev Flexible payment with "spillover" logic:
     *      - If itemId IS locked → unlocks that specific item
     *      - If itemId NOT locked → unlocks another item from locked list (LIFO)
     *      - Unused payment is refunded
     *      
     *      Use getRoyaltyOwed() first to check which items are locked.
     * @param itemIds Array of item IDs to unlock
     */
    function unlockItems(uint256[] calldata itemIds) external payable;

    /**
     * @notice transferFrom2 - The next evolution of NFT transfers
     * @dev Like Permit2 revolutionized approvals, transferFrom2 revolutionizes trading.
     *      Royalties are native. Marketplaces earn 1% for integrating.
     *      
     *      Replace transferFrom with transferFrom2. Creators win. Markets win.
     * @param from Current owner of the token
     * @param to Recipient address
     * @param tokenId Token to transfer
     * @return excess Amount of ETH refunded to msg.sender
     */
    function transferFrom2(address from, address to, uint256 tokenId) external payable returns (uint256 excess);

    /**
     * @notice batchTransferFrom2 - Batch evolution of NFT transfers
     * @dev Transfer multiple NFTs with royalties in one atomic operation.
     *      More gas efficient than multiple transferFrom2 calls.
     * @param from Current owner of all tokens
     * @param to Recipient address
     * @param tokenIds Array of token IDs to transfer
     * @return excess Amount of ETH refunded to msg.sender
     */
    function batchTransferFrom2(address from, address to, uint256[] calldata tokenIds) external payable returns (uint256 excess);

    /**
     * @notice approve2 - ERC20-style allowance for transferFrom2
     * @dev Unlike standard approve which is per-tokenId, approve2 grants an allowance
     *      for a NUMBER of items. Like ERC20 but for NFT count.
     *      
     *      Use type(uint256).max for unlimited allowance.
     *      Each transferFrom2 reduces the allowance by 1 (or batch size).
     * @param operator Address to approve
     * @param amount Number of items to approve (max uint256 for unlimited)
     */
    function approve2(address operator, uint256 amount) external;

    /**
     * @notice Check approve2 allowance for an operator (ERC20-style naming)
     * @param owner Token owner
     * @param spender Address to check allowance for
     * @return Current allowance (number of items spender can transfer via transferFrom2)
     */
    function allowance2(address owner, address spender) external view returns (uint256);

    // ═══════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS - Royalty Configuration
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice ERC-2981 royalty info for marketplace compatibility
     * @dev Standard interface for marketplaces to query royalty info.
     *      Returns this contract as receiver (royalties collected centrally).
     * @param tokenId Token ID (unused, royalty is same for all tokens)
     * @param salePrice The sale price of the NFT
     * @return receiver Address to receive royalty (always this contract)
     * @return royaltyAmount Calculated royalty based on salePrice and totalRoyaltyBps
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        external 
        view 
        returns (address receiver, uint256 royaltyAmount);

    /**
     * @notice Get the implied floor price derived from GLUE collateral
     * @dev Floor price = ETH collateral backing per 1 NFT.
     *      Used to calculate minimum royalty payment.
     * @return Floor price in wei
     */
    function getImpliedFloorPrice() external view returns (uint256);

    /**
     * @notice Get minimum royalty required per transfer
     * @dev Calculated as: floorPrice × totalRoyaltyBps / 10000
     *      Returns 0 if no collateral (no enforcement possible).
     * @return Minimum royalty in wei
     */
    function getMinimumRoyalty() external view returns (uint256);

    /**
     * @notice Check if royalty enforcement is currently active
     * @dev When false, all royalty checks are bypassed.
     * @return True if enforcement is active
     */
    function isRoyaltyActive() external view returns (bool);

    /**
     * @notice Get total royalty percentage in basis points
     * @dev Sum of all receivers' shares. 100 BPS = 1%, max 1000 BPS = 10%
     * @return Total royalty in BPS
     */
    function getRoyaltyBPS() external view returns (uint256);

    /**
     * @notice Check if an address is approved for royalty-free transfers
     * @dev Approved addresses can transfer locked items without paying.
     * @param addr Address to check
     * @return True if address is approved
     */
    function isRoyaltyExempt(address addr) external view returns (bool);

    /**
     * @notice Get all royalty receivers and their shares
     * @dev Returns parallel arrays of receivers and their BPS shares
     * @return receivers Array of receiver addresses
     * @return shares Array of BPS shares (parallel to receivers)
     */
    function getRoyaltyReceivers() external view returns (address[] memory receivers, uint256[] memory shares);
    
    /**
     * @notice Check if an address is a royalty receiver
     * @param account The address to check
     * @return isReceiver True if the address is a royalty receiver (has BPS > 0)
     */
    function isRoyaltyReceiver(address account) external view returns (bool isReceiver);

    // ═══════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS - Token Locking Status
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Check if a specific item is locked due to unpaid royalty
     * @dev Locked items cannot be transferred (except by owner or approved addresses).
     * @param itemId Item ID to check
     * @return True if item is locked
     */
    function isItemLocked(uint256 itemId) external view returns (bool);

    /**
     * @notice Get total count of items currently locked collection-wide
     * @dev Useful for monitoring overall collection compliance.
     * @return Number of locked items
     */
    function getTotalLockedCount() external view returns (uint256);

    // ═══════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS - Wallet Queries
    // ═══════════════════════════════════════════════════════════════════════════

    /**
     * @notice Check which items are locked and get the royalty amount to unlock them
     * @dev PRIMARY function for frontends to display unlock costs.
     *      Pass an array of item IDs, get back only the locked ones + total payment.
     * @param itemIds Array of item IDs to check
     * @return lockedIds Array of item IDs that are actually locked
     * @return amount Total ETH required to unlock all locked items
     */
    function getRoyaltyOwed(uint256[] calldata itemIds) external view returns (
        uint256[] memory lockedIds, 
        uint256 amount
    );

}
