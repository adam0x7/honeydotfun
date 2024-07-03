// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {LilUniswapV2} from "./LilUniswapV2.sol";

interface IWBERA {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface ILilUniswapV2 {
    function addLiquidity() external returns (uint256 liquidity);
    function swapWBERAForToken(uint256 minTokens) external returns (uint256 tokensBought);
    function swapTokenForWBERA(uint256 tokenAmount, uint256 minWBERA) external returns (uint256 wberaBought);
}

interface ICreate2Deployer {
    function deployWithCreate2(uint256 salt, bytes memory initCode) external returns (address);
    function getCreate2Address(uint256 salt, bytes32 initCodeHash) external pure returns (address);
}

contract HoneyTokenFactory is Owned {

    event TokenCreated(uint256 indexed id, string name, string memeUrl, address token, address deployer, address swapPool);
    event LiquidityAdded(uint256 indexed tokenId, address user, uint256 wberaAmount, uint256 memeAmount);

    address public constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    address public constant WBERA_ADDRESS = 0x7507c1dc16935B82698e4C63f2746A2fCf994dF8;
    IWBERA public immutable wbera;

    struct Token {
        uint256 id;
        uint256 decimals;
        string name;
        string symbol;
        string memeUrl;
        address token;
        address deployer;
        address swapPool;
    }

    mapping(uint256 => Token) public tokens;
    uint256 public tokenCount;

    constructor() Owned(msg.sender) {
        wbera = IWBERA(WBERA_ADDRESS);
    }

    function createMemecoin(bytes calldata data) external returns(address, address) {
        Token memory newToken = abi.decode(data, (Token));

        // Deploy new ERC20 token
        ERC20 token = new ERC20(newToken.name, newToken.symbol);


        bytes memory lilUniswapV2InitCode = abi.encodePacked(
            type(LilUniswapV2).creationCode,
            abi.encode(token, WBERA_ADDRESS)
        );
        uint256 poolSalt = uint256(keccak256(abi.encodePacked(tokenCount, msg.sender, newToken.name, newToken.symbol)));

        address swapPool = CREATE2_FACTORY.deployWithCreate2(poolSalt, lilUniswapV2InitCode);

        newToken.token = token;
        newToken.deployer = msg.sender;
        newToken.swapPool = swapPool;
        newToken.id = ++tokenCount;
        tokens[newToken.id] = newToken;

        emit TokenCreated(newToken.id, newToken.name, newToken.memeUrl, token, msg.sender, swapPool);

        return (address(token), swapPool);
    }

    function addLiquidity(uint256 tokenId, uint256 wberaAmount, uint256 memeAmount) external {
        Token memory token = tokens[tokenId];
        require(token.token != address(0), "Token does not exist");

        require(wbera.transferFrom(msg.sender, token.swapPool, wberaAmount), "WBERA transfer failed");
        require(IERC20(token.token).transferFrom(msg.sender, token.swapPool, memeAmount), "Memecoin transfer failed");

        uint256 liquidity = ILilUniswapV2(token.swapPool).addLiquidity();

        emit LiquidityAdded(tokenId, msg.sender, wberaAmount, memeAmount);
    }

    function swapWBERAForToken(uint256 tokenId, uint256 wberaAmount, uint256 minTokens) external {
        Token memory token = tokens[tokenId];
        require(token.token != address(0), "Token does not exist");

        require(wbera.transferFrom(msg.sender, token.swapPool, wberaAmount), "WBERA transfer failed");

        uint256 tokensBought = ILilUniswapV2(token.swapPool).swapWBERAForToken(minTokens);

        require(ERC20(token.token).transfer(msg.sender, tokensBought), "Token transfer failed");
    }

    function swapTokenForWBERA(uint256 tokenId, uint256 tokenAmount, uint256 minWBERA) external {
        Token memory token = tokens[tokenId];
        require(token.token != address(0), "Token does not exist");

        require(ERC20(token.token).transferFrom(msg.sender, token.swapPool, tokenAmount), "Token transfer failed");

        uint256 wberaBought = ILilUniswapV2(token.swapPool).swapTokenForWBERA(tokenAmount, minWBERA);

        require(wbera.transfer(msg.sender, wberaBought), "WBERA transfer failed");
    }

    function getSwapPool(uint256 tokenId) external view returns (address) {
        return tokens[tokenId].swapPool;
    }
}