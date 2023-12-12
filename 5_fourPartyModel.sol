// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


contract fourPartyModel {

    // アドレスことの残高のmapping
    mapping(address => uint) private _balances;

    // 役割
    mapping(address => bool) private _brands;
    mapping(address => bool) private _acquires;
    mapping(address => bool) private _issuers;
    mapping(address => bool) private _merchants;

    uint256 private _totalSupply;

    string  private _name   = "KINDAI JPN";
    string  private _symbol = "KDJPN";
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function name() external view returns (string memory) {
        string memory nameCopy = _name;
        return nameCopy;
    }

    function symbol() external view returns (string memory) {
        string memory symbolCopy = _symbol;
        return symbolCopy;
    }

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }
    function ownerCheck() external view returns (bool) {
        return msg.sender == _owner;
    }
    function ownerAddress() external view returns (address) {
        return _owner;
    }
    modifier onlyOwner {
        require(msg.sender == _owner, "you're not owner");
        _;
    }

    modifier onlyAcquire {
        require(_acquires[msg.sender]);
        _;
    }
    // change state of address
    function setModifierUser(address account, uint role) public onlyOwner{
        if( role == 0 ){
            _brands[account] = !_brands[account];
        }
        else if ( role == 1 ) {
            _acquires[account] = !_acquires[account];
        }
        else if ( role == 2 ) {
            _issuers[account] = !_issuers[account];
        }
    }

    // change state of address and the address make to merchant
    function setModifierMerchant(address account) public onlyAcquire{
            _merchants[account] = !_merchants[account];
    }
 
    // 追加発行 with log
    event NewMint(address indexed to, uint amount);
    function mint(address account, uint amount) public onlyAdmin{
        _balances[account] += amount;
        _totalSupply += amount;
        emit NewMint(account, amount);
    }

    
    // burn 機能 with log
    event Newburn(address indexed to, uint amount);
    function burn(address account, uint amount) public onlyAdmin{
        require(balanceOf(account) > amount, "transaction couldn't burn user's coin because there not enough coin");
        _setBalance(account, balanceOf(account) - amount);
        _totalSupply -= amount;
        emit Newburn(account, amount);
    }    
    // アカウントの残高を変更する
    function _setBalance(address account, uint amount) private {
        _balances[account] = amount;
    }
    // 残高を返す
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function balanceOfMe() public view returns (uint) {
        return _balances[msg.sender];
    }
    function whoami() public view returns (address) {
        return msg.sender;
    }
    // トランスパー
    function _transfer(address from , address to, uint amount) private {
        require(balanceOf(from) > amount, "user has not enought money");
        
        _setBalance(from , balanceOf(from) - amount );
        _setBalance(to , balanceOf(to) + amount );

    }
    // multisigのための構造体
    struct Transfer {
        address to;
        uint amount;
        bool executed;
        address ownerAddress;
        uint256 requiredConfirmations;
        uint256 totalConfirmations;
        bool isConfirmByIssuer;
        bool isConfirmByBrand;
    }

    // トランスファー情報の配列
    mapping(address => Transfer[]) public transfers;
    // 新しいトランスファーを提出する関数
    // addressがmerchantであればエラーを返す
    function submitTransfer(address _to, uint _amount) external {
        require(balanceOf(msg.sender) > _amount, "not enough coin" );
        require(!_merchants[_to], "you can not trasnfer this address beacause this address is merchant" );
        Transfer memory newTransfer = 
            Transfer({
                to: _to,
                amount: _amount,
                executed: false,
                ownerAddress: msg.sender,
                requiredConfirmations: 1,
                totalConfirmations: 0,
                isConfirmByIssuer: false,
                isConfirmByBrand: false
            });
        transfers[msg.sender].push(newTransfer);
    }

    modifier onlyAdmin {
        require(_brands[msg.sender] || _issuers[msg.sender], "This address is not admin");
        _;
    }

    
    // brand check
    function checkBrand() public view returns (bool)  {
        return _brands[msg.sender];
    }
    // issuer check
    function checkIssuer() public view returns (bool)  {
        return _issuers[msg.sender];
    }
    // acquire check
    function checkAcquire() public view returns (bool)  {
        return _acquires[msg.sender];
    }
    // merchant check
    function checkMerchant() public view returns (bool) {
        return _merchants[msg.sender];
    }


    // トランスファーを承認する関数
    // brand, issuer だけがこの関数を操作できて、どちらかが一度承諾したらtranferが実行される
    function confirmTransfer(address _userAddress,uint _transferIndex) external onlyAdmin {
        require(_transferIndex < transfers[_userAddress].length, "Transaction not found in the index");
        bool isBrand = _brands[msg.sender];
        bool isIssuer = _issuers[msg.sender];
        if (isBrand) {
            require(!transfers[_userAddress][_transferIndex].isConfirmByIssuer, "This transaction has already been checked");
            transfers[_userAddress][_transferIndex].isConfirmByIssuer = true;
            transfers[_userAddress][_transferIndex].totalConfirmations++;
        }
        if (isIssuer) {
            require(!transfers[_userAddress][_transferIndex].isConfirmByBrand, "This transaction has already been checked");
            transfers[_userAddress][_transferIndex].isConfirmByBrand = true;
            transfers[_userAddress][_transferIndex].totalConfirmations++;
        }

        if (transfers[_userAddress][_transferIndex].totalConfirmations >= transfers[_userAddress][_transferIndex].requiredConfirmations) {
            transfers[_userAddress][_transferIndex].executed = true;
            executeTransfer(_userAddress,_transferIndex);
        }
    }

    event NewExecutedTransfer(address indexed from,address indexed to, uint amount);

    // トランスファーを実行する内部関数
    // 正しいtransferIndexを入れたのか、実行のための承諾数は揃っているのか２つの条件を確認した後、実行される
    function executeTransfer(address _userAddress, uint _transferIndex) internal {
        require(_transferIndex < transfers[_userAddress].length, "Transaction not found in the index");
        require(transfers[_userAddress][_transferIndex].executed == true, "The number of confirmations required for processing is insufficient");
    
        _transfer(
            transfers[_userAddress][_transferIndex].ownerAddress, 
            transfers[_userAddress][_transferIndex].to, 
            transfers[_userAddress][_transferIndex].amount
            );
            
        emit NewExecutedTransfer(
            transfers[_userAddress][_transferIndex].ownerAddress, 
            transfers[_userAddress][_transferIndex].to, 
            transfers[_userAddress][_transferIndex].amount
            );
        delete transfers[_userAddress][_transferIndex];
    }

    mapping(address => address) private _merchantCodeToAddress;
    mapping(address => address) private _AddressToMerchantCodes;

    event NewMerchantCode(address indexed merchantCode);
    function makeMerchantCode(address _acquireAddress, address _merchantAddress) public onlyAcquire{
        bytes memory address1Bytes = abi.encodePacked(_merchantAddress);
        bytes memory address2Bytes = abi.encodePacked(_acquireAddress);
        bytes memory combinedBytes = abi.encodePacked(address1Bytes, address2Bytes);
        address merchantCode = address(uint160(uint(keccak256(combinedBytes))));
        _merchantCodeToAddress[merchantCode] = _merchantAddress;
        _AddressToMerchantCodes[_merchantAddress] = merchantCode;
        emit NewMerchantCode(merchantCode);
    }

    function showMerchantAddress(address merchantCode) public view returns (address) {
        require(_merchantCodeToAddress[merchantCode] != address(0), "you are not merchant");
        return _merchantCodeToAddress[merchantCode];
    }


    function showMerchantCode(address merchantAddress) public view returns (address) {
        require(_AddressToMerchantCodes[merchantAddress] != address(0), "you are not merchant");
        return _AddressToMerchantCodes[merchantAddress];
    }

}