// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MiniUniswapV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract MiniUniswapV2TestPool is Test {
    MiniUniswapV2Pool public uniswap;
    MockToken public token;
    address public alice = address(1);
    address public bob = address(2);

    function setUp() public {
        token = new MockToken();
        uniswap = new MiniUniswapV2(address(token));

        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        token.transfer(alice, 50000 * 10**18);
        token.transfer(bob, 50000 * 10**18);
    }

    function testAddLiquidity() public {
        vm.startPrank(alice);
        token.approve(address(uniswap), 1000 * 10**18);
        token.transfer(address(uniswap), 1000 * 10**18);
        uniswap.addLiquidity{value: 1 ether}();
        vm.stopPrank();

        assertEq(uniswap.reserve0(), 1 ether);
        assertEq(uniswap.reserve1(), 1000 * 10**18);
        assertEq(uniswap.balanceOf(alice), 1000 * 10**9);
    }

    function testRemoveLiquidity() public {
        vm.startPrank(alice);
        token.approve(address(uniswap), 1000 * 10**18);
        token.transfer(address(uniswap), 1000 * 10**18);
        uniswap.addLiquidity{value: 1 ether}();
        uint liquidity = uniswap.balanceOf(alice);
        uniswap.removeLiquidity(liquidity);
        vm.stopPrank();

        assertEq(uniswap.reserve0(), 0);
        assertEq(uniswap.reserve1(), 0);
        assertEq(uniswap.balanceOf(alice), 0);
    }

    function testSwapBERAForToken() public {
        vm.startPrank(alice);
        token.approve(address(uniswap), 1000 * 10**18);
        token.transfer(address(uniswap), 1000 * 10**18);
        uniswap.addLiquidity{value: 1 ether}();
        vm.stopPrank();

        vm.prank(bob);
        uniswap.swapBERAForToken{value: 0.1 ether}(90 * 10**18);

        assertGt(token.balanceOf(bob), 90 * 10**18);
        assertLt(token.balanceOf(bob), 100 * 10**18);
    }

    function testSwapTokenForBERA() public {
        vm.startPrank(alice);
        token.approve(address(uniswap), 1000 * 10**18);
        token.transfer(address(uniswap), 1000 * 10**18);
        uniswap.addLiquidity{value: 1 ether}();
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(uniswap), 100 * 10**18);
        uniswap.swapTokenForBERA(100 * 10**18, 0.09 ether);
        vm.stopPrank();

        assertGt(bob.balance, 100.09 ether);
        assertLt(bob.balance, 100.1 ether);
    }

    function testFailInsufficientLiquidity() public {
        vm.prank(bob);
        uniswap.swapBERAForToken{value: 0.1 ether}(90 * 10**18);
    }

    function testGetAmountOut() public {
        uint amountOut = uniswap.getAmountOut(1 ether, 10 ether, 100 * 10**18);
        assertEq(amountOut, 9070243291925465838391);
    }

    receive() external payable {}
}