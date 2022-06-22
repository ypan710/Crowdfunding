pragma solidity >= 0.6.0 < 0.9.0;

contract CrowdFunding {
    mapping(address => uint) public balanceOfContributor; // amount of Ether for an address of the contributor
    address public admin;
    uint public numberOfContributors;
    uint public minContribution;
    uint public deadline; // timestamp
    uint public goal;
    uint public raisedAmount;
    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numberOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numberOfRequests;

    event ContributeEvent(address _sender, uint _value);
    event createRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);

    constructor(uint _goal, uint _deadline) {
        deadline = block.timestamp + _deadline;
        goal = _goal;
        minContribution = 100 wei;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "You are not the admin!");
        _;
    }

    receive() payable external {
        contribute();
    }

    // create a spending request
    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        // save a copy of the request in storage
        Request storage newRequest = requests[numberOfRequests];
        numberOfRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numberOfVoters = 0;
        emit createRequestEvent(_description, _recipient, _value);
    }

    // send money to the campaign
    function contribute() public payable {
        require(block.timestamp <= deadline, "Deadline to contribute has passed!");
        require(msg.value >= minContribution, "You need to contribute at least 100 wei!"); 
        if (balanceOfContributor[msg.sender] == 0) {
            numberOfContributors++;
        }
        balanceOfContributor[msg.sender] += msg.value;  
        raisedAmount += msg.value;   
        emit ContributeEvent(msg.sender, msg.value);
    }

    // get total balance of the contract
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // get a refund
    function getRefund() public {
        require(block.timestamp > deadline, "The deadline to contribute hasn't passed!");
        require(raisedAmount < goal, "The raised amount is greater than the goal!");
        require(balanceOfContributor[msg.sender] > 0, "There is no balance to refund!");
        address payable recipient;
        balanceOfContributor[payable(msg.sender)] = 0;
        recipient.transfer(balanceOfContributor[msg.sender]);
    }

    // vote on a spending request
    function voteRequest(uint _requestNumber) public {
        require(balanceOfContributor[msg.sender] > 0, "You must be a contributor to vote!");
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.voters[msg.sender] == false, "You have voted already!");
        thisRequest.voters[msg.sender] = true;
        thisRequest.numberOfVoters++;
    }

    // make a payment for a voted request that has a specific index
    function makePayment(uint _requestNumber) public onlyAdmin{
        require(raisedAmount >= goal, "The raised amount is less than the goal!");
        Request storage thisRequest = requests[_requestNumber];
        require(thisRequest.completed == false, "The request has been completed!");
        // half of the contributors voted for this request
        require(thisRequest.numberOfVoters > numberOfContributors / 2, "You need at least half of the voters to vote for this request!");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }

}