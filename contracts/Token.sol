// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20, Ownable {
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public completedTasks;//task market completed for assignee address
    mapping(uint256=>uint256) projectTasks; //mapping for project id to tatal no of task does the project have
    mapping(uint256=>address) projectCreater; //project id to creator taking record who owns project 
    mapping(uint256=>mapping(uint256=>address)) assignee;//project id to task assignment to particular address

    constructor() ERC20("Token","TKN") Ownable() {}

    function mintToken(address to, uint256 amount,uint256 projectId) external {
        _mint(to,amount);
        //saving owner to project id mapping
        projectCreater[projectId]=to;
        //saving record for how many tasks for projectId
        projectTasks[projectId]=amount;
    }

    function burnToken(address from,uint256 amount) external {
        _burn(from,amount);
    }

    function taskAssign(address to, uint256 projectId, uint256 taskno) external {
    //require statement to check if assigner is the owner
    require(projectCreater[projectId] == msg.sender, "Unauthorized");
    //checking if task is not assigned to anyone
    require(assignee[projectId][taskno] == address(0), "Task already assigned");
    //toen is transfered to assignee for one task only
    _transfer(msg.sender, to, 1);
    //keeping record for assignee
    assignee[projectId][taskno] = to;
}

    function transferTask(uint256 projectId, uint256 taskno, address to) external {
    //check if assignee is owner of the task
    require(assignee[projectId][taskno] == msg.sender, "Unauthorized");
    //check if to address is not a zero address
    require(to != address(0), "Invalid address");
    //tranfering token to another person
    _transfer(msg.sender,to,1);
    //updating record for task assignee
    assignee[projectId][taskno] = to;
}


    function completeTask(uint256 projectId, uint256 taskno) external {
    //check if assignee is the owner of the task
    require(assignee[projectId][taskno] == msg.sender, "Unauthorized");
    //check if task is not marked completed
    require(!completedTasks[projectId][taskno][msg.sender], "Task already completed");

    // Mark the task as completed by the current assignee
    completedTasks[projectId][taskno][msg.sender] = true;

    // Transfer the token balance back to the project creator
    address projectCreator = projectCreater[projectId];
    // //take balance 
    // uint256 tokenBalance = balanceOf(msg.sender);
    //send a token to project creator back 
    _transfer(msg.sender, projectCreator, 1);
    }

   function addTask(uint256 projectId, uint256 amount) external {
    //check if creator of project is caller
    require(projectCreater[projectId] == msg.sender, "Unauthorized");
    uint256 existingTasks = projectTasks[projectId];//getting existing task
    projectTasks[projectId] = existingTasks + amount;//adding more task to the project
    _mint(msg.sender, amount);//minting tokens for tasks
    }

    function allTasksCompleted(uint256 projectId) public view returns (bool) {
    uint256 totalTasks = projectTasks[projectId]; //getting total task for each token id for a project
    for (uint256 i = 1; i <= totalTasks; i++) {//looping through to check if all the task aremarked completed
        if (!completedTasks[projectId][i][assignee[projectId][i]]) {
            return false;
        }
    }
    return true;
}

    function burnTokensIfAllTasksCompleted(uint256 projectId, address account) external returns (bool) {
    //owner is the caller check
    require(projectCreater[projectId] == account, "Unauthorized");
    //if all task are completed 
    if (allTasksCompleted(projectId)) {
        //total tokens of the burned need to change it 
        // uint256 tokenBalance = balanceOf(projectCreater[projectId]);
        uint256 tokenBalance= projectTasks[projectId];
        //burning from the creator address
        _burn(projectCreater[projectId], tokenBalance);
        return true;
    }
    return false;
    }



    function getProjectTasks(uint256 projectId) external view returns (uint256) {
        //check no of project task
    return projectTasks[projectId];
    }

    function getProjectCreater(uint256 projectId) external view returns (address) {
        //getting project creator for an ID
    return projectCreater[projectId];
    }
    
    function isTaskCompleted(uint256 projectId, uint256 taskno, address assigneeAddress) external view returns (bool) {
    //checking if task is marked true or not
    return completedTasks[projectId][taskno][assigneeAddress];
    }

    function getAssignee(uint256 projectId, uint256 taskno) external view returns (address) {
    //checking project and task assignee
    return assignee[projectId][taskno];
    }
}