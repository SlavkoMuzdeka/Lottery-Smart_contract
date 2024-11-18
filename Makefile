-include .env

build :; forge build

install :; forge install smartcontractkit/chainlink-brownie-contracts --no-commit && forge install Cyfrin/foundry-devops --no-commit && forge install transmissions11/solmate --no-commit && forge install foundry-rs/forge-std --no-commit

update :; forge update

coverage :; forge coverage

test-anvil:; forge test

test-sepolia :
	@forge test --fork-url $(SEPOLIA_RPC_URL)

deploy-anvil:
	@forge script script/Raffle.s.sol:RaffleScript --rpc-url $(ANVIL_RPC_URL) --private-key $(ANVIL_PRIVATE_KEY) --broadcast

deploy-sepolia:
	@forge script script/Raffle.s.sol:RaffleScript --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv