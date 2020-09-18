pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        assert(isAuthorized(msg.sender, msg.sig));
        _;
    }

    modifier authorized(bytes4 sig) {
        assert(isAuthorized(msg.sender, sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.data);

        _;
    }
}

contract DSMath {
    
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    /*
    uint128 functions (h is for half)
     */

    function hadd(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) internal pure returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) internal pure returns (uint128 z) {
        return x <= y ? x : y;
    }

    function hmax(uint128 x, uint128 y) internal pure returns (uint128 z) {
        return x >= y ? x : y;
    }

    /*
    int256 functions
     */

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) internal pure returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) internal pure returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) internal view returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) internal view returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmin(x, y);
    }

    function wmax(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) internal pure returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) internal pure returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) internal view returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) internal view returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) internal view returns (uint128 z) {
        // This famous algorithm is called "exponentiation by squaring"
        // and calculates x^n with x as fixed-point and n as regular unsigned.
        //
        // It's O(log n), instead of O(n) for naive repeated multiplication.
        //
        // These facts are why it works:
        //
        //  If n is even, then x^n = (x^2)^(n/2).
        //  If n is odd,  then x^n = x * x^(n-1),
        //   and applying the equation for even x gives
        //    x^n = x * (x^2)^((n-1) / 2).
        //
        //  Also, EVM division is flooring and
        //    floor[(n-1) / 2] = floor[n / 2].

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmin(x, y);
    }

    function rmax(uint128 x, uint128 y) internal pure returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) internal pure returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}


contract DSThing is DSAuth, DSNote, DSMath {}

interface SimpleStakeInterface {
    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    function stake(address user, uint256 amount) external returns (bool);
    function unstake(address _user) external returns (bool);
    function totalStakedFor(address addr) external view returns (uint256);
    function token() external view returns (address);

}

interface PriceFeed {
    function read(uint _marketId) external view returns (uint);
}


contract Rewards {
    function addMiner(address _minter) external returns (bool);
    function removeMiner(address _minter) external returns (bool);
    function approveFor(address owner, uint256 value) public returns (bool);
    function updateRMSub(uint256 _amount) public returns (bool);
    function computeRewards(address _source) public returns (uint256);
}


contract Medianizer is DSThing, SimpleStakeInterface {

    using SafeMath for uint256;

    event LogValue(uint marketId, uint val);
    event MinBlocksUpdated(uint newValue);
    event Staked(address indexed user, uint256 amount, uint256 total);
    event Unstaked(address indexed user, uint256 amount, uint256 total);
    event FeedSet(uint pos, address feed);
    event IsSub (uint256 expiryTime, uint256 blockNow);
    event Subscribed(address indexed user, uint256 expiryTime, uint256 amountPaid);

    uint public minStakeDuration = 0;
    uint public stakeSize = 0; // Stake size in Wei. Note: this is token agnostic.
    uint public next = 1;
    uint public myn = 1;
    address public token;
    uint256 public subscribeFee = 10000000000000000000; //@note: 10 tokens, real application 10K tokens
    uint256 public subBlockDuration = 100;  // @note: which interval of blocks that sub lasts for

    mapping (uint => uint) private values;
    mapping (uint => address) public feeds; // int ID => feed address
    mapping (address => uint) public indexes; // feed address => int ID
    mapping (address => address) public ownerToFeed; // msg.sender => feedAddress
    mapping (address => uint) public stakeTime; // feed address => timestamp
    mapping (address => uint) public stakesFor; // feed address => stake amount (accounting)
    mapping(address => uint256) public expiryTimes;

    modifier unsubscribed() {
        require(expiryTimes[msg.sender] < now, "Already subscribed");
        _;
    }

    modifier subscribed() {
        require(expiryTimes[msg.sender] >= now, "Not subscribed!");
        _;
    }

    constructor(uint _minStakeDuration, address _token, uint _stakeSize) public {
        minStakeDuration = _minStakeDuration;
        emit MinBlocksUpdated(_minStakeDuration);
        token = _token;
        stakeSize = _stakeSize;
    }

    /** USER INTERFACE Functions */

    /**
     * @dev function to poke the medianizer by price feed to calculate median
     */
    function poke(uint _marketId) external returns (bool) {
        uint value = compute(_marketId);
        values[_marketId] = value;
        emit LogValue(_marketId, value);
        return true;
    }
    
    /**
     * @dev function to check price feed owner
     * @param _address is owner address
     * @return price feed address related to owner
     */
    function getOwnerToFeed(address _address) public view returns (address) {
        address pfAddress = ownerToFeed[_address];
        return pfAddress;
    }

    /**
     * @dev function to check if token address = address(0)
     */
    function usesYBT() public view returns (bool) {
        return token != address(0);
    }


    function withdrawRewards(address _user) public returns (bool) {
        require(usesYBT(), "Not using token");
        require(msg.sender == _user || ownerToFeed[msg.sender] == _user, "Unauthorised");
        uint256 _amountToReturn = Rewards(token).computeRewards(_user);
        ERC20(token).transfer(msg.sender, _amountToReturn);
    }

    /** USER INTERFACE Functions */


    /** STAKING Functions */

    /**
     * @dev function to stake a price feed by an owner
     */
    function stake(address user, uint256 amount) external returns (bool) {
        require(indexes[user] == 0, "Can't stake more than once");
        require(ownerToFeed[msg.sender] == address(0), "Can't stake more than once");
        require(amount == stakeSize, "Invalid stake size");
        if (usesYBT()) {
            require(ERC20(token).balanceOf(msg.sender) >= stakeSize, "insufficient balance");
            Rewards(token).approveFor(msg.sender, amount);
            ERC20(token).transferFrom(msg.sender, address(this), amount);
            Rewards(token).addMiner(user);
        }
        stakesFor[user] = amount;
        ownerToFeed[msg.sender] = user;
        stakeTime[user] = block.timestamp;
        set(user);
        emit Staked(user, amount, amount);
        return true;
    }
 
    /**
     * @dev function to unstake a price feed by an owner
     */
    function unstake(address _user) external returns (bool) {
        require(usesYBT(), "Not using token");
        require(msg.sender == _user || ownerToFeed[msg.sender] == _user, "Unauthorised");
        uint256 _amountToReturn = (Rewards(token).computeRewards(_user)).add(stakesFor[_user]);
        require(ERC20(token).balanceOf(address(this)) >= _amountToReturn, "Amount exceeds contract balance");
        require(block.timestamp >= (stakeTime[_user] + minStakeDuration), "Can't unstake now.");
        Rewards(token).removeMiner(_user);
        stakesFor[_user] = 0;
        ownerToFeed[msg.sender] = address(0);
        ERC20(token).transfer(msg.sender, _amountToReturn);
        unset(_user);
        emit Unstaked(_user, _amountToReturn, stakesFor[_user]);
        return true;
    }

    /**
     * @notice Returns total staked for address.
     * @param addr Address to check.
     * @return amount of ethers staked.
     */
    function totalStakedFor(address addr) public view returns (uint256) {
        return stakesFor[addr];
    }

    /** STAKING Functions */


    /** SUBSCRIPTION Functions */

    /**
     * @dev Subscribe user to the system
     * @param _amount of tokens paid to subscribe
     * @param _expiry time is when the subscribe ends
     */
    function subscribe(uint256 _amount, uint256 _expiry) external unsubscribed returns (bool) {
        require(_amount == subscribeFee, "Invalid subscribtion amount");
        Rewards(token).approveFor(msg.sender, _amount);
        ERC20(token).transferFrom(msg.sender, address(this), _amount);
        expiryTimes[msg.sender] = _expiry;
        Rewards(token).updateRMSub(_amount);
        return true;
    }

    /**
     * @dev Function that returns median to subscribers
     * @param _marketId corresponding market's median is returned
     */
    function read(uint _marketId) external view returns (uint) {
        require(values[_marketId] != 0, "Medianizer: Value is not set");
        return values[_marketId];
    }

    /** SUBSCRIPTION Functions */    

    /** DATA FILTER Functions */

    function compute(uint _marketId) public view returns (uint) {
        uint[] memory vals = new uint[](next - 1);
        uint count = 0;
        // Sort feed values
        for (uint i = 1; i < next; i++) {
            if (feeds[i] != address(0)) {
                uint feedVal = PriceFeed(feeds[i]).read(_marketId);
                if (feedVal > 0) {
                    if (count == 0 || feedVal >= vals[count - 1]) {
                        vals[count] = feedVal;
                    } else {
                        uint j = 0;
                        while (feedVal >= vals[j]) {
                            j++;
                        }
                        for (uint k = count; k > j; k--) {
                            vals[k] = vals[k - 1];
                        }
                        vals[j] = feedVal;
                    }
                    count++;
                }
            }
        }
        require (count >= myn, "Not enough active feeds");
        uint value;
        if (count % 2 == 0) {
            uint val1 = vals[(count / 2) - 1];
            uint val2 = vals[count / 2];
            value = (val1 / 2) + (val2 / 2);
        } else {
            value = vals[(count - 1) / 2];
        }
        return value;
    }

    function set(address feed) private returns (bool) {
        set(next, feed);
        next++;
        return true;
    }

     function set(uint pos, address feed) private returns (bool) {
        require(pos > 0, "Position must be a positive integer");
        require(indexes[feed] == 0);
        indexes[feed] = pos; //give the feed a number 
        feeds[pos] = feed; //put the address of the feed into that number
        emit FeedSet(pos, feed);   
        return true;
    }


    /**
    - core logic
    - get the old position from the pricefeed using indexes[pf] = old position
    - if old position == next -1 ,  then just do cleanup
    - if not then store the information of the last price feed + index 
    - dump thast into the old position
    - clean up last one 
   
     */

   function unset(uint pos, address feed) private returns (bool) {
       //edge case take care of a) 1 pf in the system b) when last of tries to unstake
        if (next == 2 || pos == (next - 1)) {
            //address pf = feeds[pos];   
            feedCleanUp(pos, feed);
        } else { 
            feedCleanUp(pos, feed);
            //next will be assigned to new feed, so last feed = next-1
            address lastFeed = feeds[next - 1];
            uint lastIndex = indexes[lastFeed];
            //clean up the last element in the mapping
            feedCleanUp(lastIndex, lastFeed);
            //replace in the empty slot in the mappings
            set(pos, lastFeed);            
        }
        next--;
        return true;
    }

    //@dev: used for cleaning up mapping values
    function feedCleanUp(uint pos, address feed) private returns (bool) {
       indexes[feed] = 0 ;
       feeds[pos] = address(0); 
       return true;      
    
    }

    // when unsetting we replace the target with the last
    //   item in the mapping
    function unset(address feed) private returns (bool) {
        uint pos = indexes[feed];
        unset(pos, feed);
        return true;
    }
}