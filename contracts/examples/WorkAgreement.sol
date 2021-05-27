// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IArbitrator.sol";
import "../manifest/IArbitratorManifest.sol";
import "../Disputable.sol";

contract WorkAgreement is Disputable {
    using SafeERC20 for IERC20;

    bytes32 public immutable agreementCommitment;
    uint256 public immutable releaseAt;
    address public immutable employer;
    address public immutable contractor;

    bool public beingDisputed;
    uint256 public disputeId;

    constructor(
        IArbitrator _arbitrator,
        IArbitratorManifest _arbitratorManifest,
        bytes32 _agreementCommitment,
        uint256 _releaseAt,
        address _contractor
    )
        Disputable(_arbitrator, _arbitratorManifest) payable
    {
        agreementCommitment = _agreementCommitment;
        releaseAt = _releaseAt;
        employer = msg.sender;
        contractor = _contractor;
    }

    function releasePayment() external {
        require(msg.sender == contractor, "WorkAgreement: not contractor");
        require(!beingDisputed, "WorkAgreement: being disputed");
        require(block.timestamp >= releaseAt, "WorkAgreement: not yet unlocked");
        selfdestruct(payable(contractor));
    }

    function dispute(bytes32 _salt, bytes calldata _agreementMetadata) external {
        require(!beingDisputed, "WorkAgreement: already disputed");
        require(msg.sender == employer, "WorkAgreement: not employer");
        require(block.timestamp < releaseAt, "WorkAgreement: already unlocked");
        require(
            agreementCommitment == keccak256(abi.encode(_salt, _agreementMetadata)),
            "WorkAgreement: invalid agreement"
        );
        beingDisputed = true;
        (address recipient, IERC20 feeToken, uint256 feeAmount) = arbitrator.getDisputeFees();
        feeToken.safeTransferFrom(msg.sender, address(this), feeAmount);
        feeToken.safeApprove(recipient, feeAmount);
        disputeId = _createDisputeAgainst(contractor, employer, _agreementMetadata);
    }

    function settleDispute() external {
        require(beingDisputed, "WorkAgreement: Not being disputed");
        (, uint256 ruling) = arbitrator.rule(disputeId);
        /*
           benefit of the doubt is with the contractor, so if the ruling is
            refused by the court the contract releases the full payment to the
            contractor
        */
        selfdestruct(payable(ruling == RULING_AGAINST_ACTION ? employer : contractor));
    }
}
