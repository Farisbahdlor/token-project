// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenX {
    string public name = "TokenX"; // Place your token name here
    string public symbol = "TX"; // Place your token symbol here
    uint8 public decimals = 18;
    
    uint256 public totalSupply = 280397 * 10 ** 27; // 280397 billion tokens
    uint256 public initialSupply = 280397 * 10 **24; // 280397 million tokens
    uint256 public currentSupply; // Current token suplay circulating available in market
    
    uint256 public burnRate; // Initial burn rate: 0.000002828%
    uint256 public percentageBurn = 1000000000;
    uint256 public initialBurnRate = 2828; // Initial burn rate: 0.000002828%
    uint256 public halvingInterval = 282828; // Halving occurs every 282828 block transactions

    uint256 public baseFee = initialBurnRate * percentageBurn; // Base fee is initial burn rate
    
    uint256 public blockRewardRatio = 1 * 10 ** 21;
    uint256 public initialBlockReward = 280397; // Initial block reward: 280.397.000 tokens
    uint256 public blockReward; // The rest of token when initialize place here as reserve for reward and burn
    uint256 public blockCount; // Count the block created when transaction occur
    
    address public burnAddress = 0x0000000000000000000000000000000000280397; // Place your burn address here
    address public contractReward = 0x0000000000000000000000000000000000888888; // Place your contract reserve address here
    uint public addressCount=0;

    struct Holder{
        address holderAddress;
        uint256 balanceOf;
    }
    Holder[] private holders;

    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event CheckBalance(address indexed client, uint256 value);
    event Burn(address indexed from,address indexed to, uint256 value);
    event Reward(address indexed from,address indexed to, uint256 value);
    event Check(address indexed from, uint256 valuefrom,address indexed to, uint256 valueto);

    constructor() {
        holders.push(Holder({holderAddress : burnAddress, balanceOf : 0}));
        
        addressCount ++;
        holders.push(Holder({holderAddress : contractReward, balanceOf : (totalSupply - initialSupply)}));
        
        addressCount ++;
        holders.push(Holder({holderAddress : msg.sender, balanceOf : (initialSupply)}));
        
        currentSupply = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
        blockReward = initialBlockReward;
        burnRate = initialBurnRate;
        blockCount = 0;
    }
    
    function transfer(address _to, uint256 _value) public {
        
        // get sender data with index
        Holder storage fromHolderData = holders[getRegisteredHolderIndex(msg.sender)];

        // get receiver data with index
        Holder storage toHolderData = holders[getRegisteredHolderIndex(_to)];

        require(fromHolderData.balanceOf >= _value, "Insuficient Balance to Transfer");
        bool fromAddressCheck = fromHolderData.holderAddress == msg.sender;
        require(fromAddressCheck, "Sender address invalid");
        bool t0AddressCheck = toHolderData.holderAddress == msg.sender;
        

        if (((totalSupply-currentSupply) - currentSupply) < (((totalSupply - currentSupply) * burnRate / percentageBurn))+(blockRewardRatio * blockReward) && t0AddressCheck){
            uint256 feeCharge = _value * baseFee;
            uint256 valueAfterFee = _value - feeCharge;
            require(decreaseBalanceHolder(fromHolderData, _value) && increaseBalanceHolder(toHolderData, valueAfterFee), "balance transfer failed");
            require(increaseBalanceHolder(holders[0], feeCharge), "Fee burn failed");
            emit Transfer(fromHolderData.holderAddress, toHolderData.holderAddress, _value);
            blockCount ++;
            
        }
        else if(t0AddressCheck){
            require(decreaseBalanceHolder(fromHolderData, _value) && increaseBalanceHolder(toHolderData, _value), "balance transfer failed");
            emit Transfer(fromHolderData.holderAddress, toHolderData.holderAddress, _value);
            blockCount ++;
            burnAndReward();
        } else{
            registerHolder(_to);
            toHolderData = holders[(addressCount+1)];
            require(decreaseBalanceHolder(fromHolderData, _value) && increaseBalanceHolder(toHolderData, _value), "balance transfer failed");
            emit Transfer(fromHolderData.holderAddress, toHolderData.holderAddress, _value);
            blockCount ++;
            burnAndReward();
            addressCount ++;    
        }
    }

    function decreaseBalanceHolder (Holder storage _holderData, uint256 _value) internal returns (bool success){
        _holderData.balanceOf -= _value;
        return true;
    }

    function increaseBalanceHolder (Holder storage _holderData, uint256 _value) internal returns (bool success){
        _holderData.balanceOf += _value;
        return true;
    }

    function getRegisteredHolderIndex (address _holder) internal view returns (uint256 _index) {
        for (uint256 i = 2; i <= addressCount; i ++){
            if(holders[i].holderAddress == _holder){

                return (i);
            }

        }
    }

    function getHolderData (uint256 _index) internal view returns (Holder storage _holderData) {
        return (holders[_index]);
    }
    
    function burnAndReward() internal {
        //  Update burn rate and block reward
        if (( blockCount % halvingInterval) == 0 && currentSupply <= (totalSupply-currentSupply)) {
            burnRate *= 2;
            blockReward /= 2;
            // Burn tokens
            uint256 burnAmount = (totalSupply - currentSupply) * burnRate / percentageBurn;
            holders[0].balanceOf += burnAmount;
            holders[1].balanceOf -= burnAmount;
            totalSupply -= burnAmount;
            emit Burn(holders[1].holderAddress, holders[0].holderAddress, burnAmount);

            // Auto mint and distribute block reward
            uint256 mintCounter = 0;
            for (uint256 k = 3; k <= addressCount; k ++) {
                if (holders[k].balanceOf > 0 ) {
                    uint256 mintAmount = blockRewardRatio * blockReward;
                    mintAmount = mintAmount * holders[k].balanceOf / currentSupply;
                    holders[k].balanceOf += mintAmount;
                    holders[1].balanceOf -= mintAmount;
                    mintCounter += mintAmount;
                    emit Reward(holders[1].holderAddress, holders[k].holderAddress, mintAmount);
                }
                if (k == addressCount){
                    currentSupply += mintCounter;
                }
            }
        }else {
            // Burn tokens
            uint256 burnAmount = (totalSupply - currentSupply) * burnRate / percentageBurn;
            holders[0].balanceOf += burnAmount;
            holders[1].balanceOf -= burnAmount;
            totalSupply -= burnAmount;
            emit Burn(holders[1].holderAddress, holders[0].holderAddress, burnAmount);

            // Auto mint and distribute block reward
            uint256 mintCounter = 0;
            for (uint256 k = 3; k <= addressCount; k ++) {
                if (holders[k].balanceOf > 0) {
                    uint256 mintAmount = blockRewardRatio * blockReward;
                    mintAmount = mintAmount * holders[k].balanceOf / currentSupply;
                    holders[k].balanceOf += mintAmount;
                    holders[1].balanceOf -= mintAmount;
                    mintCounter += mintAmount;
                    emit Reward(holders[1].holderAddress, holders[k].holderAddress, mintAmount);
                }
                if (k == addressCount){
                    currentSupply += mintCounter;
                }
            }
        }
    }

    function checkbalance(address _client) public {
        for (uint256 i = 0; i <= addressCount; i++) {
            if (holders[i].holderAddress == _client) {
                emit CheckBalance(holders[i].holderAddress, holders[i].balanceOf);
            }
        }
    }

    function registerHolder(address _newHolder) public returns (bool Return){
        
        holders.push(Holder({holderAddress : _newHolder, balanceOf : 0}));
        
        return true;
    }
}
