# Deployment Guide

## Hardhat Project Setup

```bash
mkdir my-glue-project && cd my-glue-project
npm init -y
npm i -D hardhat @nomicfoundation/hardhat-toolbox
npx hardhat init  # SELECT: TypeScript
npm i @glue-finance/expansions-pack @openzeppelin/contracts
```

### hardhat.config.ts

```typescript
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      evmVersion: "cancun"
    }
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    baseSepolia: {
      url: process.env.BASE_SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    mainnet: {
      url: process.env.MAINNET_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    base: {
      url: process.env.BASE_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    optimism: {
      url: process.env.OP_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || ""
  }
};

export default config;
```

### .env

```
SEPOLIA_RPC_URL=https://rpc.sepolia.org
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
MAINNET_RPC_URL=https://eth.llamarpc.com
BASE_RPC_URL=https://mainnet.base.org
OP_RPC_URL=https://mainnet.optimism.io
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Step-by-Step Deployment

### 1. Compile
```bash
npx hardhat compile
```
Ensure no errors. Fix any issues before proceeding.

### 2. Test
```bash
npx hardhat test
```
All tests must pass. Never deploy untested code.

### 3. Deploy to Testnet
```bash
npx hardhat run scripts/deploy.ts --network sepolia
```
Save the deployed contract address.

### 4. Verify on Etherscan
```bash
npx hardhat verify --network sepolia CONTRACT_ADDRESS CONSTRUCTOR_ARG1 CONSTRUCTOR_ARG2
```

### 5. Test On-Chain
Interact via Etherscan's "Write Contract" tab or via a test script:
- Call key functions
- Verify state changes
- Test edge cases

### 6. Deploy to Mainnet
```bash
npx hardhat run scripts/deploy.ts --network mainnet
```

**⚠️ Warnings:**
- Double-check constructor arguments
- Ensure you have enough ETH for gas
- Consider gas price timing
- This is irreversible — test thoroughly first

### 7. Verify Mainnet
```bash
npx hardhat verify --network mainnet CONTRACT_ADDRESS CONSTRUCTOR_ARGS
```

### 8. Share Deployed Addresses
Provide addresses for interface integration.

## Deploy Script Template

```typescript
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);
  console.log("Balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)));

  const Contract = await ethers.getContractFactory("YourContract");
  const contract = await Contract.deploy(/* constructor args */);
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log("Deployed to:", address);

  // Wait for confirmations before verifying
  console.log("Waiting for confirmations...");
  await contract.deploymentTransaction()?.wait(5);

  console.log("Verifying...");
  // Verification handled separately via CLI
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
```
