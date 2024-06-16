// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IWarsawBikeNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {console} from "forge-std/Test.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTAuction is Ownable {
    struct Auction {
        uint256 highestBid;
        address highestBidder;
        uint256 endBlock;
        bool active;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public lastAuctionTime;
    uint256 public auctionInterval = 1 days;
    IWarsawBikeNFT public nftContract;
    address public treasury;

    event AuctionCreated(uint256 tokenId, uint256 endBlock);
    event NewBid(uint256 tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 amount);

    constructor() Ownable(msg.sender) {}

    function setNFTContract(address _contract) external onlyOwner {
        nftContract = IWarsawBikeNFT(_contract);
    }

    function setTreasury(address _newTreasury) external onlyOwner {
        treasury = _newTreasury;
    }

    function createAuction() external {
        require(
            lastAuctionTime < block.timestamp - auctionInterval,
            "Not a time for new auction"
        );
        nftContract.safeMint(address(this), "");
        uint256 tokenId = nftContract.totalSupply();

        auctions[tokenId] = Auction({
            highestBid: 0,
            highestBidder: address(0),
            endBlock: block.number + auctionInterval,
            active: true
        });

        emit AuctionCreated(tokenId, auctions[tokenId].endBlock);
    }

    function bid(uint256 tokenId) external payable {
        Auction storage auction = auctions[tokenId];
        require(block.number < auction.endBlock, "Auction has ended");
        require(
            msg.value > auction.highestBid,
            "Bid must be higher than the current highest bid"
        );

        if (auction.highestBid > 0) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund the previous highest bid
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit NewBid(tokenId, msg.sender, msg.value);
    }

    function endAuction(uint256 tokenId) external {
        Auction storage auction = auctions[tokenId];
        require(block.number >= auction.endBlock, "Auction is still ongoing");
        require(auction.active, "Auction is already ended");

        auction.active = false;
        if (auction.highestBid > 0) {
            nftContract.transferFrom(
                address(this),
                auction.highestBidder,
                tokenId
            );
            payable(treasury).transfer(auction.highestBid);
            emit AuctionEnded(
                tokenId,
                auction.highestBidder,
                auction.highestBid
            );
        } else {
            nftContract.transferFrom(address(this), treasury, tokenId);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
