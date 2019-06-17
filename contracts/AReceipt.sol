
// adapted from github.com/Azure-Samples/blockchain-devkit/blob/master/accelerators
// adapted by Alexandria Pawlik, June 2019

// version contains address-type parameters


pragma solidity ^0.4.24;

import "./FileRegistry.sol";
import "./File.sol";


// VERIFICATION RECEIPT INTERFACE
/////////////////////////////////////////////////////////////////


interface AReceipt
{
  ///////////////// accessible by blockchain users


  function Invalidate() external;

  // allows workbench users to refresh displayed data
  function Update() external pure;


  ///////////////// called by other receipts


  function IsValid() public view returns (bool);

  // determine if file matches its last verification and set state
	function Verify() public;

	// get function for external variable
	function GetFileHash() external view returns (string);

	// get function for external variable
	function GetMetadataHash() external view returns (string);


	///////////////// get functions for testing
	

	function IsChanged() external view returns (bool);

	function IsNotChanged() external view returns (bool);

	function GetAddress() external view returns (address);
	
}