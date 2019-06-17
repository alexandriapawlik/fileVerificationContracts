
// adapted from github.com/Azure-Samples/blockchain-devkit/blob/master/accelerators
// adapted by Alexandria Pawlik, June 2019

// version contains address-type parameters

pragma solidity ^0.4.24;


// FILE REGISTRY CONTRACT
/////////////////////////////////////////////////////////////////


contract FileRegistry
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
	public 
	{
		State = StateType.Closed;
	}


  ///////////////// called by members of file array


  function RegisterFile(address FileContractAddress, string FileId) 
	public
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

  // // lookup to see if this file is registered
	// function IsRegisteredFileId(bytes32 FileId)
	// public 
	// view
	// returns(bool isRegistered) 
	// {
	// 	if(FileIdIndex.length == 0) return false;

	// 	string memory FileIdString = bytes32ToString(FileId);
	// 	string memory FileIdInternalString = FileIdIndex[FileIdLookup[FileIdString].Index];

	// 	return (compareStrings(FileIdInternalString, FileIdString));
	// }

  // lookup to see if this file is registered
	function IsRegisteredFileId(string FileId)
	public 
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
	public
	view
	returns (string)
	{
		return FileIdIndex[index];
	}

	function GetFileAddressAtIndex(uint index)
	public
	view
	returns (address)
	{
		return FileAddressIndex[index];
	}

	function GetNumberOfFiles()
	public
	view
	returns (uint)
	{
		return FileAddressIndex.length;
	}

	function GetAddress()
	public
	view
	returns (address)
	{
		return address(this);
	}

	function IsOpen()
	public
	view
	returns (bool)
	{
		return (State == StateType.Open);
	}


  ///////////////// called by receipts


  function GetFileAddressGivenId(string fileid)
  public
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


// FILE CONTRACT
/////////////////////////////////////////////////////////////////


contract File
{
  ///////////////// public data


	enum StateType { Original, Active, Deleted }
	StateType public State;

  string public RegistryName;  // name of the registry that the file is located in	

  string public FileName;  // name of the file in OneDrive
  string public FileId; // identifier for the file in OneDrive, stored off chain
  string public ContentType; // 
  string public Etag; // 
  string public UploadDateTime; // MM/DD/YY HH:MM:SS
  string public NumberReceipts;  // NumReceipts as string


  ///////////////// internal data


  uint internal NumReceipts; // number of times file has been verified, length of history array
  string internal FileHash; // sha256 hash of original file content
	string internal MetadataHash; // sha256 hash of original file metadata

  // parent registry
	FileRegistry internal MyFileRegistry;
	address internal RegistryAddress;

	// verification receipt tracking (history)
	ReceiptStruct[] internal History;

	struct ReceiptStruct 
	{ 
		address ReceiptContractAddress;
		string VerificationDateTime;
		uint Index;
	}

	// history lookup
	mapping(address => ReceiptStruct) internal HistoryAddressLookup;
	address[] internal ReceiptAddressIndex;
	mapping(string => ReceiptStruct) internal HistoryDTLookup;
	string[] internal VerificationDateTimeIndex;
  

  /////////////////


	constructor (address registryAddress, string filename, string fileId, string fileHash, 
		string metadataHash, string contentType, string etag) 
	public
	{
		// file data
		FileName = filename;
    FileId = fileId;
    FileHash = fileHash;
    MetadataHash = metadataHash;
    ContentType = contentType;
    Etag = etag;
    UploadDateTime = dtToString(parseTimestamp());

		// tracking
		NumReceipts = 0;
    NumberReceipts = "0";

		// registry
		RegistryAddress = registryAddress;
		MyFileRegistry = FileRegistry(RegistryAddress);
    RegistryName = MyFileRegistry.Name();

		// if file id is already registered
		//if (MyFileRegistry.IsRegisteredFileId(stringToBytes32(FileId))) revert("A file with this id has already been registered.");
		require(!MyFileRegistry.IsRegisteredFileId(FileId), "A file with this id has already been registered.");

		// register file
    MyFileRegistry.RegisterFile(address(this), FileId);
   
    State = StateType.Original;
	}


  ///////////////// accessible by blockchain users


  function Delete() 
  public 
  {
    State = StateType.Deleted;
  }

  // allows workbench users to refresh displayed data
  function Update()
  public 
	pure {}


  ///////////////// called by members of receipt array


	// create a new verification receipt for this file
	function AddReceipt(address ReceiptContractAddress) 
  public
	returns (string ReceiptDT)
  {
		// return date and time of receipt creation
		ReceiptDT = dtToString(parseTimestamp());

		// check that file is still in use
		// if (State == StateType.Deleted) revert("Receipt cannot be created for a deleted file.");
		// if (IsVerifiedReceiptContractAddress(ReceiptContractAddress)) revert("This contract address cannot be registered to a second receipt."); 
		require(State != StateType.Deleted, "Receipt cannot be created for a deleted file.");
		require(!IsVerifiedReceiptContractAddress(ReceiptContractAddress), "This contract address cannot be registered to a second receipt.");

		// add address lookups
    HistoryAddressLookup[ReceiptContractAddress].ReceiptContractAddress = ReceiptContractAddress;
    HistoryAddressLookup[ReceiptContractAddress].VerificationDateTime = ReceiptDT;
    HistoryAddressLookup[ReceiptContractAddress].Index = ReceiptAddressIndex.push(ReceiptContractAddress)-1;
   
		// add datetime lookups 
    HistoryDTLookup[ReceiptDT].ReceiptContractAddress = ReceiptContractAddress;
    HistoryDTLookup[ReceiptDT].VerificationDateTime = ReceiptDT;
    HistoryDTLookup[ReceiptDT].Index = VerificationDateTimeIndex.push(ReceiptDT)-1;

		// increase total number of receipts
		++NumReceipts;
    NumberReceipts = uintToString(NumReceipts);

    // check if this was the first verification
		if (State != StateType.Active) State = StateType.Active;
  }

	// gets the verification date and time of the reciept at the given index
	function GetReceiptDTAtIndex(uint idx)
	public
	view
	returns (string at)
	{
		// check bounds
		require(idx < NumReceipts, "Index passed to GetReceiptDTAtIndex is too large.");

		at = VerificationDateTimeIndex[idx];
	}

	// gets the address of the receipt contract that is in 
	// the history lookup arrays one index before idx
	// does NOT ignore invalidated receipts
	// requires idx > 0
	function GetReceiptAddressBefore(uint idx)
	public
	view
	returns (address last)
	{
		// check lower bound
		require(idx > 0, "Index passed to GetReceiptAddressBefore is too small.");

		last = GetReceiptAddressAtIndex(idx - 1);
	}

	// gets the address of the receipt at the given index
	// does NOT ignore invalidated receipts
	function GetReceiptAddressAtIndex(uint idx)
	public
	view
	returns (address at)
	{
		// check upper bound (lower bound is certain with uint data type)
		require(idx < NumReceipts, "Index passed to GetReceiptAddressAtIndex is too large.");

		at = ReceiptAddressIndex[idx];
	}

	// get function for internal variable
	function GetNumberOfReceipts() 
	public
	view
	returns (uint)
	{
		return NumReceipts;
	}

	// get function for internal variable
	function GetFileHash()
	public
	view
	returns (string)
	{
		return FileHash;
	}

	// get function for internal variable
	function GetMetadataHash()
	public
	view
	returns (string)
	{
		return MetadataHash;
	}


	///////////////// get functions for testing


	function GetIndexOfReceipt(address receipt)
  public
  view
  returns (uint idx)
  {
    idx = HistoryAddressLookup[receipt].Index;
  }

	function GetAddress()
	public
	view
	returns (address)
	{
		return address(this);
	}

	function NotDeleted()
	public
	view
	returns (bool)
	{
		return (State != StateType.Deleted);
	}


  ///////////////// helper functions


	// lookup to see if a contract address for a receipt contract is already registered
  function IsVerifiedReceiptContractAddress(address ReceiptContractAddress)
  internal 
  view
  returns(bool isVerified) 
  {
    if(ReceiptAddressIndex.length == 0) return false;
  
    return (ReceiptAddressIndex[HistoryAddressLookup[ReceiptContractAddress].Index] 
			== ReceiptContractAddress);
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


  //-----------------------------------------------------
  // Type Manipulation Supporting Functions
  // adapted from github.com/oraclize/ethereum-api
  //-----------------------------------------------------


  function uintToString(uint i) 
  internal 
  pure 
  returns (string)
  {
    if (i == 0) return "0";

    uint j = i;
    uint length;
    while (j != 0)
    {
      length++;
      j /= 10;
    }

    bytes memory bstr = new bytes(length);
    uint k = length - 1;
    while (i != 0)
    {
      bstr[k--] = byte(48 + i % 10);
      i /= 10;
    }

    return string(bstr);
  }

  function strConcat(string _a, string _b, string _c, string _d, string _e) 
  internal 
  pure
  returns (string)
  {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);

    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);

    uint k = 0;

    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    
    return string(babcde);
  }


  //-----------------------------------------------------
  // DateTime Supporting Functions
  // adapted from github.com/pipermerriam/ethereum-datetime/blob/master/contracts/DateTime.sol
  //-----------------------------------------------------


  uint constant DAY_IN_SECONDS = 86400;
  uint constant YEAR_IN_SECONDS = 31536000;
  uint constant LEAP_YEAR_IN_SECONDS = 31622400;

  uint16 constant ORIGIN_YEAR = 1970;

  struct _datetime 
  {
    uint16 year;
    uint8 year2;
    uint8 month;
    uint8 day;
    uint8 hour;
    uint8 minute;
    uint8 second;
  }

  // returns current timestamp as string in form MM/DD/YY HH:MM:SS
  function parseTimestamp() 
  internal 
  view 
  returns (_datetime dt) 
  {
    uint timestamp = now;
    uint secondsAccountedFor = 0;
    uint buf;

    uint8 i;

    // Year
    dt.year = getYear(timestamp);
    buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
    secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);
    dt.year2 = uint8(dt.year % 100);

    // Month
    uint secondsInMonth;
    for (i = 1; i <= 12; i++) 
    {
      secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
      if (secondsInMonth + secondsAccountedFor > timestamp) 
      {
        dt.month = i;
        break;
      }
      secondsAccountedFor += secondsInMonth;
    }

    // Day
    for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) 
    {
      if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) 
      {
        dt.day = i;
        break;
      }
      secondsAccountedFor += DAY_IN_SECONDS;
    }

    // Hour
    dt.hour = uint8((timestamp / 60 / 60) % 24);

    // Minute
    dt.minute = uint8((timestamp / 60) % 60);

    // Second
    dt.second = uint8(timestamp % 60);
  }

  function dtToString(_datetime dt)
  internal
  pure
  returns (string datetime)
  {
    string memory hourStr;
    string memory minuteStr;
    string memory secondStr;
    string memory monthStr;
    string memory dayStr;

    // add filler 0s
    if (dt.month < 10)
    {
      monthStr = strConcat("0", uintToString(dt.month), "","", "");
    } else
    {
      monthStr = uintToString(dt.month);
    }
    if (dt.day < 10)
    {
      dayStr = strConcat("0", uintToString(dt.day), "","", "");
    } else
    {
      dayStr = uintToString(dt.day);
    }
    if (dt.hour < 10)
    {
      hourStr = strConcat("0", uintToString(dt.hour), "","", "");
    } else
    {
      hourStr = uintToString(dt.hour);
    }
    if (dt.minute < 10)
    {
      minuteStr = strConcat("0", uintToString(dt.minute), "","", "");
    } else
    {
      minuteStr = uintToString(dt.minute);
    }
    if (dt.second < 10)
    {
      secondStr = strConcat("0", uintToString(dt.second), "","", "");
    } else
    {
      secondStr = uintToString(dt.second);
    }

    // convert struct to string
    datetime = strConcat(
      strConcat(monthStr, "/", dayStr, "/", uintToString(dt.year2)), 
      " ", 
      strConcat(hourStr, ":", minuteStr, ":", secondStr), 
      "", ""
    );
  }

  function isLeapYear(uint16 year) 
  internal
  pure
  returns (bool) 
  {
    if (year % 4 != 0) 
    {
      return false;
    }
    if (year % 100 != 0) 
    {
      return true;
    }
    if (year % 400 != 0) 
    {
      return false;
    }
    return true;
  }

  function leapYearsBefore(uint year) 
  internal 
  pure 
  returns (uint) 
  {
    year -= 1;
    return year / 4 - year / 100 + year / 400;
  }

  function getDaysInMonth(uint8 month, uint16 year) 
  internal
  pure 
  returns (uint8) 
  {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) 
    {
      return 31;
    } else if (month == 4 || month == 6 || month == 9 || month == 11) 
    {
      return 30;
    } else if (isLeapYear(year)) 
    {
      return 29;
    } else 
    {
      return 28;
    }
  }

  function getYear(uint timestamp) 
  internal
  pure 
  returns (uint16) 
  {
    uint secondsAccountedFor = 0;
    uint16 year;
    uint numLeapYears;

    // Year
    year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
    numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
    secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

    while (secondsAccountedFor > timestamp) 
    {
      if (isLeapYear(uint16(year - 1))) 
      {
        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
      } else 
      {
        secondsAccountedFor -= YEAR_IN_SECONDS;
      }
      year -= 1;
    }
    return year;
  } 

}

// VERIFICATION RECEIPT CONTRACT
/////////////////////////////////////////////////////////////////


contract Receipt
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
  public
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
  public 
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
	public
	view
	returns (string)
	{
		return FileHash;
	}

	// get function for internal variable
	function GetMetadataHash()
	public
	view
	returns (string)
	{
		return MetadataHash;
	}


	///////////////// get functions for testing
	

	function IsChanged()
	public
	view
	returns (bool)
	{
		return (State == StateType.Changed);
	}

	function IsNotChanged()
	public
	view
	returns (bool)
	{
		return (State == StateType.NotChanged);
	}

	function GetAddress()
	public
	view
	returns (address)
	{
		return address(this);
	}
}