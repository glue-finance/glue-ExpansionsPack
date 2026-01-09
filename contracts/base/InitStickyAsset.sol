// SPDX-License-Identifier: BUSL-1.1

/**
 * ⚠️  LICENSE NOTICE - BUSINESS SOURCE LICENSE 1.1 ⚠️
 * 
 * This contract is licensed under BUSL-1.1. You may use it freely as long as you:
 * ✅ Do NOT modify the GLUE_STICK addresses in GluedConstants
 * ✅ Maintain integration with official Glue Protocol addresses
 * 
 * ❌ Editing GLUE_STICK_ERC20 or GLUE_STICK_ERC721 addresses = LICENSE VIOLATION
 * 
 * See LICENSE file for complete terms.
 */

/**

███████╗████████╗██╗ ██████╗██╗  ██╗██╗   ██╗    
██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝╚██╗ ██╔╝    
███████╗   ██║   ██║██║     █████╔╝  ╚████╔╝     
╚════██║   ██║   ██║██║     ██╔═██╗   ╚██╔╝      
███████║   ██║   ██║╚██████╗██║  ██╗   ██║       
╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝       
 █████╗ ███████╗███████╗███████╗████████╗                       ██╗███████╗ █████╗ ███╗   ██╗██╗                 
██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝                      ██╔╝██╔════╝██╔══██╗████╗  ██║╚██╗               
███████║███████╗███████╗█████╗     ██║                         ██║ ███████╗███████║██╔██╗ ██║ ██║               
██╔══██║╚════██║╚════██║██╔══╝     ██║                         ██║ ╚════██║██╔══██║██║╚██╗██║ ██║              
██║  ██║███████║███████║███████╗   ██║                         ╚██╗███████║██║  ██║██║ ╚████║██╔╝               
╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝                          ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝                 
███╗   ██╗ █████╗ ████████╗██╗██╗   ██╗███████╗  
████╗  ██║██╔══██╗╚══██╔══╝██║██║   ██║██╔════╝  
██╔██╗ ██║███████║   ██║   ██║██║   ██║█████╗    
██║╚██╗██║██╔══██║   ██║   ██║╚██╗ ██╔╝██╔══╝    
██║ ╚████║██║  ██║   ██║   ██║ ╚████╔╝ ███████╗  
╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝             

*/

pragma solidity ^0.8.28;

/**
@dev Interface for InitStickyAsset
*/
import {IInitStickyAsset} from '../interfaces/IInitStickyAsset.sol';

/**
@dev Library providing high-precision mathematical operations, decimal conversion, and rounding utilities for token calculations
*/
import {GluedMath} from '../libraries/GluedMath.sol';

/**
@dev Minimal Glue Protocol helper tools for advanced DeFi operations
@dev Provides utility functions for transfers, balance tracking, and glue interactions
@dev Also brings in GluedConstants (GLUE_STICK addresses, IGlueERC20/721 interfaces, PRECISION, ETH_ADDRESS, etc.)
*/
import {GluedToolsMin} from '../tools/GluedToolsMin.sol';

/**
 * @title Sticky Asset Native Standard - Initializable Version
 * @author La-Li-Lu-Le-Lo (@lalilulel0z) formerly BasedToschi
 * 
 * @notice Create proxy/clone-friendly tokens that natively integrate with Glue Protocol
 * 
 * @dev **InitStickyAsset is for CREATING sticky assets using factory/proxy patterns:**
 * 
 * 🎯 **Use InitStickyAsset When:**
 * - ✅ Building a factory that deploys sticky assets via minimal proxies (clones)
 * - ✅ Creating upgradeable sticky assets (UUPS/Transparent proxies)
 * - ✅ Deploying many similar tokens gas-efficiently (clone pattern)
 * - ✅ Need to defer glue creation until after deployment
 * - ✅ Building a launchpad or token factory platform
 * 
 * ❌ **Do NOT use InitStickyAsset if:**
 * - You want standard deployment → Use StickyAsset.sol (simpler, uses constructor)
 * - You want to build ON TOP of Glue (not create an asset) → Use GluedTools or GluedToolsERC20
 * - You just want to interact with existing glued assets → Use GluedToolsMin
 * 
 * 🔧 **What InitStickyAsset Provides:**
 * - ✅ Two-step initialization: Deploy → initializeStickyAsset()
 * - ✅ Clone-friendly: Glue created per-instance, not in constructor
 * - ✅ Initialization guard: Can only be initialized once
 * - ✅ Native unglue() function callable directly on your token
 * - ✅ Flash loan support through flashLoan() function
 * - ✅ Hook system for custom logic (sticky hooks + collateral hooks)
 * - ✅ Read functions for collateral amounts, balances, and supply
 * - ✅ EIP-7572 contract URI support for metadata
 * - ✅ Built-in reentrancy protection (EIP-1153)
 * - ✅ GluedMath helpers for precision calculations
 * 
 * 📦 **Initialization Flow:**
 * 1. Deploy the contract (constructor sets GLUE = address(0))
 * 2. Call initializeStickyAsset() which:
 *    - Creates the glue contract for THIS specific instance
 *    - Sets GLUE, FUNGIBLE, and HOOK flags
 *    - Approves the glue to spend tokens (max approval)
 *    - Sets the contract URI for metadata
 *    - Emits StickyAssetInitialized event
 * 3. The contract is now ready to use
 * 
 * 🎨 **Customization:**
 * Override these internal functions to add custom behavior:
 * - _calculateStickyHookSize(): Calculate hook size for sticky tokens
 * - _calculateCollateralHookSize(): Calculate hook size for collateral tokens
 * - _processStickyHook(): Execute logic when sticky tokens are hooked
 * - _processCollateralHook(): Execute logic when collateral is hooked
 * 
 * 💡 **Helper Tools Available:**
 * - _md512(): High-precision multiply-divide operations
 * - _adjustDecimals(): Convert amounts between different token decimals
 * - _updateContractURI(): Update the EIP-7572 contract URI
 * - isInitialized(): Check if the contract has been initialized
 * 
 * 🛡️ **Safety Features:**
 * - onlyInitialized modifier: Prevents operations before initialization
 * - AlreadyInitialized error: Prevents double initialization
 * - NotInitialized error: Prevents use before initialization
 * - InitializationFailed error: Catches glue creation failures
 * 
 * ⚠️ **Important License Note:**
 * DO NOT modify the GLUE_STICK_ERC20 or GLUE_STICK_ERC721 addresses. Doing so violates
 * the BUSL-1.1 license and breaks protocol compatibility.
 * 
 * 🆚 **InitStickyAsset vs StickyAsset:**
 * - **InitStickyAsset**: Uses initialize(), creates glue post-deployment (proxy/clone pattern)
 * - **StickyAsset**: Uses constructor, creates glue at deployment (standard pattern)
 * 
 * 📝 **Example Factory Pattern:**
 * ```solidity
 * contract TokenFactory {
 *     address public implementation;
 *     
 *     function createToken(string memory uri, bool[2] memory config) external returns (address) {
 *         address clone = Clones.clone(implementation);
 *         InitStickyAsset(clone).initializeStickyAsset(uri, config);
 *         return clone;
 *     }
 * }
 * ```
 * 
 * 📚 **Related Contracts:**
 * - For building applications that interact with glued assets: See GluedTools, GluedToolsERC20
 * - For minimal helper functions: See GluedToolsMin, GluedToolsERC20Min
 * - For standard (non-proxy) sticky assets: See StickyAsset
 */
abstract contract InitStickyAsset is IInitStickyAsset, GluedToolsMin {

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
    //        Inheriting contracts can leverage these properties to build custom logic
    // Constants (PRECISION, ETH_ADDRESS, DEAD_ADDRESS, GLUE_STICK addresses) inherited from GluedToolsMin -> GluedConstants
    
    /// @notice Address of the Glue contract for the token (set during initialization)
    address internal GLUE;
    
    /// @notice Flag indicating if the token is fungible (set during initialization)
    bool internal FUNGIBLE;

    /// @notice Flag indicating if the token has hooks (set during initialization)
    bool internal HOOK;

    /// @notice ERC-7572 compliant contract URI for metadata
    string internal _contractURI;
    
    /**
     * @notice Constructor for implementation contract - does NOT create glue
     * @dev For proxy pattern, glue creation is deferred to initializeStickyAsset()
     * @dev Sets GLUE to address(0) to indicate uninitialized state
     */
    constructor() {
        // Set GLUE to address(0) to indicate uninitialized state
        // This will be used to check if the contract has been initialized
        GLUE = address(0);
    }

    /**
     * @notice Initialize the sticky asset with glue creation - MUST be called by clones
     * @dev This replaces the glue creation logic that would normally happen in constructor
     * @dev Can only be called once per contract instance (when GLUE == address(0))
     * @param initialContractURI The contract URI for metadata
     * @param fungibleAndHook [FUNGIBLE, HOOK] configuration flags
     */
    function initializeStickyAsset(
        string memory initialContractURI,
        bool[2] memory fungibleAndHook
    ) external override {
        
        // Ensure this is only called once per contract
        if (GLUE != address(0)) revert AlreadyInitialized();
        
        // Set if the token is fungible (ERC20 = true) or non-fungible (ERC721 = false)
        FUNGIBLE = fungibleAndHook[0];

        // Set if the token has hooks (true = hooks are enabled)
        HOOK = fungibleAndHook[1];

        // Set the contract URI
        _contractURI = initialContractURI;

        // NOW create the glue for THIS specific clone instance
        if (fungibleAndHook[0] == true) {
            // Glue the ERC20 token - this will create a unique glue for this clone
            GLUE = IGlueStickERC20(GLUE_STICK_ERC20).applyTheGlue(address(this));
            
            // Verify glue was created successfully
            if (GLUE == address(0)) revert InitializationFailed();

            // Approve GLUE address to spend tokens
            (bool approveAllSuccess, ) = address(this).call(
                abi.encodeWithSelector(0x095ea7b3, GLUE, type(uint256).max)
            );

            if(!approveAllSuccess) {
                revert ApproveFailed();
            }

        } else {
            // Glue the ERC721 token - this will create a unique glue for this clone
            GLUE = IGlueStickERC721(GLUE_STICK_ERC721).applyTheGlue(address(this));
            
            // Verify glue was created successfully
            if (GLUE == address(0)) revert InitializationFailed();

            // Approve GLUE address to spend tokens
            (bool approveAllSuccess, ) = address(this).call(
                abi.encodeWithSelector(0xa22cb465, GLUE, true)
            );

            if(!approveAllSuccess) {
                revert ApproveFailed();
            }
        }

        // Emit initialization event
        emit StickyAssetInitialized(GLUE, FUNGIBLE, HOOK, _contractURI);
    }

    /**
    * @notice Check if the contract has been initialized
    * @dev Returns true if GLUE address is set (not address(0))
    * @return initialized True if the contract has been initialized, false otherwise
    */
    function isInitialized() external view override returns (bool initialized) {
        return GLUE != address(0);
    }

    /**
    * @notice Modifier to ensure the contract has been initialized
    * @dev Prevents operations on uninitialized clones
    */
    modifier onlyInitialized() {
        if (GLUE == address(0)) revert NotInitialized();
        _;
    }

    /**
    * @notice Reentrancy guard using transient storage (EIP-1153)
    * @dev Gas-efficient protection for functions with external calls
    */
    modifier nnrtnt() {
        bytes32 slot = keccak256(abi.encodePacked(address(this), "ReentrancyGuard"));
        
        assembly {
            if tload(slot) { 
                mstore(0x00, 0x3ee5aeb5) // ReentrancyGuardReentrantCall()
                revert(0x1c, 0x04)
            }
            tstore(slot, 1)
        }
        
        _;
        
        assembly {
            tstore(slot, 0)
        }
    }

    /**
    * @notice Modifier to check if the caller is the GLUE contract
    * @dev Only the GLUE contract can call the functions that use this modifier
    *
    * Use cases:
    * - Check if the caller is the GLUE contract
    */
    modifier onlyGlue() {

        // If the caller is not the GLUE contract, revert
        if (msg.sender != GLUE) revert OnlyGlue();

        // Continue execution
        _;
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
    * @notice Internal helper to execute the unglue call based on token type
    * @dev Used by derived contracts to make the correct unglue call
    * @dev IMPORTANT: Users must approve this contract to spend their tokens before calling this function
    * @dev Call approve(address(this), amount) on the token contract first
    *
    * @param collaterals Array of collateral addresses to withdraw
    * @param amount For ERC20: amount of tokens, For ERC721: any number < tokenIds.length
    * @param tokenIds For ERC20: empty array [0], For ERC721: array of token IDs to redeem
    * @param recipient Address to receive the redeemed collateral
    * @return supplyDelta Calculated proportion of total supply (in PRECISION units)
    * @return realAmount Actual amount of tokens processed after transfer
    * @return beforeTotalSupply Token supply before the unglue operation
    * @return afterTotalSupply Token supply after the unglue operation
    *
    * Prerequisites:
    * - User must have sufficient token balance
    * - User must have approved this contract to spend the required amount or token IDs
    *
    * Use cases:
    * - Unglue directly from the asset contract
    */
    function unglue(address[] calldata collaterals,uint256 amount,uint256[] memory tokenIds,address recipient) public override onlyInitialized returns (uint256 supplyDelta, uint256 realAmount, uint256 beforeTotalSupply, uint256 afterTotalSupply) {

        // Check if the token is an ERC20
        if (FUNGIBLE) {

            // If the token is an ERC20, the tokenIds array must be empty
            if (tokenIds.length > 0) {
                revert InvalidTokenIds();
            }

            // Get balance before transfer for tax calculation
            (, bytes memory balanceBeforeData) = address(this).call(abi.encodeWithSelector(0x70a08231, address(this)));
            uint256 balanceBefore = balanceBeforeData.length > 0 ? abi.decode(balanceBeforeData, (uint256)) : 0;

            // Transfer tokens from user to this contract
            address(this).call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), amount));

            // Get actual received amount (handles transfer taxes)
            (, bytes memory balanceAfterData) = address(this).call(abi.encodeWithSelector(0x70a08231, address(this)));
            uint256 actualReceived = (balanceAfterData.length > 0 ? abi.decode(balanceAfterData, (uint256)) : 0) - balanceBefore;

            // Approve and call unglue (Glue will handle all validation)
            address(this).call(abi.encodeWithSelector(0x095ea7b3, GLUE, actualReceived));
            (supplyDelta, realAmount, beforeTotalSupply, afterTotalSupply) = IGlueERC20(GLUE).unglue(collaterals, actualReceived, recipient);


        // If the token is an ERC721
        } else {

            // For ERC721 tokens, the amount must be equal to the tokenIds array length
            if (amount > tokenIds.length) {
                revert InvalidTokenIds();
            }

            // Transfer all tokens from user to this contract
            for (uint256 i = 0; i < tokenIds.length; i++) {
                address(this).call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), tokenIds[i]));
            }

            // Check if GLUE is approved for all, if not approve it
            (, bytes memory approvalData) = address(this).call(abi.encodeWithSelector(0xe985e9c5, address(this), GLUE));
            if (approvalData.length == 0 || !abi.decode(approvalData, (bool))) {
                address(this).call(abi.encodeWithSelector(0xa22cb465, GLUE, true));
            }
            
            // Call ERC721 unglue with tokenIds and capture return values
            (supplyDelta, realAmount, beforeTotalSupply, afterTotalSupply) = IGlueERC721(GLUE).unglue(collaterals, tokenIds, recipient);
        }
        
        // Return all the data from the underlying glue contract
        return (supplyDelta, realAmount, beforeTotalSupply, afterTotalSupply);
    }

    /**
    * @notice Executes a flashLoan from the glue through the Glue factory
    * @dev The receiver must implement IGluedLoanReceiver interface
    *
    * @param collateral Address of the token to borrow (cannot be this token itself)
    * @param amount Amount to borrow
    * @param receiver Address of the receiver implementing IGluedLoanReceiver
    * @param params Additional parameters for the receiver
    * @return success True if the loan operation was successful
    *
    * Use cases:
    * - Flash loan using the glued collaterals directly from the asset contract
    */
    function flashLoan(address collateral,uint256 amount,address receiver,bytes calldata params) external override onlyInitialized returns (bool success) {
        
        // Create the glues array including this contract's glue
        address[] memory glues = new address[](1);

        // Add the GLUE address to the glues array
        glues[0] = GLUE;

        // If the token is an ERC20
        if (FUNGIBLE) {

            // Execute the gluedLoan through the Glue Stick
            try IGlueStickERC20(GLUE_STICK_ERC20).gluedLoan(glues,collateral,amount,receiver,params) {

                    // Set the success to true
                    success = true;

                // If the loan operation failed
                } catch {

                    // Set the success to false
                    success = false;
                }

        // If the token is an ERC721
        } else {

            // Execute the gluedLoan through the Glue Stick
            try IGlueStickERC721(GLUE_STICK_ERC721).gluedLoan(glues,collateral,amount,receiver,params) {

                // Set the success to true
                success = true;

            // If the loan operation failed
            } catch {

                // Set the success to false
                success = false;
            }
        }
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

    // █████╗ Common external functions
    // ╚════╝ Don't edit the following functions

    /**
    * @notice Returns the size/value for the outgoing hook (when ungluing collateral)
    * @param asset The address of the collateral token
    * @return size The hook size as a percentage (in PRECISION units)
    */
    function hookSize(address asset, uint256 amount) external view override returns (uint256 size) {

        // Check if the hook is enabled
        if (!HOOK) return 0;

        // If the asset is the same as this contract
        if (asset == address(this)) {

            // If the token is an ERC20
            if (FUNGIBLE) {

                // Call the internal implementation method with the adjusted amount
                return _calculateStickyHookSize(amount);

            // If the token is an ERC721
            } else {

                // Return 0
                return 0;
            }
        } else {

            // Call the internal implementation method with the adjusted amount
            return _calculateCollateralHookSize(asset, amount);
        }
    }

    /**
    * @notice Hook function called when ungluing collateral tokens
    * @param asset The address of the collateral token
    * @param amount The amount of tokens being processed by the hook
    * @param tokenIds The token IDs being processed (Only ERC721) always empty for ERC20
    * @param recipient The address of the recipient of the unglue operation
    */
    function executeHook(address asset, uint256 amount, uint256[] memory tokenIds, address recipient) external override onlyGlue {

        // Check if the token is the same as this contract
        if (asset == GLUE || asset == address(this)) {

            // Call the internal implementation method with the adjusted amount
            // Glue already checked for the balance received, if the token has a tax you
            // receive the actual amount received and not the amount sent
            _processStickyHook(amount, tokenIds, recipient);

        // If the token is not the same as this contract
        } else {
            
            // Call the internal implementation method with the adjusted amount
            // Glue already checked for the balance received, if the token has a tax you
            // receive the actual amount received and not the amount sent.
            // If the asset is ETH, you'll receive a true boolean and asset = address(0)

            if (asset == ETH_ADDRESS) {

                // Call the internal implementation method with the adjusted amount
                _processCollateralHook(asset, amount, true, recipient);
            } else {

                // Call the internal implementation method with the adjusted amount
                _processCollateralHook(asset, amount, false, recipient);
            }

        }

        // Emit the hook executed event
        emit HookExecuted(asset, amount, tokenIds);
    }

    // █████╗ Customizable internal functions
    // ╚════╝ Override the following functions in derived contracts
    //
    //      - _calculateStickyHookSize: Logic for calculating the hook size and the ammount of sticky asset 
    //        to be sent for hook processing) [Only GlueERC20]
    //
    //      - _calculateCollateralHookSize: Logic for calculating the hook size and the ammount of collateral token to be sent for hook processing
    //
    //      - _processStickyHook: Logic for processing the hook for sticky tokens based on ammount received (ERC721 Only Read)
    //
    //      - _processCollateralHook: Logic for processing the hook for collateral tokens based on ammount received

    /**
    * @notice Internal function to calculate the outgoing hook size
    * @dev MUST BE OVERRIDDEN by derived contracts that use hooks
    *      If your contract enables OUT_HOOK_FLAG, you must override this method
    *      The default implementation returns 0, which effectively disables the hook
    * @param amount The amount of tokens being processed by the hook
    * @return size The hook size as a percentage (in PRECISION units)
    */
    function _calculateStickyHookSize(uint256 amount) internal view virtual returns (uint256 size) {

        // Derived contracts must override this if they use out hooks
        if (amount == 0) {return 0;}
        return 0; 
    }

    /**
    * @notice Internal function to calculate the outgoing hook size
    * @dev MUST BE OVERRIDDEN by derived contracts that use hooks
    *      If your contract enables OUT_HOOK_FLAG, you must override this method
    *      The default implementation returns 0, which effectively disables the hook
    * @param asset The address of the token
    * @param amount The amount of tokens being processed by the hook
    * @return size The hook size as a percentage (in PRECISION units)
    */
    function _calculateCollateralHookSize(address asset, uint256 amount) internal view virtual returns (uint256 size) {

        // Derived contracts must override this if they use out hooks
        if (amount == 0) {return 0;}
        if (asset == ETH_ADDRESS) {return 0;}
        return 0; 
    }

    /**
    * @notice Internal implementation of the incoming hook logic
    * @dev Override this method in derived contracts to implement custom hook behavior
    * @param amount The amount of tokens being processed
    * @param tokenIds The token IDs being processed (Only ERC721) always empty for ERC20
    * @param recipient The address of the recipient of the unglue operation
    */
    function _processStickyHook(uint256 amount, uint256[] memory tokenIds, address recipient) internal virtual {
        // Default implementation does nothing
        // Derived contracts should override this
    }

    /**
    * @notice Internal implementation of the outgoing hook logic
    * @dev Override this method in derived contracts to implement custom hook behavior
    * @param asset The address of the collateral token
    * @param amount The amount of tokens being processed
    * @param isETH Whether the token is ETH
    * @param recipient The address of the recipient of the unglue operation
    */
    function _processCollateralHook(address asset, uint256 amount, bool isETH, address recipient) internal virtual {
        // Default implementation does nothing
        // Derived contracts should override this
    }

/**
--------------------------------------------------------------------------------------------------------
▗▄▄▄▖▗▄▖  ▗▄▖ ▗▖    ▗▄▄▖
  █ ▐▌ ▐▌▐▌ ▐▌▐▌   ▐▌   
  █ ▐▌ ▐▌▐▌ ▐▌▐▌    ▝▀▚▖
  █ ▝▚▄▞▘▝▚▄▞▘▐▙▄▄▖▗▄▄▞▘
01010100 01101111 01101111 
01101100 01110011
*/

    // █████╗ Tools to
    // ╚════╝ build easier

    /**
     * @notice Function to manage the EIP-7572 URI changes
     */
    function _updateContractURI(string memory newURI) internal {

        // Update the contract URI
        _contractURI = newURI;
    }

    /**
    * @notice Performs a multiply-divide operation with full precision.
    * @dev Calculates floor(a * b / denominator) with full precision, using 512-bit intermediate values.
    * Throws if the result overflows a uint256 or if the denominator is zero.
    *
    * @param a The multiplicand.
    * @param b The multiplier.
    * @param denominator The divisor.
    * @return result The result of the operation.
    *
    * Use case: When you need to calculate the result of a multiply-divide operation with full precision.
    */
    function _md512(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {

        // Return the result of the operation
        return GluedMath.md512(a, b, denominator);
    }

    /**
    * @notice Performs a multiply-divide operation with full precision and rounding up.
    * @dev Calculates ceil(a * b / denominator) with full precision, using 512-bit intermediate values.
    * Throws if the result overflows a uint256 or if the denominator is zero.
    *
    * @param a The multiplicand.
    * @param b The multiplier.
    * @param denominator The divisor.
    * @return result The result of the operation, rounded up to the nearest integer.
    *
    * Use case: When you need to calculate the result of a multiply-divide operation with full precision and rounding up.
    */
    function _md512Up(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {

        // Return the result of the operation rounding up
        return GluedMath.md512Up(a, b, denominator);
    }

    /**
    * @notice Adjusts decimal places between different token decimals. With this function,
    * you can get the right ammount of tokenOut from a given tokenIn address and amount
    * espressed in tokenIn's decimals.
    * @dev If one of the tokens is ETH, you can use the address(0) as the token address.
    *
    * @param amount The amount to adjust
    * @param tokenIn The address of the input token
    * @param tokenOut The address of the output token
    * @return adjustedAmount The adjusted amount with correct decimal places
    *
    * Use case: When you need to adjust the decimal places operating with two different tokens
    */
    function _adjustDecimals(uint256 amount,address tokenIn,address tokenOut) internal view returns (uint256 adjustedAmount) {

        // Return the adjusted amount
        return GluedMath.adjustDecimals(amount, tokenIn, tokenOut);
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

    // █████╗ Functions usable to internally
    // ╚════╝ read the state of the contract

    /**
    * @notice Calculates the amount of collateral tokens that can be unglued for a given sticky token amount.
    * @dev This function is used to calculate the amount of collateral tokens that can be unglued for a given sticky token amount.
    *
    * @param stickyAmount The amount of sticky tokens to unglue.
    * @param collaterals An array of addresses representing the collateral tokens to unglue.
    * @return amounts An array containing the corresponding amounts that can be unglued.
    * @dev This function accounts for the protocol fee in its calculations.
    *
    * Use cases:
    * - Calculating the amount of collateral tokens that can be unglued for a given sticky token amount.
    * @dev This function can loose precision if the Sticky Token implement a Tax on tranfers.
    */
    function getcollateralByAmount(uint256 stickyAmount,address[] calldata collaterals) public view override onlyInitialized returns (uint256[] memory amounts) {

        // Use the known token type and glue address set in constructor
        if (FUNGIBLE) {

            // Call ERC20 collateralByAmount
            return IGlueERC20(GLUE).collateralByAmount(stickyAmount, collaterals);
        
        } else {

            // Call ERC721 collateralByAmount
            return IGlueERC721(GLUE).collateralByAmount(stickyAmount, collaterals);
        }
    }
    
    /**
    * @notice Retrieves the adjusted total supply of the sticky token.
    * @dev This function is used to get the adjusted total supply of the sticky token.
    *
    * @return adjustedTotalSupply The adjusted and actual total supply of the sticky token.
    *
    * Use cases:
    * - Retrieving the adjusted and actual total supply of the sticky token.
    */
    function getAdjustedTotalSupply() public view override onlyInitialized returns (uint256 adjustedTotalSupply) {
        
        // Use the known token type and glue address set in constructor
        if (FUNGIBLE) {

            // Call ERC20 getAdjustedTotalSupply
            return IGlueERC20(GLUE).getAdjustedTotalSupply();
        } else {

            // Call ERC721 getAdjustedTotalSupply
            return IGlueERC721(GLUE).getAdjustedTotalSupply();
        }
    }

    /**
    * @notice Calculates the supply delta based on the sticky token amount and total supply.
    * @dev This function is used to calculate the supply delta based on the sticky token amount and total supply.
    *
    * @param stickyAmount The amount of sticky tokens to calculate the supply delta for.
    * @return supplyDelta The calculated supply delta.
    * @dev This function accounts for the protocol fee in its calculations.
    *
    * Use cases:
    * - Calculating the supply delta based on the sticky token amount.
    * @dev This function can lose precision if the Sticky Token implements a Tax on transfers.
    */
    function getSupplyDelta(uint256 stickyAmount) public view override onlyInitialized returns (uint256 supplyDelta) {
        
        // Use the known token type and glue address set in constructor
        if (FUNGIBLE) {

            // Call ERC20 getSupplyDelta
            return IGlueERC20(GLUE).getSupplyDelta(stickyAmount);
        } else {

            // Call ERC721 getSupplyDelta
            return IGlueERC721(GLUE).getSupplyDelta(stickyAmount);
        }
    }

    /**
    * @notice Retrieves the balance of an array of specified collateral tokens for the glue contract.
    * @dev This function is used to get the balance of an array of specified collateral tokens for the glue contract.
    *
    * @param collaterals An array of addresses representing the collateral tokens.
    * @return balances An array containing the corresponding balances.
    *
    * Use cases:
    * - Retrieving the balance of an array of specified collateral tokens for the glue contract.
    */
    function getBalances(address[] calldata collaterals) public view override onlyInitialized returns (uint256[] memory balances) {
        
        // Use the known token type and glue address set in constructor
        if (FUNGIBLE) {

            // Call ERC20 getBalances
            return IGlueERC20(GLUE).getBalances(collaterals);
        } else {

            // Call ERC721 getBalances
            return IGlueERC721(GLUE).getBalances(collaterals);
        }
    }

    // █████╗ Functions redable only externally
    // ╚════╝ 

    /**
     * @notice Calculates the total impact of all hooks during ungluing operations
     * @dev Provides an aggregated view of how hooks will affect the token distribution
     * for a specific collateral and amount combination
     *
     * @param collateral The address of the collateral token being unglued
     * @param collateralAmount The amount of collateral token being withdrawn from the glue
     * @param stickyAmount The amount of sticky tokens being burned (for ERC20 only)
     * @return size The combined impact of all hooks as a percentage in PRECISION units
     *
     * Use case: Client-side prediction of expected output amounts accounting for hooks
     */
    function hooksImpact(address collateral, uint256 collateralAmount, uint256 stickyAmount) external view override returns (uint256 size) {

        // If the token is an ERC20
        if (FUNGIBLE) {

            // Call ERC20 hooksImpact
            uint256 hookSizeIn = _calculateStickyHookSize(stickyAmount);

            // If the hook size is 0
            if (hookSizeIn == 0) {

                // Return the collateral hook size
                return _calculateCollateralHookSize(collateral, collateralAmount);

            // If the hook size is not 0
            } else {

                // Return the hook size
                return GluedMath.md512(hookSizeIn, _calculateCollateralHookSize(collateral, collateralAmount), PRECISION);
            }

        // If the token is an ERC721
        } else {

            // Call ERC721 hooksImpact
            return _calculateCollateralHookSize(collateral, collateralAmount);
        }
    }

    /**
    * @notice Retrieves the flash loan fee for a given amount.
    * @dev This function is used to get the flash loan fee for a given amount.
    *
    * @param amount The amount to calculate the flash loan fee for.
    * @return fee The flash loan fee applied to a given amount.
    *
    * Use cases:
    * - Retrieving the flash loan fee applied to a given amount.
    */
    function getFlashLoanFeeCalculated(uint256 amount) external view override onlyInitialized returns (uint256 fee) {

        // Return the flash loan fee applied to a given amount
        if (FUNGIBLE) {
            return IGlueERC20(GLUE).getFlashLoanFeeCalculated(amount);
        } else {
            return IGlueERC721(GLUE).getFlashLoanFeeCalculated(amount);
        }
    }

    /**
    * @notice Returns the contract URI as EIP-7572
    * @dev This function is used to get the contract URI as EIP-7572
    *
    * @return uRI The contract URI
    *
    * Use cases:
    * - Retrieving the assets information in a common format as EIP-7572
    */
    function contractURI() external view override returns (string memory uRI) {
        return _contractURI;
    }

    /**
    * @notice Returns the flag indicating if the token has hooks
    *
    * @return hook If true the asset has hooks
    *
    * Use cases:
    * - Retrieving the flag indicating if the token has hooks
    */
    function hasHook() external view override returns (bool hook) {
        return HOOK;
    }

    /**
    * @notice Returns the flag indicating if the token is fungible
    * @dev This function is used to get the flag indicating if the token is fungible
    *
    * @return fungible If true the token is fungible (ERC20) if false the token is non-fungible (ERC721)
    *
    * Use cases:
    * - Retrieving the flag indicating if the token is fungible (ERC20 = true) if false the token is non-fungible (ERC721)
    */
    function isFungible() external view override returns (bool fungible) {
        return FUNGIBLE;
    }

    /**
    * @notice Returns the address of the glue contract
    * @dev This function is used to get the address of the glue contract
    *
    * @return glue The address of the glue contract
    *
    * Use cases:
    * - Retrieving the address of the glue contract
    */
    function getGlue() external view override onlyInitialized returns (address glue) {
        return GLUE;
    }

    /**
    * @notice Returns the address of the glue stick contract
    * @dev This function is used to get the address of the glue stick contract
    *
    * @return glueStick The address of the glue stick contract
    *
    * Use cases:
    * - Retrieving the address of the glue stick contract
    */
    function getGlueStick() external view override returns (address glueStick) {

        if (FUNGIBLE) {
            return address(GLUE_STICK_ERC20);
        } else {
            return address(GLUE_STICK_ERC721);
        }
    }
} 