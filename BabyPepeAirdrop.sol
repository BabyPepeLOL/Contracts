// SPDX-License-Identifier: MIT

// **********************************&@****@@############@*************************
// ******************************%@##########################@*********************
// **************************@######### # #/#.##(#/###########@********************
// *************************###################################********************
// ************************########.####,# #### ### *#### #####********************
// ***********************@####################################@*******************
// ************************((@###########&@%###################@*******************
// **********************((((((((%###&@@@@@########@@@@&%&@@@@@####&@**************
// ********************@(((((((((((((((((((@(((((((((((((((((((***(&####***********
// *******************@(((((((((@(@            @((((((@.      /@@******************
// ******************((((((((((        @@@@@@@    @/               .***************
// ****************@(((((((((@      @@@@@@@    @@  @  .@@@@@@@@@@@    /************
// ***************#(((((((((@      @@@@@        @@@  @@@         @@@   ************
// **************/(((((((((((@     @@@@@@@     @@@@ @@@@@@@     @@@@  @************
// **************(((((((((((((((   @@@@@@ @@@@@@@@& *@@@@  @@@@@@@@@ @*************
// *************(((((((((((((((((((% @@@@@@@@@@@@(((# @@@@@@@@@@@@(@***************
// ************(((((((((((((((((((((@(((((((@((((((((((((@@@@((@@******************
// ***********@(((((((((((((((((((#(((((@((((@((((((((((@(((((((@******************
// ************@((((((((((((((@(((((((@(((((((((((((((((((((@@(((******************
// ***************((((((((((((((((&%(((((((((((((((((((((((((@@********************
// ********************@((((((((((((((((((@@(((@(((((((((((@(@*********************
// ************************************#@@@@@@(((((((((((((@***********************
// *******************************************&(((@((((@@((@***********************
// *********************************************(((((((((((************************
// ***********************************************((@@/****************************

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PepeNFTandAirdrop is ERC721, Ownable {
    using Address for address;

    IERC20 public babyPepeToken;
    IERC20 public pepeToken;
    mapping(address => bool) public hasMinted;
    mapping(address => bool) public hasClaimed;

    uint256 public totalAirdropSupply;
    uint256 public mintedCount;
    uint256 public minPepeBalance;
    uint256 public minEthBalance;

    bool public mintPaused = true;
    bool public claimPaused = true;

    event Minted(address indexed user, uint256 tokenId);
    event Claimed(address indexed user, uint256 amount);

    constructor(address _babyPepeToken, address _pepeToken) ERC721("Pepe Holder NFT", "PEPENFT") {
        require(_babyPepeToken.isContract(), "_babyPepeToken must be a contract address");
        require(_pepeToken.isContract(), "_pepeToken must be a contract address");

        babyPepeToken = IERC20(_babyPepeToken);
        pepeToken = IERC20(_pepeToken);
    }

    function setTotalAirdropSupply(uint256 _totalAirdropSupply) public onlyOwner {
        totalAirdropSupply = _totalAirdropSupply;
    }

    function setMinPepeBalance(uint256 _minPepeBalance) public onlyOwner {
        minPepeBalance = _minPepeBalance;
    }

    function setMinEthBalance(uint256 _minEthBalance) public onlyOwner {
        minEthBalance = _minEthBalance;
    }

    function pauseMint() public onlyOwner {
        mintPaused = true;
    }

    function unpauseMint() public onlyOwner {
        mintPaused = false;
    }

    function pauseClaim() public onlyOwner {
        claimPaused = true;
    }

    function unpauseClaim() public onlyOwner {
        claimPaused = false;
    }

    function mint() public {
        require(!mintPaused, "Minting is paused");
        require(!hasMinted[msg.sender], "Address has already minted");
        require(pepeToken.balanceOf(msg.sender) >= minPepeBalance, "Must hold minimum Pepe");
        require(msg.sender.balance >= minEthBalance, "Must hold minimum Ether");

        mintedCount++;
        _mint(msg.sender, mintedCount);
        hasMinted[msg.sender] = true;

        emit Minted(msg.sender, mintedCount);
    }

    function claim() public {
        require(!claimPaused, "Claiming is paused");
        require(hasMinted[msg.sender], "Must mint NFT first");
        require(!hasClaimed[msg.sender], "Address has already claimed");

        uint256 amount = totalAirdropSupply / mintedCount;
        require(babyPepeToken.balanceOf(address(this)) >= amount, "Not enough tokens for airdrop");

        babyPepeToken.transfer(msg.sender, amount);
        hasClaimed[msg.sender] = true;

        emit Claimed(msg.sender, amount);
    }
}
