// SPDX-License-Identifier: BUSL-1.1

/**

██╗███╗   ██╗██╗████████╗██╗ █████╗ ██╗     ██╗███████╗ █████╗ ██████╗ ██╗     ███████╗
██║████╗  ██║██║╚══██╔══╝██║██╔══██╗██║     ██║╚══███╔╝██╔══██╗██╔══██╗██║     ██╔════╝
██║██╔██╗ ██║██║   ██║   ██║███████║██║     ██║  ███╔╝ ███████║██████╔╝██║     █████╗  
██║██║╚██╗██║██║   ██║   ██║██╔══██║██║     ██║ ███╔╝  ██╔══██║██╔══██╗██║     ██╔══╝  
██║██║ ╚████║██║   ██║   ██║██║  ██║███████╗██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝   ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝

███████╗████████╗██╗ ██████╗██╗  ██╗██╗   ██╗     █████╗ ███████╗███████╗███████╗████████╗
██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝╚██╗ ██╔╝    ██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝
███████╗   ██║   ██║██║     █████╔╝  ╚████╔╝     ███████║███████╗███████╗█████╗     ██║   
╚════██║   ██║   ██║██║     ██╔═██╗   ╚██╔╝      ██╔══██║╚════██║╚════██║██╔══╝     ██║   
███████║   ██║   ██║╚██████╗██║  ██╗   ██║       ██║  ██║███████║███████║███████╗   ██║   
╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝       ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   

██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗
██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗  
██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝  
██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗
╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝

 */
pragma solidity ^0.8.28;

import {IStickyAsset} from './IStickyAsset.sol';

/**
 * @title IInitStickyAsset
 * @author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi
 * @notice Interface for InitStickyAsset contracts that support factory deployment patterns
 * @dev Extends IStickyAsset with initialization functionality for clone/proxy deployments
 * @dev This interface is specifically designed for factory patterns where contracts are deployed
 * via clones or minimal proxies and need post-deployment initialization
 */
interface IInitStickyAsset is IStickyAsset {

/**
--------------------------------------------------------------------------------------------------------
 ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▖ ▗▖▗▄▄▖ 
▐▌   ▐▌     █  ▐▌ ▐▌▐▌ ▐▌
 ▝▀▚▖▐▛▀▀▘  █  ▐▌ ▐▌▐▛▀▘ 
▗▄▄▞▘▐▙▄▄▖  █  ▝▚▄▞▘▐▌                                               
01010011 01100101 01110100 
01110101 01110000 

    /**
     * @notice Initialize the sticky asset for factory deployment patterns
     * @dev MUST be called after cloning/proxy deployment to create the Glue contract
     * @dev Can only be called once per contract instance (when GLUE == address(0))
     * @param initialContractURI The EIP-7572 compliant contract URI for metadata
     * @param fungibleAndHook [FUNGIBLE, HOOK] configuration flags
     *        [0] = FUNGIBLE (ERC20 = true) or non-fungible (ERC721 = false)
     *        [1] = HOOK (true = hooks are enabled)
     *
     * Requirements:
     * - Contract must not be already initialized (GLUE == address(0))
     * - Must successfully create Glue contract via GlueStick
     * - Must successfully approve Glue contract for token spending
     * 
     * Effects:
     * - Sets FUNGIBLE and HOOK flags
     * - Sets contract URI
     * - Creates unique Glue contract for this instance
     * - Approves Glue contract for token operations
     * - Emits StickyAssetInitialized event
     *
     * Use cases:
     * - Factory contracts initializing newly cloned sticky assets
     * - Post-deployment setup for minimal proxy patterns
     * - One-time configuration of cloned contract instances
     */
    function initializeStickyAsset(
        string memory initialContractURI,
        bool[2] memory fungibleAndHook
    ) external;

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▖ ▗▄▄▄▖ ▗▄▖ ▗▄▄▄ 
▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌  █
▐▛▀▚▖▐▛▀▀▘▐▛▀▜▌▐▌  █
▐▌ ▐▌▐▙▄▄▖▐▌ ▐▌▐▙▄▄▀
01010010 01100101 
01100001 01100100                         
*/

    /**
     * @notice Check if the contract has been initialized
     * @dev Returns true if GLUE address is set (not address(0))
     * @return initialized True if the contract has been initialized, false otherwise
     *
     * Use cases:
     * - Factory contracts checking initialization status before use
     * - Frontend validation of contract readiness
     * - Preventing operations on uninitialized clones
     */
    function isInitialized() external view returns (bool initialized);

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖▗▖  ▗▖▗▄▄▄▖▗▄▄▖
▐▌   ▐▌  ▐▌▐▌   ▐▛▚▖▐▌  █ ▐▌   
▐▛▀▀▘▐▌  ▐▌▐▛▀▀▘▐▌ ▝▜▌  █  ▝▀▚▖
▐▙▄▄▖ ▝▚▞▘ ▐▙▄▄▖▐▌  ▐▌  █ ▗▄▄▞▘
01000101 01110110 01100101 
01101110 01110100 01110011
*/

    /**
     * @notice Emitted when the contract is successfully initialized
     * @param glue The address of the created Glue contract
     * @param fungible Whether the asset is fungible (ERC20) or non-fungible (ERC721)
     * @param hasHooks Whether the asset has hooks enabled
     * @param contractURI The EIP-7572 compliant contract URI
     *
     * Use cases:
     * - Factory tracking of deployed and initialized contracts
     * - Indexing services monitoring new sticky asset deployments
     * - Frontend notification of successful contract initialization
     */
    event StickyAssetInitialized(
        address indexed glue,
        bool indexed fungible,
        bool hasHooks,
        string contractURI
    );

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
     * @notice Thrown when trying to initialize an already initialized contract
     * @dev This prevents double initialization and maintains contract integrity
     */
    error AlreadyInitialized();

    /**
     * @notice Thrown when trying to call functions on an uninitialized contract
     * @dev This ensures proper initialization sequence in factory deployments
     */
    error NotInitialized();

    /**
     * @notice Thrown when initialization fails due to glue creation failure
     * @dev This can occur if the Glue Stick contracts are not available or malfunction
     */
    error InitializationFailed();

} 