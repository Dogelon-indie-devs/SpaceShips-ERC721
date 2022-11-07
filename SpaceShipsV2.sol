// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceShipsNFTs is ERC1155, Ownable {
  
  address constant private _DogelonTokenContract = 0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3;
  string private _BaseURI = "";
  string private _BluePrintURI = "";
  address private Owner; 
  uint private OneDayInBlockHeight = 7150;
  bool private ETHMint = false;
  uint256 private TotalShipCount;

    struct NewClass{
      uint256 ETHPrice;
      uint256 DOGELONPrice;
      uint256 MaxSupply;
      uint256 CurrentSupply;
      uint BuildDaysInBlockHeight;
      bool Unlocked;  
    }  
    NewClass[] private Classes; 

    function InitializeClasses() private {
       NewClass memory MyNewClass;
       MyNewClass.ETHPrice = 0;
       MyNewClass.DOGELONPrice = 0;
       MyNewClass.MaxSupply = 0;
       MyNewClass.BuildDaysInBlockHeight = 0;      
       Classes.push(MyNewClass);
    }

    constructor() ERC1155("") {
      Owner = msg.sender;
    }

    function uri(uint256 _TokenID) override public view returns (string memory) {    
      string memory MainURI = string(abi.encodePacked(_BaseURI, Strings.toString(_TokenID), ".json"));   
      return(MainURI);             
    }

    function AddNewClass(uint256 _ETHPrice, 
                         uint256 _DOGELONPrice, 
                         uint256 _MaxSupply, 
                         uint256 _CurrentSupply, 
                         uint _BuildDaysInBlockHeight, 
                         bool _Unlocked) public onlyOwner { 
      uint _TempBuildDaysInBlockHeight = _BuildDaysInBlockHeight * OneDayInBlockHeight;
      Classes.push(NewClass(_ETHPrice, _DOGELONPrice, _MaxSupply, _CurrentSupply, _TempBuildDaysInBlockHeight, _Unlocked)); 
    } 

    function SetBaseURI(string memory _NewURI) public onlyOwner {
      _BaseURI = _NewURI;
    }

    function SetBluePrintURI(string memory _NewURI) public onlyOwner {
      _BaseURI = _NewURI;
    }
    
    function WithdrawETH () external onlyOwner {
      payable(Owner).transfer(address(this).balance);  
    }

    function WithdrawDOGELON (uint256 _Amount) external onlyOwner {
      IERC20(_DogelonTokenContract).transfer(Owner, _Amount);
    }

    function SetETHMint (bool _State) public onlyOwner {
      ETHMint = _State;
    }

    function Mint_Using_ETH(uint8 _Class) public payable {   
      require(ETHMint, "Mint Using ETH Is Disabled For Now, Try Using Dogelon!"); 
      require(msg.value >= Classes[_Class].ETHPrice, "Not Enough Funds!");            
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;        
      }      
      uint256 _TokenID = TotalShipCount;
      _mint(msg.sender, _TokenID, 1, "");
    }

    function Mint_Using_DOGELON(uint8 _Class) public payable {
      IERC20(_DogelonTokenContract).transferFrom(msg.sender, Owner, Classes[_Class].DOGELONPrice);      
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;          
      }     
      uint256 _TokenID = TotalShipCount;
      _mint(msg.sender, _TokenID, 1, "");
    }

}