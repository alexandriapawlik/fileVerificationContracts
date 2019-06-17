
// adapted from github.com/Azure-Samples/blockchain-devkit/blob/master/accelerators
// adapted by Alexandria Pawlik, June 2019

// version contains address-type parameters


pragma solidity ^0.4.24;

// interface
import "./interfaces/IFileRegistry.sol";


// FILE REGISTRY CONTRACT
/////////////////////////////////////////////////////////////////


contract FileRegistry is IFileRegistry
{
	///////////////// public data


	enum StateType { Open, Closed }
	StateType public State;

  string public Name;
	string public Description;


  ///////////////// internal data


	FileStruct[] internal Files;

	struct FileStruct 
	{ 
		address FileContractAddress;
		string FileId; 
		uint Index;
	}

	// file tracking
	mapping(string => FileStruct) internal FileIdLookup;
  mapping(address => FileStruct) internal FileContractAddressLookup;
	address[] internal FileAddressIndex;
	string[] internal FileIdIndex;


  /////////////////


	constructor (string name, string description) 
	public
	{
		Name = name;
		Description = description;
		State = StateType.Open;
	}


  ///////////////// accessible by blockchain users


	function CloseRegistry() 
	external 
	{
		State = StateType.Closed;
	}


  ///////////////// called by members of file array


  function RegisterFile(address FileContractAddress, string FileId) 
	external
	{
		// if (State != StateType.Open) revert("File cannot be added to a registry that is not open.");
		// if (IsRegisteredFileContractAddress(FileContractAddress)) revert("This contract address cannot be registered to a second file."); 
		require(State == StateType.Open, "File cannot be added to a registry that is not open.");
		require(!IsRegisteredFileContractAddress(FileContractAddress), "This contract address cannot be registered to a second file.");

		// add lookup by address
		FileContractAddressLookup[FileContractAddress].FileContractAddress = FileContractAddress;
		FileContractAddressLookup[FileContractAddress].FileId = FileId;
		FileContractAddressLookup[FileContractAddress].Index = FileAddressIndex.push(FileContractAddress)-1;

		// add look up by reg number
		FileIdLookup[FileId].FileContractAddress = FileContractAddress;
		FileIdLookup[FileId].FileId = FileId;
		FileIdLookup[FileId].Index = FileIdIndex.push(FileId)-1;
	}

  // lookup to see if this file is registered
	function IsRegisteredFileId(string FileId)
	external 
	view
	returns(bool isRegistered) 
	{
		if(FileIdIndex.length == 0) return false;

		string memory FileIdString = FileId;
		string memory FileIdInternalString = FileIdIndex[FileIdLookup[FileIdString].Index];

		return (compareStrings(FileIdInternalString, FileIdString));
	}


	///////////////// get functions for testing


  function GetFileIdAtIndex(uint index)
	external
	view
	returns (string)
	{
		return FileIdIndex[index];
	}

	function GetFileAddressAtIndex(uint index)
	external
	view
	returns (address)
	{
		return FileAddressIndex[index];
	}

	function GetNumberOfFiles()
	external
	view
	returns (uint)
	{
		return FileAddressIndex.length;
	}

	function GetAddress()
	external
	view
	returns (address)
	{
		return address(this);
	}

	function IsOpen()
	external
	view
	returns (bool)
	{
		return (State == StateType.Open);
	}


  ///////////////// called by receipts


  function GetFileAddressGivenId(string fileid)
  external
  view
  returns (address)
  {
    return FileIdLookup[fileid].FileContractAddress;
  }


  ///////////////// helper functions


	// lookup to see if a contract address for a File contract is already registered
	function IsRegisteredFileContractAddress(address FileContractAddress)
	internal
	view
	returns(bool isRegistered) 
	{
		if(FileAddressIndex.length == 0) return false;
			
		return (FileAddressIndex[FileContractAddressLookup[FileContractAddress].Index] == FileContractAddress);
	}

	function bytes32ToString(bytes32 x)  
	internal 
	pure 
	returns(string) 
	{
		bytes memory bytesString = new bytes(32);
		uint charCount = 0;
		for (uint j = 0; j < 32; j++) 
		{
			byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
			if (char != 0) 
			{
				bytesString[charCount] = char;
				charCount++;
			}
		}

		bytes memory bytesStringTrimmed = new bytes(charCount);
		for (j = 0; j < charCount; j++) 
		{
			bytesStringTrimmed[j] = bytesString[j];
		}

		return string(bytesStringTrimmed);  
	}

	function compareStrings(string a, string b) 
	internal 
	pure 
	returns(bool)
	{
		return keccak256(bytes(a)) == keccak256(bytes(b));
	}
}