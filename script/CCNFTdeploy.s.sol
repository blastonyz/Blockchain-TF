// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import {CCNFT} from "../src/CCNFT.sol";
import {BUSD} from "../src/BUSD.sol";

contract CCNFTdeploy is Script {
    function run() external {
       
        vm.startBroadcast();
        
        
      
         new CCNFT();


        vm.stopBroadcast();
        
    }
}