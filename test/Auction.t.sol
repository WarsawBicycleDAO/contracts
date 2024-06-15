// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NFTAuction} from "../src/NFTAuction.sol";
import {WarsawBikeNFT} from "../src/WarsawBikeNFT.sol";

contract AuctionTest is Test {
    NFTAuction public auction;
    WarsawBikeNFT public nftContract;

    function setUp() public {
        vm.createSelectFork(vm.envString("RPC_ENDPOINT"), 34151260);
        auction = new NFTAuction();
        nftContract = new WarsawBikeNFT(address(auction));
        auction.setNFTContract(address(nftContract));
    }

    function test_createAuction() public {
        auction.createAuction();

        assertEq(nftContract.totalSupply(), 1);
    }

    function test_bid() public {
        auction.createAuction();

        uint tokenId = nftContract.totalSupply();
        uint value = 0.5 ether;

        address user = vm.addr(1);
        vm.deal(user, 1 ether);
        vm.prank(user);

        auction.bid{value: value}(tokenId);
        (uint highestBid, address bidder, , ) = auction.auctions(tokenId);
        assertEq(highestBid, value);
        assertEq(bidder, user);
    }
}
