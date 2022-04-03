// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../Disputable.sol";

contract SimpleDisputable is Disputable {
    constructor(address _arbitrator, address _arbitratorManifest) { 
        Disputable.initialize(_arbitrator, _arbitratorManifest);
    }

    function createDispute(bytes memory _metadata) external {
        _prepareAndPullDisputeFeeFrom(msg.sender);
        arbitrator.createDispute(2, _metadata);
    }

    function setPartiesOf(
        uint256 _disputeId,
        address _defendant,
        address _challenger
    )
        external
    {
        arbitratorManifest.setPartiesOf(_disputeId, _defendant, _challenger);
    }
}
