pragma solidity ^0.4.24;


contract Owned {
    
    address public  owner;

    constructor() public {
        owner = msg.sender;     
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
         owner = newOwner;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract DecEnergyM is Owned {
    
    mapping(address => bool) public permit;
    mapping(address => uint256) public purchaseDeposit;
    mapping(address => uint256) public total_requested;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public purchase_Request;  
    mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => bool)))) public triggered;  
    
    event Trigger(address _from, address _to, uint256 amount, uint256 price);
    event SendEnergy(address _from, address _to, uint256 amount, uint256 price);
    
    function addDeposit() payable public {
        require(permit[msg.sender] == true);  //Only permitted address can deposit
        require(purchaseDeposit[msg.sender]  + msg.value >= purchaseDeposit[msg.sender]); // Prohibiting Overflow
        purchaseDeposit[msg.sender]  += msg.value;   // Value in wei
    }
       
    function getOrRevokePermision(address _transactor, bool _permission) public onlyOwner {
        
        permit[_transactor] = _permission;   
    }
    
    function purchaseRequest(address _from, uint256 amount, uint256 price) public {
        
        require(permit[msg.sender] == true);  //Only permitted address can buy power
        require(purchaseDeposit[msg.sender] >= price);
        require(price + total_requested[msg.sender] >= total_requested[msg.sender]); // Prohibiting Overflow
        require(purchaseDeposit[msg.sender] >= price + total_requested[msg.sender]); // Addition of total requests price and this price should be less than purchse deposit
        total_requested[msg.sender] += price; 
        purchase_Request[_from][msg.sender][amount] = price;
        
    } 

    function offPurchaseRequest(address  _from, uint256 amount) public {
        
        require(permit[msg.sender]==true);  //Only permitted address
        
        uint256 previosPrice = purchase_Request[_from][msg.sender][amount];

        require(total_requested[msg.sender] >= previosPrice); // Prohibiting Overflow
        total_requested[msg.sender] -= previosPrice; 
        purchase_Request[_from][msg.sender][amount] = 0;  
    }     
      
    function trigger(address _to, uint256 amount, uint256 price) public {
        
        require(permit[msg.sender] == true);  //Only permitted address can sell power
        triggered[msg.sender][_to][amount][price] = true;
        emit Trigger(msg.sender, _to, amount, price);
    }

    function acceptOrDeny(address _from, address _to, bool acceptance, uint256 amount) public onlyOwner {
        
        require(permit[_from] == true);  //Only permitted address can sell power
        require(permit[_to] == true);    //Only permitted address can buy power
        
        uint256 buyPrice = purchase_Request[_from][_to][amount];  //Getting the price buyer wants to pay
        require(triggered[_from][_to][amount][buyPrice] = true);  //Checking whether the seller agree to sell at that price
        
        if(acceptance == true) {

            require(total_requested[_to] >= buyPrice);  // Prohibiting Underflow
            total_requested[_to] -= buyPrice;  
        
            require(purchaseDeposit[_to] >= buyPrice);  // Prohibiting Underflow
            purchaseDeposit[_to] -= buyPrice;  
        
            emit SendEnergy(_from, _to, amount, buyPrice);
            triggered[_from][_to][amount][buyPrice] = false;
            purchase_Request[_from][_to][amount] = 0;
            _from.transfer(buyPrice);
        } else {
            triggered[_from][_to][amount][buyPrice] = false;
            purchase_Request[_from][_to][amount] = 0;                     
        }   
    }
    
}

