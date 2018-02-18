pragma solidity ^0.4.18;

// import "./oraclizeAPI_0.4.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract Commit is usingOraclize {

    event logStr(string val);
    event logAddr(address val);
    event logInt(uint val);

    address[] expectedAddresses;
    address[] actualAddresses;

    // Address of the validator
    address nodeAddress;

    // In Wei
    uint256 amountToStake;

    string name;
    uint endTime;
    uint executeTime;

    // Redundant accounting to save on computation
    uint256 balance;

    bool isOver;
    mapping (address => bool) isParticipant;
    mapping (address => bool) isProven;
    mapping (address => string) urlKey;

  // Creates a new Commitment
  function Commit(address _nodeAddress, uint256 _amountToStake, string _name, uint _days,
      uint _hours, uint _minutes, uint _breathingMin) public payable {

      address[] memory emptyAddr1;
      address[] memory emptyAddr2;

      nodeAddress = _nodeAddress;
      expectedAddresses= emptyAddr1;
      actualAddresses= emptyAddr2;
      amountToStake= _amountToStake;
      name= _name;
      endTime= now + _days * 1 days + _hours * 1 hours + _minutes * 1 minutes;
      executeTime= now + _days * 1 days + _hours * 1 hours + _minutes * 1 minutes + _breathingMin * 1 minutes;
      balance= 0;
      isOver= false;
  }



   function joinCommitment() public payable {
      require (msg.value == amountToStake);
      require (now < endTime);

      balance += msg.value;
      expectedAddresses.push(msg.sender);

      // Update mapping for easy access
      isParticipant[msg.sender] = true;
      isProven[msg.sender] = false;
   }



   function proveCommitment(string senderAddrString, string nodeAddrString, string endTimeString, string executeTimeString) public payable {

     // require ((endTime < now) &&(now < executeTime));
     // require (isParticipant[msg.sender]);

    /*
    address senderAddr = parseAddr(senderAddrString);
    address nodeAddr = parseAddr(nodeAddrString);
    uint endTimeVal = stringToUint(endTimeString);
    uint executeTimeVal = stringToUint(executeTimeString);
    */

    string memory test_url1 = makeStr1(senderAddrString, nodeAddrString);

    string memory test_url2 = makeStr2(endTimeString, executeTimeString);

    string memory test_url3 = strConcat(test_url1, test_url2);

    logStr(test_url3);

    urlKey[msg.sender] = test_url3;

    // Necessary checks for later
    /*
    if ((senderAddr == msg.sender) && (nodeAddr == nodeAddress)) {
        if ((endTimeVal == endTime) && (executeTimeVal == executeTime)) {
            logStr("Success!");
        }
    }*/
   }


function submitCommitment() payable {
    // insert more require checks here

    oraclize_query("URL", urlKey[msg.sender]);
}



function makeStr1(string senderAddrString, string nodeAddrString) internal returns (string str_url) {
    string memory base_url = "https://geoproof.herokuapp.com/api/confirm?userAddress=";
    string memory node_url = "&nodeAddress=";
    str_url = strConcat(base_url, senderAddrString, node_url, nodeAddrString);
}



function makeStr2(string endTimeString, string executeTimeString) internal returns (string str_url) {
    string memory begin_url = "&beginTime=";
    string memory end_url = "&endTime=";
    str_url = strConcat(begin_url, endTimeString, end_url, executeTimeString);
}


function stringToUint(string s) constant returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }



   function __callback(bytes32 myid, string result) {
       if (msg.sender != oraclize_cbAddress()) revert();

       logStr(result);

       /*
       address provenAddr = parseAddr(result);
       if (isParticipant[provenAddr] && (! isProven[provenAddr])) {
           isProven[provenAddr] = true;
           actualAddresses.push(provenAddr);
       }*/
   }



   function closeCommitment() public {
     require (now >= executeTime);
     require (isParticipant[msg.sender]);
     require (! isOver);

     // Only allow this function to be called once
     isOver = true;

     uint256 amountToDisburse = balance/actualAddresses.length;

     for (uint i = 0; i < actualAddresses.length; i++) {
       actualAddresses[i].transfer(amountToDisburse);
     }
   }

}
