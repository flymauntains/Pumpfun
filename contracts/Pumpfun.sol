// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();

        _owner = msgSender;

        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));

        _owner = address(0);
    }
}

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals = 18;

    uint256 private _tTotal;

    string private _name;

    string private _symbol;

    uint public maxTx;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private isExcludedFromMaxTx;

    event MaxTxUpdated(uint _maxTx);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply,
        uint _maxTx
    ) {
        _name = name_;

        _symbol = symbol_;

        _tTotal = supply * 10 ** _decimals;

        require(_maxTx <= 5, "Max Transaction cannot exceed 5%.");

        maxTx = _maxTx;

        _balances[_msgSender()] = _tTotal;

        isExcludedFromMaxTx[_msgSender()] = true;

        isExcludedFromMaxTx[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 maxTxAmount = (maxTx * _tTotal) / 100;

        if (!isExcludedFromMaxTx[from]) {
            require(amount <= maxTxAmount, "Exceeds the MaxTxAmount.");
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);

        emit Transfer(from, to, amount);
    }

    function updateMaxTx(uint256 _maxTx) public onlyOwner {
        require(_maxTx <= 5, "Max Transaction cannot exceed 5%.");

        maxTx = _maxTx;

        emit MaxTxUpdated(_maxTx);
    }

    function excludeFromMaxTx(address user) public onlyOwner {
        require(
            user != address(0),
            "ERC20: Exclude Max Tx from the zero address"
        );

        isExcludedFromMaxTx[user] = true;
    }
}

contract Factory is ReentrancyGuard {
    address private owner;

    address private _feeTo;

    mapping(address => mapping(address => address)) private pair;

    address[] private pairs;

    uint private constant fee = 5;

    constructor(address fee_to) {
        owner = msg.sender;

        require(fee_to != address(0), "Zero addresses are not allowed.");

        _feeTo = fee_to;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");

        _;
    }

    event PairCreated(
        address indexed tokenA,
        address indexed tokenB,
        address pair,
        uint
    );

    function _createPair(
        address tokenA,
        address tokenB
    ) private returns (address) {
        require(tokenA != address(0), "Zero addresses are not allowed.");
        require(tokenB != address(0), "Zero addresses are not allowed.");

        Pair _pair = new Pair(address(this), tokenA, tokenB);

        pair[tokenA][tokenB] = address(_pair);
        pair[tokenB][tokenA] = address(_pair);

        pairs.push(address(_pair));

        uint n = pairs.length;

        emit PairCreated(tokenA, tokenB, address(_pair), n);

        return address(_pair);
    }

    function createPair(
        address tokenA,
        address tokenB
    ) external nonReentrant returns (address) {
        address _pair = _createPair(tokenA, tokenB);

        return _pair;
    }

    function getPair(
        address tokenA,
        address tokenB
    ) public view returns (address) {
        return pair[tokenA][tokenB];
    }

    function allPairs(uint n) public view returns (address) {
        return pairs[n];
    }

    function allPairsLength() public view returns (uint) {
        return pairs.length;
    }

    function feeTo() public view returns (address) {
        return _feeTo;
    }

    function feeToSetter() public view returns (address) {
        return owner;
    }

    function setFeeTo(address fee_to) public onlyOwner {
        require(fee_to != address(0), "Zero addresses are not allowed.");

        _feeTo = fee_to;
    }

    function txFee() public pure returns (uint) {
        return fee;
    }
}

contract Pair is ReentrancyGuard {
    receive() external payable {}

    address private _factory;

    address private _tokenA;

    address private _tokenB;

    address private lp;

    struct Pool {
        uint256 reserve0;
        uint256 reserve1;
        uint256 _reserve1;
        uint256 k;
        uint256 lastUpdated;
    }

    Pool private pool;

    constructor(address factory_, address token0, address token1) {
        require(factory_ != address(0), "Zero addresses are not allowed.");
        require(token0 != address(0), "Zero addresses are not allowed.");
        require(token1 != address(0), "Zero addresses are not allowed.");

        _factory = factory_;

        _tokenA = token0;

        _tokenB = token1;
    }

    event Mint(uint256 reserve0, uint256 reserve1, address lp);

    event Burn(uint256 reserve0, uint256 reserve1, address lp);

    event Swap(
        uint256 amount0In,
        uint256 amount0Out,
        uint256 amount1In,
        uint256 amount1Out
    );

    function mint(
        uint256 reserve0,
        uint256 reserve1,
        address _lp
    ) public returns (bool) {
        lp = _lp;

        pool = Pool({
            reserve0: reserve0,
            reserve1: reserve1,
            _reserve1: MINIMUM_LIQUIDITY(),
            k: reserve0 * MINIMUM_LIQUIDITY(),
            lastUpdated: block.timestamp
        });

        emit Mint(reserve0, reserve1, _lp);

        return true;
    }

    function swap(
        uint256 amount0In,
        uint256 amount0Out,
        uint256 amount1In,
        uint256 amount1Out
    ) public returns (bool) {
        uint256 _reserve0 = (pool.reserve0 + amount0In) - amount0Out;
        uint256 _reserve1 = (pool.reserve1 + amount1In) - amount1Out;
        uint256 reserve1_ = (pool._reserve1 + amount1In) - amount1Out;

        pool = Pool({
            reserve0: _reserve0,
            reserve1: _reserve1,
            _reserve1: reserve1_,
            k: pool.k,
            lastUpdated: block.timestamp
        });

        emit Swap(amount0In, amount0Out, amount1In, amount1Out);

        return true;
    }

    function burn(
        uint256 reserve0,
        uint256 reserve1,
        address _lp
    ) public returns (bool) {
        require(_lp != address(0), "Zero addresses are not allowed.");
        require(lp == _lp, "Only Lp holders can call this function.");

        uint256 _reserve0 = pool.reserve0 - reserve0;
        uint256 _reserve1 = pool.reserve1 - reserve1;
        uint256 reserve1_ = pool._reserve1 - reserve1;

        pool = Pool({
            reserve0: _reserve0,
            reserve1: _reserve1,
            _reserve1: reserve1_,
            k: pool.k,
            lastUpdated: block.timestamp
        });

        emit Burn(reserve0, reserve1, _lp);

        return true;
    }

    function _approval(
        address _user,
        address _token,
        uint256 amount
    ) private returns (bool) {
        require(_user != address(0), "Zero addresses are not allowed.");
        require(_token != address(0), "Zero addresses are not allowed.");

        ERC20 token_ = ERC20(_token);

        token_.approve(_user, amount);

        return true;
    }

    function approval(
        address _user,
        address _token,
        uint256 amount
    ) external nonReentrant returns (bool) {
        bool approved = _approval(_user, _token, amount);

        return approved;
    }

    function transferETH(
        address _address,
        uint256 amount
    ) public returns (bool) {
        require(_address != address(0), "Zero addresses are not allowed.");

        (bool os, ) = payable(_address).call{value: amount}("");

        return os;
    }

    function liquidityProvider() public view returns (address) {
        return lp;
    }

    function MINIMUM_LIQUIDITY() public pure returns (uint256) {
        return 1 ether;
    }

    function factory() public view returns (address) {
        return _factory;
    }

    function tokenA() public view returns (address) {
        return _tokenA;
    }

    function tokenB() public view returns (address) {
        return _tokenB;
    }

    function getReserves() public view returns (uint256, uint256, uint256) {
        return (pool.reserve0, pool.reserve1, pool._reserve1);
    }

    function kLast() public view returns (uint256) {
        return pool.k;
    }

    function priceALast() public view returns (uint256) {
        return pool.reserve1 / pool.reserve0;
    }

    function priceBLast() public view returns (uint256) {
        return pool.reserve0 / pool.reserve1;
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract Router is ReentrancyGuard {
    using SafeMath for uint256;

    address private _factory;

    address private _WETH;

    uint public referralFee;

    constructor(address factory_, address weth, uint refFee) {
        require(factory_ != address(0), "Zero addresses are not allowed.");
        require(weth != address(0), "Zero addresses are not allowed.");

        _factory = factory_;

        _WETH = weth;

        require(refFee <= 5, "Referral Fee cannot exceed 5%.");

        referralFee = refFee;
    }

    function factory() public view returns (address) {
        return _factory;
    }

    function WETH() public view returns (address) {
        return _WETH;
    }

    function transferETH(
        address _address,
        uint256 amount
    ) private returns (bool) {
        require(_address != address(0), "Zero addresses are not allowed.");

        (bool os, ) = payable(_address).call{value: amount}("");

        return os;
    }

    function _getAmountsOut(
        address token,
        address weth,
        uint256 amountIn
    ) private view returns (uint256 _amountOut) {
        require(token != address(0), "Zero addresses are not allowed.");

        Factory factory_ = Factory(_factory);

        address pair = factory_.getPair(token, _WETH);

        Pair _pair = Pair(payable(pair));

        (uint256 reserveA, , uint256 _reserveB) = _pair.getReserves();

        uint256 k = _pair.kLast();

        uint256 amountOut;

        if (weth == _WETH) {
            uint256 newReserveB = _reserveB.add(amountIn);

            uint256 newReserveA = k.div(newReserveB, "Division failed");

            amountOut = reserveA.sub(newReserveA, "Subtraction failed.");
        } else {
            uint256 newReserveA = reserveA.add(amountIn);

            uint256 newReserveB = k.div(newReserveA, "Division failed");

            amountOut = _reserveB.sub(newReserveB, "Subtraction failed.");
        }

        return amountOut;
    }

    function getAmountsOut(
        address token,
        address weth,
        uint256 amountIn
    ) external nonReentrant returns (uint256 _amountOut) {
        uint256 amountOut = _getAmountsOut(token, weth, amountIn);

        return amountOut;
    }

    function _addLiquidityETH(
        address token,
        uint256 amountToken,
        uint256 amountETH
    ) private returns (uint256, uint256) {
        require(token != address(0), "Zero addresses are not allowed.");

        Factory factory_ = Factory(_factory);

        address pair = factory_.getPair(token, _WETH);

        Pair _pair = Pair(payable(pair));

        ERC20 token_ = ERC20(token);

        bool os = transferETH(pair, amountETH);
        require(os, "Transfer of ETH to pair failed.");

        bool os1 = token_.transferFrom(msg.sender, pair, amountToken);
        require(os1, "Transfer of token to pair failed.");

        _pair.mint(amountToken, amountETH, msg.sender);

        return (amountToken, amountETH);
    }

    function addLiquidityETH(
        address token,
        uint256 amountToken
    ) external payable nonReentrant returns (uint256, uint256) {
        uint256 amountETH = msg.value;

        (uint256 amount0, uint256 amount1) = _addLiquidityETH(
            token,
            amountToken,
            amountETH
        );

        return (amount0, amount1);
    }

    function _removeLiquidityETH(
        address token,
        uint256 liquidity,
        address to
    ) private returns (uint256, uint256) {
        require(token != address(0), "Zero addresses are not allowed.");
        require(to != address(0), "Zero addresses are not allowed.");

        Factory factory_ = Factory(_factory);

        address pair = factory_.getPair(token, _WETH);

        Pair _pair = Pair(payable(pair));

        (uint256 reserveA, , ) = _pair.getReserves();

        ERC20 token_ = ERC20(token);

        uint256 amountETH = (liquidity * _pair.balance()) / 100;

        uint256 amountToken = (liquidity * reserveA) / 100;

        bool approved = _pair.approval(address(this), token, amountToken);
        require(approved);

        bool os = _pair.transferETH(to, amountETH);
        require(os, "Transfer of ETH to caller failed.");

        bool os1 = token_.transferFrom(pair, to, amountToken);
        require(os1, "Transfer of token to caller failed.");

        _pair.burn(amountToken, amountETH, msg.sender);

        return (amountToken, amountETH);
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        address to
    ) external nonReentrant returns (uint256, uint256) {
        (uint256 amountToken, uint256 amountETH) = _removeLiquidityETH(
            token,
            liquidity,
            to
        );

        return (amountToken, amountETH);
    }

    function swapTokensForETH(
        uint256 amountIn,
        address token,
        address to,
        address referree
    ) public nonReentrant returns (uint256, uint256) {
        require(token != address(0), "Zero addresses are not allowed.");
        require(to != address(0), "Zero addresses are not allowed.");
        require(referree != address(0), "Zero addresses are not allowed.");

        Factory factory_ = Factory(_factory);

        address pair = factory_.getPair(token, _WETH);

        Pair _pair = Pair(payable(pair));

        ERC20 token_ = ERC20(token);

        uint256 amountOut = _getAmountsOut(token, address(0), amountIn);

        bool os = token_.transferFrom(to, pair, amountIn);
        require(os, "Transfer of token to pair failed");

        uint fee = factory_.txFee();
        uint256 txFee = (fee * amountOut) / 100;

        uint256 _amount;
        uint256 amount;

        if (referree != address(0)) {
            _amount = (referralFee * amountOut) / 100;
            amount = amountOut - (txFee + _amount);

            bool os1 = _pair.transferETH(referree, _amount);
            require(os1, "Transfer of ETH to referree failed.");
        } else {
            amount = amountOut - txFee;
        }

        address feeTo = factory_.feeTo();

        bool os2 = _pair.transferETH(to, amount);
        require(os2, "Transfer of ETH to user failed.");

        bool os3 = _pair.transferETH(feeTo, txFee);
        require(os3, "Transfer of ETH to fee address failed.");

        _pair.swap(amountIn, 0, 0, amount);

        return (amountIn, amount);
    }

    function swapETHForTokens(
        address token,
        address to,
        address referree
    ) public payable nonReentrant returns (uint256, uint256) {
        require(token != address(0), "Zero addresses are not allowed.");
        require(to != address(0), "Zero addresses are not allowed.");
        require(referree != address(0), "Zero addresses are not allowed.");

        uint256 amountIn = msg.value;

        Factory factory_ = Factory(_factory);

        address pair = factory_.getPair(token, _WETH);

        Pair _pair = Pair(payable(pair));

        ERC20 token_ = ERC20(token);

        uint256 amountOut = _getAmountsOut(token, _WETH, amountIn);

        bool approved = _pair.approval(address(this), token, amountOut);
        require(approved, "Not Approved.");

        uint fee = factory_.txFee();
        uint256 txFee = (fee * amountIn) / 100;

        uint256 _amount;
        uint256 amount;

        if (referree != address(0)) {
            _amount = (referralFee * amountIn) / 100;
            amount = amountIn - (txFee + _amount);

            bool os = transferETH(referree, _amount);
            require(os, "Transfer of ETH to referree failed.");
        } else {
            amount = amountIn - txFee;
        }

        address feeTo = factory_.feeTo();

        bool os1 = transferETH(pair, amount);
        require(os1, "Transfer of ETH to pair failed.");

        bool os2 = transferETH(feeTo, txFee);
        require(os2, "Transfer of ETH to fee address failed.");

        bool os3 = token_.transferFrom(pair, to, amountOut);
        require(os3, "Transfer of token to pair failed.");

        _pair.swap(0, amountOut, amount, 0);

        return (amount, amountOut);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract PumpFun is ReentrancyGuard {
    receive() external payable {}

    address private owner;

    Factory private factory;

    Router private router;

    address private _feeTo;

    uint256 private fee;

    uint private constant lpFee = 5;

    uint256 private constant mcap = 100_000 ether;

    IUniswapV2Router02 private uniswapV2Router;

    struct Profile {
        address user;
        Token[] tokens;
    }

    struct Token {
        address creator;
        address token;
        address pair;
        Data data;
        string description;
        string image;
        string twitter;
        string telegram;
        string discord;
        string website;
        bool trading;
        bool tradingOnUniswap;
    }

    struct Data {
        address token;
        string name;
        string ticker;
        uint256 supply;
        uint256 price;
        uint256 marketCap;
        uint256 liquidity;
        uint256 _liquidity;
        uint256 volume;
        uint256 volume24H;
        uint256 prevPrice;
        uint256 lastUpdated;
    }

    mapping(address => Profile) public profile;

    Profile[] public profiles;

    mapping(address => Token) public token;

    Token[] public tokens;

    event Launched(address indexed token, address indexed pair, uint);

    event Deployed(address indexed token, uint256 amount0, uint256 amount1);

    constructor(
        address factory_,
        address router_,
        address fee_to,
        uint256 _fee
    ) {
        owner = msg.sender;

        require(factory_ != address(0), "Zero addresses are not allowed.");
        require(router_ != address(0), "Zero addresses are not allowed.");
        require(fee_to != address(0), "Zero addresses are not allowed.");

        factory = Factory(factory_);

        router = Router(router_);

        _feeTo = fee_to;

        fee = (_fee * 1 ether) / 1000;

        uniswapV2Router = IUniswapV2Router02(
            0x63d530FDb0A8986E444cCd2f457Df02646D7D6e2
        );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");

        _;
    }

    function createUserProfile(address _user) private returns (bool) {
        require(_user != address(0), "Zero addresses are not allowed.");

        Token[] memory _tokens;

        Profile memory _profile = Profile({user: _user, tokens: _tokens});

        profile[_user] = _profile;

        profiles.push(_profile);

        return true;
    }

    function checkIfProfileExists(address _user) private view returns (bool) {
        require(_user != address(0), "Zero addresses are not allowed.");

        bool exists = false;

        for (uint i = 0; i < profiles.length; i++) {
            if (profiles[i].user == _user) {
                return true;
            }
        }

        return exists;
    }

    function _approval(
        address _user,
        address _token,
        uint256 amount
    ) private returns (bool) {
        require(_user != address(0), "Zero addresses are not allowed.");
        require(_token != address(0), "Zero addresses are not allowed.");

        ERC20 token_ = ERC20(_token);

        token_.approve(_user, amount);

        return true;
    }

    function approval(
        address _user,
        address _token,
        uint256 amount
    ) external nonReentrant returns (bool) {
        bool approved = _approval(_user, _token, amount);

        return approved;
    }

    function launchFee() public view returns (uint256) {
        return fee;
    }

    function updateLaunchFee(uint256 _fee) public returns (uint256) {
        fee = _fee;

        return _fee;
    }

    function liquidityFee() public pure returns (uint256) {
        return lpFee;
    }

    function feeTo() public view returns (address) {
        return _feeTo;
    }

    function feeToSetter() public view returns (address) {
        return owner;
    }

    function setFeeTo(address fee_to) public onlyOwner {
        require(fee_to != address(0), "Zero addresses are not allowed.");

        _feeTo = fee_to;
    }

    function marketCapLimit() public pure returns (uint256) {
        return mcap;
    }

    function getUserTokens() public view returns (Token[] memory) {
        require(
            checkIfProfileExists(msg.sender),
            "User Profile dose not exist."
        );

        Profile memory _profile = profile[msg.sender];

        return _profile.tokens;
    }

    function getTokens() public view returns (Token[] memory) {
        return tokens;
    }

    function launch(
        string memory _name,
        string memory _ticker,
        string memory desc,
        string memory img,
        string[4] memory urls,
        uint256 _supply,
        uint maxTx
    ) public payable nonReentrant returns (address, address, uint) {
        require(msg.value >= fee, "Insufficient amount sent.");

        ERC20 _token = new ERC20(_name, _ticker, _supply, maxTx);

        address weth = router.WETH();

        address _pair = factory.createPair(address(_token), weth);

        Pair pair_ = Pair(payable(_pair));

        uint256 supply = _supply * 10 ** _token.decimals();

        bool approved = _approval(address(router), address(_token), supply);
        require(approved);

        uint256 liquidity = (lpFee * msg.value) / 100;
        uint256 value = msg.value - liquidity;

        router.addLiquidityETH{value: liquidity}(address(_token), supply);

        Data memory _data = Data({
            token: address(_token),
            name: _name,
            ticker: _ticker,
            supply: supply,
            price: supply / pair_.MINIMUM_LIQUIDITY(),
            marketCap: pair_.MINIMUM_LIQUIDITY(),
            liquidity: liquidity * 2,
            _liquidity: pair_.MINIMUM_LIQUIDITY() * 2,
            volume: 0,
            volume24H: 0,
            prevPrice: supply / pair_.MINIMUM_LIQUIDITY(),
            lastUpdated: block.timestamp
        });

        Token memory token_ = Token({
            creator: msg.sender,
            token: address(_token),
            pair: _pair,
            data: _data,
            description: desc,
            image: img,
            twitter: urls[0],
            telegram: urls[1],
            discord: urls[2],
            website: urls[3],
            trading: true,
            tradingOnUniswap: false
        });

        token[address(_token)] = token_;

        tokens.push(token_);

        bool exists = checkIfProfileExists(msg.sender);

        if (exists) {
            Profile storage _profile = profile[msg.sender];

            _profile.tokens.push(token_);
        } else {
            bool created = createUserProfile(msg.sender);

            if (created) {
                Profile storage _profile = profile[msg.sender];

                _profile.tokens.push(token_);
            }
        }

        (bool os, ) = payable(_feeTo).call{value: value}("");
        require(os);

        uint n = tokens.length;

        emit Launched(address(_token), _pair, n);

        return (address(_token), _pair, n);
    }

    function swapTokensForETH(
        uint256 amountIn,
        address tk,
        address to,
        address referree
    ) public returns (bool) {
        require(tk != address(0), "Zero addresses are not allowed.");
        require(to != address(0), "Zero addresses are not allowed.");
        require(referree != address(0), "Zero addresses are not allowed.");

        address _pair = factory.getPair(tk, router.WETH());

        Pair pair = Pair(payable(_pair));

        (uint256 reserveA, uint256 reserveB, uint256 _reserveB) = pair
            .getReserves();

        (uint256 amount0In, uint256 amount1Out) = router.swapTokensForETH(
            amountIn,
            tk,
            to,
            referree
        );

        uint256 newReserveA = reserveA + amount0In;
        uint256 newReserveB = reserveB - amount1Out;
        uint256 _newReserveB = _reserveB - amount1Out;
        uint256 duration = block.timestamp - token[tk].data.lastUpdated;

        uint256 _liquidity = _newReserveB * 2;
        uint256 liquidity = newReserveB * 2;
        uint256 mCap = (token[tk].data.supply * _newReserveB) / newReserveA;
        uint256 price = newReserveA / _newReserveB;
        uint256 volume = duration > 86400
            ? amount1Out
            : token[tk].data.volume24H + amount1Out;
        uint256 _price = duration > 86400
            ? token[tk].data.price
            : token[tk].data.prevPrice;

        token[tk].data.price = price;
        token[tk].data.marketCap = mCap;
        token[tk].data.liquidity = liquidity;
        token[tk].data._liquidity = _liquidity;
        token[tk].data.volume = token[tk].data.volume + amount1Out;
        token[tk].data.volume24H = volume;
        token[tk].data.prevPrice = _price;

        if (duration > 86400) {
            token[tk].data.lastUpdated = block.timestamp;
        }

        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i].token == tk) {
                tokens[i].data.price = price;
                tokens[i].data.marketCap = mCap;
                tokens[i].data.liquidity = liquidity;
                tokens[i].data._liquidity = _liquidity;
                tokens[i].data.volume = token[tk].data.volume + amount1Out;
                tokens[i].data.volume24H = volume;
                tokens[i].data.prevPrice = _price;

                if (duration > 86400) {
                    tokens[i].data.lastUpdated = block.timestamp;
                }
            }
        }

        return true;
    }

    function swapETHForTokens(
        address tk,
        address to,
        address referree
    ) public payable returns (bool) {
        require(tk != address(0), "Zero addresses are not allowed.");
        require(to != address(0), "Zero addresses are not allowed.");
        require(referree != address(0), "Zero addresses are not allowed.");

        address _pair = factory.getPair(tk, router.WETH());

        Pair pair = Pair(payable(_pair));

        (uint256 reserveA, uint256 reserveB, uint256 _reserveB) = pair
            .getReserves();

        (uint256 amount1In, uint256 amount0Out) = router.swapETHForTokens{
            value: msg.value
        }(tk, to, referree);

        uint256 newReserveA = reserveA - amount0Out;
        uint256 newReserveB = reserveB + amount1In;
        uint256 _newReserveB = _reserveB + amount1In;
        uint256 duration = block.timestamp - token[tk].data.lastUpdated;

        uint256 _liquidity = _newReserveB * 2;
        uint256 liquidity = newReserveB * 2;
        uint256 mCap = (token[tk].data.supply * _newReserveB) / newReserveA;
        uint256 price = newReserveA / _newReserveB;
        uint256 volume = duration > 86400
            ? amount1In
            : token[tk].data.volume24H + amount1In;
        uint256 _price = duration > 86400
            ? token[tk].data.price
            : token[tk].data.prevPrice;

        token[tk].data.price = price;
        token[tk].data.marketCap = mCap;
        token[tk].data.liquidity = liquidity;
        token[tk].data._liquidity = _liquidity;
        token[tk].data.volume = token[tk].data.volume + amount1In;
        token[tk].data.volume24H = volume;
        token[tk].data.prevPrice = _price;

        if (duration > 86400) {
            token[tk].data.lastUpdated = block.timestamp;
        }

        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i].token == tk) {
                tokens[i].data.price = price;
                tokens[i].data.marketCap = mCap;
                tokens[i].data.liquidity = liquidity;
                tokens[i].data._liquidity = _liquidity;
                tokens[i].data.volume = token[tk].data.volume + amount1In;
                tokens[i].data.volume24H = volume;
                tokens[i].data.prevPrice = _price;

                if (duration > 86400) {
                    tokens[i].data.lastUpdated = block.timestamp;
                }
            }
        }

        return true;
    }

    function deploy(address tk) public onlyOwner nonReentrant {
        require(tk != address(0), "Zero addresses are not allowed.");

        address weth = router.WETH();

        address pair = factory.getPair(tk, weth);

        ERC20 token_ = ERC20(tk);

        token_.excludeFromMaxTx(pair);

        Token storage _token = token[tk];

        (uint256 amount0, uint256 amount1) = router.removeLiquidityETH(
            tk,
            100,
            address(this)
        );

        Data memory _data = Data({
            token: tk,
            name: token[tk].data.name,
            ticker: token[tk].data.ticker,
            supply: token[tk].data.supply,
            price: 0,
            marketCap: 0,
            liquidity: 0,
            _liquidity: 0,
            volume: 0,
            volume24H: 0,
            prevPrice: 0,
            lastUpdated: block.timestamp
        });

        _token.data = _data;

        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i].token == tk) {
                tokens[i].data = _data;
            }
        }

        openTradingOnUniswap(tk);

        _token.trading = false;
        _token.tradingOnUniswap = true;

        emit Deployed(tk, amount0, amount1);
    }

    function openTradingOnUniswap(address tk) private {
        require(tk != address(0), "Zero addresses are not allowed.");

        ERC20 token_ = ERC20(tk);

        Token storage _token = token[tk];

        require(
            _token.trading && !_token.tradingOnUniswap,
            "trading is already open"
        );

        bool approved = _approval(
            address(uniswapV2Router),
            tk,
            token_.balanceOf(address(this))
        );
        require(approved, "Not approved.");

        address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(tk, uniswapV2Router.WETH());

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            tk,
            token_.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );

        ERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
}
