//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';


// create a contract called NFTStack to hold the logic for the staking contract for ERC 1115

// https://thirdweb.com/contracts/deploy/QmSpRcjKbJYfTcaUsEwBqDdrYDKZC4uyNZ2FfS9EGSioWg


contract NFTStack is ReentrancyGuard {
    
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardsToken;
    IERC1155 public immutable nftCollection;
   
    constructor(
        IERC20 _token,
        IERC1155 _nft
       
    ) {
        rewardsToken = _token;
        nftCollection = _nft;
        
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }

    struct Staker {

        uint256 amountStaked;

        StakedToken[] stakedTokens;


        uint256 timeOfLastUpdate;


        uint256 unclaimReawrds;


    }


    uint256 public rewardsPerHour = 100000;


    mapping(address => Staker) public stakers;


    mapping(uint256 => address) public stakerAddress;




    function stake (uint256 _tokenId) external nonReentrant {

       if(stakers[msg.sender].amountStaked > 0) {

            uint256 rewards = calculateRewards(msg.sender);

            stakers[msg.sender].unclaimReawrds += rewards;

        }

        stakers[msg.sender].amountStaked += 1;

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;

        stakers[msg.sender].stakedTokens.push(StakedToken(msg.sender, _tokenId));

        stakerAddress[_tokenId] = msg.sender;

        nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");

    }






    function unstake (uint256 _tokenId) external nonReentrant {

        require(stakerAddress[_tokenId] == msg.sender, "You are not the owner of this token");

        uint256 rewards = calculateRewards(msg.sender);

        stakers[msg.sender].unclaimReawrds += rewards;

        stakers[msg.sender].amountStaked -= 1;

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;

        for(uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {

            if(stakers[msg.sender].stakedTokens[i].tokenId == _tokenId) {

                stakers[msg.sender].stakedTokens[i] = stakers[msg.sender].stakedTokens[stakers[msg.sender].stakedTokens.length - 1];

                stakers[msg.sender].stakedTokens.pop();

                break;

            }

        }

        delete stakerAddress[_tokenId];

        nftCollection.safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");



    }






    function claimRewards() external nonReentrant {

               uint256 rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimReawrds;

        require(rewards > 0, 'You do not have any rewards to claim');

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;

        stakers[msg.sender].unclaimReawrds = 0;

        rewardsToken.safeTransfer(msg.sender, rewards);

    }






    function calculateRewards(address _staker) public view returns(uint256) {

        uint256 timeSinceLastUpdate = block.timestamp - stakers[_staker].timeOfLastUpdate;

        uint256 rewards = (timeSinceLastUpdate * rewardsPerHour * stakers[_staker].amountStaked) / 3600;

        return rewards;

    }

    function availableRewards(address _staker) external view returns(uint256) {

        uint256 rewards = calculateRewards(_staker) + stakers[_staker].unclaimReawrds;

        return rewards;

    }


    function setRewardsPerHour(uint256 _rewardsPerHour) external {

        rewardsPerHour = _rewardsPerHour;

    }


    function getStakeTokens(address _staker) public view returns(StakedToken[] memory) {

        if(stakers[_staker].amountStaked > 0) {

            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_staker].amountStaked);

            uint _index = 0;


            for(uint256 i = 0; i < stakers[_staker].stakedTokens.length; i++) {

                if(stakers[_staker].stakedTokens[i].staker != address(0)) {

                    _stakedTokens[_index] = stakers[_staker].stakedTokens[i];

                    _index++;

                }

            }

            return _stakedTokens;

        }else{
            return new StakedToken[](0);
        }

    }



    function getStakerAddress(uint256 _tokenId) external view returns(address) {

        return stakerAddress[_tokenId];

    }


    function getStakerInfo(address _staker) external view returns(Staker memory) {

        return stakers[_staker];

    }


    function getStakerAmountStaked(address _staker) external view returns(uint256) {

        return stakers[_staker].amountStaked;

    }


    function getStakerUnclaimRewards(address _staker) external view returns(uint256) {

        return stakers[_staker].unclaimReawrds;

    }


    function getStakerTimeOfLastUpdate(address _staker) external view returns(uint256) {

        return stakers[_staker].timeOfLastUpdate;

    }



}


// create a contract called NFTStackFactory to deploy the staking contract for ERC 1115

contract NFTStackFactory {

    event NFTStackCreated(address indexed nftStack, address indexed rewardsToken, address indexed nftCollection);

    function createNFTStack(IERC20 _rewardsToken, IERC1155 _nftCollection) external returns(address) {

        NFTStack nftStack = new NFTStack(_rewardsToken, _nftCollection);

        emit NFTStackCreated(address(nftStack), address(_rewardsToken), address(_nftCollection));

        return address(nftStack);

    }

}














