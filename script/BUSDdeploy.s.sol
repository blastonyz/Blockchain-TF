// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import {BUSD} from "../src/BUSD.sol";

contract BUSDdeploy is Script {
    function run() external {
        vm.startBroadcast();
        new BUSD();
        vm.stopBroadcast();
    }
}