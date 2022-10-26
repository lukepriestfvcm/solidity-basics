//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract SmartContractWallet {
    
    address walletOwner;
    mapping (address => uint) public allowances;
    mapping (address => bool) public isAllowedToSend;

    mapping(address => bool) public guardian;
    address payable nextOwner;
    uint8 guardiansResetCount;
    uint8 public constant confirmationsFromGuardiansForReset = 3;
    
    constructor() {
        walletOwner = msg.sender;
    }
    
    receive() external payable {}

    function spendFunds(uint amount, address payable to, bytes memory payload) public returns (bytes memory) {
        if (msg.sender != walletOwner) {
            require(isAllowedToSend[msg.sender] == true, "You are not permitted to send funds");
            require(amount <= allowances[msg.sender], "Insufficient Allowance");

            allowances[msg.sender] -= amount;
        }   

        (bool success, bytes memory returnData) = to.call{value: amount}(payload);
        require(success == true, "Transfer was unsuccessful");
        return returnData;
    }

    function setAllowances(uint amount, address to) public {
        require(msg.sender == walletOwner, "Only the wlalet owner can change allowances");
        allowances[to] = amount;

        if (amount > 0 ) {
            isAllowedToSend[to] = true;
        } else {
            isAllowedToSend[to] = false;
        }
    }

    function proposeNewOwner(address payable newOwner) public {
        require(guardian[msg.sender], "You are no guardian, aborting");
        if(nextOwner != newOwner) {
            nextOwner = newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if(guardiansResetCount >= confirmationsFromGuardiansForReset) {
            walletOwner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

}
