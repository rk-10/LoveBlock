// this contract will have all the functions required to track ownership of the 721 , this will not change ever
pragma solidity ^0.4.11;

import "./LockBase.sol";
import "./ERC721.sol";

contract BuySell {
    function _createOrder(
    address _creator,
    uint256 _lock_id,
    uint256 _startPrice,
    uint256 _endPrice,
    uint256 duration) external {}
}

contract LockOwnership is LockBase , ERC721 {
    BuySell public buySell;

    function initBuySellObj() {
        buySell = BuySell(lockBuySellAddress);
    }

    /**events  */
    event Approval(address from, address to, uint256 _tokenId);

    string public constant name = "LoveBlock";
    string public constant symbol = "LB";

    bytes4 constant InterfaceSignature_ERC165 =
    bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256("name()")) ^
    bytes4(keccak256("symbol()")) ^
    bytes4(keccak256("totalSupply()")) ^
    bytes4(keccak256("balanceOf(address)")) ^
    bytes4(keccak256("ownerOf(uint256)")) ^
    bytes4(keccak256("approve(address,uint256)")) ^
    bytes4(keccak256("transfer(address,uint256)")) ^
    bytes4(keccak256("transferFrom(address,address,uint256)")) ^
    bytes4(keccak256("tokensOfOwner(address)")) ;

    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        // DEBUG ONLY
        //require((InterfaceSignature_ERC165 == 0x01ffc9a7) && (InterfaceSignature_ERC721 == 0x9a20483d));

        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

    function _owns(address _claimant, uint256 _tokenId) view  external returns (bool) {
        return lockIndexToOwner[_tokenId] == _claimant;
    }

    function _approvedFor(address _claimant, uint256 _tokenId) view returns (bool) {
        return lockIndexToApproved[_tokenId] == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        lockIndexToApproved[_tokenId] = _approved;
    }

    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    function transfer(
    address _to,
    uint256 _tokenId
    )
    external
    whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(this._owns(msg.sender, _tokenId));
        require(locks[_tokenId].lockStatus==0);
        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(
    address _to,
    uint256 _tokenId
    )
    external
    whenNotPaused
    {
        require(this._owns(msg.sender, _tokenId));

        _approve(_tokenId, _to);

        Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
    )
    external
    whenNotPaused
    {
        require(_to != address(0));

        require(_to != address(this));
        require(_approvedFor(msg.sender, _tokenId));
        require(this._owns(_from, _tokenId));

        _transfer(_from, _to, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return locks.length - 1;
    }

    function ownerOf(uint256 _tokenId)
    external
    view
    returns (address owner)
    {
        owner = lockIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalLocks = totalSupply();
            uint256 resultIndex = 0;

            uint256 lockId;

            for (lockId = 1; lockId <= totalLocks; lockId++) {
                if (lockIndexToOwner[lockId] == _owner) {
                    result[resultIndex] = lockId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function placeOrder(uint256 _lock_id, uint256 startPrice, uint256 endPrice, uint256 _duration) external whenNotPaused{
        require(lockIndexToOwner[_lock_id] == msg.sender);
        _approve(_lock_id, lockBuySellAddress);
        buySell._createOrder(msg.sender, _lock_id, startPrice, endPrice, _duration);
    }

}