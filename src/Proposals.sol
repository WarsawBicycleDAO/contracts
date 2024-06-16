// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IWarsawBikeNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProposalPlatform is Ownable {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 requestedAmount;
        mapping(address => bool) hasVoted;
        uint256 totalVotes;
        bool executed;
    }

    uint256 public proposalCount;
    IERC721 public nftContract;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public whitelist;
    uint256 public lastExecutionTime;
    uint256 public executionInterval = 60 days;

    event ProposalCreated(
        uint256 id,
        address proposer,
        string description,
        uint256 requestedAmount
    );
    event Voted(uint256 proposalId, address voter);
    event ProposalExecuted(uint256 id);
    event ProposalDeclined(uint256 id);

    constructor(address _nftContract) Ownable(msg.sender) {
        nftContract = IERC721(_nftContract);
        lastExecutionTime = block.timestamp;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not whitelisted to create proposals");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(
            proposals[proposalId].id == proposalId,
            "Proposal does not exist"
        );
        _;
    }

    function addWhitelist(address user) external onlyOwner {
        whitelist[user] = true;
    }

    function removeWhitelist(address user) external onlyOwner {
        whitelist[user] = false;
    }

    function createProposal(
        string memory description,
        uint256 requestedAmount
    ) external onlyWhitelisted {
        uint256 proposalId = proposalCount++;
        uint256 remainingTime = lastExecutionTime +
            executionInterval -
            block.timestamp;

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + remainingTime;
        proposal.requestedAmount = requestedAmount;
        proposal.executed = false;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            description,
            requestedAmount
        );
    }

    function vote(
        uint256 proposalId,
        uint256 nftId
    ) external proposalExists(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(
            block.timestamp >= proposal.startTime,
            "Voting has not started yet"
        );
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "You have already voted");
        require(
            nftContract.ownerOf(nftId) == msg.sender,
            "You do not own this NFT"
        );

        proposal.totalVotes += 1;
        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender);
    }

    function executeProposals() external {
        require(
            block.timestamp >= lastExecutionTime + executionInterval,
            "Execution interval has not passed"
        );

        uint256 highestVotes = 0;
        uint256 secondHighestVotes = 0;
        uint256 highestProposalId;
        uint256 secondHighestProposalId;

        for (uint256 i = 0; i < proposalCount; i++) {
            Proposal storage proposal = proposals[i];
            if (!proposal.executed && proposal.totalVotes > highestVotes) {
                secondHighestVotes = highestVotes;
                secondHighestProposalId = highestProposalId;

                highestVotes = proposal.totalVotes;
                highestProposalId = proposal.id;
            } else if (
                !proposal.executed && proposal.totalVotes > secondHighestVotes
            ) {
                secondHighestVotes = proposal.totalVotes;
                secondHighestProposalId = proposal.id;
            }
        }

        if (highestVotes > 0) {
            Proposal storage highestProposal = proposals[highestProposalId];
            highestProposal.executed = true;
            (bool success, ) = highestProposal.proposer.call{
                value: highestProposal.requestedAmount
            }("");
            require(success, "Transfer failed");
            emit ProposalExecuted(highestProposalId);
        }

        if (secondHighestVotes > 0) {
            Proposal storage secondHighestProposal = proposals[
                secondHighestProposalId
            ];
            secondHighestProposal.executed = true;
            (bool success, ) = secondHighestProposal.proposer.call{
                value: secondHighestProposal.requestedAmount
            }("");
            require(success, "Transfer failed");
            emit ProposalExecuted(secondHighestProposalId);
        }

        // Decline all other proposals
        for (uint256 i = 0; i < proposalCount; i++) {
            Proposal storage proposal = proposals[i];
            if (!proposal.executed) {
                proposal.executed = true; // Mark as executed to avoid re-execution
                emit ProposalDeclined(proposal.id);
            }
        }

        lastExecutionTime = block.timestamp;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
