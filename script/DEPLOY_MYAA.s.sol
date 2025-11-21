// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {myAAHelperConfig} from "./HELPERCONFIG.s.sol";
import {myAA} from "../src/FIRST-AA.sol";
import {console2} from "forge-std/console2.sol";

contract deployMyAA is Script {
    function run() external returns (myAAHelperConfig, myAA) {
        return deploy();
    }

    function deploy() public returns (myAAHelperConfig, myAA) {
        myAAHelperConfig helperConfig = new myAAHelperConfig();
        myAAHelperConfig.Config memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        myAA newAA = new myAA(config.entryPoint);
        // helperConfig.setDeployedAA(newAA);
        newAA.transferOwnership(config.account);
        vm.stopBroadcast();

        return (helperConfig, newAA);
    }
}
