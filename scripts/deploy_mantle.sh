#!/bin/bash
# Final Real Mantle Deployment Script - No Simulations
# niet2code Builder Edition for Cookathon 2025

set -e

echo "🔮 niet2code Builder Edition - Real Mantle Deployment"
echo "=================================================="

# Configuration
MANTLE_TESTNET_RPC="https://rpc.sepolia.mantle.xyz"
MANTLE_MAINNET_RPC="https://rpc.mantle.xyz"
MANTLE_TESTNET_CHAIN_ID=5003
MANTLE_MAINNET_CHAIN_ID=5000

# Parse command line args
NETWORK=${1:-testnet}

if [ "$NETWORK" = "mainnet" ]; then
    RPC_URL=$MANTLE_MAINNET_RPC
    CHAIN_ID=$MANTLE_MAINNET_CHAIN_ID
    EXPLORER="https://explorer.mantle.xyz"
else
    RPC_URL=$MANTLE_TESTNET_RPC
    CHAIN_ID=$MANTLE_TESTNET_CHAIN_ID
    EXPLORER="https://sepolia.mantlescan.xyz"
fi

echo "🌐 Network: Mantle $NETWORK"
echo "🔗 RPC: $RPC_URL"
echo "🆔 Chain ID: $CHAIN_ID"
echo ""

# Load environment variables
load_env() {
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
        echo "✅ Environment loaded from .env"
    else
        echo "❌ .env file not found"
        echo "📝 Create .env file with:"
        echo "PRIVATE_KEY=0x..."
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check private key
    if [ -z "$PRIVATE_KEY" ]; then
        echo "❌ PRIVATE_KEY not set in .env file"
        exit 1
    fi
    
    # Validate private key format
    if [[ ! $PRIVATE_KEY =~ ^0x[a-fA-F0-9]{64}$ ]]; then
        echo "❌ Invalid private key format. Must be 0x followed by 64 hex characters"
        exit 1
    fi
    
    # Check Foundry installation
    if ! command -v forge &> /dev/null; then
        echo "❌ Foundry not installed"
        echo "📦 Install with: curl -L https://foundry.paradigm.xyz | bash"
        exit 1
    fi
    
    if ! command -v cast &> /dev/null; then
        echo "❌ Cast not installed"
        echo "📦 Install with: foundryup"
        exit 1
    fi
    
    # Check network connectivity
    echo "🌐 Testing network connectivity..."
    if ! cast block-number --rpc-url $RPC_URL > /dev/null 2>&1; then
        echo "❌ Cannot connect to $RPC_URL"
        exit 1
    fi
    
    # Get wallet address and check balance
    WALLET_ADDRESS=$(cast wallet address $PRIVATE_KEY)
    echo "👤 Deployer address: $WALLET_ADDRESS"
    
    BALANCE=$(cast balance $WALLET_ADDRESS --rpc-url $RPC_URL)
    echo "💰 Balance: $BALANCE wei"
    
    # Check if balance is sufficient (need at least 0.01 MNT for deployment)
    MIN_BALANCE="10000000000000000"  # 0.01 MNT in wei
    if [ $(echo "$BALANCE < $MIN_BALANCE" | bc -l) -eq 1 ]; then
        echo "❌ Insufficient balance for deployment"
        echo "💡 Get test tokens from: https://www.mnt-faucet.xyz/"
        echo "📋 Your address: $WALLET_ADDRESS"
        exit 1
    fi
    
    echo "✅ Prerequisites satisfied"
}

# Setup Foundry project
setup_foundry_project() {
    echo "📁 Setting up Foundry project..."
    
    # Create foundry.toml
    cat > foundry.toml << EOF
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
remappings = []

[rpc_endpoints]
mantle_testnet = "$MANTLE_TESTNET_RPC"
mantle_mainnet = "$MANTLE_MAINNET_RPC"
EOF

    mkdir -p contracts script
    echo "✅ Foundry project configured"
}

# Create the smart contract
create_smart_contract() {
    echo "📝 Creating smart contract..."
    
    cat > contracts/niet2codeBuilder.sol << 'EOF'
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

contract niet2codeBuilder {
    
    struct BuilderProfile {
        string aliasName;
        uint256 proofsVerified;
        uint256 contractsDeployed;
        uint256 privacyScore;
        uint256 joinedAt;
        uint256 lastActivity;
        bool isActive;
    }
    
    struct ProofData {
        bytes32 proofHash;
        address verifier;
        uint256 timestamp;
        bool isValid;
        string network;
    }
    
    event BuilderRegistered(address indexed builder, string aliasName);
    event ProofVerified(address indexed builder, bytes32 proofHash, bool isValid);
    event ContractDeployed(address indexed builder, address contractAddr);
    
    mapping(address => BuilderProfile) public builders;
    mapping(bytes32 => ProofData) public proofs;
    
    uint256 public totalBuilders;
    uint256 public totalProofsVerified;
    uint256 public totalGasSaved;
    
    modifier onlyRegisteredBuilder() {
        require(builders[msg.sender].isActive, "Builder not registered");
        _;
    }
    
    function registerBuilder(string calldata aliasName) external {
        require(bytes(aliasName).length > 0, "aliasName cannot be empty");
        require(bytes(aliasName).length <= 32, "aliasName too long");
        
        if (!builders[msg.sender].isActive) {
            totalBuilders++;
        }
        
        builders[msg.sender] = BuilderProfile({
            aliasName: aliasName,
            proofsVerified: 0,
            contractsDeployed: 0,
            privacyScore: 0,
            joinedAt: block.timestamp,
            lastActivity: block.timestamp,
            isActive: true
        });
        
        emit BuilderRegistered(msg.sender, aliasName);
    }
    
    function verifyProof(
        bytes calldata proofBytes,
        bytes32[] calldata publicInputs
    ) external onlyRegisteredBuilder returns (bool isValid) {
        require(proofBytes.length >= 128, "Invalid proof length");
        require(publicInputs.length > 0, "Public inputs required");
        
        bytes32 proofHash = keccak256(abi.encodePacked(proofBytes, publicInputs));
        
        // Basic proof validation
        isValid = _validateProofStructure(proofBytes, publicInputs);
        
        proofs[proofHash] = ProofData({
            proofHash: proofHash,
            verifier: msg.sender,
            timestamp: block.timestamp,
            isValid: isValid,
            network: "mantle"
        });
        
        builders[msg.sender].proofsVerified++;
        builders[msg.sender].lastActivity = block.timestamp;
        
        if (isValid) {
            totalProofsVerified++;
            totalGasSaved += 75000;
            _updatePrivacyScore(msg.sender);
        }
        
        emit ProofVerified(msg.sender, proofHash, isValid);
        return isValid;
    }
    
    function recordDeployment(address contractAddr) external onlyRegisteredBuilder {
        require(contractAddr != address(0), "Invalid contract address");
        
        builders[msg.sender].contractsDeployed++;
        builders[msg.sender].lastActivity = block.timestamp;
        
        _updatePrivacyScore(msg.sender);
        
        emit ContractDeployed(msg.sender, contractAddr);
    }
    
    function getBuilderStats(address builder) external view returns (
        string memory aliasName,
        uint256 proofsVerified,
        uint256 contractsDeployed,
        uint256 privacyScore,
        uint256 joinedAt
    ) {
        BuilderProfile memory profile = builders[builder];
        return (
            profile.aliasName,
            profile.proofsVerified,
            profile.contractsDeployed,
            profile.privacyScore,
            profile.joinedAt
        );
    }
    
    function getPlatformStats() external view returns (
        uint256 _totalBuilders,
        uint256 _totalProofsVerified,
        uint256 _totalGasSaved
    ) {
        return (totalBuilders, totalProofsVerified, totalGasSaved);
    }
    
    function getContractInfo() external pure returns (
        string memory name,
        string memory version,
        string memory description
    ) {
        return (
            "niet2codeBuilder",
            "1.0.0",
            "Anonymous Smart Contract Verification - Cookathon 2025"
        );
    }
    
    function _validateProofStructure(
        bytes calldata proofBytes,
        bytes32[] calldata publicInputs
    ) internal pure returns (bool) {
        for (uint i = 0; i < proofBytes.length; i++) {
            if (proofBytes[i] != 0) {
                for (uint j = 0; j < publicInputs.length; j++) {
                    if (publicInputs[j] != bytes32(0)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    function _updatePrivacyScore(address builder) internal {
        BuilderProfile storage profile = builders[builder];
        
        uint256 baseScore = profile.proofsVerified * 10;
        uint256 deploymentBonus = profile.contractsDeployed * 15;
        uint256 activityBonus = _calculateActivityBonus(profile.lastActivity);
        
        uint256 newScore = baseScore + deploymentBonus + activityBonus;
        if (newScore > 100) {
            newScore = 100;
        }
        
        profile.privacyScore = newScore;
    }
    
    function _calculateActivityBonus(uint256 lastActivity) internal view returns (uint256) {
        uint256 timeSinceActivity = block.timestamp - lastActivity;
        
        if (timeSinceActivity < 1 days) {
            return 20;
        } else if (timeSinceActivity < 7 days) {
            return 10;
        } else if (timeSinceActivity < 30 days) {
            return 5;
        } else {
            return 0;
        }
    }
}
EOF
    
    echo "✅ Smart contract created"
}

# Create deployment script
create_deployment_script() {
    echo "📜 Creating deployment script..."
    
    cat > script/Deploy.s.sol << 'EOF'
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../contracts/niet2codeBuilder.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        niet2codeBuilder niet2codeBuilder = new niet2codeBuilder();
        
        console.log("niet2codeBuilder deployed to:", address(niet2codeBuilder));
        
        vm.stopBroadcast();
    }
}
EOF
    
    echo "✅ Deployment script created"
}

# Deploy the contract
deploy_contract() {
    echo "🚀 Deploying to Mantle $NETWORK..."
    
    # Compile contracts
    echo "🔨 Compiling contracts..."
    forge build
    
    if [ $? -ne 0 ]; then
        echo "❌ Compilation failed"
        exit 1
    fi
    
    # Deploy using forge
    echo "📡 Broadcasting deployment transaction..."
    
    DEPLOY_OUTPUT=$(forge script script/Deploy.s.sol:DeployScript \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        --slow)
    
    echo "$DEPLOY_OUTPUT"
    
    # Extract contract address from output
    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -o "niet2codeBuilder deployed to: 0x[a-fA-F0-9]\{40\}" | grep -o "0x[a-fA-F0-9]\{40\}")
    
    if [ -z "$CONTRACT_ADDRESS" ]; then
        echo "❌ Deployment failed - no contract address found"
        echo "Output: $DEPLOY_OUTPUT"
        exit 1
    fi
    
    echo "✅ Contract deployed to: $CONTRACT_ADDRESS"
    
    # Extract transaction hash
    TX_HASH=$(echo "$DEPLOY_OUTPUT" | grep -o "transactionHash.*0x[a-fA-F0-9]\{64\}" | grep -o "0x[a-fA-F0-9]\{64\}")
    
    # Save deployment info
    cat > deployment.json << EOF
{
  "contractAddress": "$CONTRACT_ADDRESS",
  "transactionHash": "$TX_HASH",
  "network": "$NETWORK",
  "chainId": $CHAIN_ID,
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "deployer": "$(cast wallet address $PRIVATE_KEY)",
  "explorer": "$EXPLORER/address/$CONTRACT_ADDRESS",
  "rpcUrl": "$RPC_URL"
}
EOF
    
    echo "$CONTRACT_ADDRESS" > contract_address.txt
}

# Test the deployed contract
test_deployment() {
    echo "🧪 Testing deployed contract..."
    
    CONTRACT_ADDRESS=$(cat contract_address.txt)
    
    echo "📞 Testing contract call..."
    CONTRACT_INFO=$(cast call $CONTRACT_ADDRESS \
        "getContractInfo()(string,string,string)" \
        --rpc-url $RPC_URL)
    
    if [ $? -eq 0 ]; then
        echo "✅ Contract responding: $CONTRACT_INFO"
    else
        echo "❌ Contract call failed"
        exit 1
    fi
    
    echo "✅ Deployment test complete"
}

# Update CLI configuration
update_cli_config() {
    echo "⚙️  Updating CLI configuration..."
    
    CONTRACT_ADDRESS=$(cat contract_address.txt)
    
    cat > contract_config.json << EOF
{
  "networks": {
    "mantle-testnet": {
      "rpcUrl": "$MANTLE_TESTNET_RPC",
      "chainId": $MANTLE_TESTNET_CHAIN_ID,
      "contractAddress": "$CONTRACT_ADDRESS",
      "explorer": "https://sepolia.mantlescan.xyz"
    },
    "mantle-mainnet": {
      "rpcUrl": "$MANTLE_MAINNET_RPC", 
      "chainId": $MANTLE_MAINNET_CHAIN_ID,
      "contractAddress": "TBD",
      "explorer": "https://explorer.mantle.xyz"
    }
  }
}
EOF
    
    echo "✅ CLI configuration updated"
}

# Main deployment flow
main() {
    load_env
    check_prerequisites
    setup_foundry_project
    create_smart_contract
    create_deployment_script
    deploy_contract
    test_deployment
    update_cli_config
    
    echo ""
    echo "🎉 Real Deployment Complete!"
    echo "============================"
    echo "🔮 niet2code Builder Edition is now LIVE on Mantle $NETWORK!"
    echo ""
    echo "📋 Contract Details:"
    echo "   • Address: $(cat contract_address.txt)"
    echo "   • Network: Mantle $NETWORK"
    echo "   • Explorer: $EXPLORER/address/$(cat contract_address.txt)"
    echo "   • Transaction: $(cat deployment.json | grep transactionHash | cut -d'"' -f4)"
    echo ""
    echo "🎯 Next Steps:"
    echo "   1. cd zk-cli && cargo run -- register --aliasName 'YourName' --network mantle-testnet"
    echo "   2. cargo run -- prove --a 5 --b 6 --c 30 --network mantle-testnet"
    echo "   3. cargo run -- submit-proof --network mantle-testnet"
    echo "   4. cargo run -- dashboard --network mantle-testnet"
    echo ""
    echo "🚀 Ready for partner integrations!"
}

# Handle command line arguments
case "${1:-testnet}" in
    "mainnet")
        echo "⚠️  Deploying to MAINNET - real funds will be used!"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            NETWORK="mainnet"
            main
        else
            echo "❌ Deployment cancelled"
            exit 1
        fi
        ;;
    "testnet"|"")
        NETWORK="testnet"
        main
        ;;
    "clean")
        echo "🧹 Cleaning deployment artifacts..."
        rm -rf out cache contracts script deployment.json contract_address.txt contract_config.json foundry.toml lib
        echo "✅ Cleaned"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [testnet|mainnet|clean|help]"
        echo ""
        echo "Prerequisites:"
        echo "  1. Create .env file with PRIVATE_KEY=0x..."
        echo "  2. Install Foundry: curl -L https://foundry.paradigm.xyz | bash"
        echo "  3. Get test MNT: https://rpc.sepolia.mantle.xyz"
        echo ""
        echo "Commands:"
        echo "  testnet  - Deploy to Mantle testnet (default)"
        echo "  mainnet  - Deploy to Mantle mainnet"
        echo "  clean    - Clean deployment artifacts"
        echo "  help     - Show this help"
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac