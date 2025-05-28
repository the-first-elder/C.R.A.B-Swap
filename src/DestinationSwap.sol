// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// source: https://github.com/Uniswap/v3-periphery/blob/0682387198a24c7cd63566a2c58398533860a5d1/contracts/interfaces/ISwapRouter.sol#L9
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract GenerateMessageHelper {
    using SafeERC20 for IERC20;

    struct Call {
        address target;
        bytes callData;
        uint256 value;
    }

    struct Instructions {
        // Calls that will be attempted.
        Call[] calls;
        // Where the tokens go if any part of the call fails.
        // Leftover tokens are sent here as well if the action succeeds.
        address fallbackRecipient;
    }

    /**
     * @notice Generates encoded message for Uniswap swap via multicall handler
     * @param userAddress Address of the user who will receive swap results
     * @param uniswapSwapRouter Address of the Uniswap SwapRouter contract
     * @param swapParams Parameters for the Uniswap swap
     * @return bytes Encoded instructions for multicall handler
     */
    function generateMessageForMulticallHandler(
        address userAddress,
        ISwapRouter uniswapSwapRouter,
        ISwapRouter.ExactInputSingleParams memory swapParams
    ) public pure returns (bytes memory) {
        require(userAddress != address(0), "Invalid user address");
        require(address(uniswapSwapRouter) != address(0), "Invalid router address");
        require(swapParams.tokenIn != address(0), "Invalid tokenIn address");

        // Generate approve calldata for the token being swapped
        bytes memory approveCalldata =
            abi.encodeWithSelector(IERC20.approve.selector, address(uniswapSwapRouter), swapParams.amountIn);

        // Generate swap calldata
        bytes memory swapCalldata = abi.encodeWithSelector(ISwapRouter.exactInputSingle.selector, swapParams);

        // Create calls array with exact size
        Call[] memory calls = new Call[](2);
        calls[0] = Call({target: swapParams.tokenIn, callData: approveCalldata, value: 0});
        calls[1] = Call({target: address(uniswapSwapRouter), callData: swapCalldata, value: 0});

        Instructions memory instructions = Instructions({calls: calls, fallbackRecipient: userAddress});

        return abi.encode(instructions);
    }

    /**
     * @notice Generates encoded message for custom handler
     * @param userAddress Address of the user
     * @return bytes Encoded user address
     */
    function generateMessageForCustomhandler(address userAddress) public pure returns (bytes memory) {
        require(userAddress != address(0), "Invalid user address");
        return abi.encode(userAddress);
    }
}
