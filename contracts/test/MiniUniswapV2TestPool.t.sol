// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MiniUniswapV2Pool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWBERA {
    function deposit() external payable;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract MiniUniswapV2PoolTest is Test {
    MiniUniswapV2Pool public pool;
    IWBERA public wbera;
    MockToken public token;
    address public alice = address(1);
    address public bob = address(2);

    address constant WBERA_ADDRESS = 0x7507c1dc16935B82698e4C63f2746A2fCf994dF8; // Berachain WBERA address

    function setUp() public {
        // Fork Berachain
        vm.createSelectFork(vm.rpcUrl("berachain"));

        wbera = IWBERA(WBERA_ADDRESS);
        token = new MockToken();
        pool = new MiniUniswapV2Pool(address(token), WBERA_ADDRESS);

        // Fund test accounts with BERA and wrap to WBERA
        vm.deal(alice, 100000 * 10**18);
        vm.deal(bob, 100000 * 10**18);

        vm.startPrank(alice);
        wbera.deposit{value: 50000 * 10**18}();
        vm.stopPrank();

        vm.startPrank(bob);
        wbera.deposit{value: 50000 * 10**18}();
        vm.stopPrank();

        // Distribute mock tokens
        token.transfer(alice, 50000 * 10**18);
        token.transfer(bob, 50000 * 10**18);
    }

    function testAddLiquidity() public {
        vm.startPrank(alice);
        wbera.approve(address(pool), 1000 * 10**18);
        token.approve(address(pool), 1000 * 10**18);
        wbera.transfer(address(pool), 1000 * 10**18);
        token.transfer(address(pool), 1000 * 10**18);
        uint256 liquidity = pool.addLiquidity();
        vm.stopPrank();

        assertEq(pool.reserve0(), 1000 * 10**18);
        assertEq(pool.reserve1(), 1000 * 10**18);
        assertEq(pool.balanceOf(alice), 1000 * 10**18);
    }

    function testRemoveLiquidity() public {
        vm.startPrank(alice);
        wbera.approve(address(pool), 1000 * 10**18);
        token.approve(address(pool), 1000 * 10**18);
        wbera.transfer(address(pool), 1000 * 10**18);
        token.transfer(address(pool), 1000 * 10**18);
        uint256 liquidity = pool.addLiquidity();
        (uint256 amount0, uint256 amount1) = pool.removeLiquidity(liquidity);
        vm.stopPrank();

        assertEq(pool.reserve0(), 0);
        assertEq(pool.reserve1(), 0);
        assertEq(pool.balanceOf(alice), 0);
        assertEq(amount0, 1000 * 10**18);
        assertEq(amount1, 1000 * 10**18);
    }

    function testSwapWBERAForToken() public {
        vm.startPrank(alice);
        wbera.approve(address(pool), 1000 * 10**18);
        token.approve(address(pool), 1000 * 10**18);
        wbera.transfer(address(pool), 1000 * 10**18);
        token.transfer(address(pool), 1000 * 10**18);
        pool.addLiquidity();
        vm.stopPrank();

        vm.startPrank(bob);
        wbera.approve(address(pool), 100 * 10**18);
        wbera.transfer(address(pool), 100 * 10**18);
        uint256 tokensBought = pool.swapWBERAForToken(90 * 10**18);
        vm.stopPrank();

        assertGt(tokensBought, 90 * 10**18);
        assertLt(tokensBought, 100 * 10**18);
    }

    function testSwapTokenForWBERA() public {
        vm.startPrank(alice);
        wbera.approve(address(pool), 1000 * 10**18);
        token.approve(address(pool), 1000 * 10**18);
        wbera.transfer(address(pool), 1000 * 10**18);
        token.transfer(address(pool), 1000 * 10**18);
        pool.addLiquidity();
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(pool), 100 * 10**18);
        uint256 wberaBought = pool.swapTokenForWBERA(100 * 10**18, 90 * 10**18);
        vm.stopPrank();

        assertGt(wberaBought, 90 * 10**18);
        assertLt(wberaBought, 100 * 10**18);
    }

    function testGetAmountOut() public {
        uint256 amountOut = pool.getAmountOut(1 * 10**18, 10 * 10**18, 100 * 10**18);
        assertEq(amountOut, 9070243291925465838);
    }

    function testFailInsufficientLiquidity() public {
        vm.prank(bob);
        pool.swapWBERAForToken(90 * 10**18);
    }
}