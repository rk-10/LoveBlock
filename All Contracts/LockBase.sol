pragma solidity ^0.4.11;

import "./LockAccessControl.sol";

contract ERC20 {
    uint256 public decimals;
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {}
    function approve(address _spender, uint256 _value) returns (bool) {}
    function allowance(address _owner, address _spender) view returns (uint256) {}
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {}
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {}
    function balanceOf(address _owner) public view returns (uint256) {}
}

contract LockBase is LockAccessControl {
    ERC20 public erc20Token;

    function LockBase() {
        LockedLock memory firstLockedLock = LockedLock({
            partner : "none",
            message : "none"
            });

        lockedLocks[0] = firstLockedLock;
        checkIfFilled[0] = true;
        lockedLocksCount = 0;

        uint256[] memory b;
        Lock memory _lock = Lock(
            {
            lockBlueprint:"null",
            creationTime: uint64(now),
            parentArray:b,
            lockStatus: 0,
            lettersLimit: 0,
            picsLimit : 0
            });

        locks.push(_lock);
    }
    uint256 public forgingFees = 500000000;
    function setForgingFee(uint256 _fee) external onlyCLevel {
        forgingFees = _fee;
    }
    /// @dev sets the object of ERC20token
    function setErc20Address(address _erc20Addr) external onlyCLevel{
        require(_erc20Addr != address(0));
        erc20Token = ERC20(_erc20Addr);
    }
    // events to be generated
    // transfer
    event Transfer(address from,address to,uint256 tokenId);
    event LockCreated(address, uint256,string);
    event EventGenerationByForging(uint256[],address,uint256);
    event LimitPlanAdded (uint256 _l,uint256 _r);
    event LimitPlanRemoved(uint256,uint256);
    event LicenseRateTimeAdded(uint256 _t,uint256 _r);
    event LicenseRateTimeRemoved(uint256,uint256);

    struct Lock {
        string lockBlueprint;
        uint64 creationTime;
        uint256[] parentArray;
        uint256 lockStatus;
        uint256 lettersLimit;
        uint256 picsLimit;
    }

    struct LockedLock {
        string message;
        string partner;
    }

    /*** STORAGE ***/
    Lock[] public locks;
    uint256 public lockedLocksCount;
    mapping(uint256 => LockedLock) public lockedLocks;
    mapping(uint256 => address) public lockIndexToOwner;
    mapping(address => uint256) ownershipTokenCount;
    mapping (uint256 => address) public lockIndexToApproved;
    mapping (uint256 => uint256) public limitIncreaseToRate;
    mapping (uint256 => uint256) public checkMultiplierForPosition;
    mapping (uint256 => bool) public checkIfFilled;
    mapping (uint256 => uint256) public tokenIdToLockedLockPosition;
    mapping (uint64 => uint256) public timeToRateMapping;
    uint256 public lastPosition=0;
    uint256 public maxNumberOfParents = 3;

    /*LICENSING STUFF */
    function addRateAndTime(uint64 time, uint256 rateInErc20) onlyCLevel {
        timeToRateMapping[time] = rateInErc20;
        LicenseRateTimeAdded(time,timeToRateMapping[time]);
    }

    function removeRateAndTime(uint64 time) onlyCLevel {
        LicenseRateTimeRemoved(time,timeToRateMapping[time]);
        delete timeToRateMapping[time];
    }

    function AddMaxNumberOfParents(uint numberOfParents) onlyCLevel {
        maxNumberOfParents=numberOfParents;
    }
    function addLimitAndRate(uint256 limit, uint256 rate) onlyCLevel {
        require((limit%5)==0);
        limitIncreaseToRate[limit] = rate;
        LimitPlanAdded(limit,rate);
    }

    function removeLimitAndRate(uint256 limit) onlyCLevel {
        require(limitIncreaseToRate[limit]!=uint256(0));
        LimitPlanRemoved(limit,limitIncreaseToRate[limit]);
        delete limitIncreaseToRate[limit];
    }


    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        lockIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete lockIndexToApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

    function _generationCEO (
        string _blueprint,
        uint256[] _parents,
        uint256 _lettersLimit,
        uint256 _picsLimit
    ) onlyCLevel returns (uint256)
    {
        Lock memory _lock = Lock(
            {
            lockBlueprint:_blueprint,
            creationTime: uint64(now),
            parentArray:_parents,
            lockStatus: 0,
            lettersLimit: _lettersLimit,
            picsLimit : _picsLimit
            });

        uint256 newLockId = locks.push(_lock) - 1;
        _transfer(0,ceoAddress,newLockId);

        LockCreated( ceoAddress,newLockId,_blueprint);

        return newLockId;

    }

    function _generationByForging(uint256[] _parents) public whenNotPaused {
        require(_parents.length <= maxNumberOfParents);
        for ( uint256 i = 0 ; i < _parents.length ; i++ ) {
            require(lockIndexToOwner[_parents[i]]==msg.sender);
        }
        require(msg.value > forgingFees);
        uint256 fees = forgingFees;
        require(erc20Token.balanceOf(msg.sender) >= fees);
        erc20Token.transferFrom(msg.sender,ceoAddress,fees);
        uint256[] memory a;
        Lock memory _lock = Lock(
            {
            lockBlueprint:"null",
            creationTime: uint64(now),
            parentArray:a,
            lockStatus: 9,
            lettersLimit: 0,
            picsLimit : 0
            });

        uint256 newLockId = locks.push(_lock) - 1;

        _transfer(0,msg.sender,newLockId);

        EventGenerationByForging(_parents,msg.sender,newLockId);
    }
    function throwLockCreatedEvent(address owner,uint256 newLockId,string _blueprint) RWAccess {
        LockCreated(owner,newLockId,_blueprint);
    }

    function addMultiplierForPosition(uint256 pos,uint256 mul) external onlyCLevel {
        require(mul >= 1);
        checkMultiplierForPosition[pos] = mul;
    }
    function removeMultiplierForPosition (uint256 pos) external onlyCLevel {
        require(checkMultiplierForPosition[pos]!=0);
        delete checkMultiplierForPosition[pos];
    }

    function ADDlockedLocks(uint256 _lockId, string _message, string _partner) external RWAccess {
        LockedLock memory _lockedLock = LockedLock({
            message: _message,
            partner: _partner
            });

        lockedLocks[_lockId] = _lockedLock;
    }
    function SETlockParent(uint256[] _parents,uint256 _id) external RWAccess{
        Lock storage l = locks[_id];
        l.parentArray = _parents;
    }
    function SETcheckIfFilled(uint256 _id,bool _boolean) external RWAccess{
        checkIfFilled[_id] = _boolean;
    }
    function SETtokenIdToLockedLockPosition(uint256 _id, uint _pos) external RWAccess{
        tokenIdToLockedLockPosition[_id] = _pos;
    }
    function SETtimeToRateMapping(uint64 _time, uint _rate) external onlyCLevel RWAccess{
        timeToRateMapping[_time] = _rate;
    }
    function GETlockblueprint(uint _id) external view RWAccess returns (string _blueprint){
        return(locks[_id].lockBlueprint);
    }
    function GETlockcreationTime(uint _id) external view RWAccess returns (uint64 _creationtime){
        return(locks[_id].creationTime);
    }
    function GETlockparents(uint _id) external view RWAccess returns (uint[] _parentIds){
        return(locks[_id].parentArray);
    }
    function GETlockStatus(uint256 _id) external view RWAccess returns(uint256){
        return(locks[_id].lockStatus);
    }
    function GETlockletterLim(uint256 _id) external view RWAccess returns (uint256 _lettersLimit) {
        return(locks[_id].lettersLimit);
    }
    function GETlockpicsLim(uint256 _id) external view RWAccess returns (uint256 _picslimit) {
        return(locks[_id].picsLimit);
    }
    function SETlockstatus(uint256 _id,uint lockstatus) external RWAccess{
        Lock storage l = locks[_id];
        l.lockStatus = lockstatus;
    }
    function SETlockletterLim(uint256 _id, uint _letterLim) external RWAccess{
        Lock storage l = locks[_id];
        l.lettersLimit = _letterLim;
    }
    function SETlockpicLim(uint256 _id,uint _picLim) external RWAccess{
        Lock storage l = locks[_id];
        l.picsLimit = _picLim;
    }
    function SETblueprint(string _blueprint, uint256 _id) external RWAccess {
        Lock storage l = locks[_id];
        l.lockBlueprint = _blueprint;
    }
    function DELETEtokenIdToLockedLockPosition(uint256 _id) external RWAccess{
        delete tokenIdToLockedLockPosition[_id];
    }
    function REMOVElockedLocks(uint256 _pos) external RWAccess {
        delete lockedLocks[_pos];
    }
    function incrementLockedLocksCount() external RWAccess {
        lockedLocksCount++;
    }
    function decrementLockedLocksCount() external RWAccess {
        lockedLocksCount--;
    }
    function incrementLastPosition() external RWAccess {
        lastPosition++;
    }
    function SETlastPosition(uint _pos) external RWAccess {
        lastPosition = _pos;
    }
    function getParentsOfLock(uint256 lockId) constant external returns (uint256[]) {
        Lock storage referencedLock = locks[lockId];
        return referencedLock.parentArray;
    }
}