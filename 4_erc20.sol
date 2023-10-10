// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// OpenZeppelinのERC20トークンコントラクトをインポート
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/ERC20.sol";

// MyTokenコントラクトはERC20トークンを拡張します
contract MyToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // スマートコントラクトが100トークンを作成し、自身に割り当てます
        _mint(address(this), 100 * 10 ** uint(decimals()));
    }

    // Etherを受け入れるためのフォールバック関数
    receive() external payable { }

    // Etherをトークンに交換する関数
    function exchange() payable external {
        require(msg.value > 0, "Weiを送信してください");

        IERC20 token = IERC20(address(this));
        require(token.balanceOf(address(this)) >= msg.value, "トークン残高が不足しています");
        _transfer(address(this), msg.sender, msg.value);
    }

    // ユーザーにトークンを返金する関数
    function refund(uint value) external {
        _transfer(msg.sender, address(this), value);
        payable(msg.sender).transfer(value);
    }

    // ユーザーのトークン残高を取得する関数
    function balanceOfMe() external view returns (uint256){
        return balanceOf(msg.sender);
    }

    // トランスファー情報を格納するための構造体
    struct Transfera {
        address to;
        uint256 amount;
        bool executed;
        address ownerAddress;
        address issuerAddress;
        address brandAddress;
        uint256 requiredConfirmations;
        uint256 totalConfirmations;
        bool isConfirmByIssuer;
        bool isConfirmByBrand;
    }

    // トランスファー情報の配列
    Transfera[] public transfers;

    // 新しいトランスファーを提出する関数
    function submitTransfer(address _to, uint256 _amount, address _issuerAddress, address _brandAddress) external {
        Transfera memory newTransfer = Transfera({
            to: _to,
            amount: _amount,
            executed: false,
            ownerAddress: msg.sender,
            issuerAddress: _issuerAddress,
            brandAddress: _brandAddress,
            requiredConfirmations: 1,
            totalConfirmations: 0,
            isConfirmByIssuer: false,
            isConfirmByBrand: false
        });
        transfers.push(newTransfer);
        approve(_to, _amount);
    }

    // トランスファーを承認する関数
    function confirmTransfer(uint256 _transferIndex) external {
        require(_transferIndex < transfers.length, "無効なトランスファーインデックス");
        require(msg.sender == transfers[_transferIndex].issuerAddress || msg.sender == transfers[_transferIndex].brandAddress, "ブランドと発行者のみがアクセス可能です");

        if (msg.sender == transfers[_transferIndex].issuerAddress) {
            require(!transfers[_transferIndex].isConfirmByIssuer, "このトランスファーは既に確認済みです");
            transfers[_transferIndex].isConfirmByIssuer = true;
            transfers[_transferIndex].totalConfirmations++;
        }
        if (msg.sender == transfers[_transferIndex].brandAddress) {
            require(!transfers[_transferIndex].isConfirmByBrand, "このトランスファーは既に確認済みです");
            transfers[_transferIndex].isConfirmByBrand = true;
            transfers[_transferIndex].totalConfirmations++;
        }

        if (transfers[_transferIndex].totalConfirmations >= transfers[_transferIndex].requiredConfirmations) {
            transfers[_transferIndex].executed = true;
            executeTransfer(_transferIndex);
        }
    }

    // トランスファーを実行する内部関数
    function executeTransfer(uint256 _transferIndex) internal {
        require(_transferIndex < transfers.length, "無効なトランスファーインデックス");
        require(transfers[_transferIndex].executed == true, "すべての必要な当事者によるトランスファーの確認が行われていません");
    
        _transfer(
            transfers[_transferIndex].ownerAddress, 
            transfers[_transferIndex].to, 
            transfers[_transferIndex].amount);
        delete transfers[_transferIndex];
    }
}