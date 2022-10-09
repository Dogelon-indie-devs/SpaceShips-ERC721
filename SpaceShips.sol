// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DogelonSpaceShipNFT is ERC1155, Ownable {
    mapping (uint256 => string) private URIs;
 
    struct NewGeneration{
      uint256 ID;
      string Uri;
      uint256 Price;
      uint256 MaxSupply;
      bool Unlocked;  
    }  
    NewGeneration[] private Generations; 

    constructor() ERC1155("") {}
  
    function AddNewGeneration(uint256 _ID, string memory _Uri, uint256 _Price, uint256 _MaxSupply, bool _Unlocked) public onlyOwner { 
      Generations.push(NewGeneration(_ID, _Uri, _Price, _MaxSupply, _Unlocked));
      //setTokenUri(0, _Uri);
     }  

    function UnlockGeneration(uint256 _GenerationID) public onlyOwner {
      Generations[_GenerationID - 1].Unlocked = true;
    }

    function LockGeneration(uint256 _GenerationID) public onlyOwner {
      Generations[_GenerationID - 1].Unlocked = false;
    }

    function GenerationsCount() public view returns (uint256) {
      return(Generations.length);
    }

    function IsGenerationUnlocked(uint256 _GenerationID) public view returns (bool) {
      return(Generations[_GenerationID - 1].Unlocked);
    }

    function ExtractGenerationUri(uint256 _GenerationID) public view returns (string memory) {
      return(Generations[_GenerationID - 1].Uri);
    }

    function uri(uint256 _TokenID) override public view returns (string memory) {
      return(URIs[_TokenID]);
    }

    function setTokenUri(uint256 _TokenID, string memory _uri) public onlyOwner {
      URIs[_TokenID] = _uri;
    }

    function mint(address _Recipient, uint256 _TokenID, uint256 _Amount) public onlyOwner {
      _mint(_Recipient, _TokenID, _Amount, "");
    }
}