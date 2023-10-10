// SPDX-License-Identifier: MIT
// This is a simple token exchange contract for exchanging Ethereum (ETH) for an ERC-20 token.
// これは、Ethereum (ETH) を ERC-20 トークンと交換するためのシンプルなトークン交換スマートコントラクトです。

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenExchange is Ownable {
    address public tokenAddress; // The address of the ERC-20 token.
    // ERC-20 トークンのアドレス。

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    // Function for exchanging Ethereum (ETH) for the ERC-20 token.
    // Ethereum (ETH) を ERC-20 トークンと交換するための関数です。
    function exchange() external payable {
        require(msg.value > 0, "Must send Wei");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 rate = 1; // 1 Wei per 1 token (you can adjust the rate).
        // 1 Wei に対して 1 トークン（レートを調整できます）。

        uint256 tokenAmount = msg.value * rate;
        require(token.balanceOf(address(this)) >= tokenAmount, "Insufficient token balance");

        token.transfer(msg.sender, tokenAmount);
    }

    // Function for the owner to withdraw ERC-20 tokens from the contract.
    // オーナーがコントラクトから ERC-20 トークンを引き出すための関数です。
    function withdrawTokens(uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(owner(), amount);
    }

    // Function for the owner to withdraw ETH sent to the contract.
    // オーナーがコントラクトに送信された ETH を引き出すための関数です。
    function withdrawWei(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    // Function to check the balance of ETH in the contract.
    // コントラクト内の ETH の残高を確認するための関数です。
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Function to handle incoming ETH sent to the contract.
    // コントラクトに送信された ETH を処理するための関数です。
    receive() external payable {}

    // Function to receive ERC-20 tokens and return Wei equivalent.
    // ERC-20 トークンを受け取り、その Wei 相当額を返すための関数です。
    function convertTokensToWei(uint256 tokenAmount) external returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        
        uint256 rate = 1; // 1 token per 1 Wei (you can adjust the rate).
        uint256 weiAmount = tokenAmount / rate;
        
        payable(msg.sender).transfer(weiAmount);
        return weiAmount;
    }
}
