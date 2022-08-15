// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";

error alreadyMember();
error notEnoughFee(uint256);
error notMember();
error alreadyExist();
error notDelegated();
error alreadyVoted();

contract DAO is Ownable {
    uint256 public ProposalCount;
    uint256 public MemberCount;
    uint public proposalTimeout;
    struct Propasal {
        address payable to;
        uint256 amount;
        uint256 voteCount;
        bool executed;
        bool canceled;
        uint dueTimestamp;
    }
    mapping(uint256 => Propasal) Proposals;
    mapping(address => bool) private Members;
    mapping(uint256 => mapping(address => bool)) Votes;
    uint public immutable entranceFee;

    constructor(uint _entranceFee, uint timeout) payable {
        ProposalCount = 0;
        MemberCount = 0;
        entranceFee = _entranceFee * (1 ether);
        proposalTimeout = timeout;
    }

    event newProposal(
        address indexed to,
        uint256 indexed value,
        string indexed description
    );
    event newMember(address indexed member_address);
    event voteCast(address indexed voter, uint256 proposalId);
    event proposalExecuted(
        address indexed to,
        uint256 indexed value,
        uint256 indexed proposalId
    );

    function propasalThreshold() public view returns (uint256) {
        return MemberCount / uint256(2);
    }

    function isMember(address _address) public view returns (bool) {
        return Members[_address];
    }

    function checkin() public payable {
        if (msg.value >= entranceFee) {
            if (Members[msg.sender]) {
                revert alreadyMember();
            } else {
                Members[msg.sender] = true;
                emit newMember(msg.sender);
                MemberCount += 1;
            }
        } else {
            revert notEnoughFee(msg.value);
        }
    }

    //create new proposal
    function submitProposal(
        address to,
        uint256 value,
        string memory description
    ) public returns (uint256) {
        if (!Members[msg.sender]) revert notMember();

        uint256 proposalId = hashProposal(to, value, description);
        Propasal storage proposal = Proposals[proposalId];
        if (proposal.dueTimestamp != 0) revert alreadyExist();
        proposal.to = payable(to);
        proposal.amount = value;
        proposal.dueTimestamp = block.timestamp + proposalTimeout;
        ProposalCount += 1;
        emit newProposal(to, value, description);
        return proposalId;
    }

    //execute approved proposal
    function execute(uint256 proposalId) private {
        Propasal storage proposal = Proposals[proposalId];
        proposal.executed = true;

        (bool success, ) = (proposal.to).call{
            value: proposal.amount * (1 ether)
        }("");
        require(success);

        emit proposalExecuted(proposal.to, proposal.amount, proposalId);
    }

    function isActive(uint256 proposalId) public view returns (bool) {
        Propasal storage proposal = Proposals[proposalId];
        if (
            proposal.dueTimestamp <= block.timestamp ||
            proposal.executed ||
            proposal.canceled
        ) return false;
        else return true;
    }

    function castVote(uint256 proposalId, string memory declaration) public {
        Propasal storage proposal = Proposals[proposalId];
        if (isActive(proposalId)) {
            if (!Votes[proposalId][msg.sender]) {
                if (
                    keccak256(abi.encodePacked((declaration))) ==
                    keccak256(abi.encodePacked(("Approve")))
                ) {
                    Votes[proposalId][msg.sender] = true;
                    proposal.voteCount += 1;
                    emit voteCast(msg.sender, proposalId);
                    if (proposal.voteCount > propasalThreshold()) {
                        execute(proposalId);
                    }
                } else {
                    revert notDelegated();
                }
            } else {
                revert alreadyVoted();
            }
        }
    }

    function hashProposal(
        address to,
        uint256 value,
        string memory description
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(to, value, description)));
    }
}
