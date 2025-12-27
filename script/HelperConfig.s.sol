//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2PlusMock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    /* VRF Mock Parameters */
    uint96 public constant MOCK_BASE_FEE = 0.1 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15; //   //LINK / ETH price

    uint256 public constant ETH_SEPOLIA_CHAINID = 11155111;
    uint256 public constant ETH_MAINNET_CHAINID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant DEFAULT_ANVIL_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
}

contract HelperConfig is CodeConstants, Script {
    error HelperConfig__NoLocalConfig();

    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAINID] = getSepoliaConfig();
    }

    function getConfigbyChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilConfig();
        } else {
            revert HelperConfig__NoLocalConfig();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigbyChainId(block.chainid);
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30, // 30 seconds,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 65444835761950053591291610595240248796948501282236532840530313143605531272608,
                callbackGasLimit: 500000,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY")
            });
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // check if localNetworkConfig is already set
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        // Deploy a mock VRFCoordinator and set up a subscription

        vm.startBroadcast();
        VRFCoordinatorV2PlusMock vrfCoordinatorV2PlusMock = new VRFCoordinatorV2PlusMock(
                MOCK_BASE_FEE,
                MOCK_GAS_PRICE_LINK
            );

        LinkToken link = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorV2PlusMock.createSubscription();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            subscriptionId: 0,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            interval: 30, // 30 seconds
            entranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinator: address(vrfCoordinatorV2PlusMock),
            link: address(link),
            deployerKey: DEFAULT_ANVIL_KEY
        });
        vm.deal(vm.addr(localNetworkConfig.deployerKey), 100 ether);
        return localNetworkConfig;
    }
}
