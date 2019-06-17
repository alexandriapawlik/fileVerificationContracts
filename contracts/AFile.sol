
// adapted from github.com/Azure-Samples/blockchain-devkit/blob/master/accelerators
// adapted by Alexandria Pawlik, June 2019

// version contains address-type parameters


pragma solidity ^0.4.24;

import "./FileRegistry.sol";


// FILE INTERFACE
/////////////////////////////////////////////////////////////////


interface AFile
{
  ///////////////// accessible by blockchain users


  function Delete() external;

  // allows workbench users to refresh displayed data
  function Update() external pure;


  ///////////////// called by members of receipt array


	// create a new verification receipt for this file
	function AddReceipt(address ReceiptContractAddress) external returns (string ReceiptDT);

	// gets the verification date and time of the reciept at the given index
	function GetReceiptDTAtIndex(uint idx) external view returns (string at);

	// gets the address of the receipt contract that is in 
	// the history lookup arrays one index before idx
	// does NOT ignore invalidated receipts
	// requires idx > 0
	function GetReceiptAddressBefore(uint idx) external view returns (address last);

	// gets the address of the receipt at the given index
	// does NOT ignore invalidated receipts
	function GetReceiptAddressAtIndex(uint idx) public view returns (address at);

	// get function for external variable
	function GetNumberOfReceipts() external view returns (uint);

	// get function for external variable
	function GetFileHash() external view returns (string);

	// get function for external variable
	function GetMetadataHash() external view returns (string);


	///////////////// get functions for testing


	function GetIndexOfReceipt(address receipt) external view returns (uint idx);

	function GetAddress() external view returns (address);

	function NotDeleted() external view returns (bool);

}