// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./IArbitratorManifest.sol";

abstract contract ArbitratorManifestCore is IArbitratorManifest {
    mapping(address => mapping(address => bool)) public override isRepOf;
    mapping(uint256 => address) public override defendantOf;
    mapping(uint256 => address) public override challengerOf;

    function setPartiesOf(
        uint256 _disputeId,
        address _defendant,
        address _challenger
    )
        external override
    {
        require(msg.sender == _getSubjectOf(_disputeId), "ArbitratorManifest: not subject");
        defendantOf[_disputeId] = _defendant;
        challengerOf[_disputeId] = _challenger;
        emit PartiesSet(_disputeId, _defendant, _challenger);
    }

    function setRepStatus(address _rep, bool _isActive) external override {
        require(isRepOf[msg.sender][_rep] != _isActive, "ArbitratorManifest: already set");
        isRepOf[msg.sender][_rep] = _isActive;
        emit RepStateChanged(msg.sender, _rep, _isActive);
    }

    function canSubmitEvidenceFor(address _submitter, uint256 _disputeId)
        public view override returns (bool, address)
    {
        address defendant = defendantOf[_disputeId];
        if (defendant == _submitter || isRepOf[defendant][_submitter]) {
            return (true, defendant);
        }
        address challenger = challengerOf[_disputeId];
        if (challenger == _submitter || isRepOf[challenger][_submitter]) {
            return (true, challenger);
        }
        return (false, address(0));
    }

    function _getSubjectOf(uint256 _disputeId)
        internal view virtual returns (address subject);
}
