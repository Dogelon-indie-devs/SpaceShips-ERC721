// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SpaceShipsNFTs is ERC1155, Ownable {

  string private _BaseURI = "";
  string private _BluePrintURI = "";
  address private Owner; 
  uint private OneDayInBlockHeight = 7150;

    struct NewClass{
      uint8 ID;
      uint256 ETHPrice;
      uint256 DOGELONPrice;
      uint256 MaxSupply;
      uint256 CurrentSupply;
      uint BuildDays;
      bool Unlocked;  
    }  
    NewClass[] private Classes; 

    function InitializeClasses() private {
      Classes.push(NewClass(0, 0, 0, 0, 0, 0, false));  
    }

    constructor() ERC1155("") {
      Owner = msg.sender;
    }

    function uri(uint256 _TokenID) override public view returns (string memory) {    
      string memory MainURI = string(abi.encodePacked(_BaseURI, Strings.toString(_TokenID), ".json"));   
      return(MainURI);             
    }

    function AddNewClass(uint8 _ID, 
                         uint256 _ETHPrice, 
                         uint256 _DOGELONPrice, 
                         uint256 _MaxSupply, 
                         uint256 _CurrentSupply, 
                         uint _BuildDays, 
                         bool _Unlocked) public onlyOwner { 
      uint _BuildDaysInBlockHeight = _BuildDays * OneDayInBlockHeight;
      Classes.push(NewClass(_ID, _ETHPrice, _DOGELONPrice, _MaxSupply, _CurrentSupply, _BuildDaysInBlockHeight, _Unlocked)); 
    } 

    function SetBaseURI(string memory _NewURI) public onlyOwner {
      _BaseURI = _NewURI;
    }

    function SetBluePrintURI(string memory _NewURI) public onlyOwner {
      _BaseURI = _NewURI;
    }
    
}