// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

interface ICourtManifest {
    event PartiesSet(
        uint256 indexed disputeId,
        address indexed defendant,
        address indexed challenger
    );
    event RepStateChanged(
        address indexed account,
        address indexed rep,
        bool isActive
    );

    function setPartiesOf(
        uint256 _disputeId,
        address _defendant,
        address _challenger
    ) external;
    function setRepStatus(
        address _rep,
        bool _isActive
    ) external;
    function isRepOf(address _account, address _rep) external view returns (bool isRep);
    function defendantOf(uint256 _disputeId) external view returns (address defendant);
    function challengerOf(uint256 _disputeId) external view returns (address challenger);
    function canSubmitEvidenceFor(address _submitter, uint256 _disputeId)
        external view returns (bool canSubmit, address submittingFor);
}
