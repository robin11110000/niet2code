 niet2code - Anonymous Smart Contract Verification

Anonymous smart contract verification platform using zero-knowledge proofs for Cookathon 2025.

Built for builders who want to verify their smart contracts work correctly without revealing their identity or proprietary logic.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Rust](https://img.shields.io/badge/rust-1.70+-orange.svg)
![Mantle](https://img.shields.io/badge/mantle-testnet-green.svg)

 🎯 **What is niet2code?

niet2code enables developers to:
- ✅ Prove smart contracts work** without revealing the code
- 🎭 Maintain complete anonymity** while building reputation  
- ⚡ Save 60% on gas costs** with Mantle Network deployment
- 🔒 Generate cryptographic proofs** using Groth16 + BN254 curve
- 🏗️ Deploy ZK-enabled contracts** via ThirdWeb integration

## 🚀 **Quick Start**

### **Prerequisites**
- Rust 1.70+
- Node.js 18+ (for contract deployment)
- Git

**Installation**

# Clone the repository
git clone https://github.com/yourusername/niet2code.git
cd niet2code

# Set up environment variables
cp .env.example .env
# Edit .env with your credentials 

# Build the CLI
cd zk-cli
cargo build --release

# Initialize your builder profile
cargo run -- init --alias "YourBuilderName"


Configuration

Create a `.env` file in the project root:


# Test wallet for Mantle deployment (DO NOT USE REAL FUNDS)
PRIVATE_KEY=your_test_private_key_here

# Network configuration
MANTLE_TESTNET_RPC=https://rpc.sepolia.mantle.xyz
MANTLE_MAINNET_RPC=https://rpc.mantle.xyz
MANTLE_CHAIN_ID_TESTNET=5003
MANTLE_CHAIN_ID_MAINNET=5000

# Privy authentication (get from https://privy.io)
PRIVY_APP_ID=your_privy_app_id
PRIVY_APP_SECRET=your_privy_app_secret

# ThirdWeb integration (get from https://thirdweb.com)
THIRDWEB_CLIENT_ID=your_thirdweb_client_id
THIRDWEB_SECRET_KEY=your_thirdweb_secret_key


## 🔮 **Core Features**

**1. Zero-Knowledge Proof Generation**

Generate cryptographic proofs that verify multiplication without revealing inputs:

# Generate proof that you know a × b = c (without revealing a, b)
cargo run -- prove --a 7 --b 8 --c 56 --network mantle-testnet

# Verify proof locally
cargo run -- verify --proof ../proofs/proof.bin --input ../proofs/public_input.bin --vk ../keys/verifying_key.bin


**2. Anonymous Builder Registration**


# Register anonymously on-chain
cargo run -- register --alias "AnonymousBuilder" --network mantle-testnet


### **3. On-Chain Proof Submission**


# Submit proof for verification on Mantle Network
cargo run -- submit-proof --proof-file ../calldata.bin --network mantle-testnet


### **4. Builder Dashboard**


# View your anonymous builder stats
cargo run -- dashboard --network mantle-testnet

## 📊 **CLI Commands Reference**

### **Core ZK Operations**
| Command | Description | Example |
|---------|-------------|---------|
| `prove` | Generate ZK proof | `cargo run -- prove --a 5 --b 6 --c 30` |
| `verify` | Verify proof locally | `cargo run -- verify --proof proof.bin --input input.bin --vk vk.bin` |
| `submit-proof` | Submit to blockchain | `cargo run -- submit-proof --network mantle-testnet` |

### **Builder Management**
| Command | Description | Example |
|---------|-------------|---------|
| `init` | Initialize builder profile | `cargo run -- init --alias "Builder"` |
| `register` | Register on-chain | `cargo run -- register --alias "Builder" --network mantle-testnet` |
| `dashboard` | View builder stats | `cargo run -- dashboard --network mantle-testnet` |

### Integrations**
| Command | Description | Example |
|---------|-------------|---------|
| `privy auth` | Anonymous authentication | `cargo run -- privy auth` |
| `thirdweb list` | List contract templates | `cargo run -- thirdweb list` |
| `thirdweb deploy` | Deploy ZK contract | `cargo run -- thirdweb deploy --template niet2code-anonymous-nft` |


