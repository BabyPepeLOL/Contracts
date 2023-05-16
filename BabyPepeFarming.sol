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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BabyPepeLiquidityMining is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public babyPepeToken;
    IERC20 public lpToken;

    uint256 public epochDuration = 1 days;
    uint256 public rewardRate;
    uint256 public lastEpochUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalStaked;

    mapping(address => uint256) public userEpoch;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public staked;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _babyPepeToken, address _lpToken, uint256 _rewardRate) {
    require(Address.isContract(_babyPepeToken), "_babyPepeToken must be a contract address");
    require(Address.isContract(_lpToken), "_lpToken must be a contract address");

    babyPepeToken = IERC20(_babyPepeToken);
    lpToken = IERC20(_lpToken);
    rewardRate = _rewardRate;
    lastEpochUpdateTime = block.timestamp;
    }

    function currentEpoch() public view returns (uint256) {
        return (block.timestamp - lastEpochUpdateTime) / epochDuration + 1;
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        totalStaked += amount;
        staked[msg.sender] += amount;
        userEpoch[msg.sender] = currentEpoch();
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        totalStaked -= amount;
        staked[msg.sender] -= amount;
        lpToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant {
        require(userEpoch[msg.sender] < currentEpoch(), "Cannot claim reward for current epoch");
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            babyPepeToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function earned(address account) public view returns (uint256) {
        if (userEpoch[account] >= currentEpoch()) {
            return 0;
        }
        return
            (staked[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) /
            1e18 +
            rewards[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastEpochUpdateTime) * rewardRate * 1e18) / totalStaked);
    }

    function updateReward() internal {
        if (block.timestamp >= lastEpochUpdateTime + epochDuration) {
            rewardPerTokenStored = rewardPerToken();
            lastEpochUpdateTime += epochDuration;
        }
    }
}

