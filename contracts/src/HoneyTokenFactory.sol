//MIT LIcense
/*

Meme Coin is created on bonding curve
Once its created on bonding curve, its then deployed as a pool on the swap interface

Order of development
Go through first steps: purchasing memecoin on a bonding curve. what does that even mean?


*/
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract HoneyTokenFactory is Owned {

    event TokenCreated(uint256 indexed id, string name, string memeUrl, address token, address deployer);

    address owner;

    address public constant beraCreate2Factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    address v2Pool;

    struct Token {
        uint256 id;
        uint256 decimals;
        string name;
        string memeUrl;
        address token;
        address deployer;
    }

    mapping(uint256 => Token) public tokens;
    uint256 tokenCount;

    constructor() Owned(msg.sender) {}

    function createMemecoin(bytes calldata data) external returns(token) {
        Token memory newToken = abi.decode(data, (Token));

        bytes32 salt = keccak256(abi.encodePacked(data, msg.sender));
        bytes memory initCode = abi.encodePacked(
        type(ERC20).creationCode,
        abi.encode(newToken.name, newToken.symbol, newToken.decimals)
        );
        address token = beraCreate2Factory.deployWithCreate2(salt, initCode);

        newToken.token = token;
        newToken.deployer = msg.sender;
        newToken.id = ++tokenCount;
        tokens[newToken.id] = newToken;

        emit TokenCreated(newToken.id, newToken.name, newToken.memeUrl, token, msg.sender);

        return token;
    }



}
