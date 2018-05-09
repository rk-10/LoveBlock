pragma solidity ^0.4.11;

contract LockAccessControl {

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public baseAddress;
    address public buySellStorageAddress;

    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyBase() {
        require(msg.sender == baseAddress);
        _;
    }

    modifier onlyBuySellStorage() {
        require(msg.sender == buySellStorageAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    function setBaseContractAddress(address _newBaseAddress) external onlyCEO {
        require(_newBaseAddress != address(0));

        baseAddress = _newBaseAddress;
    }

    function setBuySellStorgeAddress(address _newBuySellStorage) external onlyCEO {
        require(_newBuySellStorage != address(0));

        buySellStorageAddress = _newBuySellStorage;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}
contract LockBase {
    function GETlockStatus(uint256 _id) external view returns (uint256 _lockStatus){}
    function SETlockstatus(uint256 _id,uint256 lockstatus) external {}
    function _owns(address _claimant, uint256 _tokenId) view external returns (bool) {}
    function transferFrom(address _from,address _to,uint256 _tokenId) external {}
}

contract BuySellStorage {
    mapping(address => uint256) sellOrderCount;
    function _isOnSale(uint256 _tokenId) external view returns(bool) {}
    function DELETEsellOrder(uint256 _tokenId) external {}
    function ADDsellOrder(uint _lock_id,address _sellerAddr,uint _sellingPrice,uint _status) external {}
    function GETsellOrderAddress(uint _lock_id) external returns (address) {}
    function GETsellOrderSellingPrice(uint _lock_id) external returns (uint) {}

}
contract ERC20 {
    uint256 public decimals;
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {}
    function approve(address _spender, uint256 _value) returns (bool) {}
    function allowance(address _owner, address _spender) view returns (uint256) {}
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {}
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {}
    function balanceOf(address _owner) public view returns (uint256) {}
}
contract LockBuySell is LockAccessControl {
    BuySellStorage public buysellstorage;
    LockBase public baseContract;
    ERC20 public erc20Token;

    /// @dev sets the object of ERC20token
    function setErc20Address(address _erc20Addr) external onlyCLevel{
        require(_erc20Addr != address(0));
        erc20Token = ERC20(_erc20Addr);
    }
    /// @dev initialises the object after change in address.
    function initBaseContractObj() external onlyCLevel {
        baseContract = LockBase(baseAddress);
    }
    /// @dev initialises the object after change in address.
    function initBuySellStorageObj() external onlyCLevel {
        buysellstorage = BuySellStorage(buySellStorageAddress);
    }

    function LockBuySell(
        address baseLockAddr,
        address _buysellstorageAddr,
        address erc20Address) {
        baseContract = LockBase(baseLockAddr);
        buysellstorage = BuySellStorage(_buysellstorageAddr);
        erc20Token = ERC20(erc20Address);
        buySellStorageAddress = _buysellstorageAddr;
        baseAddress = baseLockAddr;
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    event SellOrderCreated(uint256,uint256,address);
    event SellOrderCancelled(uint256);
    event SellOrderFulFilled(uint256,uint256,address,address);


    function _createOrder(
        address _creator,
        uint256 _lock_id,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 duration) external onlyBase whenNotPaused{
        createSellOrder(_creator,_startPrice, _lock_id);
    }

    function createSellOrder(address creator,uint256 price, uint256 _lock_id) internal {
        uint256 value= price;
        uint256 lock_status = baseContract.GETlockStatus(_lock_id);
        require(lock_status == 0);
        baseContract.SETlockstatus(_lock_id,2);
        buysellstorage.ADDsellOrder(_lock_id,creator,value,1);
        SellOrderCreated(_lock_id,value,creator);
    }

    function cancelSellOrder(uint256 token_id)  {
        require(baseContract.GETlockStatus(token_id)!=9);
        require(baseContract._owns(msg.sender,token_id));
        require(buysellstorage._isOnSale(token_id));
        baseContract.SETlockstatus(token_id,0);
        buysellstorage.DELETEsellOrder(token_id);
        SellOrderCancelled(token_id);
    }

    function buySellOrder(uint256 token_id ) external {
        require(baseContract.GETlockStatus(token_id)!=9);
        require(buysellstorage._isOnSale(token_id));
        baseContract.SETlockstatus(token_id,0);

        address seller_address = buysellstorage.GETsellOrderAddress(token_id);
        uint256 selling_price = buysellstorage.GETsellOrderSellingPrice(token_id);
        require(selling_price <= erc20Token.balanceOf(msg.sender));

        erc20Token.transferFrom(msg.sender,seller_address,selling_price);

        buysellstorage.DELETEsellOrder(token_id);

        require(baseContract._owns(seller_address, token_id));
        baseContract.transferFrom(seller_address, msg.sender ,token_id);
        SellOrderFulFilled(token_id,selling_price,seller_address,msg.sender);
    }
}