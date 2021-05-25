// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICourt {
    function createDispute(uint256 _possibleRulings, bytes calldata _metadata)
        external returns (uint256);
    function submitEvidence(
        uint256 _disputeId,
        address _submitter,
        bytes calldata _evidence
    ) external;
    function closeEvidencePeriod(uint256 _disputeId) external;
    function rule(uint256 _disputeId) external returns (
        address subject,
        uint256 ruling
    );
    function getDisputeFees() external view returns (
        address recipient,
        IERC20 feeToken,
        uint256 feeAmount
    );
}
