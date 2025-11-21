// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {deployMyAA} from "../script/DEPLOY_MYAA.s.sol";
import {myAAHelperConfig} from "../script/HELPERCONFIG.s.sol";
import {myAA} from "../src/FIRST-AA.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {packedUserOps} from "../script/PACKEDUSEROP.s.sol";
import {PackedUserOperation} from "../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract myAATest is Test {
    using MessageHashUtils for bytes32;
    using ECDSA for bytes32;

    myAAHelperConfig private helperConfig;
    packedUserOps private userOps;
    myAA private aa;
    address private user1 = makeAddr("Charles");
    uint256 AMOUNT = 5e18;
    ERC20Mock private USDC;

    function setUp() public {
        deployMyAA deploy = new deployMyAA();
        (helperConfig, aa) = deploy.run();

        userOps = new packedUserOps();
        USDC = ERC20Mock(helperConfig.getConfig().stableCoin);

        vm.deal(address(aa), AMOUNT * 2);
    }

    modifier ignoreChain() {
        if (block.chainid == 11155111) return;
        _;
    }

    function test_ONLY_OWNER_AND_ENTRYPOINT_CAN_CALL_EXECUTE() public {
        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector);

        vm.prank(user1);
        vm.expectRevert(myAA.myAA__NOT_AUTHORIZED.selector);
        aa.execute(address(USDC), 0, data);

        console2.log(aa.getEntryPoint());
        console2.log(aa.owner());
        console2.log(address(aa));
        console2.log(address(helperConfig));
        console2.log(msg.sender);
    }

    function test_OWNER_CAN_CALL_EXECUTE_AND_PERFORM_A_FUNCTION() public ignoreChain {
        assertEq(USDC.balanceOf(address(aa)), 0);

        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector, address(aa), AMOUNT);

        vm.prank(aa.owner());
        aa.execute(address(USDC), 0, data);

        assertEq(USDC.balanceOf(address(aa)), AMOUNT);
    }

    function test_SIGNER_IS_THE_OWNER() public view {
        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector, address(aa), AMOUNT);
        bytes memory executeCallDATA = abi.encodeWithSelector(aa.execute.selector, address(USDC), 0, data);
        PackedUserOperation memory signedUserOps =
            userOps.generateSignedUserOps(executeCallDATA, helperConfig.getConfig(), aa);
        bytes32 userOpsHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(signedUserOps);
        bytes32 ethSigned = userOpsHash.toEthSignedMessageHash();

        // sign
        address signed = ethSigned.recover(signedUserOps.signature);

        // Check
        assertEq(signed, aa.owner());
    }

    function test_VALIDATE_USEROPS() public {
        assertEq(address(aa).balance, AMOUNT * 2);

        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector, address(aa), AMOUNT);
        bytes memory executeCallDATA = abi.encodeWithSelector(aa.execute.selector, address(USDC), 0, data);
        PackedUserOperation memory signedUserOps =
            userOps.generateSignedUserOps(executeCallDATA, helperConfig.getConfig(), aa);

        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(signedUserOps);

        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = aa.validateUserOp(signedUserOps, userOpHash, AMOUNT);

        assertEq(validationData, 0);
        assertEq(address(aa).balance, (AMOUNT * 2) / 2);
    }
//0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
    function test_ANYONE_CAN_EXECUTE_AFTER_WE_SIGN() public {
        assertEq(address(aa).balance, AMOUNT * 2);

        bytes memory data = abi.encodeWithSelector(ERC20Mock.mint.selector, address(aa), AMOUNT);
        bytes memory executeCallDATA = abi.encodeWithSelector(aa.execute.selector, address(USDC), 0, data);
        PackedUserOperation memory signedUserOps =
            userOps.generateSignedUserOps(executeCallDATA, helperConfig.getConfig(), aa);

        // bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(signedUserOps);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = signedUserOps;
        
        vm.startPrank(user1, user1);
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(DEFAULT_SENDER));
        vm.stopPrank();

        assertEq(USDC.balanceOf(address(aa)), AMOUNT);
    }
}
