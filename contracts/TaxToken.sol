// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface ILiquidityAdder {
    function addOnTransfer() external;
}

contract CustomToken is Context, IERC20, IERC20Metadata, Ownable {

    address dividendWallet;
    address liquidityWallet;
    address developmentWallet;
    address liquidityAdder;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcludedFromFee;



    uint256 private _totalSupply = 100000*10**18;

    string private _name;
    string private _symbol;

    struct Taxes {
        uint16 dividend;
        uint16 liquidity;
        uint16 burn;
        uint16 development;
    }

    Taxes public taxes = Taxes(20,20,10,10);

    constructor(string memory name_, string memory symbol_, address _dividendWallet, address _liquidityWallet, address _developmentWallet, address _liquidityAdder) {
        _name = name_;
        _symbol = symbol_;
        dividendWallet = _dividendWallet;
        liquidityWallet = _liquidityWallet;
        developmentWallet = _developmentWallet;
        liquidityAdder = _liquidityAdder;
        _totalSupply = 100000*10**18;
        _balances[msg.sender] = 100000*10**18;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _tokenTransfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function setTaxPercents(uint16 _dividend, uint16 _liquidity, uint16 _burnPercent, uint16 _development) public onlyOwner{
           taxes.dividend = _dividend;
           taxes.liquidity = _liquidity;
           taxes.burn = _burnPercent;
           taxes.development = _development;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _tokenTransfer(from, to, amount);
        return true;
    }

    function excludeFromFee(address _address, bool _yesOrNo) public onlyOwner {
        isExcludedFromFee[_address] = _yesOrNo;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _tokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        if(isExcludedFromFee[msg.sender]==true){
        unchecked {
            _balances[from] = fromBalance - amount;
        }
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }
         if(isExcludedFromFee[msg.sender]==false){
            uint16 totalTax = taxes.dividend + taxes.liquidity + taxes.burn + taxes.development;
            uint256 taxAmount = (amount*totalTax)/1000;
            _balances[to] += (amount-taxAmount);
            _balances[dividendWallet] += (taxAmount/totalTax)*taxes.dividend;
            _balances[liquidityWallet] += (taxAmount/totalTax)*taxes.liquidity;
            _balances[developmentWallet] += (taxAmount/totalTax)*taxes.development;
            _burn(from,(taxAmount/totalTax)*taxes.burn);
            ILiquidityAdder(liquidityAdder).addOnTransfer();
            emit Transfer(from, to, amount - totalTax);
         }
        
        _afterTokenTransfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
