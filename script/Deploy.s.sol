// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../contracts/niet2codeBuilder.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        niet2codeBuilder niet2codeBuilder = new niet2codeBuilder();
        
        console.log("niet2codeBuilder deployed to:", address(niet2codeBuilder));
        
        vm.stopBroadcast();
    }
}
