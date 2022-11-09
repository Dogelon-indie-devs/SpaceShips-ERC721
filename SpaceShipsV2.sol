// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface IERC2981Royalties {
  function royaltyInfo(uint256 _tokenId, uint256 _value) external view returns (address _receiver, uint256 _royaltyAmount);
}

abstract contract ERC2981Base is ERC165, IERC2981Royalties {
  struct RoyaltyInfo {
    address recipient;
    uint24 amount;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    {
      return interfaceId == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract SpaceShipsNFTs is ERC1155, ERC2981Base, Ownable {

  RoyaltyInfo private _royalties;
  address constant private _DogelonTokenContract = 0x761D38e5ddf6ccf6Cf7c55759d5210750B5D60F3;
  string private _BaseURI = "";
  string private _BluePrintURI = "";
  address private Owner; 
  uint private OneDayInBlockHeight = 7150;
  bool private ETHMint = false;
  uint256 private TotalShipCount;  
  mapping (uint256 => uint8) private ShipClass;
  mapping (uint256 => uint) private ReadyAtBlockHeight;

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

    constructor(uint256 RoyaltiesPercentage) ERC1155("") {
      Owner = msg.sender;
      _setRoyalties(Owner, RoyaltiesPercentage);
      InitializeClasses();
    } 

    function _setRoyalties(address recipient, uint256 value) internal {
        uint256 RoyaltiesPercentageInBasePoints = value * 100;
        require(RoyaltiesPercentageInBasePoints <= 10000, "Royalties Too High!");
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }


    function royaltyInfo(uint256, uint256 value) external view override returns (address receiver, uint256 royaltyAmount)
    {
      RoyaltyInfo memory royalties = _royalties;
      receiver = royalties.recipient;
      royaltyAmount = (value * royalties.amount) / 10000;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981Base) returns (bool) {
      return super.supportsInterface(interfaceId);
    }

    function uri(uint256 _TokenID) override public view returns (string memory) {        
      string memory MainURI;
      if (block.number > ReadyAtBlockHeight[_TokenID]) {
        MainURI = string(abi.encodePacked(_BaseURI, Strings.toString(_TokenID), ".json"));    
      } else {
        MainURI = _BluePrintURI;   
      }     
      return(MainURI);             
    }

    function AddNewClass(uint256 _ETHPrice, 
                         uint256 _DOGELONPrice, 
                         uint256 _MaxSupply,  
                         uint _BuildDaysInBlockHeight, 
                         bool _Unlocked) public onlyOwner { 
      uint _TempBuildDaysInBlockHeight = _BuildDaysInBlockHeight * OneDayInBlockHeight;
      NewClass memory MyNewClass;
      MyNewClass.ETHPrice               = _ETHPrice;
      MyNewClass.DOGELONPrice           = _DOGELONPrice;
      MyNewClass.MaxSupply              = _MaxSupply;
      MyNewClass.BuildDaysInBlockHeight = _TempBuildDaysInBlockHeight;   
      MyNewClass.Unlocked               = _Unlocked;
      Classes.push(MyNewClass);
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

    function SetClassLock (bool _State, uint8 _Class) public onlyOwner {
      Classes[_Class].Unlocked = _State;
    }
    
    function GetExistingShipsNumber() public view returns (uint256) {    
      return(TotalShipCount);             
    }

    function GetClassByShipID(uint256 _ShipID) public view returns (uint8) {    
      uint8 ClassID = ShipClass[_ShipID];
      return(ClassID);             
    }

    function Mint_Using_ETH(uint8 _Class) public payable {   
      require(Classes[_Class].Unlocked, "Mint Is Locked For This Class!"); 
      require(ETHMint, "Mint Using ETH Is Disabled For Now, Try Using Dogelon!"); 
      require(msg.value >= Classes[_Class].ETHPrice, "Not Enough Funds!");  
      require(Classes[_Class].CurrentSupply < Classes[_Class].MaxSupply, "Max Supply Exceeded!");
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;        
      }      
      uint256 _TokenID = TotalShipCount;     
      _mint(msg.sender, _TokenID, 1, ""); 
      ShipClass[_TokenID] = _Class;
      ReadyAtBlockHeight[_TokenID] = block.number + Classes[_Class].BuildDaysInBlockHeight;
    }

    function Mint_Using_DOGELON(uint8 _Class) public payable {
      require(Classes[_Class].Unlocked, "Mint Is Locked For This Class!");
      require(Classes[_Class].CurrentSupply < Classes[_Class].MaxSupply, "Max Supply Exceeded!");     
      IERC20(_DogelonTokenContract).transferFrom(msg.sender, Owner, Classes[_Class].DOGELONPrice);      
      unchecked {
        Classes[_Class].CurrentSupply += 1;  
        TotalShipCount += 1;          
      }     
      uint256 _TokenID = TotalShipCount;     
      _mint(msg.sender, _TokenID, 1, "");
      ShipClass[_TokenID] = _Class;
      ReadyAtBlockHeight[_TokenID] = block.number + Classes[_Class].BuildDaysInBlockHeight;
    }

}