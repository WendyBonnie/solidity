// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);
    uint256 nonce;

    mapping(address => Voter) public voter;
    Proposal[] public proposals;
    WorkflowStatus choice;
    WorkflowStatus constant defaultChoice = WorkflowStatus.RegisteringVoters;

    function startRegistration() external onlyOwner {
        choice = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function endRegistration() external onlyOwner {
        choice = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function VotingStart() external onlyOwner {
        choice = WorkflowStatus.VotingSessionStarted;
    }

    function VotingEnd() external onlyOwner {
        choice = WorkflowStatus.VotingSessionEnded;
    }

    function whitelisted(address _address) external onlyOwner {
        require(
            voter[_address].isRegistered == false,
            "This address is already whitelisted !"
        );
        voter[_address].isRegistered = true;
        emit VoterRegistered(_address);
    }

    function postProposal(string memory _description) external {
        nonce++;
        require(
            choice == WorkflowStatus.ProposalsRegistrationStarted,
            "The registration is not open"
        );
        require(
            choice != WorkflowStatus.ProposalsRegistrationEnded,
            "The registration is closed"
        );
        require(
            voter[msg.sender].isRegistered == true,
            "You are not allowed to write a proposition"
        );
        uint256 proposalId = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))
        ) % 100;

        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(proposalId);
    }

    function getProposal() public view returns (string memory) {
        require(
            choice != WorkflowStatus.ProposalsRegistrationStarted,
            "The registration is not open"
        );
        require(
            choice != WorkflowStatus.ProposalsRegistrationEnded,
            "The registration is closed"
        );
        if (proposals.length < 0) {
            return "il n'y a pas de proposition";
        } else {
            return "coucou";
        }
    }

    function putMyVote(uint256 _id) external {
        require(
            choice == WorkflowStatus.VotingSessionStarted,
            "The voting session has not starting yet"
        );
        require(
            choice != WorkflowStatus.VotingSessionEnded,
            "The voting session is done"
        );
        require(proposals.length > 0, "il n'y a pas de propositions");
        require(
            voter[msg.sender].isRegistered == true,
            "You are not allowed to vote!"
        );
        require(voter[msg.sender].hasVoted == false, "You already have voted!");

        voter[msg.sender].hasVoted = true;
        voter[msg.sender].votedProposalId = _id;
        proposals[_id].voteCount++;
        emit Voted(msg.sender, _id);
    }

    function getWinner() external onlyOwner returns (string memory) {
        choice = WorkflowStatus.VotesTallied;
        uint256 winnerIndex = 0;
        uint256 maxVote = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVote) {
                maxVote = proposals[i].voteCount;
                winnerIndex = i;
            }
        }

        return proposals[winnerIndex].description;
    }
}
