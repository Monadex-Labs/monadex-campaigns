// Layout:
//     - pragma
//     - imports
//     - interfaces, libraries, contracts
//     - type declarations
//     - state variables
//     - events
//     - errors
//     - modifiers
//     - functions
//         - constructor
//         - receive function (if exists)
//         - fallback function (if exists)
//         - external
//         - public
//         - internal
//         - private

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IMonadexCampaignsPool } from "./interfaces/IMonadexCampaignsPool.sol";

import { MonadexCampaignsLibrary } from "./utils/MonadexCampaignsLibrary.sol";
import { MonadexCampaignsTypes } from "./utils/MonadexCampaignsTypes.sol";

contract MonadexCampaignsPool is Ownable, IMonadexCampaignsPool {
    using SafeERC20 for IERC20;

    address private immutable i_team;
    address private immutable i_saleToken;
    address private immutable i_fundingToken;
    uint256 private immutable i_fundingTokenVirtualAmount;
    uint256 private immutable i_priceThreshold;
    uint256 private immutable i_endingTimestamp;

    uint256 private s_reserveSaleToken;
    uint256 private s_reserveFundingToken;
    bool private s_isLocked;

    MonadexCampaignsTypes.Stage private s_stage;

    event SaleTokensPurchased(
        uint256 indexed saleTokenAmount,
        uint256 indexed fundingTokenAmount,
        address indexed receiver
    );
    event PoolBalancesUpdated(
        uint256 indexed saleTokenReserves, uint256 indexed fundingTokenReserves
    );

    error MonadexCampaignsPool__Locked();
    error MonadexCampaignsPool__CampaignEnded();
    error MonadexCampaignsPool__ZeroAmount();

    modifier globalLock() {
        if (s_isLocked) revert MonadexCampaignsPool__Locked();
        s_isLocked = true;
        _;
        s_isLocked = false;
    }

    modifier beforeEnd() {
        if (block.timestamp > i_endingTimestamp) revert MonadexCampaignsPool__CampaignEnded();
        _;
    }

    constructor(
        MonadexCampaignsTypes.CreateCampaign memory _campaignParams,
        address _owner
    )
        Ownable(_owner)
    {
        i_team = _campaignParams.team;
        i_saleToken = _campaignParams.saleToken;
        i_fundingToken = _campaignParams.fundingToken;
        i_fundingTokenVirtualAmount = _campaignParams.fundingTokenVirtualAmount;
        i_priceThreshold = _campaignParams.priceThreshold;
        i_endingTimestamp = _campaignParams.endingTimestamp;

        s_reserveSaleToken = _campaignParams.saleTokenAmount;
        s_reserveFundingToken = _campaignParams.fundingTokenVirtualAmount;

        s_stage = MonadexCampaignsTypes.Stage.Stage1;
    }

    function purchaseSaleTokens(address _receiver) external beforeEnd globalLock {
        uint256 fundingTokenAmount = IERC20(i_fundingToken).balanceOf(address(this))
            - s_reserveFundingToken - i_fundingTokenVirtualAmount;
        if (fundingTokenAmount == 0) revert MonadexCampaignsPool__ZeroAmount();

        if (s_stage == MonadexCampaignsTypes.Stage.Stage1) {
            _purchaseTokensInStage1(fundingTokenAmount);
        } else {
            _purchaseTokensInStage2(fundingTokenAmount);
        }
    }

    function syncBalancesWithReserves(address _receiver) external onlyOwner globalLock {
        IERC20(i_saleToken).safeTransfer(
            _receiver, IERC20(i_saleToken).balanceOf(address(this)) - s_reserveSaleToken
        );
        IERC20(i_fundingToken).safeTransfer(
            _receiver,
            IERC20(i_fundingToken).balanceOf(address(this)) - s_reserveFundingToken
                - i_fundingTokenVirtualAmount
        );
    }

    function getTeam() external view returns (address) {
        return i_team;
    }

    function getPoolTokens() external view returns (address, address) {
        return (i_saleToken, i_fundingToken);
    }

    function getFundingTokenVirtualAmount() external view returns (uint256) {
        return i_fundingTokenVirtualAmount;
    }

    function getPriceThreshold() external view returns (uint256) {
        return i_priceThreshold;
    }

    function getDuration() external view returns (uint256) {
        return i_endingTimestamp;
    }

    function getStage() external view returns (MonadexCampaignsTypes.Stage) {
        return s_stage;
    }

    function _purchaseTokensInStage1(uint256 _fundingTokenAmount, address _receiver) internal {
        uint256 saleTokensToPurchase = MonadexCampaignsLibrary.amountToPurchaseInStage1(
            s_reserveSaleToken, s_reserveFundingToken, _fundingTokenAmount
        );
        _updateReserves(
            s_reserveSaleToken - saleTokensToPurchase, s_reserveFundingToken + _fundingTokenAmount
        );

        IERC20(i_saleToken).safeTransfer(_receiver, saleTokensToPurchase);

        emit SaleTokensPurchased(saleTokensToPurchase, _fundingTokenAmount, _receiver);
    }

    function _purchaseTokensInStage2(uint256 _fundingTokenAmount) internal { }

    function _updateReserves(uint256 _saleTokenAmount, uint256 _fundingTokenAmount) internal {
        s_reserveSaleToken = _saleTokenAmount;
        s_reserveFundingToken = _fundingTokenAmount;

        emit PoolBalancesUpdated(_saleTokenAmount, _fundingTokenAmount);
    }
}
