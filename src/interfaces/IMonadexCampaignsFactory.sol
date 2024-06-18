// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { MonadexCampaignsTypes } from "../utils/MonadexCampaignsTypes.sol";

interface IMonadexCampaignsFactory {
    function createCampaign(MonadexCampaignsTypes.CreateCampaign calldata _campaignParams)
        external
        returns (address);

    function getPool(address _saleToken, address _fundingToken) external view returns (address);

    function getTeam(address _pool) external view returns (address);
}
