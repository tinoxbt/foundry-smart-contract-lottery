//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2PlusMock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2PlusMock.sol";
import {CodeConstants} from "./HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();

        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;

        uint256 deployerKey = helperConfig.getConfig().deployerKey;

        (uint256 subscriptionId,) = createSubscription(vrfCoordinator, deployerKey);

        return (subscriptionId, vrfCoordinator);
    }

    //create subscription

    function createSubscription(address vrfCoordinator, uint256 deployerKey) public returns (uint256, address) {
        console.log("Creating subscription on on chain Id:", block.chainid);
        vm.startBroadcast(deployerKey);
        uint256 subscriptionId = VRFCoordinatorV2PlusMock(vrfCoordinator).createSubscription();

        vm.stopBroadcast();

        console.log("Your subscription Id is:", subscriptionId);

        console.log("Please update the HelperConfig.s.sol file with this subscription Id");

        return (subscriptionId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();

        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;

        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;

        address link = helperConfig.getConfig().link;

        uint256 deployerKey = helperConfig.getConfig().deployerKey;

        fundSubscription(vrfCoordinator, subscriptionId, link, deployerKey);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address link, uint256 deployerKey)
        public
    {
        console.log("Funding subscription:", subscriptionId);

        console.log("Using VRF Coordinator:", vrfCoordinator);

        console.log("Onchain Id:", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(deployerKey);

            VRFCoordinatorV2PlusMock(vrfCoordinator).fundSubscription(subscriptionId, uint96(FUND_AMOUNT));

            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);

            LinkToken(link).transferAndCall(vrfCoordinator, uint96(FUND_AMOUNT), abi.encode(subscriptionId));

            vm.stopBroadcast();
        }

        vm.startBroadcast();

        //fund subscription

        VRFCoordinatorV2PlusMock(vrfCoordinator).fundSubscription(subscriptionId, uint96(FUND_AMOUNT));

        vm.stopBroadcast();

        console.log("Funded subscription:", subscriptionId);
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script, CodeConstants {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        uint256 deployerKey = helperConfig.getConfig().deployerKey;

        addConsumer(mostRecentlyDeployed, vrfCoordinator, subscriptionId, deployerKey);

        return (subscriptionId, vrfCoordinator);
    }

    function addConsumer(address contractToVrf, address vrfCoordinator, uint256 subscriptionId, uint256 deployerKey)
        public
    {
        console.log("Adding consumer contract:", contractToVrf);

        console.log("Using VRF Coordinator:", vrfCoordinator);

        console.log("Onchain Id:", block.chainid);

        vm.startBroadcast(deployerKey);

        VRFCoordinatorV2PlusMock(vrfCoordinator).addConsumer(subscriptionId, contractToVrf);

        vm.stopBroadcast();

        console.log("Added consumer to subscription:", subscriptionId);
    }

    function run() external {
        address mostRecentlyDeployedRaffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);

        addConsumerUsingConfig(mostRecentlyDeployedRaffle);
    }
}
