# Contract Selection Guide

Choose your base contract based on what you're building:

## Decision Tree

```
What are you building?
│
├─ A NEW token natively compatible with Glue?
│  ├─ Standard deployment → StickyAsset
│  └─ Proxy/factory pattern → InitStickyAsset
│
├─ An APP that interacts with existing Glue tokens?
│  ├─ Needs both ERC20 + ERC721 support → GluedToolsBase
│  ├─ ERC20 only (smaller contract) → GluedToolsERC20Base
│  ├─ Needs batch operations + ERC20/721 → GluedTools
│  └─ Needs batch operations + ERC20 only → GluedToolsERC20
│
└─ A flash loan strategy?
   └─ GluedLoanReceiver
```

## Contract Details

### StickyAsset
**Use when:** Creating a new token that is natively Glue-compatible.

- Auto-creates its own Glue in the constructor
- Auto-approves the Glue
- Sets `GLUE` as immutable
- Built-in `unglue()` and `flashLoan()` functions
- Override hooks for custom logic:
  - `_calculateStickyHookSize(amount) → hookSize`
  - `_calculateCollateralHookSize(asset, amount) → hookSize`
  - `_processStickyHook(amount, tokenIds[], recipient)`
  - `_processCollateralHook(asset, amount, isETH, recipient)`
- **Inherits** all GluedToolsBase helpers

### InitStickyAsset
**Use when:** Creating tokens via proxy/factory pattern (deploy first, initialize later).

- Uses `initializeStickyAsset(contractURI, fungibleAndHook)` instead of constructor
- `isInitialized() → bool`
- `modifier onlyInitialized`
- Otherwise identical to StickyAsset

### GluedToolsBase
**Use when:** Building apps that interact with Glue for both ERC20 and ERC721 tokens.

- 606 lines, full toolkit
- All helper functions (`_transferAsset`, `_burnAsset`, `_md512`, etc.)
- `nnrtnt` reentrancy guard
- Glue initialization and querying utilities

### GluedToolsERC20Base
**Use when:** Building apps that only need ERC20 support (smaller contract, saves gas).

- 486 lines, ERC20-only
- Same helpers but without ERC721 handling

### GluedTools / GluedToolsERC20
**Use when:** You need all of the above PLUS batch operations.

- Adds `_batchTransferAsset()` and `_handleExcess()`

### GluedLoanReceiver
**Use when:** Building flash loan strategies.

- Override `_executeFlashLoanLogic(params) → success` with your strategy
- `_requestGluedLoan(useERC721, glues[], collateral, amount, params)` — multi-Glue loan
- `_requestFlashLoan(glue, collateral, amount, params)` — single Glue loan
- `getCurrentTotalBorrowed()`, `getCurrentCollateral()`, `getCurrentTotalFees()`
- **Inherits** GluedToolsERC20Base

## Import

```bash
npm i @glue-finance/expansions-pack
```

```solidity
import {StickyAsset} from "@glue-finance/expansions-pack/contracts/StickyAsset.sol";
import {InitStickyAsset} from "@glue-finance/expansions-pack/contracts/InitStickyAsset.sol";
import {GluedToolsBase} from "@glue-finance/expansions-pack/contracts/GluedToolsBase.sol";
import {GluedToolsERC20Base} from "@glue-finance/expansions-pack/contracts/GluedToolsERC20Base.sol";
import {GluedTools} from "@glue-finance/expansions-pack/contracts/GluedTools.sol";
import {GluedToolsERC20} from "@glue-finance/expansions-pack/contracts/GluedToolsERC20.sol";
import {GluedLoanReceiver} from "@glue-finance/expansions-pack/contracts/GluedLoanReceiver.sol";
```
