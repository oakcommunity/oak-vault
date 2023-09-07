# OakVault

OakVault is a decentralized application that manages swaps between USDC and $OAK tokens. It leverages the proxy pattern for upgradability and follows best practices for secure smart contract development.

## Features

- **Swap Limit**: Users can swap up to 10 USDC at a time.
- **Swap Cooldown**: Users must wait 1 day between swaps.
- **Ownership**: The contract owner can deposit and withdraw both $OAK and USDC tokens.
- **Pausable**: Contract functionalities can be paused for maintenance or security reasons.
- **Upgradeable**: Uses the ERC1967 proxy pattern for upgradability.

## Setup

### Prerequisites

- [Foundry]([https://foundry.net/](https://github.com/foundry-rs/foundry)) (For smart contract compilation and deployment)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/oakcommunity/oak-vault.git
   cd oakvault

2. Compile and test the contracts:
   ```
   forge build

   forge test

### Security
OakVault has not been audited. Always exercise caution when interacting with smart contracts.
