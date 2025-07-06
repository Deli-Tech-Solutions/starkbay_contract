/// Interface for StarkBay: a decentralized multi-vendor e-commerce marketplace.
/// Allows sellers to register shops and buyers to view registered shops.
#[starknet::interface]
pub trait IStarkBay<TContractState> {
    /// Register a new shop with a name.
    fn register_shop(ref self: TContractState, shop_name: felt252);
    /// Get the total number of registered shops.
    fn get_shop_count(self: @TContractState) -> u64;
    /// Get shop info (name, owner) by index.
    fn get_shop_by_index(self: @TContractState, index: u64) -> (felt252, starknet::ContractAddress);
}

/// StarkBay contract: minimal multi-vendor marketplace.
#[starknet::contract]
pub mod StarkBay {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::*;

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Shop {
        name: felt252,
        owner: ContractAddress,
    }

    #[storage]
    pub struct Storage {
        shops: Vec<Shop>,
    }

    #[abi(embed_v0)]
    pub impl StarkBayImpl of super::IStarkBay<ContractState> {
        /// Register a new shop with the caller as owner.
        fn register_shop(ref self: ContractState, shop_name: felt252) {
            let caller = get_caller_address();
            let shop = Shop { name: shop_name, owner: caller };
            self.shops.append().write(shop);
        }

        /// Get the total number of registered shops.
        fn get_shop_count(self: @ContractState) -> u64 {
            self.shops.len()
        }

        /// Get shop info (name, owner) by index.
        fn get_shop_by_index(self: @ContractState, index: u64) -> (felt252, ContractAddress) {
            let shop = self.shops.at(index).read();
            (shop.name, shop.owner)
        }
    }
}
