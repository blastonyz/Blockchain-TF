-include .env
#Anvil
ANVIL_DEPLOYER := 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

PRIVATE_KEY_ANVIL := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80


ANVIL_CONTRACT_BUSD := 0x5FbDB2315678afecb367f032d93F642f64180aa3

ANVIL_CONTRACT_CCNFT := 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

ANVIL_RPC_URL := http://127.0.0.1:8545

#fundsToken
ERC20_CONTRACT := 0x901E14f05f5DFc058C2B6f8C7e68B9136dAa19c5
#ccnft address
CONTRACT_ADDRESS := 0x0d9F045B1A92Aad43557CFeBb64AA4215Fc7910A

FUNDS_COLLECTOR_ALT := 0x90813c2C61EE01857c2fDfD003f5272b540a7AA7

PRIVATE_KEY_SEPOLIA := 5c15f2560f82882856349e6dd28b6321e1e9c9c3911cbeeb4831d71fd988f236
SEPOLIA_RPC_URL := https://eth-sepolia.g.alchemy.com/v2/QO9VEoGt2J53QdbHsiJzZzmJLNdhqj_r
ETHERSCAN_API_KEY := EGGCPCT7NBDYXSX4EYG3XCHX3DDBPP9G6P


NETWORK_ARGS_VERIFY_SEPOLIA_NFT := --rpc-url ${SEPOLIA_RPC_URL} --private-key ${PRIVATE_KEY_SEPOLIA} --broadcast --verify -vvvv --etherscan-api-key ${ETHERSCAN_API_KEY}

deployAnvilBUSD:
	@forge script script/BUSDdeploy.s.sol --rpc-url ${ANVIL_RPC_URL} --private-key ${PRIVATE_KEY_ANVIL} --broadcast

deployAnvilCCNFT:
	@forge script script/CCNFTdeploy.s.sol --rpc-url ${ANVIL_RPC_URL} --private-key ${PRIVATE_KEY_ANVIL} --broadcast

anvilCanBuy:
	@cast send $(ANVIL_CONTRACT_CCNFT) "setCanBuy(bool)" true --private-key $(PRIVATE_KEY_ANVIL) --rpc-url $(ANVIL_RPC_URL)

anvilAddValidValues:
	@cast send $(ANVIL_CONTRACT_CCNFT) "addValidValues(uint256)" 100000000000000000000 --private-key $(PRIVATE_KEY_ANVIL) --rpc-url $(ANVIL_RPC_URL)

anvilSetMaxBatchCount:
	@cast send $(ANVIL_CONTRACT_CCNFT) "setMaxBatchCount(uint16)" 10 --private-key $(PRIVATE_KEY_ANVIL) --rpc-url $(ANVIL_RPC_URL)

anvilSetMaxValueToRaise:
	@cast send $(ANVIL_CONTRACT_CCNFT) "setMaxValueToRaise(uint)" 10000000000000000000000000 --private-key $(PRIVATE_KEY_ANVIL) --rpc-url $(ANVIL_RPC_URL)

anvilFundsTokenInitialSet: 
	@cast send $(ANVIL_CONTRACT_CCNFT) "setFundsToken(address)" $(ANVIL_FUNDS_TOKEN) --private-key $(PRIVATE_KEY_ANVIL) --rpc-url $(ANVIL_RPC_URL)

anvilFundsCollectorInitialSet: 
	@cast send $(ANVIL_CONTRACT_CCNFT) "setFundsCollector(address)" $(ANVIL_FUNDS_TOKEN) --private-key $(PRIVATE_KEY_ANVIL) --rpc-url $(ANVIL_RPC_URL)
	

anvilFeesCollectorInitialSet: 
	@cast send $(ANVIL_CONTRACT_CCNFT) "setFeesCollector(address)" $(ANVIL_FUNDS_TOKEN) --private-key $(PRIVATE_KEY_ANVIL) --rpc-url $(ANVIL_RPC_URL)	

anvilBuyInitialSet:
	@cast send $(ANVIL_CONTRACT_CCNFT) "buy(uint256,uint256)" 100000000000000000000 1 --private-key $(PRIVATE_KEY_ANVIL) --rpc-url $(ANVIL_RPC_URL)



#EtherScan
deployAndVerifyBUSD:
	@forge script script/BUSDdeploy.s.sol ${NETWORK_ARGS_VERIFY_SEPOLIA_NFT}

deployAndVerifyCCNFT:
	@forge script script/CCNFTdeploy.s.sol ${NETWORK_ARGS_VERIFY_SEPOLIA_NFT}


canBuyInitialSet: 
	@cast send $(CONTRACT_ADDRESS) "setCanBuy(bool)" true --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

validValuesInitialSet: 
	@cast send $(CONTRACT_ADDRESS) "addValidValues(uint256)" 10000000000000000 --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

maxBatchSet: 
	@cast send $(CONTRACT_ADDRESS) "setMaxBatchCount(uint16)" 10 --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

maxValueToRaiseSet: 
	@cast send $(CONTRACT_ADDRESS) "setMaxValueToRaise(uint)" 10000000000000000000000000 --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

fundsTokenInitialSet: 
	@cast send $(CONTRACT_ADDRESS) "setFundsToken(address)" $(ERC20_CONTRACT) --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

fundsCollectorInitialSet: 
	@cast send $(CONTRACT_ADDRESS) "setFundsCollector(address)" $(FUNDS_COLLECTOR_ALT) --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

feesCollectorInitialSet: 
	@cast send $(CONTRACT_ADDRESS) "setFeesCollector(address)" $(FUNDS_COLLECTOR_ALT) --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

buyFeesInitialSet:	
	@cast send $(CONTRACT_ADDRESS) "setBuyFee(uint16)" 5 --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

tradeFeesInitialSet:	
	@cast send $(CONTRACT_ADDRESS) "setTradeFee(uint16)" 5 --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

cantradeInitialSet:
	@cast send $(CONTRACT_ADDRESS) "setCanTrade(bool)" true --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

canClaimInitialSet:
	@cast send $(CONTRACT_ADDRESS) "setCanClaim(bool)" true --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)	

profitToPayInitialSet:
	@cast send $(CONTRACT_ADDRESS) "setProfitToPay(uint32)" 1 --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)	
#Compra
buyInitialSet: 
	@cast send $(CONTRACT_ADDRESS) "buy(uint256,uint256)" 10000000000000000 2 --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)	

putOnSaleInitialSet:
		@cast send $(CONTRACT_ADDRESS) "putOnSale(uint256,uint256)" 0 10000000000000000 --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

claimInitialSet: 
	@cast send $(CONTRACT_ADDRESS) "claim(uint256[])" [0] --private-key $(PRIVATE_KEY_SEPOLIA) --rpc-url $(SEPOLIA_RPC_URL)

tradeInitialSet: 
	@cast send $(CONTRACT_ADDRESS) "trade(uint256)" 0 --private-key c77aa73419b0eee2755bd19a1cf2cda85ff1327388bb596bed4d19f9210f6504 --rpc-url $(SEPOLIA_RPC_URL)

checkAllowance:
	@cast call $(ERC20_CONTRACT) "allowance(address,address)" 0x0571235134DC15a00f02916987C2c16b5fC52E2A 0x90813c2C61EE01857c2fDfD003f5272b540a7AA7 --rpc-url $(SEPOLIA_RPC_URL)	