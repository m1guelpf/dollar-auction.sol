// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DollarAuction} from "../DollarAuction.sol";

contract User {
    receive() external payable {}
}

contract DollarAuctionTest is Test {
    event AuctionStarted(uint256 endTime);
    event AuctionSettled(address indexed winner);
    event BidSubmitted(address indexed bidder, uint256 amount);

    DollarAuction auction;
    User user;

    function setUp() public {
        user = new User();
        auction = new DollarAuction();
    }

    function testCannotStartAuctionWithoutPrize() public {
        vm.expectRevert(DollarAuction.NotEnoughETH.selector);
        auction.start();
    }

    function testCanStartAuction() public {
        assertEq(auction.endTime(), 0);
        vm.deal(address(auction), 1 ether);

        vm.expectEmit(false, false, false, true);
        emit AuctionStarted(block.timestamp + 24 hours);
        auction.start();

        assertEq(auction.endTime(), block.timestamp + 24 hours);
    }

    function testCanBid() public {
        vm.deal(address(auction), 1 ether);
        auction.start();

        (address bidder, uint256 amount) = auction.highestBid();
        assertEq(amount, 0);
        assertEq(bidder, address(0));

        vm.expectEmit(true, false, false, true);
        emit BidSubmitted(address(this), 0.05 ether);
        auction.bid{value: 0.05 ether}();

        (address newBidder, uint256 newAmount) = auction.highestBid();
        assertEq(address(auction).balance, 1.05 ether);
        assertEq(newAmount, 0.05 ether);
        assertEq(newBidder, address(this));
    }

    function testCannotBidAfterEnddate() public {
        vm.deal(address(auction), 1 ether);
        auction.start();

        vm.warp(auction.endTime() + 1);

        (address bidder, uint256 amount) = auction.highestBid();
        assertEq(amount, 0);
        assertEq(bidder, address(0));

        vm.expectRevert(DollarAuction.AuctionEnded.selector);
        auction.bid{value: 0.05 ether}();

        (address newBidder, uint256 newAmount) = auction.highestBid();
        assertEq(address(auction).balance, 1 ether);
        assertEq(newAmount, 0 ether);
        assertEq(newBidder, address(0));
    }

    function testCannotBidWithoutBalance() public {
        vm.deal(address(auction), 1 ether);
        auction.start();

        auction.bid{value: 0.05 ether}();

        vm.prank(address(user));
        vm.expectRevert(DollarAuction.NotEnoughETH.selector);
        auction.bid{value: 0 ether}();

        (address newBidder, uint256 newAmount) = auction.highestBid();
        assertEq(address(auction).balance, 1.05 ether);
        assertEq(newAmount, 0.05 ether);
        assertEq(newBidder, address(this));
    }

    function testCannotBidWithLowBalance() public {
        vm.deal(address(auction), 1 ether);
        vm.deal(address(user), 1 ether);
        auction.start();

        auction.bid{value: 0.05 ether}();

        vm.prank(address(user));
        vm.expectRevert(DollarAuction.NotEnoughETH.selector);
        auction.bid{value: 0.05 ether}();

        (address newBidder, uint256 newAmount) = auction.highestBid();
        assertEq(address(auction).balance, 1.05 ether);
        assertEq(newAmount, 0.05 ether);
        assertEq(newBidder, address(this));
    }

    function testBidRefundsGetProcessed() public {
        vm.deal(address(user), 1 ether);
        vm.deal(address(auction), 1 ether);
        auction.start();

        vm.prank(address(user));
        auction.bid{value: 0.05 ether}();
        auction.bid{value: 0.1 ether}();

        assertEq(address(user).balance, 0.95 ether);

        auction.bid{value: 0.15 ether}();

        (address highestBidder, uint256 highestBid) = auction.highestBid();
        (address secondBidder, uint256 secondBid) = auction.secondBid();
        assertEq(address(user).balance, 1 ether);
        assertEq(address(auction).balance, 1.25 ether);
        assertEq(highestBid, 0.15 ether);
        assertEq(highestBidder, address(this));
        assertEq(secondBid, 0.1 ether);
        assertEq(secondBidder, address(this));
    }

    function testLateBidExtendsAuction() public {
        vm.deal(address(auction), 1 ether);
        auction.start();

        vm.warp(auction.endTime() - 14 minutes);
        uint256 endTime = auction.endTime();

        auction.bid{value: 0.05 ether}();

        assertEq(auction.endTime(), endTime + 15 minutes);
    }

    function testCanSettle() public {
        uint256 managerBalance = address(this).balance;
        vm.deal(address(user), 0.05 ether);
        vm.deal(address(auction), 1 ether);
        auction.start();

        vm.prank(address(user));
        auction.bid{value: 0.05 ether}();

        vm.warp(auction.endTime() + 1);

        vm.expectEmit(true, false, false, true);
        emit AuctionSettled(address(user));
        auction.settle();

        assertEq(address(user).balance, 1 ether);
        assertEq(address(this).balance, managerBalance + 0.05 ether);
    }

    function testCannotSettleBeforeAuctionEnds() public {
        vm.deal(address(user), 1 ether);
        vm.deal(address(auction), 1 ether);
        auction.start();

        auction.bid{value: 0.05 ether}();

        vm.expectRevert(DollarAuction.AuctionNotEnded.selector);
        auction.settle();

        assertEq(address(user).balance, 1 ether);
        assertEq(address(auction).balance, 1.05 ether);
    }

    receive() external payable {}
}
