# StarkBay Cairo Contract

StarkBay is a decentralized multi-vendor e-commerce marketplace built on Starknet, empowering sellers to launch and manage their own shops while buyers enjoy a trustless, transparent shopping experience.

## Project Structure

```
.
├── Scarb.lock
├── Scarb.toml
├── snfoundry.toml
├── src/
│   └── lib.cairo
├── target/
└── tests/
    └── test_contract.cairo
```

- **`Scarb.toml`**: Project configuration and dependencies.
- **`src/lib.cairo`**: Main contract source code (StarkBay contract).
- **`tests/test_contract.cairo`**: Integration tests for the contract.

## Contract Overview

The StarkBay contract provides the following features:
- Sellers can register their own shops (shop name and owner address).
- Buyers (and anyone) can view all registered shops.
- The contract is designed for easy extension (e.g., adding products, orders, payments).

### Main Interface
- `register_shop(shop_name: felt252)`: Register a new shop with the caller as the owner.
- `get_shop_count() -> u64`: Returns the total number of registered shops.
- `get_shop_by_index(index: u64) -> (felt252, ContractAddress)`: Returns the shop name and owner address for a given index.

## Prerequisites
- [Scarb](https://docs.swmansion.com/scarb/) (Cairo package manager)
- [Starknet Foundry](https://foundry.starknet.io/) (for testing)

## Building the Contract

To compile the contract, run:

```
scarb build
```

## Running Tests

To run the integration tests:

```
scarb test
```

## License

MIT 