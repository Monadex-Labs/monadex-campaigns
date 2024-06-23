// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract MonadexCampaignsTypes {
    struct CreateCampaign {
        address team;
        address saleTokenSupplier;
        address saleToken;
        address fundingToken;
        uint256 saleTokenAmount;
        uint256 fundingTokenVirtualAmount;
        PriceThreshold priceThreshold;
        uint256 endingTimestamp;
        uint256 vestingCliff;
    }

    struct PriceThreshold {
        uint256 saleTokenAmount;
        uint256 fundingTokenAmount;
    }

    enum Stage {
        Stage1,
        Stage2
    }

    struct Fee {
        uint256 numerator;
        uint256 denominator;
    }
}
