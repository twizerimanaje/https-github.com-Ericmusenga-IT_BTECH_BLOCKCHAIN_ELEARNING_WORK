// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract DAOGovernance {
    struct Proposal {
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
        bool executed;
    }

    IERC20 public governanceToken;
    uint256 public quorumPercentage;
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    event ProposalCreated(uint256 proposalId, string description, uint256 deadline);
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 proposalId, bool passed);
    
    constructor(address _token, uint256 _quorumPercentage) {
        governanceToken = IERC20(_token);
        quorumPercentage = _quorumPercentage;
    }
    
    function createProposal(string memory _description, uint256 _duration) external {
        proposals.push(Proposal({
            description: _description,
            yesVotes: 0,
            noVotes: 0,
            deadline: block.timestamp + _duration,
            executed: false
        }));
        emit ProposalCreated(proposals.length - 1, _description, block.timestamp + _duration);
    }
    
    function vote(uint256 _proposalId, bool _support) external {
        require(_proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline, "Voting period ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");
        
        uint256 voterWeight = governanceToken.balanceOf(msg.sender);
        require(voterWeight > 0, "No voting power");
        
        if (_support) {
            proposal.yesVotes += voterWeight;
        } else {
            proposal.noVotes += voterWeight;
        }
        hasVoted[_proposalId][msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _support, voterWeight);
    }
    
    function executeProposal(uint256 _proposalId) external {
        require(_proposalId < proposals.length, "Invalid proposal");
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.deadline, "Voting still ongoing");
        require(!proposal.executed, "Proposal already executed");
        
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 totalSupply = governanceToken.balanceOf(address(this));
        require(totalVotes * 100 / totalSupply >= quorumPercentage, "Quorum not reached");
        
        bool passed = proposal.yesVotes > proposal.noVotes;
        proposal.executed = true;
        emit ProposalExecuted(_proposalId, passed);
    }
}
