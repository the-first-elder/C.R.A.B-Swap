// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";

import {PoolManager} from "v4-core/PoolManager.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {V4Quoter} from "v4-periphery/src/lens/V4Quoter.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";

import "forge-std/console.sol";
import {CrabHook} from "../src/CrabHook.sol";
import {CrabSwap} from "../src/CrabSwap.sol";
// import {MockWeth} from "./mock/mockWeth.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

contract TestPointsHook is Test, Deployers {
    CrabHook crabHook;
    // 0xB18eE11849a805651aC5D456034FD6352cfF635d

    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    PoolManager public poolManager;
    // 19492030688782703603
    Currency token0;
    Currency token1;
    V4Quoter public quoter;
    CrabSwap crabSwap;
    address weth = 0xE591bf0A0CF924A0674d7792db046B23CEbF5f34;
    address router = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165; // arb sep
    address link = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
    uint64 destinationChainSelector = 7717148896336251131;
    address mockUser = 0xf89c26A4B5a71283250ae3a28e89dEb3Ed555a1c; // seploia eth whale
    // 0xE591bf0A0CF924A0674d7792db046B23CEbF5f34 weth
    address receiver = 0xC4dC3C1F03EB80E66693Fb75BcDb46F2EdcF67dC; // on holesky
    uint256 amountOfWethToMint = 4 ether;
    address hookAddress;

    function setUp() public {
        deployFreshManagerAndRouters();
        vm.startPrank(mockUser);
        console.log(address(mockUser).balance);
        quoter = new V4Quoter(manager);
        crabSwap = new CrabSwap(manager);
        (token0, token1) = deployMintAndApprove2Currencies();
        MockERC20(Currency.unwrap(token0)).mint(mockUser, 50 ether);
        MockERC20(Currency.unwrap(token1)).mint(mockUser, 50 ether);
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG);
        hookAddress = address(flags);
        deployCodeTo("CrabHook.sol:CrabHook", abi.encode(manager, CrabSwap(crabSwap)), hookAddress);
        crabHook = CrabHook(payable(hookAddress));
        MockERC20(Currency.unwrap(token0)).approve(address(crabSwap), type(uint256).max);
        MockERC20(Currency.unwrap(token1)).approve(address(crabSwap), type(uint256).max);

        // (bool success, bytes memory data) = address(metaFiRouter).call{value: 1 ether}("");
        // require(success, "failed deposit");
        address[9] memory toApprove = [
            address(swapRouter),
            address(swapRouterNoChecks),
            address(modifyLiquidityRouter),
            address(modifyLiquidityNoChecks),
            address(donateRouter),
            address(takeRouter),
            address(claimsRouter),
            address(nestedActionRouter.executor()),
            address(actionsRouter)
        ];

        // for (uint256 i = 0; i < toApprove.length; i++) {
        //     MockWeth(payable(weth)).approve(toApprove[i], type(uint256).max);
        // }
        vm.stopPrank();
    }

    function test_swap() public {
        vm.startBroadcast(mockUser);
        uint24 fee = 3000; // 0.3%
        int24 tickSpacing = 60;
        (PoolKey memory key2, PoolId id2) =
            initPoolAndAddLiquidity(token0, token1, IHooks(address(crabHook)), fee, 1 << 96);
        bool zeroForOne = true;
        SwapParams memory params = SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: 1 ether,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT
        });
        console.log("hook", address(key2.hooks));
        console.log("Expected MetaFi address:", address(crabHook));
        require(address(key2.hooks) == address(crabHook), "Hook address mismatch!");
        console.log(
            "mock token 0 before balance",
            MockERC20(Currency.unwrap(token0)).balanceOf(mockUser),
            MockERC20(Currency.unwrap(token1)).balanceOf(mockUser)
        );
        crabSwap.swap(key2, params, "");
        console.log(
            "after balance",
            MockERC20(Currency.unwrap(token0)).balanceOf(mockUser),
            MockERC20(Currency.unwrap(token1)).balanceOf(mockUser)
        );
        // swap(key2, true, 1 ether, abi.encode(true));
        vm.stopBroadcast();
    }
}
