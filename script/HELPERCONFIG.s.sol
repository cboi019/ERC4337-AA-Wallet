// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {EntryPoint} from "../account-abstraction/contracts/core/EntryPoint.sol";
import {myAA} from "../src/FIRST-AA.sol";

contract myAAHelperConfig is Script {
    error myAAHelperConfig__NOT_AUTHORIZED();

    address private SEPOLIA_ENTRY_POINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    address private STABLE_COIN = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; // USDT
    address private SEP_WALLET = 0x708657DA3e4eFFa7334779C9A1E759DC38A5BF94; // My metamask testnet wallet
    address private ANVIL_WALLET = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720; // Anvil default wallet
    uint128 private SEPOLIA_CHAIN_ID = 11155111;
    uint128 private ANVIL_CHAIN_ID = 31337;

    Config private s_config;
    // myAA private deployedAA;

    struct Config {
        address entryPoint;
        address stableCoin;
        address account;
    }

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            s_config = EthNetConfig();
        } else if (block.chainid == ANVIL_CHAIN_ID) {
            s_config = MockNetConfig();
        } else {
            revert("UNSUPPORTED CHAIN");
        }
    }

    function EthNetConfig() internal view returns (Config memory) {
        return Config({entryPoint: SEPOLIA_ENTRY_POINT, stableCoin: STABLE_COIN, account: SEP_WALLET});
    }

    function MockNetConfig() internal returns (Config memory) {
        vm.startBroadcast();
        EntryPoint entryPoint = new EntryPoint();
        ERC20Mock mockToken = new ERC20Mock();
        vm.stopBroadcast();

        return Config({entryPoint: address(entryPoint), stableCoin: address(mockToken), account: ANVIL_WALLET});
    }

    function getConfig() public view returns (Config memory) {
        return s_config;
    }

    // function setDeployedAA(myAA _aa) public {
    //     deployedAA = _aa;
    // }

    // function getDeployedAA() public view returns (myAA) {
    //     return deployedAA;
    // }

    function getANVIL_WALLET() public view returns (address) {
        return ANVIL_WALLET;
    }
}
