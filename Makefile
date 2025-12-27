-include .env

.PHONY: all test deploy

build:; forge build
test:; forge test
deploy:; forge script script/DeployRaffle.s.sol:DeployRaffle

install:; forge install cyfrin/foundry-devops@0.2.2 && forge install smartcontractkit/chainlink@42c74fcd30969bca26a9aadc07463d1c2f473b8c && forge install foundry-rs/forge-std@v1.7.0 && forge install transmissions11/solmate@v6 


deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account default --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)