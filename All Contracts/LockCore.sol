pragma solidity ^0.4.16;
import "./LockOwnership.sol";

contract LockCore is LockOwnership {
    function LockCore()  {
        paused = true;

        ceoAddress = msg.sender;

        cooAddress = msg.sender;

    }
    function getBalanceContract() constant onlyCLevel returns(uint) {
        return this.balance;
    }
    function withdraw(uint amount) payable onlyCLevel returns(bool) {
        require(amount < this.balance);
        ceoAddress.transfer(amount);
        return true;
    }
}