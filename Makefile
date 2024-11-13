-include .env

install :; forge install smartcontractkit/chainlink-brownie-contracts --no-commit

build :; forge build

coverage :; forge coverage