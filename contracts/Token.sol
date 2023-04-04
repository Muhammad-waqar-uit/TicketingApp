// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20, Ownable {
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public completedTasks;//task marked completed for assignee address
    mapping(uint256=>uint256) projectTasks; //mapping for project id to total no of task in specific projectId
    mapping(uint256=>address) projectCreater; //project id to creator (taking record who owns project)
    mapping(uint256=>mapping(uint256=>address)) assignTask;//project id to task assignment to particular address
    //events 
    event projectTask(uint projectId,uint nooftasks,address owner);//total project task on creation event
    event assignTasks(uint projectId,uint taskno,address from, address to);//assignment of task to any address event
    event transfertoOther(uint projectId,uint taskno,address from, address to);//transfertoOther meaning assigner transfer his task to someone else event
    event taskComplete(uint projectId, uint taskno,address assignee,bool check);//task complete marked by the assignee event
    event addmoreTask(uint projectId,uint amount,address owner);//adding more task to current project event
    event projectMarkedComplete(uint projectId,address owner,bool check); //marking project complete just for record that invoice generated event
    
    constructor() ERC20("Token","TKN") Ownable() {}

    function mintToken(address to, uint256 amount,uint256 projectId) external {
        _mint(to,amount);
        //project id to owner mapping
        projectCreater[projectId]=to;
        //saving record for how many tasks for projectId
        projectTasks[projectId]=amount;
        emit projectTask(projectId, amount, msg.sender);
    }

    function burnToken(address from,uint256 amount) external {
        _burn(from,amount);
    }

    function taskAssign(address to, uint256 projectId, uint256 taskno) external {
        //require statement to check if assigner is the owner
        require(projectCreater[projectId] == msg.sender, "Unauthorized");
        //checking if task is not assigned to anyone
        require(assignTask[projectId][taskno] == address(0), "Task already assigned");
        //token is transfered to assignee for one task only
        _transfer(msg.sender, to, 1);
        //keeping record for assignee
        assignTask[projectId][taskno] = to;
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
        address projectCreator = projectCreater[projectId];
        //send a token to project creator back 
        _transfer(msg.sender, projectCreator, 1);
        emit taskComplete(projectId,taskno,msg.sender,true);
    }

    function addTask(uint256 projectId, uint256 amount) external {
        //check if creator of project is calling
        require(projectCreater[projectId] == msg.sender, "Unauthorized");
        uint256 existingTasks = projectTasks[projectId];//getting existing task for project
        projectTasks[projectId] = existingTasks + amount;//adding more task to the project
        _mint(msg.sender, amount);//minting tokens for tasks
        emit addmoreTask(projectId, amount, msg.sender);
    }

    function allTasksCompleted(uint256 projectId) public view returns (bool) {
        uint256 totalTasks = projectTasks[projectId]; //getting total task for each token id for a project
        for (uint256 i = 1; i <= totalTasks; i++) {//looping through to check if all the task are marked completed
            if (!completedTasks[projectId][i][assignTask[projectId][i]]) {
                return false;
            }
        }
        return true;
    }

    function burnTokensIfAllTasksCompleted(uint256 projectId, address account) external returns (bool) {
        //owner is the caller check requirement
        require(projectCreater[projectId] == account, "Unauthorized");
        //if all task are completed check requirment
        if (allTasksCompleted(projectId)) {
            //total tokens of the project to burn
            uint256 tokenBalance= projectTasks[projectId];
            //burning from the creator address
            _burn(projectCreater[projectId], tokenBalance);
            emit projectMarkedComplete(projectId,msg.sender,true);
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
        return assignTask[projectId][taskno];
    }
}

