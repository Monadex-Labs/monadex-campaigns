// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { MonadexCampaignsTypes } from "../utils/MonadexCampaignsTypes.sol";

interface IMonadexCampaignsPool {
    function purchaseSaleTokens(address _receiver) external returns (uint256);

    function getPriceThreshold()
        external
        view
        returns (MonadexCampaignsTypes.PriceThreshold memory);

    function getStage() external view returns (MonadexCampaignsTypes.Stage);

    function getReserves() external view returns (uint256, uint256);
}
