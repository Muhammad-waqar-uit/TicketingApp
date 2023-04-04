// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20, Ownable {
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public completedTasks;
    mapping(uint256=>uint256) projectTasks;
    mapping(uint256=>address) projectCreater;
    mapping(uint256=>mapping(uint256=>address)) assignee;

    constructor() ERC20("Token","TKN") Ownable() {}

    function mintToken(address to, uint256 amount,uint256 projectId) external {
        _mint(to,amount);
        projectCreater[projectId]=to;
        projectTasks[projectId]=amount;
    }

    function burnToken(address from,uint256 amount) external {
        _burn(from,amount);
    }

    function taskAssign(address to, uint256 projectId, uint256 taskno) external {
    require(projectCreater[projectId] == msg.sender, "Unauthorized");
    require(assignee[projectId][taskno] == address(0), "Task already assigned");
    _transfer(msg.sender, to, 1);
    assignee[projectId][taskno] = to;
}

    function transferTask(uint256 projectId, uint256 taskno, address to) external {
    require(assignee[projectId][taskno] == msg.sender, "Unauthorized");
    require(to != address(0), "Invalid address");
    _transfer(msg.sender,to,1);
    assignee[projectId][taskno] = to;
}


    function completeTask(uint256 projectId, uint256 taskno) external {
    require(assignee[projectId][taskno] == msg.sender, "Unauthorized");
    require(!completedTasks[projectId][taskno][msg.sender], "Task already completed");

    // Mark the task as completed by the current assignee
    completedTasks[projectId][taskno][msg.sender] = true;

    // Transfer the token balance back to the project creator
    address projectCreator = projectCreater[projectId];
    uint256 tokenBalance = balanceOf(msg.sender);
    _transfer(msg.sender, projectCreator, tokenBalance);
    }

   function addTask(uint256 projectId, uint256 amount) external {
    require(projectCreater[projectId] == msg.sender, "Unauthorized");
    uint256 existingTasks = projectTasks[projectId];
    projectTasks[projectId] = existingTasks + amount;
    _mint(msg.sender, amount);
    }

    function allTasksCompleted(uint256 projectId) public view returns (bool) {
    uint256 totalTasks = projectTasks[projectId];
    for (uint256 i = 1; i <= totalTasks; i++) {
        if (!completedTasks[projectId][i][assignee[projectId][i]]) {
            return false;
        }
    }
    return true;
}

    function burnTokensIfAllTasksCompleted(uint256 projectId, address account) external returns (bool) {
    require(projectCreater[projectId] == account, "Unauthorized");
    if (allTasksCompleted(projectId)) {
        uint256 tokenBalance = balanceOf(projectCreater[projectId]);
        _burn(projectCreater[projectId], tokenBalance);
        return true;
    }
    return false;
    }



    function getProjectTasks(uint256 projectId) external view returns (uint256) {
    return projectTasks[projectId];
    }

    function getProjectCreater(uint256 projectId) external view returns (address) {
    return projectCreater[projectId];
    }
    
    function isTaskCompleted(uint256 projectId, uint256 taskno, address assigneeAddress) external view returns (bool) {
    return completedTasks[projectId][taskno][assigneeAddress];
    }

    function getAssignee(uint256 projectId, uint256 taskno) external view returns (address) {
    return assignee[projectId][taskno];
    }

}