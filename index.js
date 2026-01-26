// Glue Protocol Expansions Pack (published as @glueExpansionsPack)
// Main entry point for importing Glue Protocol contracts

module.exports = {
  // Base contracts
  StickyAsset: './contracts/base/StickyAsset.sol',
  InitStickyAsset: './contracts/base/InitStickyAsset.sol',
  GluedLoanReceiver: './contracts/base/GluedLoanReceiver.sol',
  GluedTools: './contracts/base/GluedTools.sol',
  GluedToolsERC20: './contracts/base/GluedToolsERC20.sol',
  
  // Interface contracts
  IStickyAsset: './contracts/interfaces/IStickyAsset.sol',
  IInitStickyAsset: './contracts/interfaces/IInitStickyAsset.sol',
  IGlueERC20: './contracts/interfaces/IGlueERC20.sol', 
  IGlueERC721: './contracts/interfaces/IGlueERC721.sol',
  IGluedHooks: './contracts/interfaces/IGluedHooks.sol',
  IGluedLoanReceiver: './contracts/interfaces/IGluedLoanReceiver.sol',
  
  // Library contracts
  GluedMath: './contracts/libraries/GluedMath.sol',
  GluedConstants: './contracts/libraries/GluedConstants.sol',
  
  // Blueprint contracts (ready-to-use implementations)
  ERC721G: './contracts/blueprints/ERC721G.sol',
  IERC721G: './contracts/interfaces/IERC721G.sol',
  
  // Tools (Base helpers with full functionality)
  GluedToolsBase: './contracts/tools/GluedToolsBase.sol',
  GluedToolsERC20Base: './contracts/tools/GluedToolsERC20Base.sol',
  
  // Example contracts
  BasicStickyToken: './contracts/examples/BasicStickyToken.sol',
  AdvancedStickyToken: './contracts/examples/AdvancedStickyToken.sol',
  ExampleArbitrageBot: './contracts/examples/ExampleArbitrageBot.sol',
  
  // Mock Contracts for Testing - Interface-Specific
  // These mocks implement exact protocol behavior with realistic hook simulation
  MockUnglueERC20: './contracts/mocks/MockUnglueERC20.sol',        // Individual ERC20 unglue testing
  MockUnglueERC721: './contracts/mocks/MockUnglueERC721.sol',      // Individual ERC721 unglue testing
  MockBatchUnglueERC20: './contracts/mocks/MockBatchUnglueERC20.sol',   // Batch ERC20 unglue testing
  MockBatchUnglueERC721: './contracts/mocks/MockBatchUnglueERC721.sol', // Batch ERC721 unglue testing

  // Mock Contracts for Flash Loans
  MockFlashLoan: './contracts/mocks/MockFlashLoan.sol',            // Individual flash loan testing
  MockGluedLoan: './contracts/mocks/MockGluedLoan.sol',           // Cross-glue flash loan testing

  // Advanced Mock Contracts with Configurable Addresses (Testing Only)
  MockStickyAsset: './contracts/mocks/MockStickyAsset.sol',        // Mock sticky asset with custom addresses
  MockGluedLoanReceiver: './contracts/mocks/MockGluedLoanReceiver.sol' // Mock flash loan receiver
}; 