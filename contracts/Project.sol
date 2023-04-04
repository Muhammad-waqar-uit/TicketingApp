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

    // function taskCompleted(uint amountOfTaskCompleted,uint _tokenId) external {
    //     address projectOwner = ownerOf(_tokenId);
    //     require(_token.balanceOf(projectOwner) >= amountOfTaskCompleted , "Balance is invalid");
    //     _token.burnToken(projectOwner, amountOfTaskCompleted);
    // }

    function generateInvoice(uint256 projectId,string memory tokenURI) external{
        address sender=msg.sender;//callers address
        //condition to check if all the task are marked true for a project
        if(_token.burnTokensIfAllTasksCompleted(projectId,sender)){
        _tokenIds.increment(); // Increment the tokenIds counter
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId); // mint the token to the sender
        _setTokenURI(newTokenId, tokenURI);
        }else{
            revert cannotGenerateInvoice();
        }
       
    }
//    function generateInvoice(uint256 projectId, string memory tokenURI) external {
//     bytes memory payload = abi.encodeWithSignature("burnTokensIfAllTasksCompleted(uint256)", projectId);
//     (bool success,) = address(_token).delegatecall(payload);
//     if (!success) {
//         revert cannotGenerateInvoice();
//     }
//     _tokenIds.increment();
//     uint256 newTokenId = _tokenIds.current();
//     _mint(msg.sender, newTokenId);
//     _setTokenURI(newTokenId, tokenURI);
// }

}