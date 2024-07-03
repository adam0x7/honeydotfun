pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "solmate/utils/FixedPointMathLib.sol";

interface IWBERA is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract LilUniswapV2 is ERC20 {
    using FixedPointMathLib for uint256;

    IWBERA public immutable wbera;
    IERC20 public immutable token1;
    uint public reserve0;
    uint public reserve1;

    constructor(address _token, address _wbera) ERC20("LILUNI", "LU") {
        token1 = IERC20(_token);
        wbera = IWBERA(_wbera);
    }

    function addLiquidity() external returns (uint256 liquidity) {
        uint256 balance0 = wbera.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        if (totalSupply() == 0) {
            liquidity = (amount0 * amount1).sqrt();
        } else {
            liquidity = min(
                (amount0 * totalSupply()) / reserve0,
                (amount1 * totalSupply()) / reserve1
            );
        }

        require(liquidity > 0, "Insufficient liquidity minted");
        _mint(msg.sender, liquidity);

        _update(balance0, balance1);
        return liquidity;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function removeLiquidity(uint liquidity) external returns (uint256 amount0, uint256 amount1) {
        require(balanceOf(msg.sender) >= liquidity, "Insufficient liquidity");
        amount0 = (liquidity * reserve0) / totalSupply();
        amount1 = (liquidity * reserve1) / totalSupply();

        _burn(msg.sender, liquidity);
        _update(reserve0 - amount0, reserve1 - amount1);

        wbera.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        return (amount0, amount1);
    }

    function swapWBERAForToken(uint256 minTokens) external returns (uint256 tokensBought) {
        uint256 wberaIn = wbera.balanceOf(address(this)) - reserve0;
        tokensBought = getAmountOut(wberaIn, reserve0, reserve1);
        require(tokensBought >= minTokens, "Insufficient output amount");

        token1.transfer(msg.sender, tokensBought);
        _update(wbera.balanceOf(address(this)), token1.balanceOf(address(this)));
        return tokensBought;
    }

    function swapTokenForWBERA(uint256 tokenAmount, uint256 minWBERA) external returns (uint256 wberaBought) {
        wberaBought = getAmountOut(tokenAmount, reserve1, reserve0);
        require(wberaBought >= minWBERA, "Insufficient output amount");

        token1.transferFrom(msg.sender, address(this), tokenAmount);
        wbera.transfer(msg.sender, wberaBought);
        _update(wbera.balanceOf(address(this)), token1.balanceOf(address(this)));
        return wberaBought;
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
        reserve1 = _reserve1;
    }
}