// Main contract module
#[starknet::contract]
 pub mod StarkBay{
    use super::*;
    use starknet::ContractAddress;
    use starknet::storage::*;
    use starknet::get_caller_address;
    use crate::interfaces::IStarkBay::IStarkBay;

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Shop {
        name: felt252,
        owner: ContractAddress,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Product {
        id: u64,
        name: felt252,
        description: felt252,
        price: u128,
        quantity: u64,
    }

    #[storage]
    pub struct Storage {
        shops: Vec<Shop>,
        // Mapping: shop_index => Vec<Product>
        products: Map<u64, Vec<Product>>,
        // Mapping: shop_index => next product id
        next_product_id: Map<u64, u64>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ProductAdded: ProductAdded,
        ProductUpdated: ProductUpdated,
        ProductRemoved: ProductRemoved,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ProductAdded {
        shop_index: u64,
        product_id: u64,
        name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ProductUpdated {
        shop_index: u64,
        product_id: u64,
        name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ProductRemoved {
        shop_index: u64,
        product_id: u64,
    }

    #[abi(embed_v0)]
    pub impl StarkBayImpl of IStarkBay<ContractState> {
        // --- Shop Management (existing) ---
        fn register_shop(ref self: ContractState, shop_name: felt252) {
            let caller = get_caller_address();
            let shop = Shop { name: shop_name, owner: caller };
            self.shops.append().write(shop);
        }

        fn get_shop_count(self: @ContractState) -> u64 {
            self.shops.len()
        }

        fn get_shop_by_index(self: @ContractState, index: u64) -> (felt252, ContractAddress) {
            let shop = self.shops.at(index).read();
            (shop.name, shop.owner)
        }

        // --- Product Management (new) ---
        fn add_product(
            ref self: ContractState,
            shop_index: u64,
            name: felt252,
            description: felt252,
            price: u128,
            quantity: u64,
        ) {
            let caller = get_caller_address();
            let shop = self.shops.at(shop_index).read();
            assert(shop.owner == caller, 'Only owner can add products');

            let product_id = self.next_product_id.entry(shop_index).read();
            let product = Product {
                id: product_id,
                name,
                description,
                price,
                quantity,
            };
            self.products.entry(shop_index).append().write(product);
            self.next_product_id.entry(shop_index).write(product_id + 1);

            self.emit(Event::ProductAdded(ProductAdded {
                shop_index,
                product_id,
                name,
            }));
        }

        fn update_product(
            ref self: ContractState,
            shop_index: u64,
            product_id: u64,
            name: felt252,
            description: felt252,
            price: u128,
            quantity: u64,
        ) {
            let caller = get_caller_address();
            let shop = self.shops.at(shop_index).read();
            assert(shop.owner == caller, 'Only owner can update products');

            let mut products = self.products.entry(shop_index);
            let mut product = products.at(product_id).read();
            product.name = name;
            product.description = description;
            product.price = price;
            product.quantity = quantity;
            products.at(product_id).write(product);

            self.emit(Event::ProductUpdated(ProductUpdated {
                shop_index,
                product_id,
                name,
            }));
        }

        fn remove_product(ref self: ContractState, shop_index: u64, product_id: u64) {
            let caller = get_caller_address();
            let shop = self.shops.at(shop_index).read();
            assert(shop.owner == caller, 'Only owner can remove products');

            let mut products = self.products.entry(shop_index);
            // Remove by setting to a default product (could be improved with a more advanced data structure)
            let mut product = products.at(product_id).read();
            product.name = 0;
            product.description = 0;
            product.price = 0;
            product.quantity = 0;
            products.at(product_id).write(product);

            self.emit(Event::ProductRemoved(ProductRemoved {
                shop_index,
                product_id,
            }));
        }

        fn get_product(
            self: @ContractState,
            shop_index: u64,
            product_id: u64,
        ) -> (felt252, felt252, u128, u64) {
            let product = self.products.entry(shop_index).at(product_id).read();
            (product.name, product.description, product.price, product.quantity)
        }

        fn get_product_count(self: @ContractState, shop_index: u64) -> u64 {
            self.products.entry(shop_index).len()
        }

        fn list_shops(self: @ContractState, start: u64, count: u64) -> Array<(felt252, ContractAddress)> {
            let mut result = array![];
            let total = self.shops.len();
            let end = if start + count > total { total } else { start + count };
            let mut i = start;
            while i < end {
                let shop = self.shops.at(i).read();
                result.append((shop.name, shop.owner));
                i = i + 1;
            };
            result
        }

        fn list_products(self: @ContractState, shop_index: u64, start: u64, count: u64) -> Array<(u64, felt252, felt252, u128, u64)> {
            let mut result = array![];
            let total = self.products.entry(shop_index).len();
            let end = if start + count > total { total } else { start + count };
            let mut i = start;
            while i < end {
                let product = self.products.entry(shop_index).at(i).read();
                result.append((product.id, product.name, product.description, product.price, product.quantity));
                i = i + 1;
            };
            result
        }
    }
}