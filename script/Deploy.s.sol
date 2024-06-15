// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "src/NFTAuction.sol";
import "src/Proposals.sol";
import "src/WarsawBikeNFT.sol";

contract DeployScript is Script {
    NFTAuction public auction;
    WarsawBikeNFT public nftContract;
    ProposalDAO public proposals;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        auction = new NFTAuction();
        nftContract = new WarsawBikeNFT(address(auction));
        auction.setNFTContract(address(nftContract));
        proposals = new ProposalDAO(address(nftContract), 1 days);

        console.log("Auction address: ", address(auction));
        console.log("NFT contract address: ", address(nftContract));
        console.log("Proposals address: ", address(proposals));

        vm.stopBroadcast();
    }
}
