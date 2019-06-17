// var reg = require('./build/contracts/FileRegistry.json');
// // var file = artifacts.require("File");
// // var receipt = artifacts.require("Receipt");

// module.exports = async function(deployer) 
// {
// 	let reg1 = await deployer.deploy(reg, "reg1", "new registry");
// 	console.log("deployed");
// 	console.log(reg1.Name());
// }


module.exports = function(callback) {
	let Web3 = require('./node_modules/web3');
const truffleContract = require('./node_modules/truffle-contract')
let contract = truffleContract(require('./build/contracts/FileRegistry.json'));
var provider = new Web3.providers.HttpProvider("http://localhost:7545");
var web3 = new Web3(provider);
contract.setProvider(web3.currentProvider);

//workaround: https://github.com/trufflesuite/truffle-contract/issues/57
if (typeof contract.currentProvider.sendAsync !== "function") {
	contract.currentProvider.sendAsync = function() {
		return contract.currentProvider.send.apply(
			contract.currentProvider, arguments
		);
	};
}

contract.deployed().then(function(instance){
	return instance.Name();
}).then(response => {
	console.log(response);
});
}