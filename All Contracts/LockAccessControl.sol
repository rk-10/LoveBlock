pragma solidity ^0.4.11;
contract LockAccessControl {

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public lockUpgradeAddress;
    address public lockBuySellAddress;
    address public lockLicenseAddress;
    address public forgeLockAddress;


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

    modifier onlyBuySell() {
        require(msg.sender == lockBuySellAddress);
        _;
    }

    modifier onlyUpgrade() {
        require(msg.sender == lockUpgradeAddress);
        _;
    }

    modifier onlyLicense() {
        require(msg.sender == lockLicenseAddress);
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

    modifier RWAccess() {
        require(
        msg.sender == lockLicenseAddress ||
        msg.sender == lockUpgradeAddress ||
        msg.sender == lockBuySellAddress ||
        msg.sender == forgeLockAddress ||
        msg.sender == address(this)
        );
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    function setLockUpgradeAddress(address _newLockUpgradeAddr) external onlyCEO {
        require(_newLockUpgradeAddr != address(0));

        lockUpgradeAddress = _newLockUpgradeAddr;
    }

    function setLockBuySellAddress(address _newLockBuySellAddr) external onlyCEO {
        require(_newLockBuySellAddr != address(0));

        lockBuySellAddress = _newLockBuySellAddr;
    }

    function setLockLicenseAddress(address _newLockLicenseAddr) external onlyCEO {
        require(_newLockLicenseAddr != address(0));

        lockLicenseAddress = _newLockLicenseAddr;
    }

    function setForgeLockAddress(address _newForgeLockAddress) external onlyCEO {
        require(_newForgeLockAddress != address(0));

        forgeLockAddress = _newForgeLockAddress;
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