// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ProposalPlatform} from "../src/Proposals.sol";
import {WarsawBikeNFT} from "../src/WarsawBikeNFT.sol";
import {NFTAuction} from "../src/NFTAuction.sol";

contract ProposalPlatformTest is Test {
    ProposalPlatform public proposalPlatform;
    WarsawBikeNFT public nftContract;
    NFTAuction public auction;

    address user1;
    address user2;

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_ENDPOINT"), 34151260);
        auction = new NFTAuction();
        nftContract = new WarsawBikeNFT(address(auction));
        auction.setNFTContract(address(nftContract));
        user1 = vm.addr(1);
        user2 = vm.addr(2);

        vm.startPrank(address(auction));
        nftContract.safeMint(user1, "");
        nftContract.safeMint(user2, "");
        vm.stopPrank();

        proposalPlatform = new ProposalPlatform(address(nftContract));
        proposalPlatform.addWhitelist(user1);
        proposalPlatform.addWhitelist(user2);

        deal(address(proposalPlatform), 5 ether);
        auction.setTreasury(address(proposalPlatform));
    }

    // user who holds NFT can create proposals with createProposal()
    function test_createProposal() public {
        vm.startPrank(user1);

        proposalPlatform.createProposal("My Proposal", 0.01 ether);

        (
            uint256 id,
            address proposer,
            string memory description,
            ,
            ,
            uint256 requestedAmount,
            ,

        ) = proposalPlatform.proposals(0);

        assertEq(id, 0);
        assertEq(proposer, user1);
        assertEq(description, "My Proposal");
        assertEq(requestedAmount, 0.01 ether);
    }

    function testVoteAndExecuteProposals() public {
        // User1 creates a proposal
        vm.startPrank(user1);
        proposalPlatform.createProposal("Test Proposal 1", 1 ether);
        vm.stopPrank();

        // User2 creates another proposal
        vm.startPrank(user2);
        proposalPlatform.createProposal("Test Proposal 2", 2 ether);
        vm.stopPrank();

        // Both users vote for their own proposals
        vm.startPrank(user1);
        proposalPlatform.vote(0, 0);
        vm.stopPrank();

        vm.startPrank(user2);
        proposalPlatform.vote(1, 1);
        vm.stopPrank();

        // Move forward in time to pass the execution interval
        vm.warp(block.timestamp + 60 days + 1);

        uint256 initialBalanceUser1 = user1.balance;
        uint256 initialBalanceUser2 = user2.balance;

        // Execute proposals
        proposalPlatform.executeProposals();

        // Check if proposals are executed and funds are transferred
        (uint256 id1, , , , , , , bool executed1) = proposalPlatform.proposals(
            0
        );
        (uint256 id2, , , , , , , bool executed2) = proposalPlatform.proposals(
            1
        );

        assertEq(id1, 0);
        assertEq(id2, 1);
        assertTrue(executed1);
        assertTrue(executed2);

        assertApproxEqRel(user1.balance, initialBalanceUser1 + 1 ether, 1e16);
        assertApproxEqRel(user2.balance, initialBalanceUser2 + 2 ether, 1e16);
    }
}
