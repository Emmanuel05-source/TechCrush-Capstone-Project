// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {UICertiVerification} from "../src/UICertiVerification.sol";

contract DeployUICertiVerification is Script {
    function run() external returns (UICertiVerification) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Derive the true deployer address matching the private key
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Pass the explicit deployer address as initialOwner instead of msg.sender
        UICertiVerification certContract = new UICertiVerification(
            deployerAddress
        );

        vm.stopBroadcast();

        return certContract;
    }
}
