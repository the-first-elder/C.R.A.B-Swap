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

contract CrabHook is BaseHook {
    CrabSwap crab;
    // Initialize BaseHook and ERC20

    constructor(IPoolManager _manager,CrabSwap _crab) BaseHook(_manager) {
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
            beforeSwapReturnDelta: false,
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
        (int256 bestPrice, address chain) = crab.getBestPrice(Currency.unwrap(key.currency0), Currency.unwrap(key.currency1));
        console2.log("bestprice",bestPrice);
        
        // Get the current price, tick, and liquidity from the pool
        // (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(key.toId());
        // uint128 liquidity = poolManager.getLiquidity(key.toId());
        // uint24 feePips = key.fee; // Retrieve the fee

        // Set target price for the swap direction
        uint160 sqrtPriceTargetX96 = swapParams.zeroForOne ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1;

        // The hook must not return a delta unless `beforeSwapReturnDelta` is enabled.
        // So we return zero deltas.
        BeforeSwapDelta deltas = toBeforeSwapDelta(0, 0);
        return (this.beforeSwap.selector, deltas, 0);
    }

    // function _afterSwap(
    //     address sender,
    //     PoolKey calldata key,
    //     IPoolManager.SwapParams calldata swapParams,
    //     BalanceDelta delta,
    //     bytes calldata extraData
    // ) internal override returns (bytes4, int128) {
    //     console2.log("maybe");
    //     bool stakeOnEigen = abi.decode(extraData, (bool));

    //     uint256 amountReceived;
    //     address tokenReceived;

    //     if (delta.amount0() > 0) {
    //         amountReceived = uint256(int256(delta.amount0()));
    //         tokenReceived = Currency.unwrap(key.currency0);
    //     } else {
    //         amountReceived = uint256(int256(delta.amount1()));
    //         tokenReceived = Currency.unwrap(key.currency1);
    //     }
    //     // console2.log("sender", sender, address(this), tx.origin);
    //     // Store the swap info
    //     // pendingTransfers[tx.origin] = SwapInfo({token: tokenReceived, amount: amountReceived});
    //     return (this.afterSwap.selector, 0);
    // }

    receive() external payable {}
}
