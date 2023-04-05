// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20, Ownable {
    //mapping to keep record of task completion
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public completedTasks;
    //mapping to keep record of project total task respective to ids
    mapping(uint256=>uint256) projectTasks; 
    //mapping to keep record of project creator with respect to id
    mapping(uint256=>address) projectCreator; 
    //mapping for task assignment
    mapping(uint256=>mapping(uint256=>address)) assignTask;
    //events 
    //event for total project task on creation 
    event projectTask(uint projectId,uint nooftasks,address owner);
    //event for assignment of task to any address event
    event assignTasks(uint projectId,uint taskno,address from, address to);
    //event for transfertoOther meaning assigner transfer his task to someone else 
    event transfertoOther(uint projectId,uint taskno,address from, address to);
    //event for task complete marked by the assignee
    event taskComplete(uint projectId, uint taskno,address assignee,bool check);
    //event for adding more task to current project 
    event addmoreTask(uint projectId,uint amount,address owner);
    //event marking project complete just for record that invoice generated 
    event projectMarkedComplete(uint projectId,address owner,bool check);
    
    constructor() ERC20("Token","TKN") Ownable() {}

    function mintToken(address to, uint256 amount,uint256 projectId) external {
        _mint(to,amount);
        //storing project creator 
        projectCreator[projectId]=to;
        // projectId to task mapping
        projectTasks[projectId]=amount;
        //event 
        emit projectTask(projectId, amount, msg.sender);
    }

    function burnToken(address from,uint256 amount) external {
        _burn(from,amount);
    }

    function taskAssign(address to, uint256 projectId, uint256 taskno) external {
        //checking is task assigner is the owner
        require(projectCreator[projectId] == msg.sender, "Unauthorized");
        //checking if task is not assigned to anyone
        require(assignTask[projectId][taskno] == address(0), "Task already assigned");
        //token is transfered to assignee for one task only
        _transfer(msg.sender, to, 1);
        //keeping record for assignee
        assignTask[projectId][taskno] = to;
        //event
        emit assignTasks(projectId,taskno,msg.sender,to);
    }

    function transferTask(uint256 projectId, uint256 taskno, address to) external {
        //check if assignee is owner of the task
        require(assignTask[projectId][taskno] == msg.sender, "Unauthorized");
        //check if to address is not a zero address
        require(to != address(0), "Invalid address");
        //tranfering token to another person to who task is assigned
        _transfer(msg.sender,to,1);
        //updating record for task assignee to next
        assignTask[projectId][taskno] = to;
        //event
        emit transfertoOther(projectId,taskno,msg.sender,to);
    }


    function completeTask(uint256 projectId, uint256 taskno) external {
        //check if assignee is the owner of the task
        require(assignTask[projectId][taskno] == msg.sender, "Unauthorized");
        //check if task is not marked completed
        require(!completedTasks[projectId][taskno][msg.sender], "Task already completed");
        // Mark the task as completed by the current assignee
        completedTasks[projectId][taskno][msg.sender] = true;
        // getting address of project owner
        address projectowner = projectCreator[projectId];
        //send a token to project creator back 
        _transfer(msg.sender, projectowner, 1);
        //event
        emit taskComplete(projectId,taskno,msg.sender,true);
    }

    function addTask(uint256 projectId, uint256 amount) external {
        //check if the project owner is adding task
        require(projectCreator[projectId] == msg.sender, "Unauthorized");
        uint256 existingTasks = projectTasks[projectId];//getting existing task for project
        projectTasks[projectId] = existingTasks + amount;//adding more task to the project
        _mint(msg.sender, amount);//minting tokens for tasks
        emit addmoreTask(projectId, amount, msg.sender);//event
    }

    function allTasksCompleted(uint256 projectId) public view returns (bool) {
        uint256 totalTasks = projectTasks[projectId]; //getting total task for each token id for a project
        for (uint256 i = 1; i <= totalTasks; i++) {//looping through to check if all the task are marked completed
            if (!completedTasks[projectId][i][assignTask[projectId][i]]) {//checking if task is not completed/completed
                return false;
            }
        }
        return true;
    }

    function burnTokensIfAllTasksCompleted(uint256 projectId, address account) external returns (bool) {
        //check if project owner is the caller address
        require(projectCreator[projectId] == account, "Unauthorized");
        //if all task are completed for the project
        if (allTasksCompleted(projectId)) {
            //total tokens of the project to burn
            uint256 tokenBalance= projectTasks[projectId];
            //burning from the creator address
            _burn(projectCreator[projectId], tokenBalance);
            //event
            emit projectMarkedComplete(projectId,msg.sender,true);
            //return to nofity other fuction
            return true;
        }
        return false;
    }

    function getProjectTasks(uint256 projectId) external view returns (uint256) {
        //getting total project task
        return projectTasks[projectId];
    }

    function getProjectCreater(uint256 projectId) external view returns (address) {
        //getting project creator for an ID
        return projectCreator[projectId];
    }
    
    function isTaskCompleted(uint256 projectId, uint256 taskno, address assigneeAddress) external view returns (bool) {
        //checking if task is marked (true or not)
        return completedTasks[projectId][taskno][assigneeAddress];
    }

    function getAssignee(uint256 projectId, uint256 taskno) external view returns (address) {
        //getting assigner for project and its task will return address
        return assignTask[projectId][taskno];
    }
}