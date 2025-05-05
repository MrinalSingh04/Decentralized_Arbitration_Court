// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract DecentralizedArbitrationCourt {

    // Define a dispute
    struct Dispute {
        uint256 disputeID;
        address partyA;
        address partyB;
        uint256 evidenceA; // Simplified evidence storage, can be hashed data
        uint256 evidenceB;
        uint256 votesForA;
        uint256 votesForB;
        uint256 status; // 0 - ongoing, 1 - resolved
        address arbitrator;
        uint256 arbitratorFee;
    }

    // Track stakers and their tokens
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public rewards;
    
    // Track disputes
    mapping(uint256 => Dispute) public disputes;
    uint256 public disputeCount;
    
    // Event logs
    event DisputeCreated(uint256 disputeID, address indexed partyA, address indexed partyB);
    event Voted(uint256 disputeID, address indexed voter, bool voteForA);
    event DisputeResolved(uint256 disputeID, address indexed winner);

    // Modifier to ensure that only stakers can participate in voting
    modifier onlyStaker() {
        require(stakes[msg.sender] > 0, "You must stake tokens to participate.");
        _;
    }

    // Function to create a dispute
    function createDispute(address _partyB, uint256 _evidenceA, uint256 _evidenceB) public {
        disputeCount++;
        disputes[disputeCount] = Dispute({
            disputeID: disputeCount,
            partyA: msg.sender,
            partyB: _partyB,
            evidenceA: _evidenceA,
            evidenceB: _evidenceB,
            votesForA: 0,
            votesForB: 0,
            status: 0,
            arbitrator: address(0),
            arbitratorFee: 0
        });
        
        emit DisputeCreated(disputeCount, msg.sender, _partyB);
    }

    // Function to stake tokens to participate in voting
    function stakeTokens(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        stakes[msg.sender] += amount;
    }

    // Function to vote on a dispute
    function vote(uint256 disputeID, bool voteForA) public onlyStaker {
        Dispute storage dispute = disputes[disputeID];
        require(dispute.status == 0, "Dispute already resolved");
        
        if (voteForA) {
            dispute.votesForA++;
        } else {
            dispute.votesForB++;
        }

        emit Voted(disputeID, msg.sender, voteForA);
    }

    // Function to resolve the dispute
    function resolveDispute(uint256 disputeID, address _arbitrator) public {
        Dispute storage dispute = disputes[disputeID];
        require(dispute.status == 0, "Dispute already resolved");
        require(msg.sender == _arbitrator, "Only the arbitrator can resolve the dispute");

        // Determine winner based on vote counts
        address winner;
        if (dispute.votesForA > dispute.votesForB) {
            winner = dispute.partyA;
        } else {
            winner = dispute.partyB;
        }

        // Transfer rewards (simplified, actual transfer would depend on application)
        rewards[winner] += stakes[dispute.partyA] + stakes[dispute.partyB];

        // Finalize the dispute
        dispute.status = 1;
        dispute.arbitrator = _arbitrator;
        
        emit DisputeResolved(disputeID, winner);
    }

    // Function to withdraw staked tokens (once the dispute is resolved)
    function withdrawTokens() public {
        uint256 stakeAmount = stakes[msg.sender];
        require(stakeAmount > 0, "No staked tokens to withdraw");
        
        stakes[msg.sender] = 0;
        payable(msg.sender).transfer(stakeAmount);
    }

    // Function to withdraw rewards
    function withdrawRewards() public {
        uint256 rewardAmount = rewards[msg.sender];
        require(rewardAmount > 0, "No rewards to withdraw");

        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(rewardAmount);
    }
    
    // Function to fund the contract with ETH for rewards and arbitration fees
    function fundContract() public payable {}

    // Helper function to check the contract balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
