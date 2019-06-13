
import "truffle/Assert.sol";
import "../contracts/FileRegistry.sol";

pragma solidity ^0.4.24;

contract TestNew
{
	FileRegistry public registry;
	File public file1; 
	File public file2;
	Receipt public receipt11;
	Receipt public receipt12;
	Receipt public receipt13;
	Receipt public receipt14;

	function testNewRegistry() public
	{
		string memory name = "myregistry";
		string memory des = "test registry";

		registry = new FileRegistry(name, des);

		Assert.equal(registry.Name(), name, "registry.GetName() error");
		Assert.equal(registry.Description(), des, "registry.GetDescription() error");
		Assert.equal(registry.GetNumberOfFiles(), 0, "registry.GetNumberOfFiles() error");
	}

	function testNewFile1() public
	{
		string memory name = "myfile.doc";
		string memory id = "00001";
		string memory contenthash = "1a2b3c";
		string memory metahash = "a1b2c3";
		string memory filetype = "doc file";
		string memory etag = "whatevenisanetag";

		file1 = new File(
			registry.GetAddress(), 
			name,
			id,
			contenthash,
			metahash,
			filetype,
			etag
		);

		Assert.equal(file1.FileName(), name, "file1.GetName() error");
		Assert.equal(file1.FileId(), id, "file1.GetFileId() error");
		Assert.equal(file1.GetFileHash(), contenthash, "file1.GetFileHash() error");
		Assert.equal(file1.GetMetadataHash(), metahash, "file1.GetMetadataHash() error");
		Assert.equal(file1.ContentType(), filetype, "file1.GetContentType() error");
		Assert.equal(file1.Etag(), etag, "file1.GetEtag() error");
		Assert.equal(file1.GetNumberOfReceipts(), 0, "file1.GetNumberOfReceipts() error");

		Assert.equal(registry.GetNumberOfFiles(), 1, "registry.GetNumberOfFiles() error");
		Assert.isTrue(registry.IsRegisteredFileId(id), "registry.IsRegisteredFileId(id) false");
		Assert.equal(registry.GetFileAddressGivenId(id), file1.GetAddress(), "registry.GetFileAddressGivenId() error");
	}

	function testNewFile2() public
	{
		string memory name = "myfile.doc";
		string memory id = "00002";
		string memory contenthash = "1a2b3c";
		string memory metahash = "a1b2c3";
		string memory filetype = "doc file";
		string memory etag = "whatevenisanetag";

		file2 = new File(
			registry.GetAddress(), 
			name,
			id,
			contenthash,
			metahash,
			filetype,
			etag
		);

		Assert.equal(registry.GetNumberOfFiles(), 2, "registry.GetNumberOfFiles() error");
		Assert.isTrue(registry.IsRegisteredFileId(id), "registry.IsRegisteredFileId(id) false");
		Assert.equal(registry.GetFileAddressGivenId(id), file2.GetAddress(), "registry.GetFileAddressGivenId() error");
	}

	function testNewReceipt11() public
	{
		// file 1, notchanged receipt

		string memory id = "00001";
		string memory contenthash = "1a2b3c";
		string memory metahash = "a1b2c3";

		receipt11 = new Receipt(
			registry.GetAddress(),
			id,
			contenthash,
			metahash
		);

		Assert.equal(receipt11.GetFileHash(), contenthash, "receipt11.GetFileHash() error");
		Assert.equal(receipt11.GetMetadataHash(), metahash, "receipt11.GetMetadataHash() error");
		Assert.isTrue(receipt11.IsValid(), "receipt11.IsValid() false");
		Assert.isTrue(receipt11.IsNotChanged(), "receipt11.IsNotChanged() false");

		Assert.equal(file1.GetNumberOfReceipts(), 1, "file1.GetNumberOfReceipts() error");
	}

	function testNewReceipt12() public
	{
		// file 1, changed receipt

		string memory id = "00001";
		string memory contenthash = "1a2b3d"; // changed content
		string memory metahash = "a1b2c3";

		receipt12 = new Receipt(
			registry.GetAddress(),
			id,
			contenthash,
			metahash
		);

		Assert.isTrue(receipt12.IsValid(), "receipt12.IsValid() false");
		Assert.isTrue(receipt12.IsChanged(), "receipt12.IsChanged() false");

		Assert.equal(file1.GetNumberOfReceipts(), 2, "file1.GetNumberOfReceipts() error");
	}

	function testNewReceipt13() public
	{
		// file 1, notchanged receipt after receipt12

		string memory id = "00001";
		string memory contenthash = "1a2b3d";
		string memory metahash = "a1b2c3";

		receipt13 = new Receipt(
			registry.GetAddress(),
			id,
			contenthash,
			metahash
		);

		Assert.isTrue(receipt13.IsValid(), "receipt13.IsValid() false");
		Assert.isTrue(receipt13.IsNotChanged(), "receipt13.IsNotChanged() false");

		Assert.equal(file1.GetNumberOfReceipts(), 3, "file1.GetNumberOfReceipts() error");
	}

	function testInvalidate1() public
	{
		// file 1, remove receipt12 and revalidate receipt13 as changed

		Assert.isTrue(receipt11.IsNotChanged(), "receipt11 changed");
		Assert.isTrue(receipt12.IsChanged(), "receipt12 not changed");
		Assert.isTrue(receipt13.IsNotChanged(), "receipt13 changed");

		// functions should ignore validity
		Assert.equal(file1.GetReceiptAddressBefore(1), receipt11.GetAddress(), "GetReceiptAddressBefore() error");
		Assert.equal(file1.GetReceiptAddressAtIndex(1), receipt12.GetAddress(), "GetReceiptAddressBefore() error");

		receipt12.Invalidate();

		Assert.isTrue(receipt11.IsNotChanged(), "receipt11 changed");
		Assert.isFalse(receipt12.IsValid(), "receipt12 valid");
		Assert.isTrue(receipt13.IsChanged(), "receipt13 not changed");  // revalidated

		Assert.equal(file1.GetNumberOfReceipts(), 3, "file1.GetNumberOfReceipts() error");  // unchanged

		// functions should ignore validity
		Assert.equal(file1.GetReceiptAddressBefore(1), receipt11.GetAddress(), "GetReceiptAddressBefore() error");
		Assert.equal(file1.GetReceiptAddressAtIndex(1), receipt12.GetAddress(), "GetReceiptAddressBefore() error");
	}

	function testNewReceipt14() public
	{
		// file 1, matches receipt11 and original

		string memory id = "00001";
		string memory contenthash = "1a2b3c";
		string memory metahash = "a1b2c3";

		receipt14 = new Receipt(
			registry.GetAddress(),
			id,
			contenthash,
			metahash
		);

		Assert.isTrue(receipt14.IsValid(), "receipt14.IsValid() false");
		Assert.isTrue(receipt14.IsChanged(), "receipt14.IsChanged() false");

		Assert.equal(file1.GetNumberOfReceipts(), 4, "file1.GetNumberOfReceipts() error");
	}

	function testInvalidate2() public
	{
		// file 1, remove receipt11 and receipt13 and revalidate receipt14 with original as notchanged

		Assert.isTrue(receipt11.IsNotChanged(), "receipt11 changed");
		Assert.isFalse(receipt12.IsValid(), "receipt12 valid");
		Assert.isTrue(receipt13.IsChanged(), "receipt13 not changed");
		Assert.isTrue(receipt14.IsChanged(), "receipt14 not changed");  

		receipt11.Invalidate();
		receipt13.Invalidate();

		Assert.isFalse(receipt11.IsValid(), "receipt11 valid");
		Assert.isFalse(receipt12.IsValid(), "receipt12 valid");
		Assert.isFalse(receipt13.IsValid(), "receipt13 valid");
		Assert.isTrue(receipt14.IsNotChanged(), "receipt14 changed");  // matches original
	}
}