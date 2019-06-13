var MyRegistry = artifacts.require("FileRegistry");
var MyFile = artifacts.require("File");
var MyReceipt = artifacts.require("Receipt");

module.exports = function(deployer, network, accounts) {
  // use chained promises to deploy contracts in order
	deployer.deploy(
		MyRegistry, 
		"reg1", 
		"test registry").then(function () {
			return deployer.deploy(
				MyFile, 
				MyRegistry.address, 
				"file.txt", 
				"b!gxfcp0CJzE2dD2Zax80EiuYYS2L3eJxAnm48XW3dAnrFZKRoz24US7ugximwGGgH.01H4QS6JHI3IKOADLRMJF3DRQ7MZTA22UH",
				"9b5ab3735fb81e680ea231f885cdc4b9e3a7a3edf9288b9fcd6f50a78c6bba0f",
				"e17c6830288d8365056a26293f571f7969f5e7a7e3dff5520931f4ed9b726b37",
				"txt",
				"{E014DAE8-710D-4B62-B1C6-1F66660D6A86},2").then(function() {
					return deployer.deploy(
						MyReceipt,
						MyRegistry.address,
						"b!gxfcp0CJzE2dD2Zax80EiuYYS2L3eJxAnm48XW3dAnrFZKRoz24US7ugximwGGgH.01H4QS6JHI3IKOADLRMJF3DRQ7MZTA22UH",
						"9b5ab3735fb81e680ea231f885cdc4b9e3a7a3edf9288b9fcd6f50a78c6bba0f",
						"e17c6830288d8365056a26293f571f7969f5e7a7e3dff5520931f4ed9b726b37");
				})
		});
};