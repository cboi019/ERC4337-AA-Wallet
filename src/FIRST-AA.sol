// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IAccount} from "../account-abstraction/contracts/interfaces/IAccount.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "../account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {PackedUserOperation} from "../account-abstraction/contracts/interfaces/PackedUserOperation.sol";

/**
 * @title myAA
 * @author Charles Onyii
 * @notice A minimal ERC-4337 compliant Account Abstraction wallet implementation
 * @dev This contract implements the core ERC-4337 specification allowing gasless transactions via UserOperations.
 * Only the owner or EntryPoint can execute transactions. Signature validation ensures only the owner can authorize operations.
 */
contract myAA is Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    
    error myAA__NOT_AUTHORIZED();
    error myAA__INVALID_NONCE();
    error myAA__TRANSACTION_FAILED();
    error myAA__CALL_FAILED(bytes);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    using MessageHashUtils for bytes32;
    using ECDSA for bytes32;

    /// @notice The ERC-4337 EntryPoint contract that validates and executes UserOperations
    IEntryPoint private immutable i_ENTRY_POINT;
    
    /// @notice Sequential nonce to prevent replay attacks
    uint256 private s_NONCE;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to only the EntryPoint contract
     * @dev Reverts with myAA__NOT_AUTHORIZED if caller is not the EntryPoint
     */
    modifier onlyEntryPoint() {
        if (msg.sender != address(i_ENTRY_POINT)) revert myAA__NOT_AUTHORIZED();
        _;
    }

    /**
     * @notice Restricts function access to EntryPoint or owner
     * @dev Allows both direct owner calls and EntryPoint-mediated UserOp execution
     */
    modifier onlyEntryPointAndOwner() {
        if (msg.sender != address(i_ENTRY_POINT) && msg.sender != owner()) revert myAA__NOT_AUTHORIZED();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Account Abstraction wallet
     * @param _entryPoint Address of the ERC-4337 EntryPoint contract
     * @dev Sets the deployer as the initial owner via Ownable constructor
     */
    constructor(address _entryPoint) Ownable(msg.sender) {
        i_ENTRY_POINT = IEntryPoint(_entryPoint);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Executes a transaction to any destination address
     * @param _dest The target contract or address to call
     * @param _value Amount of ETH to send with the call (in wei)
     * @param _functionData Encoded function call data
     * @dev Can only be called by owner directly or via EntryPoint through validateUserOp
     * @dev Increments nonce after successful execution to prevent replay attacks
     */
    function execute(address _dest, uint256 _value, bytes calldata _functionData) external onlyEntryPointAndOwner {
        (bool success, bytes memory result) = _dest.call{value: _value}(_functionData);
        if (!success) revert myAA__CALL_FAILED(result);

        s_NONCE++;
    }

    /**
     * @notice Validates a UserOperation before execution (ERC-4337 requirement)
     * @param userOp The UserOperation struct containing transaction details and signature
     * @param userOpHash Hash of the UserOperation for signature verification
     * @param missingAccountFunds Amount of ETH needed to cover gas costs
     * @return validationData 0 if signature is valid, 1 if invalid (per ERC-4337 spec)
     * @dev This function is called by the EntryPoint before executing the UserOperation
     * @dev Verifies signature matches owner, checks nonce validity, and prefunds gas
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        onlyEntryPoint
        returns (uint256 validationData)
    {
        validationData = _verifySig(userOp, userOpHash);

        if (userOp.nonce != getNonce()) revert myAA__INVALID_NONCE();

        _payPreFund(msg.sender, missingAccountFunds);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies that the UserOperation signature is from the wallet owner
     * @param userOp The UserOperation containing the signature to verify
     * @param userOpHash Hash of the UserOperation that was signed
     * @return validationData SIG_VALIDATION_SUCCESS (0) if valid, SIG_VALIDATION_FAILED (1) if invalid
     * @dev Uses ECDSA signature recovery with EIP-191 eth_sign message prefix
     */
    function _verifySig(PackedUserOperation calldata userOp, bytes32 userOpHash) internal view returns (uint256) {
        bytes32 ethSigned = userOpHash.toEthSignedMessageHash();
        address signer = ethSigned.recover(userOp.signature);

        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        } else {
            return SIG_VALIDATION_SUCCESS;
        }
    }

    /**
     * @notice Sends ETH to the EntryPoint to cover gas costs for the UserOperation
     * @param _entryPoint Address of the EntryPoint contract to send funds to
     * @param missingAccountFunds Amount of ETH required for gas payment
     * @dev Only sends funds if missingAccountFunds > 0
     * @dev Reverts if the transfer fails
     */
    function _payPreFund(address _entryPoint, uint256 missingAccountFunds) internal {
        if (missingAccountFunds > 0) {
            (bool success,) = _entryPoint.call{value: missingAccountFunds}("");
            if (!success) revert myAA__TRANSACTION_FAILED();
        }
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current nonce value
     * @return Current nonce used for replay protection
     */
    function getNonce() public view returns (uint256) {
        return s_NONCE;
    }

    /**
     * @notice Returns the EntryPoint contract address
     * @return Address of the ERC-4337 EntryPoint contract
     */
    function getEntryPoint() public view returns (address) {
        return address(i_ENTRY_POINT);
    }

    /**
     * @notice Allows contract to receive ETH for gas prefunding
     * @dev Required for the wallet to hold ETH for paying gas fees
     */
    receive() external payable {}
}