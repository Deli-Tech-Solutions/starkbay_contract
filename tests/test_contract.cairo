// Integration test for the StarkBay contract
use starkbay_contract::{StarkBay, IStarkBayDispatcher, IStarkBayDispatcherTrait};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait};
use starknet::ContractAddress;

// Helper function to deploy the contract and return a dispatcher
fn deploy_starkbay() -> IStarkBayDispatcher {
    let contract = declare("StarkBay").unwrap().contract_class();
    // No constructor args
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    IStarkBayDispatcher { contract_address }
}

#[test]
fn test_register_and_query_shops() {
    let dispatcher = deploy_starkbay();

    // Register first shop as seller1
    let seller1: ContractAddress = 123.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, seller1);
    dispatcher.register_shop('ShopOne');
    stop_cheat_caller_address(dispatcher.contract_address);

    // Register second shop as seller2
    let seller2: ContractAddress = 456.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, seller2);
    dispatcher.register_shop('ShopTwo');
    stop_cheat_caller_address(dispatcher.contract_address);

    // Assert shop count is 2
    let count = dispatcher.get_shop_count();
    assert(count == 2, 'Shop count should be 2');

    // Assert first shop info
    let (name1, owner1) = dispatcher.get_shop_by_index(0);
    assert(name1 == 'ShopOne', 'First shop name mismatch');
    assert(owner1 == seller1, 'First shop owner mismatch');

    // Assert second shop info
    let (name2, owner2) = dispatcher.get_shop_by_index(1);
    assert(name2 == 'ShopTwo', 'Second shop name mismatch');
    assert(owner2 == seller2, 'Second shop owner mismatch');
}

#[test]
fn test_product_lifecycle() {
    let dispatcher = deploy_starkbay();
    let _spy = spy_events();

    // Register a shop as seller
    let seller: ContractAddress = 123.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, seller);
    dispatcher.register_shop('ShopOne');
    stop_cheat_caller_address(dispatcher.contract_address);

    // Add a product as shop owner
    start_cheat_caller_address(dispatcher.contract_address, seller);
    dispatcher.add_product(0, 'ProductA', 'DescA', 1000, 10);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Check product count
    let count = dispatcher.get_product_count(0);
    assert(count == 1, 'Product count should be 1');

    // Check product details
    let (name, desc, price, qty) = dispatcher.get_product(0, 0);
    assert(name == 'ProductA', 'Product name mismatch');
    assert(desc == 'DescA', 'Product description mismatch');
    assert(price == 1000, 'Product price mismatch');
    assert(qty == 10, 'Product quantity mismatch');

    // Update product as shop owner
    start_cheat_caller_address(dispatcher.contract_address, seller);
    dispatcher.update_product(0, 0, 'ProductA+', 'DescA+', 2000, 5);
    stop_cheat_caller_address(dispatcher.contract_address);

    let (name2, desc2, price2, qty2) = dispatcher.get_product(0, 0);
    assert(name2 == 'ProductA+', 'Product name update failed');
    assert(desc2 == 'DescA+', ' description update failed');
    assert(price2 == 2000, 'Product price update failed');
    assert(qty2 == 5, 'Product quantity update failed');

    // Remove product as shop owner
    start_cheat_caller_address(dispatcher.contract_address, seller);
    dispatcher.remove_product(0, 0);
    stop_cheat_caller_address(dispatcher.contract_address);

    let (name3, desc3, price3, qty3) = dispatcher.get_product(0, 0);
    assert(name3 == 0, 'Product name should be cleared');
    assert(desc3 == 0, ' description should be cleared');
    assert(price3 == 0, 'Product price should be cleared');
    assert(qty3 == 0, ' quantity should be cleared');
}

#[test]
#[should_panic]
fn test_non_owner_cannot_add_product() {
    let dispatcher = deploy_starkbay();
    // Register a shop as seller
    let seller: ContractAddress = 123.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, seller);
    dispatcher.register_shop('ShopOne');
    stop_cheat_caller_address(dispatcher.contract_address);

    // Try to add a product as a non-owner
    let not_owner: ContractAddress = 456.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, not_owner);
    dispatcher.add_product(0, 'HackerProduct', 'Hacked', 1, 1);
    stop_cheat_caller_address(dispatcher.contract_address);
}