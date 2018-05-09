pragma solidity ^0.4.11;

contract LockAccessControl {

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

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

    uint256 public lastPosition;
    mapping (uint256 => bool) public checkIfFilled;
    mapping (uint256 => uint256) public tokenIdToLockedLockPosition;
    mapping (uint256 => uint256) public checkMultiplierForPosition;
    mapping (uint64 => uint256) public timeToRateMapping;
    mapping(uint256 => address) public lockIndexToOwner;


    function ADDlockedLocks(uint256 _lockId, string _message, string _partner) external {}
    function SETcheckIfFilled(uint256 _id,bool _boolean) external {}
    function SETtokenIdToLockedLockPosition(uint256 _id, uint _pos) external {}
    function SETlastPosition(uint256 _pos) external {}
    function incrementLockedLocksCount() external {}
    function decrementLockedLocksCount() external {}
    function incrementLastPosition() external {}

    function GETlockStatus(uint256 _id) external view returns (uint256 _lockStatus){}
    function SETlockstatus(uint256 _id,uint256 lockstatus) external {}

    function REMOVElockedLocks(uint256 _pos) external{}
    function DELETEtokenIdToLockedLockPosition(uint256 _id) external {}
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

contract LicenseLock is LockAccessControl {
    LockBase public baseContract;
    ERC20 public erc20Token;
    /// @dev sets the object of ERC20token
    function setErc20Address(address _erc20Addr) external onlyCLevel{
        require(_erc20Addr != address(0));
        erc20Token = ERC20(_erc20Addr);
    }
    function setBaseContractAddress(address _newBaseAddr) external onlyCLevel {
        require(_newBaseAddr != address(0));

        baseContract = LockBase(_newBaseAddr);
    }
    /*Events*/
    event LicenseGiven(uint256,uint256,uint64,string,string,address);
    event LicenseRemoved(uint256,uint256);


    /* Constructor */
    function LicenseLock(address baseAddr, address erc20Address) {
        baseContract = LockBase(baseAddr);
        erc20Token = ERC20(erc20Address);
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    function licenseLock(
        uint256 _tokenId,
        string _message,
        string _partner,
        uint256 position,
        uint64 time
    ) external whenNotPaused
    {
        require(baseContract.timeToRateMapping(time) != 0);
        require(erc20Token.balanceOf(msg.sender) >= baseContract.timeToRateMapping(time));

        require(baseContract.lockIndexToOwner(_tokenId) == msg.sender);
        require(position >= 0);

        var (lock_status) = baseContract.GETlockStatus(_tokenId);
        require(lock_status == 0);
        if(position == 0) {
            require(!baseContract.checkIfFilled(baseContract.lastPosition()+1));

            baseContract.ADDlockedLocks(baseContract.lastPosition()+1,_partner,_message);
            baseContract.incrementLastPosition();
            uint256 lockedLockId = baseContract.lastPosition();
            baseContract.SETtokenIdToLockedLockPosition(_tokenId,lockedLockId);
            baseContract.SETcheckIfFilled(lockedLockId,true);
            // fire event
            LicenseGiven(_tokenId,lockedLockId,time,_partner,_message,msg.sender);
        } else {
            require(!baseContract.checkIfFilled(position));
            if( position > baseContract.lastPosition() ) {
                baseContract.SETlastPosition(position);
            }
            baseContract.ADDlockedLocks(position,_partner,_message);
            baseContract.SETtokenIdToLockedLockPosition(_tokenId,position);
            baseContract.SETcheckIfFilled(position,true);
            LicenseGiven(_tokenId,position,time,_partner,_message,msg.sender);

        }
        baseContract.incrementLockedLocksCount();

        if(baseContract.checkMultiplierForPosition(position)!=0) {
            erc20Token.transferFrom(msg.sender,ceoAddress,baseContract.timeToRateMapping(time)*baseContract.checkMultiplierForPosition(position));
        } else {
            erc20Token.transferFrom(msg.sender,ceoAddress,baseContract.timeToRateMapping(time));
        }
        baseContract.SETlockstatus(_tokenId,1);
    }

    function removeLockLicense (uint256 token_id) external onlyCLevel {
        require(baseContract.checkIfFilled(baseContract.tokenIdToLockedLockPosition(token_id)));
        baseContract.SETlockstatus(token_id,0);
        LicenseRemoved(token_id,baseContract.tokenIdToLockedLockPosition(token_id));
        baseContract.REMOVElockedLocks(baseContract.tokenIdToLockedLockPosition(token_id));
        baseContract.DELETEtokenIdToLockedLockPosition(token_id);
        baseContract.decrementLockedLocksCount();
        baseContract.SETcheckIfFilled(baseContract.tokenIdToLockedLockPosition(token_id),false);
    }
}

