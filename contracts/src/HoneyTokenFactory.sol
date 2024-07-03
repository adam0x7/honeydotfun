// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

interface IWBERA {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IMiniUniswapV2 {
    function addLiquidity() external returns (uint256 liquidity);
    function swapWBERAForToken(uint256 minTokens) external returns (uint256 tokensBought);
    function swapTokenForWBERA(uint256 tokenAmount, uint256 minWBERA) external returns (uint256 wberaBought);
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

    function createMemecoin(bytes calldata data) external returns(address token, address swapPool) {
        Token memory newToken = abi.decode(data, (Token));

        uint256 salt = uint256(keccak256(abi.encodePacked(data, msg.sender)));
        bytes memory initCode = abi.encodePacked(
            type(ERC20).creationCode,
            abi.encode(newToken.name, newToken.symbol, newToken.decimals)
        );

        (bool success, bytes memory returnData) = CREATE2_FACTORY.call(
            abi.encodePacked(
                bytes4(keccak256("deployWithCreate2(uint256,bytes)")),
                abi.encode(salt, initCode)
            )
        );
        require(success, "Token deployment failed");
        token = abi.decode(returnData, (address));

        bytes memory poolInitCode = abi.encodePacked(
            type(MiniUniswapV2).creationCode,
            abi.encode(token, WBERA_ADDRESS)
        );
        uint256 poolSalt = uint256(keccak256(abi.encodePacked("pool", salt)));

        (success, returnData) = CREATE2_FACTORY.call(
            abi.encodePacked(
                bytes4(keccak256("deployWithCreate2(uint256,bytes)")),
                abi.encode(poolSalt, poolInitCode)
            )
        );
        require(success, "Pool deployment failed");
        swapPool = abi.decode(returnData, (address));

        newToken.token = token;
        newToken.deployer = msg.sender;
        newToken.swapPool = swapPool;
        newToken.id = ++tokenCount;
        tokens[newToken.id] = newToken;

        emit TokenCreated(newToken.id, newToken.name, newToken.memeUrl, token, msg.sender, swapPool);

        return (token, swapPool);
    }

    function addLiquidity(uint256 tokenId, uint256 wberaAmount, uint256 memeAmount) external {
        Token memory token = tokens[tokenId];
        require(token.token != address(0), "Token does not exist");

        require(wbera.transferFrom(msg.sender, token.swapPool, wberaAmount), "WBERA transfer failed");
        require(ERC20(token.token).transferFrom(msg.sender, token.swapPool, memeAmount), "Memecoin transfer failed");

        uint256 liquidity = IMiniUniswapV2(token.swapPool).addLiquidity();

        emit LiquidityAdded(tokenId, msg.sender, wberaAmount, memeAmount);
    }

    function swapWBERAForToken(uint256 tokenId, uint256 wberaAmount, uint256 minTokens) external {
        Token memory token = tokens[tokenId];
        require(token.token != address(0), "Token does not exist");

        require(wbera.transferFrom(msg.sender, token.swapPool, wberaAmount), "WBERA transfer failed");

        uint256 tokensBought = IMiniUniswapV2(token.swapPool).swapWBERAForToken(minTokens);

        require(ERC20(token.token).transfer(msg.sender, tokensBought), "Token transfer failed");
    }

    function swapTokenForWBERA(uint256 tokenId, uint256 tokenAmount, uint256 minWBERA) external {
        Token memory token = tokens[tokenId];
        require(token.token != address(0), "Token does not exist");

        require(ERC20(token.token).transferFrom(msg.sender, token.swapPool, tokenAmount), "Token transfer failed");

        uint256 wberaBought = IMiniUniswapV2(token.swapPool).swapTokenForWBERA(tokenAmount, minWBERA);

        require(wbera.transfer(msg.sender, wberaBought), "WBERA transfer failed");
    }

    function getSwapPool(uint256 tokenId) external view returns (address) {
        return tokens[tokenId].swapPool;
    }
}