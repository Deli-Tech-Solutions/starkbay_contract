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
    assert(count == 2, 100);

    // Assert first shop info
    let (name1, owner1) = dispatcher.get_shop_by_index(0);
    assert(name1 == 'ShopOne', 101);
    assert(owner1 == seller1, 102);

    // Assert second shop info
    let (name2, owner2) = dispatcher.get_shop_by_index(1);
    assert(name2 == 'ShopTwo', 103);
    assert(owner2 == seller2, 104);
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
    assert(count == 1, 105);

    // Check product details
    let (name, desc, price, qty) = dispatcher.get_product(0, 0);
    assert(name == 'ProductA', 106);
    assert(desc == 'DescA', 107);
    assert(price == 1000, 108);
    assert(qty == 10, 109);

    // Update product as shop owner
    start_cheat_caller_address(dispatcher.contract_address, seller);
    dispatcher.update_product(0, 0, 'ProductA+', 'DescA+', 2000, 5);
    stop_cheat_caller_address(dispatcher.contract_address);

    let (name2, desc2, price2, qty2) = dispatcher.get_product(0, 0);
    assert(name2 == 'ProductA+', 110);
    assert(desc2 == 'DescA+', 111);
    assert(price2 == 2000, 112);
    assert(qty2 == 5, 113);

    // Remove product as shop owner
    start_cheat_caller_address(dispatcher.contract_address, seller);
    dispatcher.remove_product(0, 0);
    stop_cheat_caller_address(dispatcher.contract_address);

    let (name3, desc3, price3, qty3) = dispatcher.get_product(0, 0);
    assert(name3 == 0, 114);
    assert(desc3 == 0, 115);
    assert(price3 == 0, 116);
    assert(qty3 == 0, 117);
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

#[test]
fn test_list_shops_pagination() {
    let dispatcher = deploy_starkbay();
    // Register 3 shops
    let seller1: ContractAddress = 111.try_into().unwrap();
    let seller2: ContractAddress = 222.try_into().unwrap();
    let seller3: ContractAddress = 333.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, seller1);
    dispatcher.register_shop('ShopA');
    stop_cheat_caller_address(dispatcher.contract_address);
    start_cheat_caller_address(dispatcher.contract_address, seller2);
    dispatcher.register_shop('ShopB');
    stop_cheat_caller_address(dispatcher.contract_address);
    start_cheat_caller_address(dispatcher.contract_address, seller3);
    dispatcher.register_shop('ShopC');
    stop_cheat_caller_address(dispatcher.contract_address);
    // List all shops
    let all = dispatcher.list_shops(0, 10);
    assert(all.len() == 3, 118);
    assert(*all.at(0) == ('ShopA', seller1), 119);
    assert(*all.at(1) == ('ShopB', seller2), 120);
    assert(*all.at(2) == ('ShopC', seller3), 121);
    // Paginate: get only 2
    let page = dispatcher.list_shops(1, 2);
    assert(page.len() == 2, 122);
    assert(*page.at(0) == ('ShopB', seller2), 123);
    assert(*page.at(1) == ('ShopC', seller3), 124);
    // Out of bounds
    let empty = dispatcher.list_shops(5, 2);
    assert(empty.len() == 0, 125);
}

#[test]
fn test_list_products_pagination() {
    let dispatcher = deploy_starkbay();
    // Register a shop
    let seller: ContractAddress = 999.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, seller);
    dispatcher.register_shop('ShopX');
    // Add 3 products
    dispatcher.add_product(0, 'P1', 'D1', 10, 1);
    dispatcher.add_product(0, 'P2', 'D2', 20, 2);
    dispatcher.add_product(0, 'P3', 'D3', 30, 3);
    stop_cheat_caller_address(dispatcher.contract_address);
    // List all products
    let all = dispatcher.list_products(0, 0, 10);
    assert(all.len() == 3, 126);
    let (id0, n0, d0, p0, q0) = *all.at(0);
    assert(n0 == 'P1' && d0 == 'D1' && p0 == 10 && q0 == 1, 127);
    let (id1, n1, d1, p1, q1) = *all.at(1);
    assert(n1 == 'P2' && d1 == 'D2' && p1 == 20 && q1 == 2, 128);
    let (id2, n2, d2, p2, q2) = *all.at(2);
    assert(n2 == 'P3' && d2 == 'D3' && p2 == 30 && q2 == 3, 129);
    // Paginate: get only 2
    let page = dispatcher.list_products(0, 1, 2);
    assert(page.len() == 2, 130);
    let (_, n1b, _, _, _) = *page.at(0);
    let (_, n2b, _, _, _) = *page.at(1);
    assert(n1b == 'P2', 131);
    assert(n2b == 'P3', 132);
    // Out of bounds
    let empty = dispatcher.list_products(0, 5, 2);
    assert(empty.len() == 0, 133);
}

#[test]
fn test_duplicate_shop_registration_and_count() {
    let dispatcher = deploy_starkbay();
    let owner: ContractAddress = 555.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.register_shop('ShopDup');
    dispatcher.register_shop('ShopDup');
    stop_cheat_caller_address(dispatcher.contract_address);
    let count = dispatcher.get_shop_count();
    assert(count == 2, 100);
    let (name1, owner1) = dispatcher.get_shop_by_index(0);
    let (name2, owner2) = dispatcher.get_shop_by_index(1);
    assert(name1 == 'ShopDup' && name2 == 'ShopDup', 101);
    assert(owner1 == owner && owner2 == owner, 102);
}

#[test]
#[should_panic]
fn test_add_product_to_nonexistent_shop_should_panic() {
    let dispatcher = deploy_starkbay();
    let owner: ContractAddress = 888.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.add_product(0, 'P', 'D', 1, 1); // No shop registered yet
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
#[should_panic]
fn test_update_product_out_of_bounds_should_panic() {
    let dispatcher = deploy_starkbay();
    let owner: ContractAddress = 777.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.register_shop('Shop');
    dispatcher.add_product(0, 'P', 'D', 1, 1);
    dispatcher.update_product(0, 5, 'P', 'D', 1, 1); // Invalid product_id
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
#[should_panic]
fn test_remove_product_out_of_bounds_should_panic() {
    let dispatcher = deploy_starkbay();
    let owner: ContractAddress = 666.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.register_shop('Shop');
    dispatcher.add_product(0, 'P', 'D', 1, 1);
    dispatcher.remove_product(0, 3); // Invalid product_id
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
#[should_panic]
fn test_get_product_out_of_bounds_should_panic() {
    let dispatcher = deploy_starkbay();
    let owner: ContractAddress = 9999.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.register_shop('Shop');
    dispatcher.add_product(0, 'P', 'D', 1, 1);
    stop_cheat_caller_address(dispatcher.contract_address);
    dispatcher.get_product(0, 2); // Invalid product_id
}

#[test]
#[should_panic]
fn test_update_product_as_non_owner_should_panic() {
    let dispatcher = deploy_starkbay();
    let owner: ContractAddress = 1010.try_into().unwrap();
    let not_owner: ContractAddress = 2020.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.register_shop('Shop');
    dispatcher.add_product(0, 'P', 'D', 1, 1);
    stop_cheat_caller_address(dispatcher.contract_address);
    start_cheat_caller_address(dispatcher.contract_address, not_owner);
    dispatcher.update_product(0, 0, 'X', 'Y', 2, 2);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
#[should_panic]
fn test_remove_product_as_non_owner_should_panic() {
    let dispatcher = deploy_starkbay();
    let owner: ContractAddress = 3030.try_into().unwrap();
    let not_owner: ContractAddress = 4040.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.register_shop('Shop');
    dispatcher.add_product(0, 'P', 'D', 1, 1);
    stop_cheat_caller_address(dispatcher.contract_address);
    start_cheat_caller_address(dispatcher.contract_address, not_owner);
    dispatcher.remove_product(0, 0);
    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
fn test_list_products_after_removal() {
    let dispatcher = deploy_starkbay();
    let owner: ContractAddress = 5050.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.register_shop('Shop');
    dispatcher.add_product(0, 'P1', 'D1', 1, 1);
    dispatcher.add_product(0, 'P2', 'D2', 2, 2);
    dispatcher.remove_product(0, 0);
    stop_cheat_caller_address(dispatcher.contract_address);
    let products = dispatcher.list_products(0, 0, 2);
    assert(products.len() == 2, 134);
    let (id0, n0, d0, p0, q0) = *products.at(0);
    assert(n0 == 0 && d0 == 0 && p0 == 0 && q0 == 0, 200);
    let (id1, n1, d1, p1, q1) = *products.at(1);
    assert(n1 == 'P2' && d1 == 'D2' && p1 == 2 && q1 == 2, 201);
}

#[test]
fn test_list_shops_and_products_zero_count_and_start() {
    let dispatcher = deploy_starkbay();
    let owner: ContractAddress = 6060.try_into().unwrap();
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.register_shop('Shop');
    dispatcher.add_product(0, 'P', 'D', 1, 1);
    stop_cheat_caller_address(dispatcher.contract_address);
    // Zero count
    let shops = dispatcher.list_shops(0, 0);
    assert(shops.len() == 0, 300);
    let products = dispatcher.list_products(0, 0, 0);
    assert(products.len() == 0, 301);
    // Start >= length
    let shops2 = dispatcher.list_shops(5, 1);
    assert(shops2.len() == 0, 302);
    let products2 = dispatcher.list_products(0, 5, 1);
    assert(products2.len() == 0, 303);
}