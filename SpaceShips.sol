// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DogelonSpaceShipNFT is ERC1155, Ownable {
    
    address public Owner;
    struct NewGeneration{
      uint256 ID;
      string Uri;
      string BluePrintUri;
      uint256 Price;
      uint256 MaxSupply;
      uint256 CurrentSupply;
      bool Unlocked;  
    }  
    NewGeneration[] private Generations; 

    mapping (uint256 => bool) private FullyBuiltedTokens;
    mapping (uint256 => bool) private MintedTokens;
    mapping (uint256 => address) private TokensOwners;

    constructor() ERC1155("") {
      Owner = msg.sender;
    }
  
    function AddNewGeneration(uint256 _ID, string memory _Uri, string memory _BluePrintUri, uint256 _Price, uint256 _MaxSupply, bool _Unlocked) public onlyOwner { 
      uint256 _CurrentSupply = 0;    
      Generations.push(NewGeneration(_ID, _Uri, _BluePrintUri, _Price, _MaxSupply, _CurrentSupply, _Unlocked)); 
     }  

    function UnlockGeneration(uint256 _GenerationID) public onlyOwner {
      Generations[_GenerationID - 1].Unlocked = true;
    }

    function LockGeneration(uint256 _GenerationID) public onlyOwner {
      Generations[_GenerationID - 1].Unlocked = false;
    }

    function GenerationsCount() public view onlyOwner returns (uint256) {
      return(Generations.length);
    }

    function ExtractGenerationIDByTokenID(uint256 _TokenID) private view returns (uint256) {
      require(Generations.length >= 1, "Generations Empty!");
      require(_TokenID >= 1, "Invalid Token ID!");
      require(Generations[Generations.length - 1].MaxSupply >= _TokenID, "Invalid Token ID!");  
      uint256 I = 0;
      uint256 GenerationID = 0;
      uint256 GenerationsArrayLength = Generations.length - 1;      
      while (I <= GenerationsArrayLength) {       
        if (Generations[I].MaxSupply >= _TokenID) {
          GenerationID = Generations[I].ID;
          break;
        } 
        I++;
      }
      return(GenerationID); 
    }

    function IsGenerationUnlocked(uint256 _GenerationID) private view returns (bool) {
      return(Generations[_GenerationID - 1].Unlocked);
    }

    function ExtractGenerationUri(uint256 _GenerationID) private view returns (string memory) {
      return(Generations[_GenerationID - 1].Uri);
    }

    function uri(uint256 _TokenID) override public view returns (string memory) {    
      string memory MainURI;
      if (FullyBuiltedTokens[_TokenID]) {
        MainURI = string(abi.encodePacked(ExtractGenerationUri(ExtractGenerationIDByTokenID(_TokenID)), Strings.toString(_TokenID), ".json"));   
      } else {
        MainURI = Generations[ExtractGenerationIDByTokenID(_TokenID) - 1].BluePrintUri;   
      }     
      return(MainURI);             
    }
   
    function ChangeGenerationURI(uint256 _GenerationID, string memory _NewURI) public onlyOwner{
      Generations[_GenerationID - 1].Uri = _NewURI; 
    }

    function ChangeGenerationBluePrintURI(uint256 _GenerationID, string memory _NewURI) public onlyOwner{
      Generations[_GenerationID - 1].BluePrintUri = _NewURI; 
    }

    function SetTokenAsFullyBuilted(uint256 _TokenID) public {
      require(TokensOwners[_TokenID] == msg.sender || msg.sender == Owner, "Only Owner Can Fully Built Tokens!");
      FullyBuiltedTokens[_TokenID] = true;
    }

    function GetGenerationCurrentSupply(uint256 _GenerationID) public view onlyOwner returns (uint256) {
      return(Generations[_GenerationID - 1].CurrentSupply);
    }

    function Withdraw(address _TokenContract, uint256 _Amount, bool _ETHWithdraw) external onlyOwner {
      IERC20(_TokenContract).transfer(msg.sender, _Amount);
      if (_ETHWithdraw) {
        payable(msg.sender).transfer(address(this).balance);  
      }   
    }

    function mint(uint256 _TokenID, bool _ETHMint) public payable {
      require(IsGenerationUnlocked(ExtractGenerationIDByTokenID(_TokenID)), "This Generation Is Not Unlocked Yet!");
      require(_TokenID >= 1, "Invalid Token ID!");
      require(Generations[Generations.length - 1].MaxSupply >= _TokenID, "Invalid Token ID!"); 
      require(MintedTokens[_TokenID] == false, "Token Already Minted!"); 
      require(msg.value >= Generations[ExtractGenerationIDByTokenID(_TokenID) - 1].Price, "Not Enough Funds!");   
      _mint(msg.sender, _TokenID, 1, "");
      MintedTokens[_TokenID] = true;
      TokensOwners[_TokenID] = msg.sender;
      unchecked {
        Generations[ExtractGenerationIDByTokenID(_TokenID) - 1].CurrentSupply += 1;    
      }
    }
}