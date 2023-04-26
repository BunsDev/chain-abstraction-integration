// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDCAHubPositionHandler, IDCAPermissionManager} from "@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol";

import {SwapAndXCall} from "../../../origin/Swap/SwapAndXCall.sol";
import {TestHelper} from "../../utils/TestHelper.sol";
import {UniV2Swapper} from "../../../shared/Swap/Uniswap/UniV2Swapper.sol";
import {UniV3Swapper} from "../../../shared/Swap/Uniswap/UniV3Swapper.sol";
import {MeanFinanceTarget} from "../../../integration/MeanFinance/MeanFinanceTarget.sol";

import "forge-std/console.sol";

contract MeanFinanceTargetTest is TestHelper {
  SwapAndXCall swapAndXCall;
  UniV2Swapper uniV2Swapper;
  UniV3Swapper uniV3Swapper;
  MeanFinanceTarget meanFinanceTarget;

  // OPTIMISM ADDRESSES
  address public immutable OP_OP = 0x4200000000000000000000000000000000000042;
  address public immutable OP_USDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
  address public immutable OP_OP_WHALE = 0x2501c477D0A35545a387Aa4A3EEe4292A9a8B3F0;
  address public immutable OP_ONEINCH_SWAPPER = 0x1111111254EEB25477B68fb85Ed929f73A960582;

  // BNB ADDRESSES
  address public immutable BNB_USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
  address public immutable BNB_WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
  address public immutable BNB_USDC_WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
  address public immutable BNB_MEAN_HUB = 0xA5AdC5484f9997fBF7D405b9AA62A7d88883C345;
  address public immutable BNB_UNIV2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

  // POLYGON ADDRESSES
  address public immutable POLYGON_USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address public immutable POLYGON_WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
  address public immutable POLYGON_USDC_WHALE = 0x1205f31718499dBf1fCa446663B532Ef87481fe1;
  address public immutable POLYGON_MEAN_HUB = 0xA5AdC5484f9997fBF7D405b9AA62A7d88883C345;
  address public immutable POLYGON_UNIV2_ROUTER = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Quickswap Router
  address public immutable POLYGON_UNIV3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // UniswapV3 Router

  address public immutable FALLBACK_ADDRESS = address(1);
  address public immutable OWNER_ADDRESS = address(2);

  function utils_setUpOptimismForOrigin() public {
    setUpOptimism(87307161);
    swapAndXCall = new SwapAndXCall(CONNEXT_OPTIMISM);
    vm.prank(OP_OP_WHALE);
    TransferHelper.safeTransfer(OP_OP, address(this), 1000 ether);

    vm.label(address(swapAndXCall), "SwapAndXCall");
    vm.label(address(this), "MeanFinanceTargetTest");
    vm.label(OP_OP, "OP_OP");
    vm.label(OP_USDC, "OP_USDC");
    vm.label(OP_OP_WHALE, "OP_OP_WHALE");
  }

  function utils_setUpBNBForDestination() public {
    setUpBNB(27284448);
    uniV2Swapper = new UniV2Swapper(BNB_UNIV2_ROUTER);
    meanFinanceTarget = new MeanFinanceTarget(CONNEXT_BNB, BNB_MEAN_HUB);
    meanFinanceTarget.addSwapper(address(uniV2Swapper));

    vm.label(address(uniV2Swapper), "BNB_UniV2Swapper");
    vm.label(BNB_UNIV2_ROUTER, "BNB_UniV2Router");
    vm.label(BNB_WBNB, "BNB_WBNB");
    vm.label(BNB_USDC, "BNB_USDC");
  }

  function utils_setUpPolygonForDestination() public {
    setUpPolygon(41491942);
    uniV3Swapper = new UniV3Swapper(POLYGON_UNIV3_ROUTER);
    uniV2Swapper = new UniV2Swapper(POLYGON_UNIV2_ROUTER);
    meanFinanceTarget = new MeanFinanceTarget(CONNEXT_POLYGON, POLYGON_MEAN_HUB);
    meanFinanceTarget.addSwapper(address(uniV3Swapper));
    meanFinanceTarget.addSwapper(address(uniV2Swapper));

    vm.label(address(uniV3Swapper), "Polygon_UniV3Swapper");
    vm.label(address(uniV2Swapper), "Polygon_UniV2Swapper");
    vm.label(POLYGON_UNIV3_ROUTER, "Polygon_UniV3Router");
    vm.label(POLYGON_UNIV2_ROUTER, "Polygon_UniV2Router");
    vm.label(POLYGON_USDC, "POLYGON_USDC");
    vm.label(POLYGON_WETH, "POLYGON_WETH");
  }

  function test_MeanFinanceTargetTest__worksFromOptimismToBNB() public {
    utils_setUpOptimismForOrigin();
    utils_setUpBNBForDestination();

    vm.selectFork(optimismForkId);
    assertEq(vm.activeFork(), optimismForkId);

    // origin
    // start with OP and swap to USDC to bridge to destination
    TransferHelper.safeApprove(OP_OP, address(swapAndXCall), 1000 ether);
    bytes
      memory oneInchApiDataOpToUsdc = hex"12aa3caf000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a00000000000000000000000042000000000000000000000000000000000000420000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c31607000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f00000000000000000000000000000000000000000000003635c9adc5dea000000000000000000000000000000000000000000000000000000000000078f1ff510000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000097c00000000000000000000000000000000000000095e0009300008e60008cc00a0c9e75c480000000000000007020100000000000000000000000000000000000000000000089e0006d100032700a007e5c0d200000000000000000000000000000000000000000000030300021c0001cd00a0c9e75c4800000000000000002a0800000000000000000000000000000000000000000000000000019f00004f02a0000000000000000000000000000000000000000000000000003e23993ea6ce3cee63c1e500fc1f3296458f9b2a27a0b91dd7681c4020e09d0542000000000000000000000000000000000000425126a132dab612db5cb9fc9ac426a0cc215a3423f9c942000000000000000000000000000000000000420004f41766d800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000146409db6c1079d00000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a000000000000000000000000000000000000000000000000000000006436df18000000000000000000000000000000000000000000000000000000000000000100000000000000000000000042000000000000000000000000000000000000420000000000000000000000004200000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000b005cef732b384620ee63c1e50195d9d28606ee55de7667f0f176ebfc3215cfd9c0420000000000000000000000000000000000000600a0bd46a34303b5ad7d6d6f92a77f47f98c28c84893fbccc9480900000000000000000000006c43da214fab3315aa6c02e0b8f2bfb7ef2e3c60a50000000000000000000000ae88d07558470484c03d3bb44c3ecc36cafcf43253000000000000000000000051000000000000000000000000da10009cbd5d07dd0cecc66161fc93d7c9000da1000000000000000000000000b5ad7d6d6f92a77f47f98c28c84893fbccc9480900000000000000000000000088d07558470484c03d3bb44c3ecc36cafcf432530000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c3160700a007e5c0d200000000000000000000000000000000000000000000000000038600008e4820a6d7d0e650aa40ffa42d845a354c12c2bc0ab15f42000000000000000000000000000000000000429331621200000000000000000000000042000000000000000000000000000000000000420000000000000000000000004200000000000000000000000000000000000006000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a00a0c9e75c48000000000000000029090000000000000000000000000000000000000000000000000002ca00011c4312f9d5940c2313636546ab9852354860dce275dbad00000000000000000000000000000000000000000000000000000000045a6d40002424b31a0c000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000001000276a400000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000420000000000000000000000000000000000000600a007e5c0d200000000000000000000000000000000000000000000000000018a0000d05120c35dadb65012ec5796536bd9864ed8773abc74c44200000000000000000000000000000000000006006402b9446c0000000000000000000000004200000000000000000000000000000000000006000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a0000000000000000000000007086622e6db990385b102d79cb1218947fb549a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040207086622e6db990385b102d79cb1218947fb549a9627dd56a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000600000000000000000000000004200000000000000000000000000000000000006000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a000000000000000000000000000000000000000000000000000000000000000100a0c9e75c480000000000000000221000000000000000000000000000000000000000000000000000019f00004f02a0000000000000000000000000000000000000000000000000000000001b17ef8fee63c1e5011d751bc1a723accf1942122ca9aa82d49d08d2ae42000000000000000000000000000000000000425126a132dab612db5cb9fc9ac426a0cc215a3423f9c942000000000000000000000000000000000000420004f41766d800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000039913b6500000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a000000000000000000000000000000000000000000000000000000006436df18000000000000000000000000000000000000000000000000000000000000000100000000000000000000000042000000000000000000000000000000000000420000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c3160700000000000000000000000000000000000000000000000000000000000000000020d6bdbf787f5c764cbc14f9669b88837ca1490cca17c3160700a0f2fa6b667f5c764cbc14f9669b88837ca1490cca17c3160700000000000000000000000000000000000000000000000000000000866238220000000000000000000000000098760180a06c4eca277f5c764cbc14f9669b88837ca1490cca17c316071111111254eeb25477b68fb85ed929f73a96058200000000cfee7c08";

    // destination
    // set up destination swap params
    uint256 amountOutMin = 0;
    bytes memory encodedSwapData = abi.encode(amountOutMin);

    address cTokenForWBNB = 0x57a64a77f8E4cFbFDcd22D5551F52D675cc5A956;
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address _from = WBNB;
    address _to = cTokenForWBNB;
    uint32 _amountOfSwaps = 10;
    uint32 _swapInterval = 3600 seconds;
    address _owner = OWNER_ADDRESS;
    IDCAPermissionManager.PermissionSet[] memory permissions = new IDCAPermissionManager.PermissionSet[](1);
    IDCAPermissionManager.Permission[] memory permission = new IDCAPermissionManager.Permission[](1);
    permission[0] = IDCAPermissionManager.Permission.INCREASE;
    permissions[0] = IDCAPermissionManager.PermissionSet(address(10), permission);
    bytes memory _forwardCallData = abi.encode(_from, _to, _amountOfSwaps, _swapInterval, _owner, permissions);

    bytes memory _swapperData = abi.encode(address(uniV2Swapper), WBNB, encodedSwapData, _forwardCallData);

    // final calldata includes both origin and destination swaps
    bytes memory callData = abi.encode(FALLBACK_ADDRESS, _swapperData);
    // set up swap calldata
    swapAndXCall.swapAndXCall(
      OP_OP,
      OP_USDC,
      1000 ether,
      OP_ONEINCH_SWAPPER,
      oneInchApiDataOpToUsdc,
      BNB_DOMAIN_ID,
      address(0x1),
      address(this),
      300,
      callData,
      123 // fake relayer fee, will be in USDC
    );

    vm.selectFork(bnbForkId);
    vm.prank(BNB_USDC_WHALE);
    TransferHelper.safeTransfer(BNB_USDC, address(meanFinanceTarget), 100 ether);
    vm.prank(CONNEXT_BNB);
    meanFinanceTarget.xReceive(
      bytes32(""),
      100 ether, // Final Amount receive via Connext(After AMM calculation)
      BNB_USDC,
      address(0),
      123,
      callData
    );
    assertEq(IERC20(cTokenForWBNB).balanceOf(address(meanFinanceTarget)), 0);
    assertEq(IERC20(BNB_USDC).balanceOf(address(meanFinanceTarget)), 0);
  }

  function test_MeanFinanceTargetTest__worksFromOptimismToPolygon() public {
    utils_setUpOptimismForOrigin();
    utils_setUpPolygonForDestination();

    vm.selectFork(optimismForkId);
    assertEq(vm.activeFork(), optimismForkId);

    // origin
    // start with OP and swap to USDC to bridge to destination
    TransferHelper.safeApprove(OP_OP, address(swapAndXCall), 1000 ether);
    bytes
      memory oneInchApiDataOpToUsdc = hex"12aa3caf000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a00000000000000000000000042000000000000000000000000000000000000420000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c31607000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f00000000000000000000000000000000000000000000003635c9adc5dea000000000000000000000000000000000000000000000000000000000000078f1ff510000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000097c00000000000000000000000000000000000000095e0009300008e60008cc00a0c9e75c480000000000000007020100000000000000000000000000000000000000000000089e0006d100032700a007e5c0d200000000000000000000000000000000000000000000030300021c0001cd00a0c9e75c4800000000000000002a0800000000000000000000000000000000000000000000000000019f00004f02a0000000000000000000000000000000000000000000000000003e23993ea6ce3cee63c1e500fc1f3296458f9b2a27a0b91dd7681c4020e09d0542000000000000000000000000000000000000425126a132dab612db5cb9fc9ac426a0cc215a3423f9c942000000000000000000000000000000000000420004f41766d800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000146409db6c1079d00000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a000000000000000000000000000000000000000000000000000000006436df18000000000000000000000000000000000000000000000000000000000000000100000000000000000000000042000000000000000000000000000000000000420000000000000000000000004200000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000002a000000000000000000000000000000000000000000000000b005cef732b384620ee63c1e50195d9d28606ee55de7667f0f176ebfc3215cfd9c0420000000000000000000000000000000000000600a0bd46a34303b5ad7d6d6f92a77f47f98c28c84893fbccc9480900000000000000000000006c43da214fab3315aa6c02e0b8f2bfb7ef2e3c60a50000000000000000000000ae88d07558470484c03d3bb44c3ecc36cafcf43253000000000000000000000051000000000000000000000000da10009cbd5d07dd0cecc66161fc93d7c9000da1000000000000000000000000b5ad7d6d6f92a77f47f98c28c84893fbccc9480900000000000000000000000088d07558470484c03d3bb44c3ecc36cafcf432530000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c3160700a007e5c0d200000000000000000000000000000000000000000000000000038600008e4820a6d7d0e650aa40ffa42d845a354c12c2bc0ab15f42000000000000000000000000000000000000429331621200000000000000000000000042000000000000000000000000000000000000420000000000000000000000004200000000000000000000000000000000000006000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a00a0c9e75c48000000000000000029090000000000000000000000000000000000000000000000000002ca00011c4312f9d5940c2313636546ab9852354860dce275dbad00000000000000000000000000000000000000000000000000000000045a6d40002424b31a0c000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000001000276a400000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000420000000000000000000000000000000000000600a007e5c0d200000000000000000000000000000000000000000000000000018a0000d05120c35dadb65012ec5796536bd9864ed8773abc74c44200000000000000000000000000000000000006006402b9446c0000000000000000000000004200000000000000000000000000000000000006000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a0000000000000000000000007086622e6db990385b102d79cb1218947fb549a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040207086622e6db990385b102d79cb1218947fb549a9627dd56a000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000600000000000000000000000004200000000000000000000000000000000000006000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a000000000000000000000000000000000000000000000000000000000000000100a0c9e75c480000000000000000221000000000000000000000000000000000000000000000000000019f00004f02a0000000000000000000000000000000000000000000000000000000001b17ef8fee63c1e5011d751bc1a723accf1942122ca9aa82d49d08d2ae42000000000000000000000000000000000000425126a132dab612db5cb9fc9ac426a0cc215a3423f9c942000000000000000000000000000000000000420004f41766d800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000039913b6500000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000f0694acc9e941b176e17b9ef923e71e7b8b2477a000000000000000000000000000000000000000000000000000000006436df18000000000000000000000000000000000000000000000000000000000000000100000000000000000000000042000000000000000000000000000000000000420000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c3160700000000000000000000000000000000000000000000000000000000000000000020d6bdbf787f5c764cbc14f9669b88837ca1490cca17c3160700a0f2fa6b667f5c764cbc14f9669b88837ca1490cca17c3160700000000000000000000000000000000000000000000000000000000866238220000000000000000000000000098760180a06c4eca277f5c764cbc14f9669b88837ca1490cca17c316071111111254eeb25477b68fb85ed929f73a96058200000000cfee7c08";

    // destination
    // set up destination swap params
    uint24 poolFee = 500;
    uint256 amountOutMin = 0;
    bytes memory encodedSwapData = abi.encode(poolFee, amountOutMin);

    address cTokenForWETH = 0xD809c769A04246855fee98423B180C7CCa6bF07c;
    address WETH = POLYGON_WETH;
    address minter = address(0x1234567890);

    address _from = POLYGON_WETH;
    address _to = cTokenForWETH;
    uint32 _amountOfSwaps = 10;
    uint32 _swapInterval = 3600 seconds;
    address _owner = OWNER_ADDRESS;
    IDCAPermissionManager.PermissionSet[] memory permissions = new IDCAPermissionManager.PermissionSet[](1);
    IDCAPermissionManager.Permission[] memory permission = new IDCAPermissionManager.Permission[](1);
    permission[0] = IDCAPermissionManager.Permission.INCREASE;
    permissions[0] = IDCAPermissionManager.PermissionSet(address(10), permission);
    bytes memory _forwardCallData = abi.encode(_from, _to, _amountOfSwaps, _swapInterval, _owner, permissions);

    bytes memory _swapperData = abi.encode(address(uniV3Swapper), WETH, encodedSwapData, _forwardCallData);

    // final calldata includes both origin and destination swaps
    bytes memory callData = abi.encode(FALLBACK_ADDRESS, _swapperData);
    // set up swap calldata
    swapAndXCall.swapAndXCall(
      OP_OP,
      OP_USDC,
      1000 ether,
      OP_ONEINCH_SWAPPER,
      oneInchApiDataOpToUsdc,
      POLYGON_DOMAIN_ID,
      address(0x1),
      address(this),
      300,
      callData,
      123 // fake relayer fee, will be in USDC
    );

    vm.selectFork(polygonForkId);

    // Trying with univ3swapper
    vm.prank(POLYGON_USDC_WHALE);
    TransferHelper.safeTransfer(POLYGON_USDC, address(meanFinanceTarget), 100000000); // 100 USDC transfer
    assertEq(IERC20(cTokenForWETH).balanceOf(minter), 0);
    vm.prank(CONNEXT_POLYGON);
    meanFinanceTarget.xReceive(bytes32(""), 100000000, POLYGON_USDC, address(0), 123, callData);
    assertEq(IERC20(cTokenForWETH).balanceOf(address(meanFinanceTarget)), 0);
    assertEq(IERC20(POLYGON_USDC).balanceOf(address(meanFinanceTarget)), 0);
    assertGt(IERC20(cTokenForWETH).balanceOf(minter), 0);
  }

  function test_MeanFinanceTargetTest__worksWithSwappersOnPolygon() public {
    utils_setUpPolygonForDestination();

    // destination
    // set up destination swap params
    uint24 poolFee = 500;
    uint256 amountOutMin = 0;
    bytes memory encodedSwapDataForV3 = abi.encode(poolFee, amountOutMin);
    bytes memory encodedSwapDataForV2 = abi.encode(amountOutMin);

    address cTokenForWETH = 0xD809c769A04246855fee98423B180C7CCa6bF07c;
    address WETH = POLYGON_WETH;
    address minter = address(0x1234567890);

    address _from = WETH;
    address _to = cTokenForWETH;
    uint32 _amountOfSwaps = 10;
    uint32 _swapInterval = 3600 seconds;
    address _owner = OWNER_ADDRESS;
    IDCAPermissionManager.PermissionSet[] memory permissions = new IDCAPermissionManager.PermissionSet[](1);
    IDCAPermissionManager.Permission[] memory permission = new IDCAPermissionManager.Permission[](1);
    permission[0] = IDCAPermissionManager.Permission.INCREASE;
    permissions[0] = IDCAPermissionManager.PermissionSet(address(10), permission);
    bytes memory _forwardCallData = abi.encode(_from, _to, _amountOfSwaps, _swapInterval, _owner, permissions);

    bytes memory _swapperDataForV3 = abi.encode(address(uniV3Swapper), WETH, encodedSwapDataForV3, _forwardCallData);
    bytes memory _swapperDataForV2 = abi.encode(address(uniV2Swapper), WETH, encodedSwapDataForV2, _forwardCallData);

    // final calldata includes both origin and destination swaps
    bytes memory callDataForV3 = abi.encode(FALLBACK_ADDRESS, _swapperDataForV3);
    bytes memory callDataForV2 = abi.encode(FALLBACK_ADDRESS, _swapperDataForV2);

    // Trying with univ3swapper
    vm.prank(POLYGON_USDC_WHALE);
    TransferHelper.safeTransfer(POLYGON_USDC, address(meanFinanceTarget), 100000000); // 100 USDC transfer
    assertEq(IERC20(cTokenForWETH).balanceOf(minter), 0);
    vm.prank(CONNEXT_POLYGON);
    meanFinanceTarget.xReceive(bytes32(""), 100000000, POLYGON_USDC, address(0), 123, callDataForV3);
    assertEq(IERC20(cTokenForWETH).balanceOf(address(meanFinanceTarget)), 0);
    assertEq(IERC20(POLYGON_USDC).balanceOf(address(meanFinanceTarget)), 0);
    assertGt(IERC20(cTokenForWETH).balanceOf(minter), 0);

    uint256 cTokenBalanceAfterFirstSwap = IERC20(cTokenForWETH).balanceOf(minter);
    assertGt(cTokenBalanceAfterFirstSwap, 0);

    // Trying with univ2swapper
    vm.prank(POLYGON_USDC_WHALE);
    TransferHelper.safeTransfer(POLYGON_USDC, address(meanFinanceTarget), 100000000); // 100 USDC transfer
    vm.prank(CONNEXT_POLYGON);
    meanFinanceTarget.xReceive(bytes32(""), 100000000, POLYGON_USDC, address(0), 123, callDataForV2);
    assertEq(IERC20(cTokenForWETH).balanceOf(address(meanFinanceTarget)), 0);
    assertEq(IERC20(POLYGON_USDC).balanceOf(address(meanFinanceTarget)), 0);
    assertGt(IERC20(cTokenForWETH).balanceOf(minter), cTokenBalanceAfterFirstSwap);
  }
}
