pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {

  IERC20 token;

  uint public totalLiquidity;
  mapping(address => uint) public liquidity;

  constructor(address token_addr) {
    token = IERC20(token_addr);
  }

  function init(uint tokens) public payable returns (uint) {
    require(totalLiquidity == 0, "DEX:init - already has liquidity");

    totalLiquidity = address(this).balance;
    liquidity[msg.sender] = totalLiquidity;

    require(token.transferFrom(msg.sender, address(this), tokens));
    return totalLiquidity;
  }

  function price(uint input_amount, uint input_reserve, uint output_reserve) public view returns (uint) {
    uint input_amount_with_fee = input_amount * 997;
    uint numerator = input_amount_with_fee * output_reserve;
    uint denominator = input_reserve * 1000 + input_amount_with_fee;
    return numerator / denominator;
  }

  function ethToToken() public payable returns (uint256) {
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 tokens_bought = price(msg.value, address(this).balance - msg.value, token_reserve);
    require(token.transfer(msg.sender, tokens_bought));
    return tokens_bought;
  }

  function tokenToEth(uint256 tokens) public returns (uint256) {
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_bought = price(tokens, token_reserve, address(this).balance);
    (bool sent, ) = msg.sender.call{value: eth_bought}("");
    require(sent, "Failed to send user eth.");
    require(token.transferFrom(msg.sender, address(this), tokens));
    return eth_bought;
  }

  function deposit() public payable returns (uint256) {
    uint256 eth_reserve = address(this).balance - msg.value;
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 token_amount = ((msg.value * token_reserve) / eth_reserve) + 1;
    uint256 liquidity_minted = (msg.value * totalLiquidity) / eth_reserve;
    liquidity[msg.sender] += liquidity_minted;
    totalLiquidity += liquidity_minted;
    require(token.transferFrom(msg.sender, address(this), token_amount));
    return liquidity_minted;
  }

  function withdraw(uint256 liq_amount) public returns (uint256, uint256) {
    uint256 token_reserve = token.balanceOf(address(this));
    uint256 eth_amount = (liq_amount * address(this).balance) / totalLiquidity;
    uint256 token_amount = (liq_amount * token_reserve) / totalLiquidity;
    liquidity[msg.sender] -= liq_amount;
    totalLiquidity -= liq_amount;
    (bool sent, ) = msg.sender.call{value: eth_amount}("");
    require(sent, "Failed to send user eth.");
    require(token.transfer(msg.sender, token_amount));
    return (eth_amount, token_amount);
  }
}
