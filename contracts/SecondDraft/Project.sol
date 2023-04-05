// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error cannotGenerateInvoice();

contract PROJECT is ERC721URIStorage,Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; // Tracking the no of tokens minted
    Token private _token;
    
    //event
    event invoiceCreated(
        string tokenURI,
        address to,
        uint tokenId
    );
    
    event invoiceforTaskCreated(
        string tokenURI,
        address to,
        uint tokenId,
        uint[] tasks
    );

    event projectCreated(
        string  tokenURI,
        address from,
        address to, 
        uint numOfTask, 
        uint tokenId
    );

    constructor(Token token) ERC721("PROJECT", "PRJ") Ownable(){
        _token = token;
    }

    // This function is called when the project and token for task is to be created
    function createProject(address _to,string memory tokenURI,uint _numOfTask) external onlyOwner returns (uint256) {
        require(msg.sender != address(0),"Has Zero Address");
        require(_to != address(0),"Has Zero Address");
        _tokenIds.increment(); // Increment the tokenIds counter
        uint256 newTokenId = _tokenIds.current(); // The new token id is the current value of the counter
        _mint(_to, newTokenId); // mint the token to the sender
        _setTokenURI(newTokenId, tokenURI); // set the tokenURI to the tokenId.

        // numOfTaskPerProject[newTokenId] = _numOfTask;
        _token.mintToken(_to,_numOfTask,newTokenId);
        
        emit projectCreated(
            tokenURI,
            msg.sender,
            _to, 
            _numOfTask, 
            newTokenId
        );

        return newTokenId;
    }

    function generateInvoice(uint256 projectId,string memory tokenURI) external{
        address projectCreator=_token.getProjectCreator(projectId);
        //condition to check if all the task are marked true meaning completed for a project
        if(_token.burnTokensIfAllTasksCompleted(projectId)){
        _tokenIds.increment(); // Increment the tokenIds counter
        uint256 newTokenId = _tokenIds.current();
        _mint(projectCreator, newTokenId); // mint the token to the project owner/ project creator 
        _setTokenURI(newTokenId, tokenURI);
        emit invoiceCreated(tokenURI,projectCreator,newTokenId);
        }else{
            revert cannotGenerateInvoice();// error when some task or all task are not completed
        }
    }

        function generateInvoiceforTask(uint256 projectId, string memory tokenURI, uint[] memory taskIds) public {
            //getting the owner of project id
            address projectCreator=_token.getProjectCreator(projectId);
            bool allTasksCompleted = true; // flag to track if all tasks are completed
    
            // Loop through the array of taskIds
            for (uint i = 0; i < taskIds.length; i++) {
            // Get the address of the assignee for the task
            address assignee = _token.getAssignee(projectId, taskIds[i]);
            // Check if the assignee address is not zero
            require(assignee != address(0), "Assignee address not found");
            // Check if the task is marked as completed
            if (!_token.isTaskCompleted(projectId, taskIds[i], assignee)) {
                allTasksCompleted = false; // Update the flag if any task is not completed
                break; // Exit the loop if any task is not completed
            }
    }
    
        // Generate NFT and burn the tokens if all tasks are completed
        if (allTasksCompleted) {
            _tokenIds.increment(); // Increment the tokenIds counter
            uint256 newTokenId = _tokenIds.current();
            _mint(projectCreator, newTokenId); // Mint the token to the owner of project
            _setTokenURI(newTokenId, tokenURI);
            // Burn the tokens of completed tasks
            _token.burnToken(projectCreator, taskIds.length);
            emit invoiceforTaskCreated(tokenURI,projectCreator,newTokenId,taskIds);
        } else {
            revert("Not all tasks completed"); // Revert if any task is not completed
        }
    }
}