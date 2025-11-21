# ERC-4337 Account Abstraction Wallet

A lightweight, gas-efficient implementation of the ERC-4337 Account Abstraction standard, enabling gasless transactions and advanced wallet functionality.

## Overview

This project implements a minimal yet fully functional AA wallet that allows users to execute transactions through UserOperations validated by the ERC-4337 EntryPoint. The wallet supports signature-based authentication, nonce management, and gas prefunding for seamless user experiences.

## Key Features

- ✅ **ERC-4337 Compliant**: Full implementation of Account Abstraction standard
- ✅ **Signature Validation**: ECDSA signature verification with EIP-191 message hashing
- ✅ **Nonce Management**: Sequential nonce tracking for replay attack prevention
- ✅ **Gas Abstraction**: Automatic gas prefunding to EntryPoint for gasless UX
- ✅ **Owner Control**: Secure access control via OpenZeppelin's Ownable
- ✅ **Comprehensive Testing**: 5 passing tests with 54%+ coverage
- ✅ **Multi-chain Support**: Works on Ethereum, Base, Arbitrum, Optimism, and other EVM chains

## Technical Architecture

### Core Components

**myAA.sol** - Main wallet contract
- `execute()` - Executes arbitrary transactions to any address
- `validateUserOp()` - Validates UserOperations before execution (EntryPoint callback)
- `_verifySig()` - ECDSA signature recovery and owner verification
- `_payPreFund()` - Sends ETH to EntryPoint for gas coverage

**HELPERCONFIG.s.sol** - Network configuration helper
- Automatically configures EntryPoint addresses for Sepolia and Anvil
- Deploys mock contracts for local testing
- Manages network-specific parameters

**DEPLOY_MYAA.s.sol** - Deployment script
- Deploys wallet with correct EntryPoint address
- Transfers ownership to specified account
- Network-agnostic deployment logic

**PACKEDUSEROP.s.sol** - UserOperation generation
- Creates properly formatted UserOperations
- Handles signature generation with private keys
- Configures gas limits and fees

## Installation
```bash
# Clone the repository
git clone <your-repo-url>
cd <repo-name>

# Install dependencies
forge install

# Install OpenZeppelin contracts
forge install OpenZeppelin/openzeppelin-contracts

# Install ERC-4337 account-abstraction
forge install eth-infinitism/account-abstraction
```

## Usage

### Deploy the Wallet
```bash
# Deploy to Anvil (local)
forge script script/DEPLOY_MYAA.s.sol --rpc-url anvil --broadcast

# Deploy to Sepolia
forge script script/DEPLOY_MYAA.s.sol --rpc-url sepolia --broadcast --verify
```

### Run Tests
```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test test_VALIDATE_USEROPS

# Check coverage
forge coverage
```

### Generate and Execute UserOperations
```solidity
// Create UserOperation
PackedUserOperation memory userOp = generateSignedUserOps(
    executeCalldata,
    config,
    aaWallet
);

// Submit to EntryPoint
IEntryPoint(entryPoint).handleOps([userOp], payable(bundler));
```

## Test Coverage
```
File                          % Lines        % Statements   % Branches     % Funcs
src/FIRST-AA.sol              90.43% (27/29) 84.85% (28/33) 37.50% (3/8)  100.00% (9/9)
```

### Test Suite

- ✅ `test_ONLY_OWNER_AND_ENTRYPOINT_CAN_CALL_EXECUTE` - Access control validation
- ✅ `test_OWNER_CAN_CALL_EXECUTE_AND_PERFORM_A_FUNCTION` - Direct owner execution
- ✅ `test_SIGNER_IS_THE_OWNER` - Signature verification correctness
- ✅ `test_VALIDATE_USEROPS` - UserOperation validation flow
- ✅ `test_ANYONE_CAN_EXECUTE_AFTER_WE_SIGN` - Bundler execution after signature

## Security Considerations

- **Nonce Management**: Sequential nonces prevent replay attacks
- **Signature Verification**: Uses OpenZeppelin's ECDSA library for secure signature recovery
- **Access Control**: Only owner or EntryPoint can execute transactions
- **Gas Prefunding**: Automatic validation of sufficient funds before execution
- **Reentrancy**: Execute function increments nonce after external calls

## Network Support

| Network  | EntryPoint Address                          | Supported |
|----------|---------------------------------------------|-----------|
| Sepolia  | `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789` | ✅        |
| Mainnet  | `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789` | ✅        |
| Base     | `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789` | ✅        |
| Arbitrum | `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789` | ✅        |
| Optimism | `0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789` | ✅        |

*EntryPoint v0.6 is deployed at the same address across all chains*

## Future Enhancements

- [ ] Multi-signature support
- [ ] Session key management
- [ ] Social recovery mechanisms
- [ ] Custom paymaster integration
- [ ] Batch transaction execution

## Tech Stack

- **Solidity**: ^0.8.28
- **Foundry**: Testing and deployment framework
- **OpenZeppelin**: Security-audited contract libraries
- **ERC-4337**: Account Abstraction standard (EntryPoint v0.6)

## License

MIT

## Author

Charles Onyii - ERC-4337 & Advanced Foundry Testing Specialist

## Acknowledgments

- [Patrick Collins](https://github.com/PatrickAlphaC) - Foundry course
- [eth-infinitism](https://github.com/eth-infinitism/account-abstraction) - ERC-4337 reference implementation
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts) - Secure contract libraries# ERC4337-AA-Wallet
