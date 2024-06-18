// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { MonadexCampaignsTypes } from "../utils/MonadexCampaignsTypes.sol";

interface IMonadexCampaignsPool {
    function getStage() external view returns (MonadexCampaignsTypes.Stage);
}
