# dollar-auction.sol

> A dollar auction implementation in Solidity

A dollar auction is a [non-zero sum sequential game](https://en.wikipedia.org/wiki/Dollar_auction), where you auction some amount of currency higher than the minimum bid, and keep the two highest bids (the first one wins, but the second one doesn't get refunded).

This presents a scenario where, even after the highest bid exceeds the prize, the only way for the second highest bidder to cut their losses is to continue bidding.

## Development

This repository uses the [Foundry](https://github.com/gakonst/foundry) smart contract toolkit. You can download the Foundry installer by running `curl -L https://foundry.paradigm.xyz | bash`, and then install the latest version by running `foundryup` on a new terminal window (additional instructions are available [on the Foundry repo](https://github.com/gakonst/foundry#installation)).

Once you have everything installed, you can run `make` from the base directory to install all dependencies, and build the smart contracts. You can run the automated tests with `make test`.

## License

This project is open-sourced software licensed under the MIT license. See the [License file](LICENSE) for more information.
