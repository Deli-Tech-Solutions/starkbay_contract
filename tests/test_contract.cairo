// Integration test for the StarkBay contract
use starkbay_contract::{StarkBay, IStarkBayDispatcher, IStarkBayDispatcherTrait};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};
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
