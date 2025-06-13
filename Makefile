# niet2code Builder Edition - Makefile

.PHONY: all build clean deploy-mantle test dashboard

# Build all components
all: build-workspace build-verifier

build-workspace:
	@echo "🔮 Building workspace (prover + CLI)..."
	cargo build --release

build-verifier:
	@echo "🔮 Building verifier contract..."
	cd verifier-contract && make all

# Deploy to Mantle Network
deploy-mantle: all
	@echo "🚀 Deploying niet2code Builder Edition to Mantle..."
	@if [ -f "./scripts/deploy_mantle.sh" ]; then \
		./scripts/deploy_mantle.sh; \
	else \
		echo "❌ Deploy script not found. Run from project root."; \
	fi

# Generate proof and show dashboard
demo: all
	@echo "🔮 niet2code Builder Edition Demo"
	cd zk-cli && cargo run --release -- init --aliasName "Demo Builder"
	cd zk-cli && cargo run --release -- prove --a 7 --b 8 --c 56 --network mantle-testnet
	cd zk-cli && cargo run --release -- dashboard

# Show builder dashboard
dashboard:
	cd zk-cli && cargo run --release -- dashboard

# Show partner roadmap
partners:
	cd zk-cli && cargo run --release -- partners

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	cargo clean
	cd verifier-contract && make clean 2>/dev/null || true
	rm -rf keys/ proofs/ calldata.bin builder_stats.json deployment.json

# Run tests
test:
	cargo test

help:
	@echo "🔮 niet2code Builder Edition"
	@echo "Available commands:"
	@echo "  make all          - Build all components"
	@echo "  make deploy-mantle - Deploy to Mantle Network"
	@echo "  make demo         - Run full demo"
	@echo "  make dashboard    - Show builder stats"
	@echo "  make partners     - Show partner roadmap"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make test         - Run tests"