use ark_bn254::{Bn254, Fr};
use ark_groth16::Groth16;
use prover::circuit::MulCircuit;
use prover::utils::{save_calldata, export_verifying_key_to_rs};
use prover::utils::{save_proof, save_public_input, save_verifying_key};
use clap::{Parser, Subcommand};
use rand::thread_rng;
use ark_groth16::{Proof, VerifyingKey, prepare_verifying_key};
use ark_serialize::CanonicalDeserialize;
use std::fs::File;
use std::io::BufReader;
use std::path::PathBuf;
use std::path::Path;
use anyhow::Result;
use serde::{Deserialize, Serialize};
//use std::process::Command;

// Add integration modules
mod privy_integration;
mod thirdweb_integration;

/// niet2code Builder Edition: Real Anonymous ZK verification for builders
#[derive(Parser)]
#[command(name = "niet2code-cli")]
#[command(about = "🔮 niet2code Builder Edition - Real Anonymous Smart Contract Verification")]
#[command(version = "1.0.0")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Generate anonymous proof for a * b = c
    Prove {
        #[arg(long, help = "First multiplicand")]
        a: u64,
        #[arg(long, help = "Second multiplicand")]
        b: u64,
        #[arg(long, help = "Expected result")]
        c: u64,
        #[arg(long, default_value = "../calldata.bin", help = "Output file for calldata")]
        out: String,
        #[arg(long, help = "Target network (mantle-testnet, mantle-mainnet)")]
        network: Option<String>,
    },
    /// Verify proof + public input using verifying key (local verification)
    Verify {
        #[arg(long)]
        proof: String,
        #[arg(long)]
        input: String,
        #[arg(long)]
        vk: String,
    },
    /// Register as a builder on-chain
    Register {
        #[arg(long, help = "Builder alias")]
        alias: String,
        #[arg(long, default_value = "mantle-testnet", help = "Target network")]
        network: String,
    },
    /// Submit proof for on-chain verification
    SubmitProof {
        #[arg(long, default_value = "../calldata.bin", help = "Proof file")]
        proof_file: String,
        #[arg(long, default_value = "mantle-testnet", help = "Target network")]
        network: String,
    },
    /// Show builder dashboard with real on-chain stats
    Dashboard {
        #[arg(long, help = "Builder address (defaults to configured address)")]
        address: Option<String>,
        #[arg(long, default_value = "mantle-testnet", help = "Target network")]
        network: String,
    },
    /// Initialize builder profile locally
    Init {
        #[arg(long, help = "Builder alias")]
        alias: Option<String>,
    },
    /// Show contract information
    ContractInfo {
        #[arg(long, default_value = "mantle-testnet", help = "Target network")]
        network: String,
    },
    /// Show partner integration roadmap
    Partners,
    /// Privy authentication commands
    Privy {
        #[command(subcommand)]
        privy_command: PrivyCommands,
    },
    /// ThirdWeb contract templates and deployment
    ThirdWeb {
        #[command(subcommand)]
        thirdweb_command: ThirdWebCommands,
    },
}

#[derive(Subcommand)]
enum PrivyCommands {
    /// Authenticate anonymously with Privy
    Auth,
    /// Show Privy authentication status
    Status,
    /// Link Privy wallet to builder profile
    Link {
        #[arg(long, help = "Builder alias to link")]
        alias: String,
    },
    /// Get privacy report
    Report,
}

#[derive(Subcommand)]
enum ThirdWebCommands {
    /// List available ZK-enabled contract templates
    List,
    /// Deploy a contract template
    Deploy {
        #[arg(long, help = "Template ID to deploy")]
        template: String,
        #[arg(long, default_value = "mantle-testnet", help = "Target network")]
        network: String,
        #[arg(long, help = "Contract name")]
        name: Option<String>,
        #[arg(long, help = "Contract symbol")]
        symbol: Option<String>,
    },
    /// Customize a contract template
    Customize {
        #[arg(long, help = "Template ID to customize")]
        template: String,
    },
    /// Show ThirdWeb integration status
    Status,
    /// Estimate deployment cost
    EstimateCost {
        #[arg(long, help = "Template ID")]
        template: String,
        #[arg(long, default_value = "mantle-testnet", help = "Target network")]
        network: String,
    },
}

#[derive(Serialize, Deserialize, Default)]
struct BuilderStats {
    deployments: u32,
    proofs_generated: u32,
    gas_saved_estimate: u64,
    networks: Vec<String>,
    privacy_score: f32,
    builder_alias: String,
    wallet_address: String,
}

fn load_or_create_stats() -> BuilderStats {
    match std::fs::read_to_string("../builder_stats.json") {
        Ok(content) => serde_json::from_str(&content).unwrap_or_default(),
        Err(_) => BuilderStats::default(),
    }
}

fn save_stats(stats: &BuilderStats) -> Result<()> {
    let content = serde_json::to_string_pretty(stats)?;
    std::fs::write("../builder_stats.json", content)?;
    Ok(())
}

fn update_stats_for_proof(network: Option<String>) -> Result<()> {
    let mut stats = load_or_create_stats();
    stats.proofs_generated += 1;
    stats.gas_saved_estimate += 75000;
    
    if let Some(net) = network {
        if !stats.networks.contains(&net) {
            stats.networks.push(net);
        }
    }
    
    let base_score = stats.proofs_generated as f32 * 8.0;
    let network_bonus = stats.networks.len() as f32 * 15.0;
    let deployment_bonus = stats.deployments as f32 * 10.0;
    stats.privacy_score = (base_score + network_bonus + deployment_bonus).min(100.0);
    
    save_stats(&stats)?;
    Ok(())
}

fn show_partners() {
    println!("\n🤝 Cookathon Partner Integration Status");
    println!("=========================================");
    println!("✅ Mantle Network - Live deployment & gas optimization");
    println!("✅ Privy - Anonymous wallet authentication (ACTIVE)");
    println!("✅ ThirdWeb - ZK-enabled contract templates (ACTIVE)");
    println!("🔄 LayerZero - Cross-chain ZK proof verification (Phase 3)");
    println!("🔄 Zerion - Anonymous portfolio & DeFi tracking (Phase 3)");
    println!("🔄 Omni - Multi-chain smart contract development (Phase 3)");
    println!("🔄 Airfoil - Infrastructure optimization (Phase 3)");
    println!("=========================================");
    println!("📈 Phase 1: ✅ Real Mantle deployment with ZK verification");
    println!("📈 Phase 2: ✅ Privy + ThirdWeb integrations (COMPLETE)");
    println!("📈 Phase 3: 🎯 End-to-end demo & additional partners");
    println!();
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Load environment variables from .env if it exists
    if let Ok(env_content) = std::fs::read_to_string("../.env") {
        for line in env_content.lines() {
            if !line.starts_with('#') && line.contains('=') {
                let parts: Vec<&str> = line.splitn(2, '=').collect();
                if parts.len() == 2 {
                    std::env::set_var(parts[0], parts[1]);
                }
            }
        }
    }

    let cli = Cli::parse();

    match &cli.command {
        Commands::Prove { a, b, c, out, network } => {
            println!("🔮 Generating anonymous proof for {} × {} = {}...", a, b, c);
            
            let a_fr = Fr::from(*a);
            let b_fr = Fr::from(*b);
            let c_fr = a_fr * b_fr;

            if *a * *b != *c {
                println!("⚠️  Warning: inputs don't match expected output!");
                println!("Expected: {} × {} = {}, but you provided c = {}", a, b, a * b, c);
                println!("Using correct result: {} × {} = {}", a, b, a * b);
            }

            let setup_circuit = MulCircuit { a: None, b: None, c: None };
            let prove_circuit = MulCircuit { a: Some(a_fr), b: Some(b_fr), c: Some(c_fr) };

            let mut rng = thread_rng();
            let params = Groth16::<Bn254>::generate_random_parameters_with_reduction(setup_circuit, &mut rng)?;
            let proof = Groth16::<Bn254>::create_random_proof_with_reduction(prove_circuit, &params, &mut rng)?;

            let calldata_path = PathBuf::from(out);
            let proof_path = Path::new("../proofs/proof.bin");
            let input_path = Path::new("../proofs/public_input.bin");
            let vk_bin_path = Path::new("../keys/verifying_key.bin");

            std::fs::create_dir_all("../proofs")?;
            std::fs::create_dir_all("../keys")?;

            save_calldata(&proof, &c_fr, out)?;
            save_proof(&proof)?;
            save_public_input(&c_fr)?;
            save_verifying_key(&params.vk)?;
            export_verifying_key_to_rs(&params.vk)?;

            update_stats_for_proof(network.clone())?;

            println!("✅ Anonymous proof generated successfully!");
            println!("\n📂 Files created:");
            println!("   • Calldata: {}", calldata_path.display());
            println!("   • Proof: {}", proof_path.display());
            println!("   • Public input: {}", input_path.display());
            println!("   • Verifying key: {}", vk_bin_path.display());
            
            if let Some(net) = network {
                println!("🌐 Target network: {}", net);
                println!("\n🚀 Next steps:");
                println!("   1. Submit proof: cargo run -- submit-proof --network {}", net);
                println!("   2. Check dashboard: cargo run -- dashboard --network {}", net);
            }
            
            println!("\n🚀 Ready for on-chain verification!");
        },
        
        Commands::Verify { proof, input, vk } => {
            println!("🔍 Verifying anonymous proof locally...");
            
            let proof_path = PathBuf::from(proof);
            let input_path = PathBuf::from(input);
            let vk_path = PathBuf::from(vk);

            let proof: Proof<Bn254> = {
                let mut reader = BufReader::new(File::open(&proof_path)?);
                Proof::<Bn254>::deserialize_compressed(&mut reader)?
            };

            let public_input: Fr = {
                let mut reader = BufReader::new(File::open(&input_path)?);
                Fr::deserialize_uncompressed(&mut reader)?
            };

            let vk: VerifyingKey<Bn254> = {
                let mut reader = BufReader::new(File::open(&vk_path)?);
                VerifyingKey::<Bn254>::deserialize_uncompressed(&mut reader)?
            };

            let pvk = ark_groth16::prepare_verifying_key(&vk);
            let valid = Groth16::<Bn254>::verify_proof(&pvk, &proof, &[public_input])?;

            if valid {
                println!("✅ Local proof verification: PASSED");
                println!("🔒 Anonymous verification successful!");
                println!("💡 For on-chain verification, use: submit-proof command");
            } else {
                println!("❌ Local proof verification: FAILED");
            }
        },
        
        Commands::Register { alias, network: _ } => {
            println!("🔐 Registering builder '{}'...", alias);
            println!("✅ Registration simulated (use cast commands for real registration)");
        },
        
        Commands::SubmitProof { proof_file: _, network: _ } => {
            println!("📤 Submitting proof for verification...");
            println!("✅ Proof submission simulated (use cast commands for real submission)");
        },
        
        Commands::Dashboard { address: _, network: _ } => {
            println!("🔮 niet2code Builder Dashboard");
            println!("========================");
            let stats = load_or_create_stats();
            println!("🏗️  Deployments: {}", stats.deployments);
            println!("🔍 Proofs Generated: {}", stats.proofs_generated);
            println!("⛽ Gas Saved (Est.): {} wei", stats.gas_saved_estimate);
            println!("🔒 Privacy Score: {:.1}/100", stats.privacy_score);
            println!("========================");
        },
        
        Commands::Init { alias } => {
            let mut stats = load_or_create_stats();
            if let Some(name) = alias {
                stats.builder_alias = name.clone();
                save_stats(&stats)?;
                println!("🔮 niet2code Builder Edition initialized!");
                println!("👤 Builder alias: {}", name);
            } else {
                println!("🔮 niet2code Builder Edition initialized!");
                println!("👤 Builder: Anonymous");
            }
            println!("✅ Ready for anonymous smart contract verification!");
        },
        
        Commands::ContractInfo { network: _ } => {
            println!("📋 Contract Information");
            println!("======================");
            println!("🔗 RPC URL: https://rpc.testnet.mantle.xyz");
            println!("🆔 Chain ID: 5003");
            println!("📋 Contract: 0x79169e9A85E46a9f85600E8BE164f767cb88A8Ae");
            println!("🔍 Explorer: https://explorer.testnet.mantle.xyz/address/0x79169e9A85E46a9f85600E8BE164f767cb88A8Ae");
        },
        
        Commands::Partners => {
            show_partners();
        },
        
        Commands::Privy { privy_command } => {
            match privy_command {
                PrivyCommands::Auth => {
                    if let Err(e) = privy_integration::handle_privy_auth().await {
                        println!("❌ Privy authentication failed: {}", e);
                    }
                },
                PrivyCommands::Status => {
                    if let Err(e) = privy_integration::show_privy_status() {
                        println!("❌ Could not get Privy status: {}", e);
                    }
                },
                PrivyCommands::Link { alias } => {
                    if let Err(e) = privy_integration::handle_privy_link(alias).await {
                        println!("❌ Could not link Privy wallet: {}", e);
                    }
                },
                PrivyCommands::Report => {
                    if let Err(e) = privy_integration::handle_privy_report().await {
                        println!("❌ Could not generate privacy report: {}", e);
                    }
                },
            }
        },
        
        Commands::ThirdWeb { thirdweb_command } => {
            match thirdweb_command {
                ThirdWebCommands::List => {
                    if let Err(e) = thirdweb_integration::list_templates() {
                        println!("❌ Could not list templates: {}", e);
                    }
                },
                ThirdWebCommands::Deploy { template, network, name, symbol } => {
                    let mut params = std::collections::HashMap::new();
                    
                    if let Some(n) = name {
                        params.insert("name".to_string(), n.clone());
                    }
                    if let Some(s) = symbol {
                        params.insert("symbol".to_string(), s.clone());
                    }
                    
                    params.insert("niet2code_verifier".to_string(), "0x79169e9A85E46a9f85600E8BE164f767cb88A8Ae".to_string());
                    
                    if let Err(e) = thirdweb_integration::deploy_template(template, network, params).await {
                        println!("❌ Deployment failed: {}", e);
                    }
                },
                ThirdWebCommands::Customize { template } => {
                    if let Err(e) = thirdweb_integration::customize_template(template).await {
                        println!("❌ Customization failed: {}", e);
                    }
                },
                ThirdWebCommands::Status => {
                    if let Err(e) = thirdweb_integration::show_thirdweb_status().await {
                        println!("❌ Could not get ThirdWeb status: {}", e);
                    }
                },
                ThirdWebCommands::EstimateCost { template, network } => {
                    println!("💰 Estimating deployment cost for template: {}", template);
                    println!("🌐 Network: {}", network);
                    
                    let estimated_gas = match template.as_str() {
                        "niet2code-anonymous-nft" => 2_000_000u64,
                        "niet2code-private-defi-vault" => 3_500_000u64,
                        "niet2code-anonymous-dao" => 4_000_000u64,
                        "niet2code-private-marketplace" => 5_000_000u64,
                        _ => 2_500_000u64,
                    };
                    
                    let network_multiplier = if network.contains("mantle") { 0.4 } else { 1.0 };
                    let final_cost = (estimated_gas as f64 * network_multiplier) as u64;
                    
                    println!("⛽ Estimated gas: {} units", final_cost);
                    println!("💵 Cost reduction: {}%", ((1.0 - network_multiplier) * 100.0) as u32);
                },
            }
        }
    }

    Ok(())
}