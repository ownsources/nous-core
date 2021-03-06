pragma solidity ^0.4.10;

import "./models/DougDB.sol";
import "./security/DougEnabled.sol";

/// @title DOUG
/// @author Andreas Olofsson
/// @notice This contract is used to register other contracts by name.
/// @dev Stores the contracts as entries in a doubly linked list, so that
/// the list of elements can be gotten.
contract Doug is DougDB {

  address owner;

  // When adding a contract.
  event AddContract(address indexed caller, bytes32 indexed name, uint16 indexed code);
  // When removing a contract.
  event RemoveContract(address indexed caller, bytes32 indexed name, uint16 indexed code);

    // Constructor
    function Doug(){
        owner = msg.sender;
    }

    //todo test function
    function testAddContract(address addr) constant returns (bool){
        return DougEnabled(addr).setDougAddress(address(this));
    }

    // @notice Add a contract to Doug. This contract should extend DougEnabled, because
    // Doug will attempt to call 'setDougAddress' on that contract before allowing it
    // to register. It will also ensure that the contract cannot be selfdestructed by anyone
    // other than Doug. Finally, Doug allows over-writing of previous contracts with
    // the same name, thus you may replace contracts with new ones.
    // @param name The bytes32 name of the contract.
    // @param addr The address to the actual contract.
    // @returns result showing if the adding succeeded or failed.
    function addContract(bytes32 name, address addr) returns (bool result) {
        // Only the owner may add, and the contract has to be DougEnabled and
        // return true when setting the Doug address.
        if(msg.sender != owner || !DougEnabled(addr).setDougAddress(address(this))){
          // Access denied. Should divide these up into two maybe.
          AddContract(msg.sender, name, 403);
          return false;
        }
        // Add to contract.
        bool ae = _addElement(name, addr);

        if (ae) {
          AddContract(msg.sender, name, 201);
        } else {
          // Can't overwrite.
          AddContract(msg.sender, name, 409);
        }
        return ae;
    }



    // @notice Remove a contract from doug.
    // @param name The bytes32 name of the contract.
    // @returns boolean showing if the removal succeeded or failed.
    function removeContract(bytes32 name) returns (bool result) {
        if(msg.sender != owner){
            RemoveContract(msg.sender, name, 403);
            return false;
        }
        bool re = _removeElement(name);
        if(re){
          RemoveContract(msg.sender, name, 200);
        } else {
          // Can't remove, it's already gone.
          RemoveContract(msg.sender, name, 410);
        }
        return re;
    }

    // @notice Gets a contract from Doug.
    // @param name The bytes32 name of the contract.
    // @returns The address of the contract. If no contract with that name exists, it will
    // return zero.
    function contracts(bytes32 name) returns (address addr){
      return list[name].contractAddress;
    }

    function contractsTest(bytes32 name) constant returns (address addr){
      return list[name].contractAddress;
    }

    /// @notice Remove (selfdestruct) Doug.
    function remove(){
        if(msg.sender == owner){
            // Finally, remove doug. Doug will now have all the funds of the other contracts,
            // and when suiciding it will all go to the owner.
            selfdestruct(owner);
        }
    }

}
