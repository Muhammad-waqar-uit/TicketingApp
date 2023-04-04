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
    // mapping (uint => uint) numOfTaskPerProject;
    event invoiceCreated(
        string tokenURI,
        address to,
        uint tokenId
    );
    event projectCreated(
        string  tokenURI,
        address from,
        address to, 
        uint numOfTask, 
        uint tokenId
    );
    event invoiceofTask(
        string tokenURI,
        address to,
        uint tokenId,
        uint[] arrtask
    ); 
    constructor(Token token) ERC721("PROJECT", "PRJ") Ownable(){
        _token = token;
    }

    // This function is called when the token is to be created
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
        address sender=msg.sender;//callers address
        //condition to check if all the task are marked true meaning completed for a project
        if(_token.burnTokensIfAllTasksCompleted(projectId,sender)){
        _tokenIds.increment(); // Increment the tokenIds counter
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId); // mint the token to the sender
        _setTokenURI(newTokenId, tokenURI);
        emit invoiceCreated(tokenURI,msg.sender, newTokenId);
        }else{
            revert cannotGenerateInvoice();
        }
    }

        function generateInvoiceforTask(uint256 projectId,string memory tokenURI,uint[] memory arrtask) external{
            for(uint i=0;i<arrtask.length;i++){
                //address of each assignee for the task no
                address assignee = _token.getAssignee(projectId, arrtask[i]);
                //checking if address is not a zero address
                require(assignee != address(0), "Assignee address not found");
                //checking if that task is marked completed or not
                _token.isTaskCompleted(projectId,arrtask[i],assignee);
                _tokenIds.increment(); // Increment the tokenIds counter
                uint256 newTokenId = _tokenIds.current();
                _mint(msg.sender, newTokenId); // mint the token to the sender
                _setTokenURI(newTokenId, tokenURI);
                emit invoiceofTask(tokenURI, msg.sender, newTokenId, arrtask);
            }
            //address of sender/project owner
             address sender=msg.sender;
             //burning the token of tasks
            _token.burnToken(sender,arrtask.length);
        }

}