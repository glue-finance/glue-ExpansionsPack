// SPDX-License-Identifier: BUSL-1.1

/**

███████╗████████╗██╗ ██████╗██╗  ██╗██╗   ██╗     █████╗ ███████╗███████╗███████╗████████╗
██╔════╝╚══██╔══╝██║██╔════╝██║ ██╔╝╚██╗ ██╔╝    ██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝
███████╗   ██║   ██║██║     █████╔╝  ╚████╔╝     ███████║███████╗███████╗█████╗     ██║   
╚════██║   ██║   ██║██║     ██╔═██╗   ╚██╔╝      ██╔══██║╚════██║╚════██║██╔══╝     ██║   
███████║   ██║   ██║╚██████╗██║  ██╗   ██║       ██║  ██║███████║███████║███████╗   ██║   
╚══════╝   ╚═╝   ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝       ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   

@title Mock Sticky Asset Native Standard
@author @BasedToschi
@notice Mock implementation of the Sticky Asset Standard for testing
@dev Identical to StickyAsset.sol but allows configurable glue stick addresses in constructor, with warnings only at the end
*/

pragma solidity ^0.8.28;

import {IStickyAsset} from '../interfaces/IStickyAsset.sol';
import {IGluedHooks} from '../interfaces/IGluedHooks.sol';
import {IGlueStickERC20, IGlueERC721} from '../interfaces/IGlueERC20.sol';
import {GluedMath} from '../libraries/GluedMath.sol';

/**
 * @title MockStickyAsset
 * @notice Mock implementation of the Sticky Asset Native Standard for testing
 * @dev Identical functionality to StickyAsset.sol but with configurable glue stick addresses
 */
abstract contract MockStickyAsset is IStickyAsset {
    using GluedMath for uint256;

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONSTANTS AND IMMUTABLES
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /// @notice Precision constant for mathematical operations (1e18 = 100%)
    uint256 internal constant PRECISION = 1e18;

    /// @notice Magic value for successful executeOperation calls
    bytes32 private constant FLASH_LOAN_SUCCESS = keccak256("FLASH_LOAN_SUCCESS");

    /// @notice Configurable glue stick addresses (set in constructor for testing)
    address private immutable MOCK_GLUE_STICK_ERC20;
    address private immutable MOCK_GLUE_STICK_ERC721;

    /// @notice Contract metadata URI (EIP-7572)
    string private _contractURI;

    /// @notice Sticky asset biological configuration
    BIO private immutable _bio;

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Initialize the sticky asset with configurable glue stick addresses
     * @param contractURI_ EIP-7572 contract metadata URI
     * @param bio_ Biological configuration array [FUNGIBLE, HOOK]
     * @param glueStickERC20_ Mock ERC20 glue stick address for testing
     * @param glueStickERC721_ Mock ERC721 glue stick address for testing
     */
    constructor(
        string memory contractURI_,
        bool[2] memory bio_,
        address glueStickERC20_,
        address glueStickERC721_
    ) {
        _contractURI = contractURI_;
        _bio = bio_[1] ? BIO.HOOK : BIO.NO_HOOK;
        
        require(glueStickERC20_ != address(0), "Mock glue stick ERC20 cannot be zero");
        require(glueStickERC721_ != address(0), "Mock glue stick ERC721 cannot be zero");
        
        MOCK_GLUE_STICK_ERC20 = glueStickERC20_;
        MOCK_GLUE_STICK_ERC721 = glueStickERC721_;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // PUBLIC VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Get contract metadata URI (EIP-7572)
     * @return The contract metadata URI
     */
    function contractURI() external view override returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Get biological configuration
     * @return Current BIO configuration
     */
    function getBio() external view override returns (BIO) {
        return _bio;
    }

    /**
     * @notice Check if hooks are enabled
     * @return True if hooks are enabled
     */
    function hasHooks() external view override returns (bool) {
        return _bio == BIO.HOOK;
    }

    /**
     * @notice Get the mock ERC20 glue stick address
     * @return Mock ERC20 glue stick address
     */
    function _getGlueStickERC20() internal view returns (address) {
        return MOCK_GLUE_STICK_ERC20;
    }

    /**
     * @notice Get the mock ERC721 glue stick address  
     * @return Mock ERC721 glue stick address
     */
    function _getGlueStickERC721() internal view returns (address) {
        return MOCK_GLUE_STICK_ERC721;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // HOOK FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Calculate size of sticky hook (override this for custom logic)
     * @param amount Amount of tokens involved in the operation
     * @return size Size of the hook in the same units as amount
     */
    function _calculateStickyHookSize(uint256 amount) internal view virtual returns (uint256 size) {
        // Default: no hooks
        return 0;
    }

    /**
     * @notice Calculate size of collateral hook (override this for custom logic)
     * @param asset Address of the collateral asset
     * @param amount Amount of collateral involved
     * @return size Size of the hook in the same units as amount
     */
    function _calculateCollateralHookSize(address asset, uint256 amount) internal view virtual returns (uint256 size) {
        // Default: no hooks
        return 0;
    }

    /**
     * @notice Process sticky hook execution (override this for custom logic)
     * @param amount Amount of tokens in the hook
     * @param tokenIds Array of token IDs (for ERC721 tokens)
     */
    function _processStickyHook(uint256 amount, uint256[] memory tokenIds) internal virtual {
        // Default: no processing
    }

    /**
     * @notice Process collateral hook execution (override this for custom logic)
     * @param asset Address of the collateral asset
     * @param amount Amount of collateral in the hook
     * @param isETH Whether the collateral is ETH
     */
    function _processCollateralHook(address asset, uint256 amount, bool isETH) internal virtual {
        // Default: no processing
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // FLASH LOAN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Execute a flash loan from the glue
     * @param collateral Address of the collateral to borrow (address(0) for ETH)
     * @param amount Amount to borrow
     * @param receiver Address that will receive the flash loan
     * @param params Additional data for the flash loan
     * @return success True if the flash loan was successful
     */
    function flashLoan(
        address collateral,
        uint256 amount,
        address receiver,
        bytes calldata params
    ) external override returns (bool success) {
        address glueAddress = _getGlueForAsset();
        require(glueAddress != address(0), "No glue deployed for this asset");

        // Call flash loan on the appropriate glue
        try IGlueERC20(glueAddress).flashLoan(collateral, amount, receiver, params) returns (bool result) {
            success = result;
        } catch {
            success = false;
        }

        emit FlashLoanExecuted(glueAddress, collateral, amount, receiver, success);
        return success;
    }

    /**
     * @notice Get the glue contract address for this asset
     * @return glue Address of the glue contract
     */
    function _getGlueForAsset() internal view returns (address glue) {
        // Check with ERC20 glue stick first
        try IGlueStickERC20(_getGlueStickERC20()).getGlueAddress(address(this)) returns (address glueERC20) {
            if (glueERC20 != address(0)) {
                return glueERC20;
            }
        } catch {
            // Continue to ERC721 check
        }

        // Check with ERC721 glue stick
        try IGlueStickERC721(_getGlueStickERC721()).getGlueAddress(address(this)) returns (address glueERC721) {
            return glueERC721;
        } catch {
            return address(0);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // MATHEMATICAL HELPER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice High-precision multiplication and division
     * @param a First operand
     * @param b Second operand (numerator)
     * @param denominator Denominator
     * @return result Result of (a * b) / denominator with high precision
     */
    function _md512(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        return GluedMath.md512(a, b, denominator);
    }

    /**
     * @notice Adjust token amounts for different decimal places
     * @param amount Amount to adjust
     * @param tokenIn Source token address
     * @param tokenOut Destination token address
     * @return adjustedAmount Amount adjusted for decimal differences
     */
    function _adjustDecimals(uint256 amount, address tokenIn, address tokenOut) internal view returns (uint256 adjustedAmount) {
        return GluedMath.adjustDecimals(amount, tokenIn, tokenOut);
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // INTERNAL UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Update contract metadata URI (only owner)
     * @param newContractURI New contract metadata URI
     */
    function _setContractURI(string memory newContractURI) internal {
        string memory oldURI = _contractURI;
        _contractURI = newContractURI;
        emit ContractURIUpdated(oldURI, newContractURI);
    }

    /**
     * @notice Check if an address is a contract
     * @param account Address to check
     * @return True if the address is a contract
     */
    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    /**
     * @notice Safe transfer of ETH
     * @param to Recipient address
     * @param amount Amount of ETH to transfer
     */
    function _safeTransferETH(address to, uint256 amount) internal {
        bool success;
        assembly {
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }
        require(success, "ETH transfer failed");
    }

    /**
     * @notice Safe transfer of ERC20 tokens
     * @param token Token contract address
     * @param to Recipient address
     * @param amount Amount of tokens to transfer
     */
    function _safeTransfer(address token, address to, uint256 amount) internal {
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, to, amount);
        bytes memory returndata = _callOptionalReturn(token, data);
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "ERC20 transfer failed");
        }
    }

    /**
     * @notice Safe transfer from for ERC20 tokens
     * @param token Token contract address
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount of tokens to transfer
     */
    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        bytes memory data = abi.encodeWithSelector(0x23b872dd, from, to, amount);
        bytes memory returndata = _callOptionalReturn(token, data);
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "ERC20 transferFrom failed");
        }
    }

    /**
     * @notice Call a function with optional return data
     * @param target Target contract address
     * @param data Function call data
     * @return returndata Return data from the call
     */
    function _callOptionalReturn(address target, bytes memory data) private returns (bytes memory returndata) {
        require(_isContract(target), "Call to non-contract");

        (bool success, bytes memory result) = target.call(data);
        if (success) {
            if (result.length == 0) {
                // Only check `extcodesize` if the call was successful and the return data is empty
                require(_isContract(target), "Call to non-contract");
            }
            return result;
        } else {
            if (result.length > 0) {
                assembly {
                    let returndata_size := mload(result)
                    revert(add(32, result), returndata_size)
                }
            } else {
                revert("Low-level call failed");
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // RECEIVE FUNCTION
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Allow contract to receive ETH
     */
    receive() external payable {}

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // WARNING SECTION - DO NOT DEPLOY TO MAINNET
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * ⚠️  WARNING: DEPLOYING THIS CONTRACT ON MAINNET VIOLATES THE GLUE PROTOCOL LICENSE ⚠️
     * 
     * This MockStickyAsset contract is designed EXCLUSIVELY for testing and development.
     * It allows passing custom glue stick addresses which is FORBIDDEN in production.
     * 
     * LICENSE VIOLATIONS:
     * ❌ Deploying on mainnet = LICENSE VIOLATION
     * ❌ Deploying on production networks = LICENSE VIOLATION
     * ❌ Using custom glue stick addresses in production = LICENSE VIOLATION
     * ❌ Bypassing official glue stick addresses = LICENSE VIOLATION
     * 
     * PERMITTED USES:
     * ✅ Local testing and development ONLY
     * ✅ Test networks with mock data ONLY
     * ✅ Integration testing in controlled environments ONLY
     * 
     * For production deployments:
     * 1. Use the official StickyAsset.sol contract
     * 2. Ensure it references the official deployed glue stick addresses
     * 3. Follow all Glue Protocol license requirements
     * 
     * ⚠️  WARNING: DEPLOYING THIS CONTRACT ON MAINNET VIOLATES THE GLUE PROTOCOL LICENSE ⚠️
     */
} 