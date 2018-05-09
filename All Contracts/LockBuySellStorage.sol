pragma solidity ^0.4.11;
contract LockAccessControl {

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public lockBuySell;

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

    modifier onlyRWAccess() {
        require(
            msg.sender == lockBuySell
        );
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

    function setLockBuySell(address _newLockBuySellAddress) external onlyCLevel {
        require(_newLockBuySellAddress != address(0));
        lockBuySell = _newLockBuySellAddress;
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

    function unpause() public onlyCLevel whenPaused {
        paused = false;
    }
}


contract LockBuySellStorage is LockAccessControl {

    function LockBuySellStorage() {
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    struct SellOrder {
        address seller ;
        uint256 sellingPrice;
        uint256 status;
        uint256 lock_id;
    }

    /*** Storage**/
    mapping(uint256 => SellOrder) public tokenIdToSellOrder;

    function _isOnSale(uint256 _tokenId) external onlyRWAccess returns(bool) {
        if( tokenIdToSellOrder[_tokenId].status == 1 ){
            return true;
        } else {
            return false;
        }
    }
    function DELETEsellOrder(uint256 _tokenId) external onlyRWAccess {
        delete tokenIdToSellOrder[_tokenId];
    }

    function ADDsellOrder(uint256 _lock_id,address _sellerAddr,uint256 _sellingPrice,uint256 _status ) external onlyRWAccess whenNotPaused{
        SellOrder memory _sellorder = SellOrder({
            seller: _sellerAddr,
            sellingPrice: _sellingPrice,
            lock_id: _lock_id,
            status: _status
            });
        tokenIdToSellOrder[_lock_id] = _sellorder;
    }

    function GETsellOrderAddress(uint256 _lock_id) external view onlyRWAccess returns (address) {
        return(tokenIdToSellOrder[_lock_id].seller);
    }

    function GETsellOrderSellingPrice(uint256 _lock_id) external view onlyRWAccess returns (uint256) {
        return(tokenIdToSellOrder[_lock_id].sellingPrice);
    }
}