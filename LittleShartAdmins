// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract LittleShartAdmins {
    address masterAdmin;
    address[] admins;
    
    modifier onlyAdmin {
        require(_isAdmin(msg.sender), "Sender is not an admin!");
        _;
    }
    
    function addAdmin(address _address) public onlyAdmin {
        require(!_isAdmin(_address), "Address is already an admin!");
        admins.push(_address);
    }
    
    function removeAdmin(uint index) public onlyAdmin {
        require(index <= admins.length - 1, "Invalid Index of Admins");
        require(admins.length >= 2, "Cannot remove all admins!");
        require(admins[index] != masterAdmin, "Cannot remove master admin!");
        delete admins[index];
        
        admins[index] = admins[admins.length-1];
        admins.pop();
    }
    
    function _isAdmin(address _address) internal view returns (bool) {
        for (uint i=0;i<admins.length;i++) {
            if (admins[i] == _address) { return true; }
        }
        return false;
    }
}
