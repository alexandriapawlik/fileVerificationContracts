
import "truffle/Assert.sol";
//import "truffle/DeployedAddresses.sol";
import "../contracts/FileRegistry.sol";

pragma solidity ^0.4.24;

contract TestExisting
{
	FileRegistry registry;
	File file;
	Receipt receipt;

	function beforeAll()
	{
		registry = FileRegistry(X);
		file = File(X);
		receipt = Receipt(X);
	}

	function testDeployedRegistry()
	{
		Assert.equal(registry.GetNumberOfFiles(), 1, "wrong number of files");
	}

	function testDeployedFile()
	{
		Assert.equal(file.GetNumberOfReceipts(), 1, "wrong number of receipts");
		Assert.equal(file.GetReceiptAddressAtIndex(0), X, "wrong address at index");
		Assert.equal(file.GetReceiptAddressBefore(1), X, "wrong address at index");
	}

	function testDeployedReceipt()
	{
		Assert.isTrue(receipt.IsValid(), "receipt is invalid");
		Assert.isTrue(receipt.IsNotChanged(), "receipt notchanged is false");
		Assert.isFalse(receipt.IsChanged(), "receipt changed is true");
	}

	function testDeleteAndClose()
	{
		file.Delete();
		Assert.isFalse(file.NotDeleted(), "file was not deleted");

		registry.CloseRegistry();
		Assert.isFalse(registry.IsOpen(), "registry was not closed");
	}
}