// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDeltaLibrary, BalanceDelta} from "v4-core/types/BalanceDelta.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";

import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";

import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Currency} from "v4-core/types/Currency.sol";

import {CurrencySettler} from "v4-periphery/lib/v4-core/test/utils/CurrencySettler.sol";

import {IWETH9} from "v4-periphery/src/interfaces/external/IWETH9.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {console2} from "forge-std/console2.sol";
import {CrabSwap} from "./CrabSwap.sol";

interface SpokePoolInterface {
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        int64 relayerFeePct,
        uint32 quoteTimestamp,
        bytes memory message,
        uint256 maxCount
    ) external payable;
}

contract CrabHook is BaseHook {
    using CurrencySettler for Currency;

    CrabSwap crab;
    address constant CurrentChainSpokePool = address(0);

    struct ChainInfo {
        address spokePool;
        uint256 chainID;
        address chainRecipient;
    }

    struct SwapInstruction {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        address recipient;
        uint256 minAmountOut;
        uint256 deadline;
    }

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

    // Initialize BaseHook and ERC20
    constructor(IPoolManager _manager, CrabSwap _crab) BaseHook(_manager) {
        crab = CrabSwap(_crab);
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterAddLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: true,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _beforeSwap(address sender, PoolKey calldata key, SwapParams calldata swapParams, bytes calldata extradata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        address base = swapParams.zeroForOne ? Currency.unwrap(key.currency0) : Currency.unwrap(key.currency1);
        address quote = swapParams.zeroForOne ? Currency.unwrap(key.currency1) : Currency.unwrap(key.currency0);
        bool useCrab = abi.decode(extradata, (bool));
        if (useCrab) {
            try crab.getBestPrice(base, quote) returns (int256 bestPrice, address chain) {
                CrabSwap.ChainInfo memory info = crab.getChainInfo(chain);

                bytes memory message = abi.encode(
                    ExactInputSingleParams({
                        tokenIn: base,
                        tokenOut: quote,
                        fee: 0,
                        recipient: tx.origin,
                        deadline: block.timestamp + 1 hours,
                        amountIn: uint256(swapParams.amountSpecified),
                        amountOutMinimum: uint256(swapParams.amountSpecified) - (uint256(swapParams.amountSpecified) / 10), // 10% slippage
                        sqrtPriceLimitX96: 0 // No price limit
                    })
                );

                ERC20(base).approve(address(CurrentChainSpokePool), uint256(swapParams.amountSpecified));

                (bool success,) = address(CurrentChainSpokePool).call(
                    abi.encodeWithSelector(
                        SpokePoolInterface.deposit.selector,
                        info.chainRecipient,
                        base,
                        uint256(swapParams.amountSpecified),
                        info.chainID,
                        500,
                        uint32(block.timestamp),
                        message,
                        0
                    )
                );
                if (success) {
                    // Deposit worked → absorb swap so v4 doesn't run
                    console2.log("success ignoring v4");
                    int128 inAmount = int128(uint128(uint256(swapParams.amountSpecified)));

                    BeforeSwapDelta deltas = toBeforeSwapDelta(
                        swapParams.zeroForOne ? -inAmount : int128(0), // token0 delta
                        swapParams.zeroForOne ? int128(0) : -inAmount // token1 delta
                    );
                    return (this.beforeSwap.selector, deltas, 0);
                } else {
                    console2.log("Bridge failed, falling back to v4");
                    BeforeSwapDelta deltas = toBeforeSwapDelta(0, 0);
                    return (this.beforeSwap.selector, deltas, 0);
                }
            } catch {
                console2.log("exitedd");
                BeforeSwapDelta deltas = toBeforeSwapDelta(0, 0);
                return (this.beforeSwap.selector, deltas, 0);
            }
        } else {
            console2.log("using univ4 swap");
            BeforeSwapDelta deltas = toBeforeSwapDelta(0, 0);
            return (this.beforeSwap.selector, deltas, 0);
        }
    }

    receive() external payable {}
}
