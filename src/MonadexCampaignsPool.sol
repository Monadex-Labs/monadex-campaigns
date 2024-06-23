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
    uint256 private immutable i_endingTimestamp;
    uint256 private immutable i_vestingCliff;

    uint256 private s_reserveSaleToken;
    uint256 private s_reserveFundingToken;
    MonadexCampaignsTypes.PriceThreshold private s_priceThreshold;
    bool private s_isLocked;

    MonadexCampaignsTypes.Stage private s_stage;

    uint256 constant VESTING_INTERVAL = 1 weeks;
    uint256 private vestedAmount;

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

    constructor(MonadexCampaignsTypes.CreateCampaign memory _campaignParams) Ownable(msg.sender) {
        i_team = _campaignParams.team;
        i_saleToken = _campaignParams.saleToken;
        i_fundingToken = _campaignParams.fundingToken;
        i_fundingTokenVirtualAmount = _campaignParams.fundingTokenVirtualAmount;
        i_endingTimestamp = _campaignParams.endingTimestamp;
        i_vestingCliff = _campaignParams.vestingCliff;

        s_reserveSaleToken = _campaignParams.saleTokenAmount;
        s_reserveFundingToken = _campaignParams.fundingTokenVirtualAmount;
        s_priceThreshold = _campaignParams.priceThreshold;

        s_stage = hasCrossedStage1()
            ? MonadexCampaignsTypes.Stage.Stage2
            : MonadexCampaignsTypes.Stage.Stage1;
    }

    function purchaseSaleTokens(address _receiver)
        external
        beforeEnd
        globalLock
        returns (uint256)
    {
        uint256 fundingTokenAmount = IERC20(i_fundingToken).balanceOf(address(this))
            - s_reserveFundingToken - i_fundingTokenVirtualAmount;
        if (fundingTokenAmount == 0) revert MonadexCampaignsPool__ZeroAmount();

        uint256 saleTokensToPurchase;
        if (s_stage == MonadexCampaignsTypes.Stage.Stage1) {
            if (hasCrossedStage1()) {
                s_stage = MonadexCampaignsTypes.Stage.Stage2;
                saleTokensToPurchase = _purchaseTokensInStage2(fundingTokenAmount);
            } else {
                saleTokensToPurchase = _purchaseTokensInStage1(fundingTokenAmount);
            }
        } else {
            saleTokensToPurchase = _purchaseTokensInStage2(fundingTokenAmount);
        }
        if (saleTokensToPurchase == 0) revert MonadexCampaignsPool__ZeroAmount();

        _updateReserves(
            s_reserveSaleToken - saleTokensToPurchase, s_reserveFundingToken + fundingTokenAmount
        );
        IERC20(i_saleToken).safeTransfer(_receiver, saleTokensToPurchase);

        emit SaleTokensPurchased(saleTokensToPurchase, fundingTokenAmount, _receiver);

        return saleTokensToPurchase;
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

    function getPriceThreshold()
        external
        view
        returns (MonadexCampaignsTypes.PriceThreshold memory)
    {
        return s_priceThreshold;
    }

    function getEndingTimestamp() external view returns (uint256) {
        return i_endingTimestamp;
    }

    function getStage() external view returns (MonadexCampaignsTypes.Stage) {
        return s_stage;
    }

    function getReserves() external view returns (uint256, uint256) {
        return (s_reserveSaleToken, s_reserveFundingToken);
    }

    function hasCrossedStage1() public view returns (bool) {
        if (
            s_reserveSaleToken <= s_priceThreshold.saleTokenAmount
                && s_reserveFundingToken >= s_priceThreshold.fundingTokenAmount
        ) return true;
        return false;
    }

    function _purchaseTokensInStage1(uint256 _fundingTokenAmount) internal view returns (uint256) {
        return MonadexCampaignsLibrary.amountToPurchaseInStage1(
            s_reserveSaleToken, s_reserveFundingToken, _fundingTokenAmount
        );
    }

    function _purchaseTokensInStage2(uint256 _fundingTokenAmount) internal view returns (uint256) {
        return
            MonadexCampaignsLibrary.amountToPurchaseInStage2(_fundingTokenAmount, s_priceThreshold);
    }

    function _updateReserves(uint256 _saleTokenAmount, uint256 _fundingTokenAmount) internal {
        s_reserveSaleToken = _saleTokenAmount;
        s_reserveFundingToken = _fundingTokenAmount;

        emit PoolBalancesUpdated(_saleTokenAmount, _fundingTokenAmount);
    }
}
