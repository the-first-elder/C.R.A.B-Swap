# 🦀 CrabSwap

<div align="center">

  <img src="./crab-logo.png" alt="CrabSwap Logo" width="100"/>

  <div>A cross-chain arbitrage protocol that brings the power of automated trading across multiple blockchain networks</div>

  <br/>
<!-- [![License: ISC](https://img.shields.io/badge/License-ISC-blue.svg)](https://opensource.org/licenses/ISC) -->

  [![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://book.getfoundry.sh/)
  [![Pyth Network](https://img.shields.io/badge/Powered%20by-Pyth%20Network-00A3FF.svg)](https://pyth.network/)
  [![Across Protocol](https://img.shields.io/badge/Bridged%20by-Across%20Protocol-FF6B6B.svg)](https://across.to/)

</div>

## 🌟 Overview

CrabSwap is a sophisticated cross-chain arbitrage protocol that combines the power of Pyth Network's price feeds with Across Protocol's bridging capabilities to execute profitable trades across different blockchain networks. By monitoring price discrepancies in real-time and leveraging efficient cross-chain bridging, CrabSwap enables automated arbitrage opportunities that were previously difficult to capture.

### 🔄 How It Works

1. **Price Discovery**: Continuously monitors token prices across different chains using Pyth Network's reliable price feeds
2. **Opportunity Detection**: Identifies profitable arbitrage opportunities when price discrepancies exceed the threshold
3. **Cross-Chain Bridging**: Uses Across Protocol to securely bridge assets to the target chain
4. **Trade Execution**: Executes trades using Uniswap V4 pools to capture the price difference
5. **Profit Optimization**: Automatically calculates optimal trade sizes and routes for maximum profitability

## ✨ Features

### 🎯 Core Features

- Cross-chain price monitoring using Pyth Network price feeds
- Seamless asset bridging using Across Protocol
- Integration with Uniswap V4 concentrated liquidity pools
- Automated arbitrage execution when opportunities are detected
- Gas-efficient implementation

### 🔧 Technical Features

- Real-time price feed updates across multiple chains
- Smart slippage protection and price impact calculations
- Automated gas optimization for cross-chain operations
- Comprehensive monitoring and alerting system
- Secure private key management and transaction signing

## 🛠️ Architecture

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Pyth      │  │   Before    │  │   Across    │  │    Auto     │  │   Return    │
│   Network   │─▶│    Swap     │─▶│  Protocol   │─▶│    Swap     │─▶│   Funds     │
│  Price Feeds│  │    Hook     │  │   Bridge    │  │  on Bridge  │  │   to User   │
└─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘
        (if user doesnt want to use crosschain feature perform regular swap)
                        │ 
                        ▼
                ┌─────────────┐
                │  Uniswap V4 │
                │   Pools     │
                └─────────────┘
```

## 📋 Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) - For smart contract development
- Node.js and npm - For JavaScript dependencies
- Access to RPC endpoints for the target networks
- Across Protocol API access
- Sufficient funds for gas and bridging fees

## 🚀 Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/crabswap.git
cd crabswap
```

2. Install dependencies:

```bash
forge install
npm install
```

<!-- ## ⚙️ Configuration -->

<!-- ## 💻 Usage -->

### Development

```bash
# Build contracts
forge build

# Run tests
forge test

# Deploy to network
forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```


## 📁 Project Structure

```
crabswap/
├── src/                           # Smart contract source files
│   ├── CrabHook.sol/              # Hook implementations
│   ├── CrabSwap.sol/              # V4Swap implementations
│   ├── DestinationSwap.sol/       # V3 across swap implementations
├── test/                          # Test files
│   ├── Crab.t.sol/                # test swap implementations
├── script/                        # Deployment and interaction scripts
├── lib/                           # External dependencies
└── out/                           # Compiled contracts
```

## 🔌 Dependencies

- [Pyth Network SDK](https://docs.pyth.network/pythnet-price-feeds/solidity) - For cross-chain price feed integration
- [Across Protocol](https://docs.across.to/) - For cross-chain asset bridging
- [Uniswap V4 Core](https://github.com/Uniswap/v4-core) - For pool interactions
- [Foundry](https://book.getfoundry.sh/) - Development framework

## 🔒 Security

### Smart Contract Security

- All contracts are thoroughly tested with comprehensive test coverage
- Price feed validation and slippage protection
- Secure cross-chain bridging with Across Protocol
- Gas optimization for cross-chain operations
- Secure private key management

<!-- ### Operational Security

- Automated monitoring of all cross-chain operations
- Real-time alerts for suspicious activities
- Regular security audits and updates
- Emergency pause functionality
- Multi-signature wallet support -->

<!-- ## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing code style
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting PR -->
<!-- 
## 📄 License

This project is licensed under the ISC License - see the LICENSE file for details. -->

## 🙏 Acknowledgments

- Uniswap team for V4 protocol
- Pyth Network for cross-chain price feed infrastructure
- Across Protocol team for cross-chain bridging infrastructure

<!-- ## 📞 Support

For support, please:

- Open an issue in the GitHub repository
- Join our Discord community
- Check our documentation -->

---

<div align="center">
Made with ❤️ by the CrabSwap team
</div>
