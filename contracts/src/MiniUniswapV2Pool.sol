pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MiniUniswapV2Pool is ERC20 {
    IERC20 public immutable token;
    uint public reserve0; // BERA reserve
    uint public reserve1; // token reserve

    constructor(address _token) ERC20("MiniUniLP", "MLPT") {
        token = IERC20(_token);
    }

    function addLiquidity() external payable {
        uint token1Amount = token.balanceOf(address(this)) - reserve1;
        uint liquidity;
        uint balance0 = address(this).balance;
        uint amount0 = balance0 - reserve0;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * token1Amount);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply()) / reserve0,
                (token1Amount * totalSupply()) / reserve1
            );
        }

        require(liquidity > 0, "Insufficient liquidity minted");
        _mint(msg.sender, liquidity);

        _update(balance0, token.balanceOf(address(this)));
    }

    function removeLiquidity(uint liquidity) external {
        require(balanceOf(msg.sender) >= liquidity, "Insufficient liquidity");
        uint amount0 = (liquidity * reserve0) / totalSupply();
        uint amount1 = (liquidity * reserve1) / totalSupply();

        _burn(msg.sender, liquidity);
        _update(reserve0 - amount0, reserve1 - amount1);

        payable(msg.sender).transfer(amount0);
        token.transfer(msg.sender, amount1);
    }

    function swapBERAForToken(uint minTokens) external payable {
        uint tokensBought = getAmountOut(msg.value, reserve0, reserve1);
        require(tokensBought >= minTokens, "Insufficient output amount");

        token.transfer(msg.sender, tokensBought);
        _update(address(this).balance, token.balanceOf(address(this)));
    }

    function swapTokenForBERA(uint tokenAmount, uint minBERA) external {
        uint beraBought = getAmountOut(tokenAmount, reserve1, reserve0);
        require(beraBought >= minBERA, "Insufficient output amount");

        token.transferFrom(msg.sender, address(this), tokenAmount);
        payable(msg.sender).transfer(beraBought);
        _update(address(this).balance, token.balanceOf(address(this)));
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function _update(uint _reserve0, uint _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reset1;
    }

    receive() external payable {}
}