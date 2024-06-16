## Warsaw Bycicles Club

**Smart contracts from Warsaw Bycicles Club project**

Contracts:

- **WarsawBikeNFT**: `OpenZeppelin`'s ERC721 contract with `Enumerable` and `URIStorage` extensions.
- **NFTAuction**: Contract that auctions one `WarsawBikeNFT` everyday, highest bidder wins, others get refunded.
- **ProposalPlatform**: Whitelisted wallets can create proposals and holder of `WarsawBikeNFT` can vote on them. Every two months the two most upvoted proposals get executed.

## Usage

You need to populate `.env` first. `RPC_ENDPOINT` must be of Avalanche Fuji network.

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploy

```shell
$ source .env
$ forge script script/Deploy.s.sol:DeployScript --chain avalanche --rpc-url $RPC_ENDPOINT -vvvv
```
