//MIT LIcense
/*

Meme Coin is created on bonding curve
Once its created on bonding curve, its then deployed as a pool on the swap interface

Order of development
Go through first steps: purchasing memecoin on a bonding curve. what does that even mean?


*/
pragma solidity ^0.8.0;


contract HoneyTokenFactory {

    address owner;

    address public constant _CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    address v2Pool;

    address router;

    struct Token {
        uint256 id;
        string name;
        string memeUrl;
        address token;
        address deployer;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function createMemecoin(bytes calldata data) public returns(bytes) {
        Token memory newToken = abi.decode(data, (Token));

        bytes32 salt = keccak256(abi.encodePacked(data, msg.sender));


    }



}
