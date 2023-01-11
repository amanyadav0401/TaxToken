//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./mock_router/interfaces/IUniswapV2Router02.sol";

contract LiquidityAdder is Ownable {

address token;
IUniswapV2Router02 router;
address WETH;

constructor(IUniswapV2Router02 _router, address _token, address _weth) {
    router = _router;
    WETH = _weth;
    token = _token;
    IERC20(token).approve(address(router), 100000*10**18); 
}

modifier onlyToken{
    require(msg.sender==token,"Call only allowed from token!");
    _;
}



function addOnTransfer() public onlyToken {
     address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;
    uint[] memory amounts = router.getAmountsOut(IERC20(token).balanceOf(address(this)),path );   
    router.addLiquidityETH{value:amounts[1]}(token, IERC20(token).balanceOf(address(this)), 0, 0, owner(), block.timestamp+3600);
}

 function addByAdmin() public onlyOwner {
    router.addLiquidityETH(token, IERC20(token).balanceOf(address(this)), 0, 0, owner(), block.timestamp+3600);
 }

}