// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

/// @title DollarAuction
/// @title Miguel Piedrafita
/// @notice A dollar auction for 1 ETH in Solidity
contract DollarAuction is ReentrancyGuard {
    ///////////////////////////////////////////////////////////////////////////////
    ///                                  ERRORS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when trying to submit a bid lower than the minimum amount
    error NotEnoughETH();

    /// @notice Thrown when trying to submit a bid after the auction's end
    error AuctionEnded();

    /// @notice Thrown when trying to settle the auction while it's still going
    error AuctionNotEnded();

    ///////////////////////////////////////////////////////////////////////////////
    ///                                  EVENTS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when the auction starts
    /// @param endTime The timestamp for the end of the auction (without extensions)
    event AuctionStarted(uint256 endTime);

    /// @notice Emitted when the auction ends
    /// @param winner The address for the winner of the auction
    event AuctionSettled(address indexed winner);

    /// @notice Emitted when a new bid is submitted
    /// @param bidder The address who submitted the bid
    /// @param amount The value of the bid
    event BidSubmitted(address indexed bidder, uint256 amount);

    ///////////////////////////////////////////////////////////////////////////////
    ///                                 STRUCTS                                ///
    //////////////////////////////////////////////////////////////////////////////

    /// @dev Parameters for bids
    /// @param bidder The address of the wallet who submitted the bid
    /// @param amount The value of the bid
    struct Bid {
        address bidder;
        uint256 amount;
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                              CONFIG STORAGE                            ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice The prize for the auction
    uint256 public constant AUCTION_PRIZE = 1 ether;

    /// @notice The duration of the auction (without extensions)
    uint256 public constant AUCTION_DURATION = 24 hours;

    /// @notice The minimum increment between each bid
    uint256 public constant BID_INCREMENT = 0.05 ether;

    /// @notice The deployer of this contract
    address public immutable manager = msg.sender;

    ///////////////////////////////////////////////////////////////////////////////
    ///                               DATA STORAGE                             ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Bid on the lead so far
    Bid public highestBid;

    /// @notice Second highest bid
    Bid public secondBid;

    /// @notice Timestamp for the end of the auction (without extensions)
    uint256 public endTime;

    ///////////////////////////////////////////////////////////////////////////////
    ///                              AUCTION LOGIC                             ///
    //////////////////////////////////////////////////////////////////////////////

    /// @notice Kickstart the auction
    /// @dev There must be at least 1 ETH in the contract before starting the auction
    function start() public payable {
        if (address(this).balance < AUCTION_PRIZE) revert NotEnoughETH();
        endTime = block.timestamp + AUCTION_DURATION;

        emit AuctionStarted(endTime);
    }

    /// @notice Bid on the auction
    function bid() public payable {
        if (block.timestamp > endTime) revert AuctionEnded();
        if (msg.value < highestBid.amount + BID_INCREMENT)
            revert NotEnoughETH();

        Bid memory refund = secondBid;
        secondBid = highestBid;
        highestBid = Bid({bidder: msg.sender, amount: msg.value});

        emit BidSubmitted(msg.sender, msg.value);
        if (endTime - block.timestamp < 15 minutes) endTime += 15 minutes;

        SafeTransferLib.safeTransferETH(refund.bidder, refund.amount);
    }

    /// @notice Settle the auction, once it ends
    function settle() public payable nonReentrant {
        if (block.timestamp <= endTime) revert AuctionNotEnded();

        emit AuctionSettled(highestBid.bidder);

        SafeTransferLib.safeTransferETH(highestBid.bidder, AUCTION_PRIZE);
        SafeTransferLib.safeTransferETH(manager, address(this).balance);
    }
}
