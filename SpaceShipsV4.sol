// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "hardhat/console.sol"; // For Test Only

contract SpaceShipsNFTs is ERC721, ERC2981, Ownable {

  using Strings for uint256;
  uint256 private LastMintedShipID;
  address constant private _DogelonTokenContract = 0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3;
  string private _BaseURI = "";
  string private _BluePrintURI = "";
  address private Owner; 
  uint private OneDayInBlockHeight = 7150;
  uint256 private TotalShipCount;  
  mapping (uint256 => uint8) private ShipClass;
  mapping (uint256 => uint)  private ReadyAtBlockHeight;
  mapping (address => bool)  private Whitelisted;

    struct NewClass{
      uint256 DOGELONPrice;
      uint256 MaxMintSupply;
      uint256 CurrentSupply;
      uint BuildDaysInBlockHeight;
      bool Unlocked;  
    }  
    NewClass[] private Classes; 

    function InitializeClasses() private {
      NewClass memory MyNewClass;  
      Classes.push(MyNewClass);
    }
  
    constructor() ERC721("SPACESHIPSNFTS", "SPACESHIPS") {
      Owner = msg.sender;
      InitializeClasses();
      _setDefaultRoyalty(Owner, 1000);
    } 

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
      return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
    
    function SetRoyalty(address _Receiver, uint96 _RoyaltyPercentageInBasePoints) public onlyOwner {
      _setDefaultRoyalty(_Receiver, _RoyaltyPercentageInBasePoints);
    }

    function tokenURI(uint256 tokenId) override public virtual view returns (string memory) {
      _requireMinted(tokenId);       
      if (block.number > ReadyAtBlockHeight[tokenId]) {
        return string(abi.encodePacked(_BaseURI, tokenId.toString(), ".json"));
      }
      return _BluePrintURI;
    }

    function AddNewClass(uint256 _DOGELONPrice, 
                         uint256 _MaxMintSupply,  
                         uint _BuildDays) public onlyOwner { 
      uint _TempBuildDaysInBlockHeight  = _BuildDays * OneDayInBlockHeight;
      NewClass memory MyNewClass;
      MyNewClass.DOGELONPrice           = _DOGELONPrice;
      MyNewClass.MaxMintSupply          = _MaxMintSupply;
      MyNewClass.BuildDaysInBlockHeight = _TempBuildDaysInBlockHeight;   
      MyNewClass.Unlocked               = true;
      Classes.push(MyNewClass);
    } 
    
    function GetClasses() public view returns (NewClass[] memory) {
      return Classes;
    }

    function SetBaseURI(string memory _NewURI) public onlyOwner {
      _BaseURI = _NewURI;
    }

    function SetBluePrintURI(string memory _NewURI) public onlyOwner {
      _BluePrintURI = _NewURI;
    }

    function WithdrawETH () external onlyOwner {
      payable(Owner).transfer(address(this).balance);  
    }

    function RescueTokens (address _TokenAddress, uint256 _Amount) external onlyOwner {
      IERC20(_TokenAddress).transfer(Owner, _Amount);
    }

    function SetClassUnlocked (bool _State, uint8 _Class) public onlyOwner {
      Classes[_Class].Unlocked = _State;
    }
    
    function GetTotalShipCount() public view returns (uint256) {    
      return(TotalShipCount);             
    }

    function GetClassByShipID(uint256 _ShipID) public view returns (uint8) {    
      uint8 ClassID = ShipClass[_ShipID];
      return(ClassID);             
    }

    function SetExternalContractWhitelist(address _Contract, bool _State) public onlyOwner {
      Whitelisted[_Contract] = _State;
    }

    function Whitelisted_contract_mint(address NewTokenOwner, uint8 _Class) public {
      require(Whitelisted[msg.sender] || msg.sender == Owner, "Only Whitelisted Contracts Can Use This Mint Method!"); 
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;          
      }     
      uint256 _TokenID = TotalShipCount;     
      _mint(NewTokenOwner, _TokenID);
      ShipClass[_TokenID] = _Class;
      LastMintedShipID = _TokenID;
      ReadyAtBlockHeight[_TokenID] = block.number + Classes[_Class].BuildDaysInBlockHeight;
    }

    function Mint_Using_DOGELON(uint8 _Class) public payable {
      require(Classes[_Class].Unlocked, "Minting Is Locked For This Class!");
      require(Classes[_Class].CurrentSupply < Classes[_Class].MaxMintSupply, "Max Supply Exceeded!");   
      IERC20(_DogelonTokenContract).transferFrom(msg.sender, Owner, Classes[_Class].DOGELONPrice);      
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;          
      }     
      uint256 _TokenID = TotalShipCount;     
      _mint(msg.sender, _TokenID);
      ShipClass[_TokenID] = _Class;
      LastMintedShipID = _TokenID;
      ReadyAtBlockHeight[_TokenID] = block.number + Classes[_Class].BuildDaysInBlockHeight;
    }

}