// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract MonadexCampaignsTypes {
    struct CreateCampaign {
        address team;
        address saleToken;
        address fundingToken;
        uint256 saleTokenAmount;
        uint256 fundingTokenVirtualAmount;
        uint256 priceThreshold;
        uint256 endingTimestamp;
    }

    enum Stage {
        Stage1,
        Stage2
    }
}
