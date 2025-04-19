use todo_list_contract::todo_list::{
    IMyTodoListDispatcher, IMyTodoListSafeDispatcher, IMyTodoListSafeDispatcherTrait,
    IMyTodoListDispatcherTrait,
};

use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::ContractAddress;

pub fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}
pub fn EBUKA() -> ContractAddress {
    'EBUKA'.try_into().unwrap()
}

fn deploy_contract(initial_count: u64) -> ContractAddress {
    let class_hash = declare("MyTodoList").unwrap().contract_class();
    let mut calldata = array![];
    OWNER().serialize(ref calldata);
    initial_count.serialize(ref calldata);
    let (contract_address, _) = class_hash.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_add_task_owner() {
    let contract_address = deploy_contract(0);
    let todo = IMyTodoListDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    let task_name = todo.add_task('', 'Upload assignment to repo');
    stop_cheat_caller_address(contract_address);
    assert!(
        task_name == 'Upload assignment to repo',
        "Task name expected to be Upload assignment to repo",
    );
}

#[test]
#[feature("safe_dispatcher")]
fn test_add_task_not_owner() {
    let contract_address = deploy_contract(0);
    let todo = IMyTodoListSafeDispatcher { contract_address };
    start_cheat_caller_address(contract_address, EBUKA());
    let result = todo.add_task('', 'I am not authorized');
    stop_cheat_caller_address(contract_address);
    assert!(result.is_err(), "Not allowed to add task because you are not owner");
}

#[test]
fn test_complete_task() {
    let contract_address = deploy_contract(0);
    let todo = IMyTodoListDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    let task_name = todo.add_task('', 'Complete your cleanup');
    todo.complete_task(task_name);
    stop_cheat_caller_address(contract_address);
}


#[test]
#[feature("safe_dispatcher")]
fn test_delete_task_not_owner() {
    let contract_address = deploy_contract(0);
    let todo = IMyTodoListSafeDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    let task_name_result = todo.add_task('Prepare weekend summary');
    assert!(task_name_result.is_ok(), "Owner should be able to create task");
    let task_name = task_name_result.unwrap();
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, EBUKA());
    let result = todo.delete_task(task_name);
    stop_cheat_caller_address(contract_address);
    assert!(result.is_err(), "User without permission cannot delete task");
}

#[test]
fn test_get_all_tasks() {
    let contract_address = deploy_contract(0);
    let todo = IMyTodoListDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    todo.add_task('', 'This remains');
    todo.add_task('', 'This is deleted');
    todo.delete_task(2);
    let tasks = todo.get_all_tasks();
    stop_cheat_caller_address(contract_address);
    assert!(tasks.len() == 1, "Result length is incorrect");
}
