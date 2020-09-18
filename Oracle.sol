///@dev Version of this Oracle Contract is V 1.0

pragma solidity 0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract Oracle is Ownable {

  using SafeMath for uint256;

  //Primary Owner
  address public ownership;
  uint256 public startMarketId;
  uint256 public endMarketId;
  //Secondary Owner Addresses
  mapping (address => bool) private secondaryOwners;    

  constructor() public {
    ownership = msg.sender;
  }

  /**
   * Mappings
   */

	//	- Mapping of an Asset To their Hourly Prices 
	//	- Maps an assest to hour to price 
	//	- 1 = Forex Price, 2 = Cryptocurrency (BTC) Price
  mapping(uint256 => mapping(uint256 => int256)) public AssetToHourToPrice;
  // Mapping of price entries to the timestamp when they were set.
  // Structure is similar to AssetToHourToPrice but instead of tracking price, it tracks timestamp.
  mapping(uint256 => mapping(uint256 => uint256)) public PriceTimestamp;

	/**
   * EVENTS
   */
  event LogPriceUpdate(uint256 _marketId, uint256 _timeslot, int256 _oldValue, int256 _newValue, uint256 _timestamp);
  event LogStartMarketIdChange(uint256 _oldValue, uint256 _newValue);
  event LogEndMarketIdChange(uint256 _oldValue, uint256 _newValue);
  event LogSecondaryOwnerChange(address indexed _owner, bool _state);
  event LogFallback(address indexed _caller);

	/**
   * Modifiers 
   */
  modifier isHuman() {
    address _addr = msg.sender;
    uint256 _codeLength;
    // @dev FIXME security/no-inline-assembly: Avoid using Inline Assembly.
    assembly {_codeLength := extcodesize(_addr)}
    require(_codeLength == 0, "sorry humans only");
    _;
  }

  //Fallback function 
  // @dev FIXME this is not exactly a fallaback function and its name collides with the modifier above.
  function() isHuman public { 
    //check if no data is being sent to the contract (malicious code!)
    require(msg.data.length == 0);
    //Log the fallback function
    emit LogFallback(msg.sender);
    revert();
  }

	/**
   * Primary ADMIN Functions
   */

	// Setter for Price of an Asset. Ex: 0 = Default, 1 = USD/CND, 2 = BTC/USD 
  function setPrice(uint256 _marketId, uint256 _timeslot, int256 _price) isHuman external {
    // Adding Authentication
    require(secondaryOwners[msg.sender] == true, "Unauthorised");
    // Ensure market ID is in range
    require(_marketId != 0 && _marketId >= startMarketId && _marketId <= endMarketId, "marketID outOfRange");
    // Ensure prices are 24 hours
    require(_timeslot >= 0 && _timeslot <= 23, "timeslot outOfRange");
    // Ensure positive price
    require(_price > 0 && _price <= 10**18, "price outOfRange");

    //Storing the old value to emit in event 
    int256 value = AssetToHourToPrice[_marketId][_timeslot]; 
    //Update the new price
    AssetToHourToPrice[_marketId][_timeslot] = _price;
    // Timestamp this entry.
    // @dev note that dependence on "now" or "block.timestamp" is mildly concerning. However,
    // it is acceptable here as it doesn't determine funds transfer.
    // @see https://consensys.github.io/smart-contract-best-practices/recommendations/#timestamp-dependence
    uint256 timestamp = now;
    PriceTimestamp[_marketId][_timeslot] = timestamp;
    //Emit event for price updates 
    emit LogPriceUpdate(_marketId, _timeslot, value, _price, timestamp);
  }

  //Setter for Start Market Id
  function setStartMarketId(uint256 _startMarketId) isHuman external {
    require(secondaryOwners[msg.sender] == true, "Non-secondary user");
    require(_startMarketId > 0, "marketID outOfRange");
    emit LogStartMarketIdChange(startMarketId, _startMarketId);
    startMarketId = _startMarketId;
  }

	//Setter for End Market Id: ADMIN ONLY
  function setEndMarketId(uint256 _endMarketId) isHuman external {
    require(secondaryOwners[msg.sender] == true, "Non-secondary user");
    require(_endMarketId > 0, "marketID outOfRange");
    emit LogEndMarketIdChange(endMarketId, _endMarketId);
    endMarketId = _endMarketId;
  }

	//Getter to be used for the relevant Main Smart Contract
  function getPrice(uint256 _marketId, uint256 _timeslot) public view returns ( int256 res ){
    // Ensure market ID is in range
    require(_marketId != 0 && _marketId >= startMarketId && _marketId <= endMarketId, "marketID outOfRange");
    // Ensure prices are 24 hours
    require(_timeslot >= 0 && _timeslot <= 23, "timeslot outOfRange");
    // Ensure price has been set.
    int256 value = AssetToHourToPrice[_marketId][_timeslot];
    require(value > 0, "Price Unset");
    // Ensure set price is not stale, i.e. not older than 24 hours. This can happen if Oracle daemon has stopped
    // updating the contract for some reason.
    require(now < ( PriceTimestamp[_marketId][_timeslot].add(1 days)), "Stale Data");
    
    return value;
  }

	/**
   * External Call Functions
   */

	/** 
   * Ownership Functions 
   */

	//function to add secondary owners 
  function addOwnerSecondary (address _owner) onlyOwner external  {
    secondaryOwners[_owner] = true;
    emit LogSecondaryOwnerChange(_owner, true);
  }

  //function to blacklist the secondary owners
  function removeOwnerSecondary (address _owner) onlyOwner external  {
    secondaryOwners[_owner] = false;
    emit LogSecondaryOwnerChange(_owner, false);
  }

  //function to check if an address is an owner 
  function isSecondaryOwner (address _owner) external view returns (bool res) {
    if(secondaryOwners[_owner] == true){
      return true;
    } else {
      return false;
    }
  }
}