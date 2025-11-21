// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {deployMyAA} from "./DEPLOY_MYAA.s.sol";
import {PackedUserOperation} from "../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {myAAHelperConfig} from "./HELPERCONFIG.s.sol";
import {myAA} from "../src/FIRST-AA.sol";
import {console2} from "forge-std/console2.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract packedUserOps is Script {
    using MessageHashUtils for bytes32;

    function generateSignedUserOps(bytes memory callData, myAAHelperConfig.Config memory config, myAA _aa)
        public
        view
        returns (PackedUserOperation memory)
    {
        uint256 nonce = _aa.getNonce();

        PackedUserOperation memory unsignedUserOps = _generateUnsignedUserOps(address(_aa), nonce, callData);
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(unsignedUserOps);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_PRIVATE_KEY = 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_PRIVATE_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }

        unsignedUserOps.signature = abi.encodePacked(r, s, v);
        console2.log(v);
        console2.logBytes32(r);
        console2.logBytes32(s);
        return unsignedUserOps;
    }

    function _generateUnsignedUserOps(address sender, uint256 nonce, bytes memory callData)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint128 gasLimit = 16777216;
        uint128 callGasLimit = gasLimit;
        uint128 PRIORITY_FEE = 256;
        uint128 MAX_FEE = PRIORITY_FEE;

        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(gasLimit) << 128 | callGasLimit),
            preVerificationGas: gasLimit,
            gasFees: bytes32(uint256(PRIORITY_FEE) << 128 | MAX_FEE),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
