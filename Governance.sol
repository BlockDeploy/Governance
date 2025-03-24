// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Governance {
    // Structure to store proposal information
    struct Proposal {
        address proposer;           // Creator of the proposal
        string description;         // Description of the proposal (e.g., "Allocate 10 ETH")
        uint voteCount;             // Total number of votes
        uint deadline;              // Voting deadline (in seconds since Unix epoch)
        bool executed;              // Whether the proposal has been executed
        mapping(address => bool) hasVoted; // Who has already voted
    }

    // Mapping of proposals by their ID
    mapping(uint => Proposal) public proposals;
    uint public proposalCount;      // Proposal counter
    mapping(address => uint) public votes; // Total votes of each participant (for statistics)

    // Events to track actions
    event ProposalCreated(uint indexed proposalId, address proposer, string description, uint deadline);
    event Voted(uint indexed proposalId, address voter, uint voteCount);
    event ProposalExecuted(uint indexed proposalId);

    // Modifiers
    modifier validProposal(uint proposalId) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        _;
    }

    modifier votingActive(uint proposalId) {
        require(block.timestamp <= proposals[proposalId].deadline, "Voting period has ended");
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }

    // Create a new proposal
    function createProposal(string memory _description, uint _votingDuration) external {
        uint proposalId = proposalCount;
        Proposal storage newProposal = proposals[proposalId];
        
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.voteCount = 0;
        newProposal.deadline = block.timestamp + _votingDuration; // E.g., 7 days = 604800 seconds
        newProposal.executed = false;

        proposalCount += 1;
        emit ProposalCreated(proposalId, msg.sender, _description, newProposal.deadline);
    }

    // Vote for a proposal
    function vote(uint proposalId) external validProposal(proposalId) votingActive(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "You have already voted");

        proposal.hasVoted[msg.sender] = true;
        proposal.voteCount += 1;
        votes[msg.sender] += 1; // Increase the participant's total vote count

        emit Voted(proposalId, msg.sender, proposal.voteCount);
    }

    // Execute a proposal (e.g., after reaching a vote threshold)
    function executeProposal(uint proposalId) external validProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.deadline, "Voting period is still active");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCount > 0, "No votes received"); // Minimal check

        proposal.executed = true;
        // Add execution logic here, e.g., sending funds or calling another contract
        emit ProposalExecuted(proposalId);
    }

    // Get proposal information
    function getProposal(uint proposalId) external view validProposal(proposalId) 
        returns (address proposer, string memory description, uint voteCount, uint deadline, bool executed) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.proposer, proposal.description, proposal.voteCount, proposal.deadline, proposal.executed);
    }

    // Check if an address has voted for a proposal
    function hasVoted(uint proposalId, address voter) external view validProposal(proposalId) returns (bool) {
        return proposals[proposalId].hasVoted[voter];
    }

    // Get the total number of votes of a participant
    function getVoterVotes(address voter) external view returns (uint) {
        return votes[voter];
    }
}