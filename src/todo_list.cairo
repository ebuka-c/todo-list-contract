#[derive(Copy, Drop, starknet::Store, Serde, PartialEq)]
pub struct Task {
    name: felt252,
    description: felt252,
    is_completed: bool,
}


#[starknet::interface]
pub trait IMyTodoList<TContractState> {
    /// add task function.
    fn add_task(ref self: TContractState, task_name: felt252, description: felt252);
    /// complete task function.
    fn complete_task(self: @TContractState, task_name: felt252) -> bool;
    /// delete task function.
    fn delete_task(self: @TContractState, task_name: felt252) -> bool;
    /// get all tasks function.
    fn get_all_tasks(self: @TContractState);
}

/// contract for managing tasks
#[starknet::contract]
pub mod MyTodoList {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::event::EventEmitter;
    use starknet::storage::{
        Map, StoragePointerReadAccess, StoragePointerWriteAccess, StorageMapWriteAccess,
        StorageMapReadAccess,
    };


    use super::{Task};

    #[storage]
    struct Storage {
        tasks: Map<felt252, Task>,
        taskCount: u64,
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Added: Added,
        TaskCompleted: TaskCompleted,
        TaskDeleted: TaskDeleted,
    }

    #[derive(Drop, starknet::Event)]
    struct Added {
        task_name: felt252,
        description: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct TaskCompleted {
        task_id: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct TaskDeleted {
        task_id: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, _owner: ContractAddress, initial_count: u64) {
        self.owner.write(_owner);
        self.taskCount.write(initial_count);
    }

    #[abi(embed_v0)]
    impl MyTodoListImpl of super::IMyTodoList<ContractState> {
        fn add_task(ref self: ContractState, task_name: felt252, description: felt252) {
            let caller = get_caller_address();
            assert!(self.owner.read() == caller, "Only owner can add tasks");

            self.tasks.write(task_name, true);
            self.emit(Added { task_name, description });
        }

        fn complete_task(self: @ContractState, task_name: felt252) -> bool {
            let caller = get_caller_address();
            let owner = self.owner.read();

            assert(caller == owner, 'Only owner can complete tasks');
            let mut task = self.tasks.read(task_name);
            assert(task.name == task_name, 'Task does not exist');
            assert(!task.is_completed, 'Task already completed');

            task.is_completed = true;
            self.tasks.write(task_name, task);

            self.emit(TaskCompleted { task_id });

            true
        }

        fn delete_task(self: @ContractState, task_name: felt252) -> bool {
            let caller = get_caller_address();
            assert(self.owner.read() == caller, 'Unauthorized');
            let task = self.tasks.read(task_name);
            assert(task.name == task_name, 'Task does not exist');

            let blank_task = Task {
                name: 'clean up', description: 'clean house', is_completed: false,
            };
            self.tasks.write(task_id, blank_task);
            self.emit(TaskDeleted { task_id });
            true
        }

        fn get_all_tasks(self: @ContractState) {}
    }
}
