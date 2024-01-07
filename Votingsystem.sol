// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

contract Voter {

    struct Party {
        string name;
        int votecount;
    }

    struct VoterInfo {
        bool isEligible;
        string votedto;
        bool voted;
    }

    address electionhead;
    mapping(address => VoterInfo) public voters;
    bool public votingInProgress;
    Party[] public parties;
    string public winningParty;

    event ElectionStarted();
    event ElectionStopped();
    event PartyVoted(address indexed voter, string partyName);
    event PartyAdded(string partyName);

    modifier onlyelectionhead() {
        require(msg.sender == electionhead, "Not ElectionHead");
        _;
    }

    modifier onlyEligible() {
        require(voters[msg.sender].isEligible, "Not eligible to vote");
        _;
    }

    constructor(string[] memory partyNames) {
        electionhead = msg.sender;
        for (uint256 i = 0; i < partyNames.length; i++) {
            parties.push(Party({name: partyNames[i], votecount: 0}));
        }
    }

    function startElection() public onlyelectionhead {
        votingInProgress = true;
        emit ElectionStarted();
    }

    function stopElection() public onlyelectionhead {
        votingInProgress = false;
        resultofvoting();
        emit ElectionStopped();
    }

    function voteparty(uint partyNo) public onlyEligible {
        VoterInfo storage vote = voters[msg.sender];
        require(votingInProgress, "Voting not started");
        require(!vote.voted, "Already voted");
        vote.voted = true;
        vote.votedto = parties[partyNo].name;
        parties[partyNo].votecount++;
        emit PartyVoted(msg.sender, parties[partyNo].name);
    }

    function registeryourself(address person) public {
        require(!voters[person].isEligible, "Already registered");
        voters[person].isEligible = true;
        voters[person].voted = false;
    }

    function addParty(string memory partyName) public onlyelectionhead {
        parties.push(Party({name: partyName, votecount: 0}));
        emit PartyAdded(partyName);
    }

    function resultofvoting() internal {
        int voteCount = 0;
        for (uint256 i = 0; i < parties.length; i++) {
            if (parties[i].votecount > voteCount) {
                voteCount = parties[i].votecount;
                winningParty = parties[i].name;
            }
        }
    }
}
