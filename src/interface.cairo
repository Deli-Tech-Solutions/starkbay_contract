use starknet::ContractAddress;

#[starknet::interface]
pub trait IStarkBay<TContractState> {
    // Shop management
    fn register_shop(ref self: TContractState, shop_name: felt252);
    fn get_shop_count(self: @TContractState) -> u64;
    fn get_shop_by_index(self: @TContractState, index: u64) -> (felt252, ContractAddress);
    fn list_shops(self: @TContractState, start: u64, count: u64) -> Array<(felt252, ContractAddress)>;

    // Product management
    fn add_product(
        ref self: TContractState,
        shop_index: u64,
        name: felt252,
        description: felt252,
        price: u128,
        quantity: u64,
    );
    fn update_product(
        ref self: TContractState,
        shop_index: u64,
        product_id: u64,
        name: felt252,
        description: felt252,
        price: u128,
        quantity: u64,
    );
    fn remove_product(ref self: TContractState, shop_index: u64, product_id: u64);
    fn get_product(
        self: @TContractState,
        shop_index: u64,
        product_id: u64,
    ) -> (felt252, felt252, u128, u64);
    fn get_product_count(self: @TContractState, shop_index: u64) -> u64;
    fn list_products(self: @TContractState, shop_index: u64, start: u64, count: u64) -> Array<(u64, felt252, felt252, u128, u64)>;
} 