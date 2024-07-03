// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";

import {HoneyTokenFactory} from "../src/HoneyTokenFactory.sol";


contract HoneyTokenFactoryTest is DSTest {
    HoneyTokenFactory factory;

    function setUp() public {
        factory = new HoneyTokenFactory();
    }

    function testDeployMemecoinAndCreateLiquidity() public {
        HoneyTokenFactory.Token memory token = HoneyTokenFactory.Token({
            id: 0,
            decimals: 18,
            name: "Memecoin",
            symbol: "MEME",
            memeUrl: "https://meme.com",
            token: address(0),
            deployer: address(0),
            swapPool: address(0),
            supply: 1000
        });
        (address tokenAddress, address swapPool) = factory.createMemecoin(abi.encode(token));

        assertEq(tokenAddress, address(0));
        assertEq(swapPool, address(0));
    }

}