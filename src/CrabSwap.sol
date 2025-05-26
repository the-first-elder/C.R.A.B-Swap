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

import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";
import {CurrencySettler} from "v4-periphery/lib/v4-core/test/utils/CurrencySettler.sol";
import {IWETH9} from "v4-periphery/src/interfaces/external/IWETH9.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

import {console} from "forge-std/console.sol";

contract CrabSwap {
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencySettler for Currency;
    // Use CurrencyLibrary and BalanceDeltaLibrary
    // to add some helper functions over the Currency and BalanceDelta
    // data types
    using CurrencyLibrary for Currency;
    using BalanceDeltaLibrary for BalanceDelta;

    IPoolManager poolManager;

    struct CallbackData {
        address user;
        PoolKey key;
        SwapParams params;
        bytes hookData;
    }

    address[] public supportedChains;
    mapping(address => string) public chainName;
    mapping(address chain => mapping(address quote => mapping(address base => bytes32 tokenId))) public chainToTokenId;

    constructor(IPoolManager _manager) {
        poolManager = _manager;
    }

    function addTokenInfo(address _chain, string memory _chainName, address _quote,address _base, bytes32 _tokenId)
        external
    {
        chainToTokenId[_chain][_quote][_base] = _tokenId;
        supportedChains.push(_chain);
        chainName[_chain] = _chainName;
    }

    function getBestPrice(address quote, address base) public view returns (int256 bestPrice, address chain) {
        int256 highestPrice = 0;
        address bestChain;
        for (uint256 i = 0; i < supportedChains.length; i++) {
            address chain = supportedChains[i];
            bytes32 tokenId = chainToTokenId[chain][quote][base];
            if (tokenId == bytes32(0)) continue; // Skip if no token ID found for this chain

            bytes32 priceFeedId = tokenId;
            PythStructs.Price memory pythPrice = IPyth(chain).getPriceNoOlderThan(priceFeedId, 60);

            // Convert price to uint256 for comparison
            int256 currentPrice = int256(pythPrice.price);

            // Update highest price if current price is higher
            if (currentPrice > highestPrice) {
                highestPrice = currentPrice;
                bestChain = chain;
            }
        }

        // require(highestPrice > 0, "No valid price found");
        return (highestPrice, bestChain);
    }

    function swap(PoolKey memory key, SwapParams memory params, bytes calldata hookData)
        external
        returns (BalanceDelta swapDelta)
    {
        ERC20(Currency.unwrap(params.zeroForOne ? key.currency0 : key.currency1)).transferFrom(
            msg.sender, address(this), uint256(params.amountSpecified)
        );
        // Encode callback data
        bytes memory callbackData = abi.encode(CallbackData(msg.sender, key, params, hookData));

        // Call `unlock()`, which triggers `unlockCallback()`
        swapDelta = abi.decode(poolManager.unlock(callbackData), (BalanceDelta));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(poolManager), "Only PoolManager can call");

        CallbackData memory callbackData = abi.decode(data, (CallbackData));

        // Execute the swap inside the callback
        BalanceDelta swapDelta = poolManager.swap(callbackData.key, callbackData.params, callbackData.hookData);
        int256 delta0 = swapDelta.amount0();
        int256 delta1 = swapDelta.amount1();
        console.log("delta0 ", delta0);
        console.log("delta 1", delta1);

        if (delta0 < 0) {
            callbackData.key.currency0.settle(poolManager, callbackData.user, uint256(-delta0), false);
        }
        if (delta1 < 0) {
            callbackData.key.currency1.settle(poolManager, callbackData.user, uint256(-delta1), false);
        }

        if (delta0 > 0) {
            callbackData.key.currency0.take(poolManager, callbackData.user, uint256(delta0), false);
        }

        if (delta1 > 0) {
            callbackData.key.currency1.take(poolManager, callbackData.user, uint256(delta1), false);
        }

        return abi.encode(swapDelta);
    }

    receive() external payable {}
}
