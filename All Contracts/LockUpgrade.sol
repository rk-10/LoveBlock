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
    mapping (uint256 => uint256) public limitIncreaseToRate;

    mapping(uint256 => address) public lockIndexToOwner;


    function GETlockStatus(uint256 _id) external view  returns(uint256){}
    /** Lock Getters */
    function GETlockletterLim(uint256 _id) external view returns (uint256 _lettersLimit){}
    function GETlockpicsLim(uint256 _id) external view returns (uint256 _picslimit){}

    /** Lock setters */
    function SETlockstatus(uint256 _id,uint256 lockstatus) external {}
    function SETlockletterLim(uint256 _id, uint256 _letterLim) external {}
    function SETlockpicLim(uint256 _id,uint256 _picLim) external {}

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

contract LockUpgrade is LockAccessControl {

    /** Events */
    event LockUpgraded (uint lockid, uint256 increaseByValue);

    LockBase public baseContract;
    ERC20 public erc20Token;
    function setBaseContractAddress(address _newBaseAddr) external onlyCLevel {
        require(_newBaseAddr != address(0));
        baseContract = LockBase(_newBaseAddr);
    }
    /// @dev sets the object of ERC20token
    function setErc20Address(address _erc20Addr) external onlyCLevel{
        require(_erc20Addr != address(0));
        erc20Token = ERC20(_erc20Addr);
    }
    function LockUpgrade(address baseAddr, address erc20Address) {
        baseContract = LockBase(baseAddr);
        erc20Token = ERC20(erc20Address);
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    function upgradeLock(uint256 lockId,uint256 increaseByValue) external whenNotPaused {
        require(baseContract.GETlockStatus(lockId)!=9);
        require(baseContract.lockIndexToOwner(lockId)==msg.sender);
        uint256 lockLetterLim = baseContract.GETlockletterLim(lockId);
        uint256 lockPicLim = baseContract.GETlockpicsLim(lockId);
        require(baseContract.limitIncreaseToRate(increaseByValue)!=0);

        uint256 fees = baseContract.limitIncreaseToRate(increaseByValue);
        require(erc20Token.balanceOf(msg.sender) >= fees);
        erc20Token.transferFrom(msg.sender,ceoAddress,fees);
        baseContract.SETlockletterLim(lockId,lockLetterLim+increaseByValue);
        baseContract.SETlockpicLim(lockId,lockPicLim+increaseByValue);
        LockUpgraded(lockId,increaseByValue);
    }
}


