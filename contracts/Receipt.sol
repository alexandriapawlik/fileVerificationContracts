
// adapted from github.com/Azure-Samples/blockchain-devkit/blob/master/accelerators
// adapted by Alexandria Pawlik, June 2019

// version contains address-type parameters


pragma solidity ^0.4.24;

// interface
import "./AReceipt.sol";


// VERIFICATION RECEIPT CONTRACT
/////////////////////////////////////////////////////////////////


contract Receipt is AReceipt
{
  ///////////////// public data


	enum StateType { NotVerified, Changed, NotChanged, Invalid}
	StateType public State;

	string public FileName; // name of the file that this receipt is for
	string public VerificationDateTime; // MM/DD/YY HH:MM:SS
	

  ///////////////// internal data


  uint internal Index;  // index of receipt in file's history array
  string internal FileHash; // sha256 hash of instant file content
	string internal MetadataHash; // sha256 hash of instant file metadata

  File internal MyFile;
	address internal FileAddress;


  /////////////////


	constructor (address registryAddress, string fileId, string fileHash, string metadataHash)
	public
	{
		// for debugging, not permanent
		State = StateType.NotVerified;

		// verification data
		FileHash = fileHash;
		MetadataHash = metadataHash;

    // registry
		FileRegistry MyFileRegistry = FileRegistry(registryAddress);

    // find file id in this registry
    FileAddress = MyFileRegistry.GetFileAddressGivenId(fileId);

		// file
		MyFile = File(FileAddress);
		FileName = MyFile.FileName();

		// add verification receipt to history, makes sure that file has not been deleted
		VerificationDateTime = MyFile.AddReceipt(address(this));
    Index = MyFile.GetNumberOfReceipts() - 1;

		// if this is the first verification, verify with original
		if (Index == 0)
		{
			VerifyWithOriginal();
		}
		// else this is not the first verification, compare to the most recent valid verification
		else
    {
      Verify();
    }
	}


  ///////////////// accessible by blockchain users


  function Invalidate()
  external
  {
    State = StateType.Invalid;

    // if this isn't the last receipt
    if (Index < (MyFile.GetNumberOfReceipts() - 1)) 
    {
			// if there's a valid receipt after this one
			if (GetNextValidReceiptAfter(Index) > Index)
			{
				Receipt(MyFile.GetReceiptAddressAtIndex(GetNextValidReceiptAfter(Index))).Verify();
			}
    }
  }

  // allows workbench users to refresh displayed data
  function Update()
  external 
	pure {}


  ///////////////// helper functions


  function VerifyWithOriginal()
  internal
  {
    // first check that metadata hashes (contenttype, etag, id) match
    if ( !compareStrings(MetadataHash, MyFile.GetMetadataHash()) ) 
    {
      State = StateType.Changed;
    }
    // then check that content hashes match
    else if ( !compareStrings(FileHash, MyFile.GetFileHash()) )
    {
      State = StateType.Changed;
    }
    // unchanged
    else
    {
      State = StateType.NotChanged;
    }
  }

	function stringToAddress(string _a) 
  internal 
  pure 
  returns(address)
  {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    
    for (uint i=2; i<2+2*20; i+=2)
    {
      iaddr *= 256;
      b1 = uint160(tmp[i]);
      b2 = uint160(tmp[i+1]);
      if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
      else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
      if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
      else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
      iaddr += (b1*16+b2);
    }

    return address(iaddr);
  }

	function stringToBytes32(string memory source) 
  internal 
  pure 
  returns(bytes32 result) 
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) 
    {
      return 0x0;
    }

    assembly 
    {
      result := mload(add(source, 32))
    }
  }

	function compareStrings(string a, string b) 
  internal 
  pure 
  returns(bool)
  {
    return keccak256(bytes(a)) == keccak256(bytes(b));
  }

	// assumes that receipt at idx isn't the last receipt
	// returns the index of the next valid receipt in the array (idx increasing)
	// returns idx if all the following receipts are invalid
	function GetNextValidReceiptAfter(uint idx)
	internal
	view
	returns (uint)
	{
		for (uint i = idx; i < MyFile.GetNumberOfReceipts(); ++i)
		{
			if (Receipt(MyFile.GetReceiptAddressAtIndex(i)).IsValid()) return i;
		}
		// returns idx if all the following receipts are invalid
		return idx;
	}


  ///////////////// called by other receipts


  function IsValid()
  public
  view
  returns (bool)
  {
    return (State != StateType.Invalid);
  }

  // determine if file matches its last verification and set state
	function Verify()
	public
	{
		require(State != StateType.Invalid, "Attempted to verify a receipt that's been invalidated.");

    // find most recent valid verification
    uint backcount = 0;
    while ( 
			(backcount < Index) &&
      !Receipt(MyFile.GetReceiptAddressBefore(Index - backcount)).IsValid() )
    {
      ++backcount;
    }

    // if backcount reached its limit, compare back to original
    if (backcount == Index)
    {
      VerifyWithOriginal();
    }
    else 
    {
      // first check that metadata hashes (contenttype, etag, id) match
      if ( !compareStrings(MetadataHash,
        Receipt(MyFile.GetReceiptAddressBefore(Index - backcount)).GetMetadataHash()) ) 
      {
        State = StateType.Changed;
      } 
      // then check that content hashes match
      else if ( !compareStrings(FileHash,
        Receipt(MyFile.GetReceiptAddressBefore(Index - backcount)).GetFileHash()) ) 
      {
        State = StateType.Changed;
      }
      // unchanged
      else
      {
        State = StateType.NotChanged;
      }
    }    
	}

	// get function for internal variable
	function GetFileHash()
	external
	view
	returns (string)
	{
		return FileHash;
	}

	// get function for internal variable
	function GetMetadataHash()
	external
	view
	returns (string)
	{
		return MetadataHash;
	}


	///////////////// get functions for testing
	

	function IsChanged()
	external
	view
	returns (bool)
	{
		return (State == StateType.Changed);
	}

	function IsNotChanged()
	external
	view
	returns (bool)
	{
		return (State == StateType.NotChanged);
	}

	function GetAddress()
	external
	view
	returns (address)
	{
		return address(this);
	}
}