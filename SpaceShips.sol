// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DogelonSpaceShipNFT is ERC1155, Ownable {

    struct NewGeneration{
      uint256 ID;
      string Uri;
      string BluePrintUri;
      uint256 Price;
      uint256 MaxSupply;
      bool Unlocked;  
    }  
    NewGeneration[] private Generations; 
    mapping (uint256 => bool) MintedTokens;

    constructor() ERC1155("") {}
  
    function AddNewGeneration(uint256 _ID, string memory _Uri, string memory _BluePrintUri, uint256 _Price, uint256 _MaxSupply, bool _Unlocked) public onlyOwner { 
      Generations.push(NewGeneration(_ID, _Uri, _BluePrintUri, _Price, _MaxSupply, _Unlocked)); 
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
      if (MintedTokens[_TokenID]) {
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

    function mint(address _Recipient, uint256 _TokenID, uint256 _Amount) public payable {
      require(IsGenerationUnlocked(ExtractGenerationIDByTokenID(_TokenID)), "This Generation Is Not Unlocked Yet!");
      require(_TokenID >= 1, "Invalid Token ID!");
      require(Generations[Generations.length - 1].MaxSupply >= _TokenID, "Invalid Token ID!"); 
      require(MintedTokens[_TokenID] == false, "Token Already Minted!"); 
      require(msg.value >= Generations[ExtractGenerationIDByTokenID(_TokenID) - 1].Price * _Amount, "Not Enough Funds!");
      
      _mint(_Recipient, _TokenID, _Amount, "");
      MintedTokens[_TokenID] = true;
    }
}