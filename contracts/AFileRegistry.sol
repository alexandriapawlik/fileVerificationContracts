
// adapted from github.com/Azure-Samples/blockchain-devkit/blob/master/accelerators
// adapted by Alexandria Pawlik, June 2019

// version contains address-type parameters


pragma solidity ^0.4.24;


// FILE REGISTRY INTERFACE
/////////////////////////////////////////////////////////////////


interface AFileRegistry
{
  ///////////////// accessible by blockchain users


	function CloseRegistry() external;


  ///////////////// called by members of file array


  function RegisterFile(address FileContractAddress, string FileId) external;

  // lookup to see if this file is registered
	function IsRegisteredFileId(string FileId) external view returns(bool isRegistered);


	///////////////// get functions for testing


  function GetFileIdAtIndex(uint index) external view returns (string);

	function GetFileAddressAtIndex(uint index) external view returns (address);

	function GetNumberOfFiles() external view returns (uint);

	function GetAddress() external view returns (address);

	function IsOpen() external view returns (bool);


  ///////////////// called by receipts


  function GetFileAddressGivenId(string fileid) external view returns (address);
	
}