// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/HoneyTokenFactory.sol";
import "../src/MiniUniswapV2Pool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWBERA {
    function deposit() external payable;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

contract HoneyTokenFactoryTest is Test {
    HoneyTokenFactory public factory;
    IWBERA public wbera;
    address public alice = address(1);
    address public bob = address(2);

    address constant WBERA_ADDRESS = 0x7507c1dc16935B82698e4C63f2746A2fCf994dF8;
    address constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function setUp() public {
        // Fork Berachain
        vm.createSelectFork(vm.rpcUrl("berachain"));

        wbera = IWBERA(WBERA_ADDRESS);
        factory = new HoneyTokenFactory();

        // Fund test accounts with BERA and wrap to WBERA
        vm.deal(alice, 100000 * 10**18);
        vm.deal(bob, 100000 * 10**18);

        vm.startPrank(alice);
        wbera.deposit{value: 50000 * 10**18}();
        vm.stopPrank();

        vm.startPrank(bob);
        wbera.deposit{value: 50000 * 10**18}();
        vm.stopPrank();
    }

    function testCreateMemecoin() public {
        vm.startPrank(alice);
        bytes memory data = abi.encode(
            HoneyTokenFactory.Token({
                id: 0,
                decimals: 18,
                name: "TestCoin",
                symbol: "TEST",
                memeUrl: "https://example.com/meme.jpg",
                token: address(0),
                deployer: address(0),
                swapPool: address(0)
            })
        );
        (address token, address swapPool) = factory.createMemecoin(data);
        vm.stopPrank();

        assertNotEq(token, address(0), "Token address should not be zero");
        assertNotEq(swapPool, address(0), "SwapPool address should not be zero");
        assertEq(factory.tokenCount(), 1, "Token count should be 1");

        HoneyTokenFactory.Token memory createdToken = factory.tokens(1);
        assertEq(createdToken.name, "TestCoin", "Token name should match");
        assertEq(createdToken.symbol, "TEST", "Token symbol should match");
        assertEq(createdToken.deployer, alice, "Deployer should be alice");
    }

    function testAddLiquidity() public {
        // First, create a memecoin
        vm.startPrank(alice);
        bytes memory data = abi.encode(
            HoneyTokenFactory.Token({
                id: 0,
                decimals: 18,
                name: "TestCoin",
                symbol: "TEST",
                memeUrl: "https://example.com/meme.jpg",
                token: address(0),
                deployer: address(0),
                swapPool: address(0)
            })
        );
        (address token, address swapPool) = factory.createMemecoin(data);

        // Approve tokens for liquidity
        wbera.approve(address(factory), 1000 * 10**18);
        ERC20(token).approve(address(factory), 1000 * 10**18);

        // Add liquidity
        factory.addLiquidity(1, 1000 * 10**18, 1000 * 10**18);
        vm.stopPrank();

        // Check liquidity was added
        assertEq(ERC20(swapPool).balanceOf(alice) > 0, true, "Liquidity tokens should be minted");
    }

    function testSwapWBERAForToken() public {
        // Setup: Create memecoin and add liquidity
        vm.startPrank(alice);
        bytes memory data = abi.encode(
            HoneyTokenFactory.Token({
                id: 0,
                decimals: 18,
                name: "TestCoin",
                symbol: "TEST",
                memeUrl: "https://example.com/meme.jpg",
                token: address(0),
                deployer: address(0),
                swapPool: address(0)
            })
        );
        (address token, ) = factory.createMemecoin(data);
        wbera.approve(address(factory), 1000 * 10**18);
        ERC20(token).approve(address(factory), 1000 * 10**18);
        factory.addLiquidity(1, 1000 * 10**18, 1000 * 10**18);
        vm.stopPrank();

        // Perform swap
        vm.startPrank(bob);
        wbera.approve(address(factory), 100 * 10**18);
        uint256 initialBalance = ERC20(token).balanceOf(bob);
        factory.swapWBERAForToken(1, 100 * 10**18, 90 * 10**18);
        uint256 finalBalance = ERC20(token).balanceOf(bob);
        vm.stopPrank();

        assertGt(finalBalance, initialBalance, "Token balance should increase after swap");
    }

    function testSwapTokenForWBERA() public {
        // Setup: Create memecoin and add liquidity
        vm.startPrank(alice);
        bytes memory data = abi.encode(
            HoneyTokenFactory.Token({
                id: 0,
                decimals: 18,
                name: "TestCoin",
                symbol: "TEST",
                memeUrl: "https://example.com/meme.jpg",
                token: address(0),
                deployer: address(0),
                swapPool: address(0)
            })
        );
        (address token, ) = factory.createMemecoin(data);
        wbera.approve(address(factory), 1000 * 10**18);
        ERC20(token).approve(address(factory), 1000 * 10**18);
        factory.addLiquidity(1, 1000 * 10**18, 1000 * 10**18);
        vm.stopPrank();

        // Transfer some tokens to Bob for swapping
        vm.prank(alice);
        ERC20(token).transfer(bob, 100 * 10**18);

        // Perform swap
        vm.startPrank(bob);
        ERC20(token).approve(address(factory), 100 * 10**18);
        uint256 initialBalance = wbera.balanceOf(bob);
        factory.swapTokenForWBERA(1, 100 * 10**18, 90 * 10**18);
        uint256 finalBalance = wbera.balanceOf(bob);
        vm.stopPrank();

        assertGt(finalBalance, initialBalance, "WBERA balance should increase after swap");
    }

    function testGetSwapPool() public {
        vm.startPrank(alice);
        bytes memory data = abi.encode(
            HoneyTokenFactory.Token({
                id: 0,
                decimals: 18,
                name: "TestCoin",
                symbol: "TEST",
                memeUrl: "https://example.com/meme.jpg",
                token: address(0),
                deployer: address(0),
                swapPool: address(0)
            })
        );
        (,address expectedSwapPool) = factory.createMemecoin(data);
        vm.stopPrank();

        address actualSwapPool = factory.getSwapPool(1);
        assertEq(actualSwapPool, expectedSwapPool, "getSwapPool should return the correct swap pool address");
    }
}