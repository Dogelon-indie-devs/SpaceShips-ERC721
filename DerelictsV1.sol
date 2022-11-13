// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract DerelictsNFTs is ERC1155, ERC2981, Ownable {

  uint256 SalvageCostDogelon = 10000000;
  uint256 private LastMintedShipID;
  address constant private _DogelonTokenContract = 0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3;
  string private _DerelictURI = "";
  address private Owner; 
  bool private PauseSalvageRights = false;
  uint256 private TotalShipCount;  
  mapping (uint256 => bool) private ShipDerelict;  
  mapping (address => bool) private SalvageRights;

    constructor() ERC1155("") {
      Owner = msg.sender;
      InitializeClasses();
      _setDefaultRoyalty(Owner, 1000);
    } 

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
      return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
    
    function SetRoyalty(address _Receiver, uint96 _RoyaltyPercentageInBasePoints) public onlyOwner {
      _setDefaultRoyalty(_Receiver, _RoyaltyPercentageInBasePoints);
    }
    
    function uri(uint256 _TokenID) override public view returns (string memory) {   
      return( _DerelictURI );             
    }

    function SetSalvageRightsState(bool _State) public onlyOwner {
      PauseSalvageRights = _State;
    }

    function GiftSalvageRights(address _Player) public onlyOwner {
      SalvageRights[_Player] = true;
    }
    
    function WithdrawETH () external onlyOwner {
      payable(Owner).transfer(address(this).balance);  
    }

    function WithdrawDOGELON (uint256 _Amount) external onlyOwner {
      IERC20(_DogelonTokenContract).transfer(Owner, _Amount);
    }

    function ChangeSalvageCosts(uint256 _Dogelon, uint256 _Ether) public onlyOwner {    
      SalvageCostDogelon = _Dogelon;
      SalvageCostEther   = _Ether;          
    }
    
    function GetSalvageCosts() public view onlyOwner returns (uint256, uint256) {    
      return(SalvageCostDogelon, SalvageCostEther);        
    }
    
    function SetShipAsDerelict(uint256 _ShipID) public onlyOwner {    
      ReadyAtBlockHeight[_ShipID] = block.timestamp;
      ShipDerelict[_ShipID] = true;     
    }
    
    function PlayerHasSalvageRights(address _Player) public view returns (bool) {    
      return(SalvageRights[_Player]);        
    } 
 
    function BuySalvageRightsDogelon() payable external {    
      if (!SalvageRights[msg.sender]) {
        require(IERC20(_DogelonTokenContract).balanceOf(msg.sender) >= SalvageCostDogelon, "Not Enough Funds!");
        IERC20(_DogelonTokenContract).transferFrom(msg.sender, Owner, SalvageCostDogelon); 
        SalvageRights[msg.sender] = true;
      }     
    }

    function BuySalvageRightsEther() payable external {   
      if (!SalvageRights[msg.sender]) {   
        require(msg.value >= SalvageCostEther, "Not Enough Funds!"); 
        payable(Owner).transfer(SalvageCostEther);  
        SalvageRights[msg.sender] = true;
      }     
    }

    function MintDerelictAndTransferOwnershipEther(uint8 _Class, address _Player) public onlyOwner {    
      if (SalvageRights[_Player]) { 
        Mint_Using_ETH(_Class);
        safeTransferFrom(msg.sender, _Player, LastMintedShipID, 1, "");
        SalvageRights[_Player] = false;  
      }
    }
    
    function MintDerelictAndTransferOwnershipDogelon(uint8 _Class, address _Player) public onlyOwner {    
      if (SalvageRights[_Player]) { 
        Mint_Using_DOGELON(_Class);
        safeTransferFrom(msg.sender, _Player, LastMintedShipID, 1, "");
        SalvageRights[_Player] = false;  
      }
    }

    function SetDerelictURI(string memory _Uri) public onlyOwner {    
      _DerelictURI = _Uri; 
    }
}