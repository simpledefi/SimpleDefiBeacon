//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract combine_beacon is Ownable {
    struct sFee {
        uint current_amount;
        uint replacement_amount;
        uint256 start;
    }

    struct sExchange {
        address current_logic_contract;
        address replacement_logic_contract;
        uint256 start;
    }
    struct aDiscount {
        address _user;
        uint _discount;
        uint _expires;
    }
    struct sDiscount {
        uint discount_amount;
        uint expires;
    }

    struct sExchangeInfo {
        address chefContract;
        address routerContract;
        address rewardToken;
        address intermediateToken;
        address baseToken;
        string pendingCall;
        string contractType_solo;
        string contractType_pooled;
    }

    mapping (string => mapping(string => sFee)) public mFee;
    mapping (string => sExchange) public mExchanges;
    mapping (address => sDiscount) public mDiscounts;
    mapping (string => sExchangeInfo) public mExchangeInfo;
    mapping (string => address) public mData;

    bool bitFlip;

    event feeSet(string _exchange, string _function, uint _amount, uint256 _time, uint256 _current);
    event discountSet(address _user, uint _discount, uint _expires);
    event exchangeSet(string  _exchange, address _replacement_logic_contract, uint256 _start);
    
    ///@notice Calculate fee with discount from user
    ///@param _exchange Exchange name
    ///@param _type Type of fee
    ///@param _user User address
    ///@return amount - amount of the fee
    ///@return expires - unix timestamp when the discount expires

    function getFee(string memory _exchange, string memory _type, address _user) public view returns (uint,uint) {
        sFee memory rv = mFee[_exchange][_type];
        sDiscount memory disc = mDiscounts[_user];
        if (rv.replacement_amount == 0 && rv.current_amount == 0) {
            rv = mFee['DEFAULT'][_type];
        }

        uint amount =  (rv.start != 0 && rv.start <= block.timestamp) ? rv.replacement_amount : rv.current_amount;
        uint expires = (disc.discount_amount > 0 && (disc.expires <= block.timestamp || disc.expires == 0)) ? disc.expires : 1;

        if (disc.discount_amount > 0 && (disc.expires <= block.timestamp || disc.expires == 0)) {
            
            amount = amount - (amount *(disc.discount_amount/100) / (10**18)); 
        }
        else {

        }

        return (amount,expires);
    }
    ///@notice get a constant setting and check for new value baed on timestamp
    ///@param _exchange Exchange name
    ///@param _type Name of constant
    ///@return value of constant

    function getConst(string memory _exchange, string memory _type) public view returns (uint) {
        sFee memory rv = mFee[_exchange][_type];
        if (rv.replacement_amount == 0 && rv.current_amount == 0) {
            rv = mFee['DEFAULT'][_type];
        }
        return (rv.start != 0 && rv.start <= block.timestamp) ? rv.replacement_amount : rv.current_amount;
    }


    ///@notice Accept an array of users and discounts from teh admin only
    ///@param _discount struct array of users and discounts    
    function setDiscount(aDiscount[] memory  _discount) public onlyOwner{ 
        for (uint i = 0; i < _discount.length; i++) {
            setDiscount(_discount[i]._user, _discount[i]._discount, _discount[i]._expires);
        }
    }

    ///@notice Accept a user and discount from the admin only
    ///@param _user User address
    ///@param _amount Discount amount
    ///@param _expires Unix timestamp when the discount expires
    function setDiscount(address _user, uint _amount, uint _expires) public onlyOwner {
        require(_amount <= 100 ether,"Cannot exceed 100%");
        mDiscounts[_user].discount_amount = _amount;
        if (_expires > 0 && _expires < 31536000) {
            _expires = block.timestamp + _expires;
        }
        mDiscounts[_user].expires = _expires;

        emit discountSet(_user,_amount,_expires);
    }

    ///@notice Sets a fee for an exchange and function
    ///@param _exchange Exchange name
    ///@param _type Function name
    ///@param _replacement_amount Amount of the fee
    ///@param _start Unix timestamp when the fee starts
    function setFee(string memory _exchange, string memory _type, uint _replacement_amount, uint256 _start) public onlyOwner {
        sFee memory rv = mFee[_exchange][_type];
        
        if (_start < 1209600) {
            _start = block.timestamp + _start;
        }
        
        if (rv.start != 0 && rv.start < block.timestamp) {
            mFee[_exchange][_type].current_amount = mFee[_exchange][_type].replacement_amount;
        }
        
        mFee[_exchange][_type].start = _start;
        mFee[_exchange][_type].replacement_amount = _replacement_amount;

        if (rv.current_amount == 0) {
            mFee[_exchange][_type].current_amount = _replacement_amount;
        }
        emit feeSet(_exchange,_type,_replacement_amount,_start, block.timestamp);
    }
    
    ///@notice Get logic contract for an exchange
    ///@param _exchange Exchange name
    ///@return address of the logic contract
    function getExchange(string memory _exchange) public view returns(address) {
        sExchange memory rv = mExchanges[_exchange];

        if (rv.start != 0 && rv.start < block.timestamp) {
            return rv.replacement_logic_contract;
        }
        return rv.current_logic_contract;
    }

    //@notice Set address for a logic contract that comes into effect at specific timestamp
    ///@dev set _start to 0 to take effect immediately
    ///@param _exchange Exchange name
    ///@param _replacement_logic_contract Address of the logic contract
    ///@param _start Unix timestamp when the logic contract comes into effect
    function setExchange(string memory _exchange, address _replacement_logic_contract, uint256 _start) public onlyOwner {
        sExchange memory rv = mExchanges[_exchange];
        
        if (_start < 1209600) {
            _start = block.timestamp + _start;
        }
        
        if (rv.start != 0 && rv.start <= block.timestamp) {
            mExchanges[_exchange].current_logic_contract = mExchanges[_exchange].replacement_logic_contract;
        }
        
        mExchanges[_exchange].start = _start;
        mExchanges[_exchange].replacement_logic_contract = _replacement_logic_contract;
        if (mExchanges[_exchange].current_logic_contract == address(0) || _start <= block.timestamp) {
            mExchanges[_exchange].current_logic_contract = _replacement_logic_contract;
        }
        emit exchangeSet(_exchange, _replacement_logic_contract, _start);
    }
    
    //@notice Set information for exchange
    ///@param _name Exchange name
    ///@param _chefContract Address of the MasterChef contract for pool information
    ///@param _routerContract Address of the Router contract 
    ///@param _rewardToken Address of the reward token for exchange
    ///@param _pendingCall string of the function in the MasterChef contract that gets the pending reward for a pool
    ///@param _baseToken FUTURE CODE: Address of the token used as base for all calculations. Currently it is only BNB
    ///@param _contractType_solo Name of Logic Contract to be called  from "getExchange" for solo farming
    ///@param _contractType_pooled Name of Logic Contract to be called  from "getExchange" for pooled farming
    function setExchangeInfo(string memory _name, address _chefContract, address _routerContract, address _rewardToken, string memory _pendingCall,address _intermediateToken, address _baseToken, string memory _contractType_solo, string memory _contractType_pooled) public onlyOwner {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_chefContract != address(0), "Chef contract cannot be empty");
        require(_routerContract != address(0), "Route contract cannot be empty");
        require(_rewardToken != address(0), "Reward token cannot be empty");
        require(bytes(_pendingCall).length > 0, "Pending call cannot be empty");
        require(bytes(_contractType_solo).length > 0, "Contract type cannot be empty");
        require(bytes(_contractType_pooled).length > 0, "Contract type cannot be empty");

        mExchangeInfo[_name].chefContract = _chefContract;
        mExchangeInfo[_name].routerContract = _routerContract;
        mExchangeInfo[_name].rewardToken = _rewardToken;
        mExchangeInfo[_name].pendingCall = _pendingCall;
        mExchangeInfo[_name].intermediateToken = _intermediateToken;
        mExchangeInfo[_name].baseToken = _baseToken;
        mExchangeInfo[_name].contractType_solo = _contractType_solo;
        mExchangeInfo[_name].contractType_pooled = _contractType_pooled;
    }
    
    ///@notice Get information for exchange
    ///@param _name Exchange name
    ///@return Structure containing exchange information creaded by setExchangeInfo
    function getExchangeInfo(string memory _name) public view returns (sExchangeInfo memory) {
        return mExchangeInfo[_name];
    }

    ///@notice Get identifier for contract type based on exchange name
    ///@param _name Exchange name
    ///@param _type Type of contract (0=solo, 1=pooled)
    ///@return _contract Name of contract type

    function getContractType(string memory _name, uint _type) public view returns (string memory _contract) {                
        _contract = _type== 0?mExchangeInfo[_name].contractType_solo:mExchangeInfo[_name].contractType_pooled;
    }


    ///@notice Set address of lookup key (ie. FEECOLLECTOR, ADMINUSER, etc)
    ///@param _key Key name
    ///@param _value Address of specified key
    function setAddress(string memory _key, address _value) public onlyOwner {
        require(bytes(_key).length > 0, "Key cannot be empty");
        require(_value != address(0), "Value cannot be empty");
        mData[_key] = _value;
    }

    ///@notice Get address of lookup key (ie. FEECOLLECTOR, ADMINUSER, etc)
    ///@param _key Key name
    ///@return Address of specified key
    function getAddress(string memory _key) public view returns(address) {
        return mData[_key];
    }
}

