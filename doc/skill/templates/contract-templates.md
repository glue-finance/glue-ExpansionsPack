# Contract Templates

## Basic StickyAsset Token

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {StickyAsset} from "@glue-finance/expansions-pack/contracts/StickyAsset.sol";

contract MyToken is ERC20, StickyAsset {
    constructor()
        ERC20("MyToken", "MTK")
        StickyAsset("ipfs://metadata-uri", [true, false]) // [fungible, hasHook]
    {
        _mint(msg.sender, 1_000_000 * 1e18);
    }
}
```

## StickyAsset with Revenue Hook (Collateral Hook)

Routes a percentage of every unglue withdrawal to a treasury.

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {StickyAsset} from "@glue-finance/expansions-pack/contracts/StickyAsset.sol";

contract RevenueToken is ERC20, StickyAsset {
    address public immutable treasury;
    uint256 public constant HOOK_FEE = 1e17; // 10%

    constructor(address _treasury)
        ERC20("RevenueToken", "REV")
        StickyAsset("ipfs://metadata-uri", [true, true]) // [fungible, hasHook]
    {
        treasury = _treasury;
        _mint(msg.sender, 1_000_000 * 1e18);
    }

    function _calculateCollateralHookSize(
        address,
        uint256 amount
    ) internal pure override returns (uint256) {
        return _md512(amount, HOOK_FEE, PRECISION);
    }

    function _processCollateralHook(
        address asset,
        uint256 amount,
        bool isETH,
        address
    ) internal override {
        if (isETH) {
            payable(treasury).transfer(amount);
        } else {
            _transferAsset(asset, treasury, amount, new uint256[](0), true);
        }
    }
}
```

## Glue Router (Interact with Existing Glues)

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {GluedToolsERC20} from "@glue-finance/expansions-pack/contracts/GluedToolsERC20.sol";

contract GlueRouter is GluedToolsERC20 {
    function depositToGlue(address token, uint256 amount) external nnrtnt {
        address glue = _initializeGlue(token, true);
        uint256 received = _transferFromAsset(token, msg.sender, glue, amount, new uint256[](0), true);
        // received = actual amount after any tax
    }

    function checkBacking(
        address token,
        address[] calldata collaterals
    ) external view returns (uint256[] memory) {
        return _getGlueBalances(token, collaterals, true);
    }
}
```

## Flash Loan Receiver

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import {GluedLoanReceiver} from "@glue-finance/expansions-pack/contracts/GluedLoanReceiver.sol";

contract MyFlashLoan is GluedLoanReceiver {
    function _executeFlashLoanLogic(
        bytes memory params
    ) internal override returns (bool) {
        // Your flash loan strategy here
        // Borrowed funds are available in this contract
        // Must return true and have enough to repay + 0.01% fee

        return true;
    }

    function executeLoan(
        address glue,
        address collateral,
        uint256 amount
    ) external nnrtnt {
        _requestFlashLoan(glue, collateral, amount, "");
    }

    function executeMultiLoan(
        address[] calldata glues,
        address collateral,
        uint256 amount
    ) external nnrtnt {
        _requestGluedLoan(false, glues, collateral, amount, "");
    }
}
```

## Test Template

```typescript
import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("MyContract", function () {
  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners();
    const Contract = await ethers.getContractFactory("MyContract");
    const contract = await Contract.deploy(/* args */);
    return { contract, owner, user1, user2 };
  }

  describe("Deployment", function () {
    it("Should deploy correctly", async function () {
      const { contract, owner } = await loadFixture(deployFixture);
      expect(await contract.getAddress()).to.not.equal(ethers.ZeroAddress);
    });
  });

  describe("Core Functions", function () {
    it("Should work as expected", async function () {
      const { contract, owner, user1 } = await loadFixture(deployFixture);
      // Test your functions here
    });
  });
});
```

## Deploy Script Template

```typescript
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "ETH");

  const Contract = await ethers.getContractFactory("MyContract");
  const contract = await Contract.deploy(/* constructor args */);
  await contract.waitForDeployment();

  const address = await contract.getAddress();
  console.log("✅ Deployed to:", address);

  // Wait for block confirmations
  console.log("Waiting for confirmations...");
  await contract.deploymentTransaction()?.wait(5);
  console.log("Ready for verification.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
```
