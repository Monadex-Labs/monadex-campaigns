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

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { IMonadexCampaignsFactory } from "./interfaces/IMonadexCampaignsFactory.sol";
import { IMonadexCampaignsPool } from "./interfaces/IMonadexCampaignsPool.sol";

import { MonadexCampaignsLibrary } from "./utils/MonadexCampaignsLibrary.sol";
import { MonadexCampaignsTypes } from "./utils/MonadexCampaignsTypes.sol";

contract MonadexCampaignsRouter {
    using SafeERC20 for IERC20;

    address private immutable i_factory;

    error MonadexCampaignsRouter__DeadlinePassed();
    error MonadexCampaignsRouter__CampaignDoesNotExist();
    error MonadexCampaignsRouter__CampaignInStage2();
    error MonadexCampaignsRouter__AmountZero();
    error MonadexCampaignsRouter__InsufficientSaleTokenAmount();
    error MonadexCampaignsRouter__InsufficientFundingTokenAmount();
    error MonadexCampaignsRouter__CampaignInStage1();

    modifier notZero(uint256 _amount) {
        if (_amount == 0) revert MonadexCampaignsRouter__AmountZero();
        _;
    }

    modifier beforeDeadline(uint256 _deadline) {
        if (block.timestamp > _deadline) revert MonadexCampaignsRouter__DeadlinePassed();
        _;
    }

    constructor(address _factory) {
        i_factory = _factory;
    }

    function purchaseExactSaleTokensForFundingTokensInStage1(
        address _saleToken,
        address _fundingToken,
        uint256 _saleTokenAmount,
        uint256 _maxFundingTokenAmount,
        address _receiver,
        uint256 _deadline
    )
        external
        notZero(_saleTokenAmount)
        notZero(_maxFundingTokenAmount)
        beforeDeadline(_deadline)
        returns (uint256, uint256)
    {
        address pool = _validate(_saleToken, _fundingToken, MonadexCampaignsTypes.Stage.Stage1);

        uint256 fundingTokensToSend = MonadexCampaignsLibrary
            .getFundingTokenAmountforSaleTokenAmountInStage1(pool, _saleTokenAmount);
        if (fundingTokensToSend > _maxFundingTokenAmount) {
            revert MonadexCampaignsRouter__InsufficientFundingTokenAmount();
        }
        IERC20(_fundingToken).safeTransferFrom(msg.sender, pool, fundingTokensToSend);
        uint256 saleTokensPurchased = IMonadexCampaignsPool(pool).purchaseSaleTokens(_receiver);

        return (saleTokensPurchased, fundingTokensToSend);
    }

    function purchaseSaleTokensForExactFundingTokensInStage1(
        address _saleToken,
        address _fundingToken,
        uint256 _fundingTokenAmount,
        uint256 _minSaleTokenAmount,
        address _receiver,
        uint256 _deadline
    )
        external
        notZero(_fundingTokenAmount)
        notZero(_minSaleTokenAmount)
        beforeDeadline(_deadline)
        returns (uint256, uint256)
    {
        address pool = _validate(_saleToken, _fundingToken, MonadexCampaignsTypes.Stage.Stage1);

        IERC20(_fundingToken).safeTransferFrom(msg.sender, pool, _fundingTokenAmount);
        uint256 saleTokensPurchased = IMonadexCampaignsPool(pool).purchaseSaleTokens(_receiver);
        if (saleTokensPurchased < _minSaleTokenAmount) {
            revert MonadexCampaignsRouter__InsufficientSaleTokenAmount();
        }

        return (saleTokensPurchased, _fundingTokenAmount);
    }

    function purchaseExactSaleTokensForFundingTokensInStage2(
        address _saleToken,
        address _fundingToken,
        uint256 _saleTokenAmount,
        address _receiver,
        uint256 _deadline
    )
        external
        notZero(_saleTokenAmount)
        beforeDeadline(_deadline)
        returns (uint256, uint256)
    {
        address pool = _validate(_saleToken, _fundingToken, MonadexCampaignsTypes.Stage.Stage2);

        uint256 fundingTokensToSend = MonadexCampaignsLibrary
            .getFundingTokenAmountforSaleTokenAmountInStage2(pool, _saleTokenAmount);
        IERC20(_fundingToken).safeTransferFrom(msg.sender, pool, fundingTokensToSend);
        uint256 saleTokensPurchased = IMonadexCampaignsPool(pool).purchaseSaleTokens(_receiver);

        return (saleTokensPurchased, fundingTokensToSend);
    }

    function purchaseSaleTokensForExactFundingTokensInStage2(
        address _saleToken,
        address _fundingToken,
        uint256 _fundingTokenAmount,
        address _receiver,
        uint256 _deadline
    )
        external
        notZero(_fundingTokenAmount)
        beforeDeadline(_deadline)
        returns (uint256, uint256)
    {
        address pool = _validate(_saleToken, _fundingToken, MonadexCampaignsTypes.Stage.Stage2);

        IERC20(_fundingToken).safeTransferFrom(msg.sender, pool, _fundingTokenAmount);
        uint256 saleTokensPurchased = IMonadexCampaignsPool(pool).purchaseSaleTokens(_receiver);

        return (saleTokensPurchased, _fundingTokenAmount);
    }

    function _validatePool(
        address _saleToken,
        address _fundingToken
    )
        internal
        view
        returns (address)
    {
        address pool = IMonadexCampaignsFactory(i_factory).getPool(_saleToken, _fundingToken);
        if (pool == address(0)) revert MonadexCampaignsRouter__CampaignDoesNotExist();

        return pool;
    }

    function _validateStage(address _pool, MonadexCampaignsTypes.Stage _stage) internal view {
        MonadexCampaignsTypes.Stage stage = IMonadexCampaignsPool(_pool).getStage();
        if (stage != _stage) {
            if (_stage == MonadexCampaignsTypes.Stage.Stage1) {
                revert MonadexCampaignsRouter__CampaignInStage2();
            } else {
                revert MonadexCampaignsRouter__CampaignInStage1();
            }
        }
    }

    function _validate(
        address _saleToken,
        address _fundingToken,
        MonadexCampaignsTypes.Stage _stage
    )
        internal
        view
        returns (address)
    {
        address pool = _validatePool(_saleToken, _fundingToken);
        _validateStage(pool, _stage);

        return pool;
    }
}
