// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiSigWallet {
    address public owner;
    address public bankAddress;
    address public brandAddress;
    address public tokenAddress;
    uint256 public requiredConfirmations;
    uint256 public totalConfirmations;

    struct Transfer {
        address to;
        uint256 amount;
        bool executed;
    }

    Transfer[] public transfers;

    mapping(address => bool) public isConfirmed;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyBankOrBrand() {
        require(msg.sender == bankAddress || msg.sender == brandAddress, "Only bank or brand can confirm");
        _;
    }

    constructor(
        address _owner,
        address _bankAddress,
        address _brandAddress,
        address _tokenAddress,
        uint256 _requiredConfirmations
    ) {
        owner = _owner;
        bankAddress = _bankAddress;
        brandAddress = _brandAddress;
        tokenAddress = _tokenAddress;
        requiredConfirmations = _requiredConfirmations;
    }

    function submitTransfer(address _to, uint256 _amount) external onlyOwner {
        Transfer memory newTransfer = Transfer({
            to: _to,
            amount: _amount,
            executed: false
        });
        transfers.push(newTransfer);
    }

    function confirmTransfer(uint256 _transferIndex) external onlyBankOrBrand {
        require(_transferIndex < transfers.length, "Invalid transfer index");
        require(!isConfirmed[msg.sender], "You have already confirmed this transfer");

        isConfirmed[msg.sender] = true;
        transfers[_transferIndex].executed = true;
        totalConfirmations++;

        if (totalConfirmations >= requiredConfirmations) {
            executeTransfer(_transferIndex);
        }
    }

    function executeTransfer(uint256 _transferIndex) internal {
        require(_transferIndex < transfers.length, "Invalid transfer index");
        require(transfers[_transferIndex].executed == true, "Transfer has not been confirmed by all required parties");

        Transfer storage transfer = transfers[_transferIndex];
        IERC20 token = IERC20(transfer.to);
        require(token.transfer(transfer.to, transfer.amount), "Transfer failed");

        delete transfers[_transferIndex];
        totalConfirmations = 0;
        isConfirmed[bankAddress] = false;
        isConfirmed[brandAddress] = false;
    }
}
