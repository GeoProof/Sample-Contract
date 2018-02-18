pragma solidity ^0.4.18;

// import "./oraclizeAPI_0.4.sol";
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

/*
Inputs:
"0xDaed2aB0Ba49B268AF6f62a92F3f96001A7a5aF", 10, "hello", 1, 1, 1, 1
"0xb5f13DEbf210395f133CeC286a9Bea5256809AB6", 
"0xDaed2aB0Ba49B268AF6f62a92F3f96001A7a5aFf", "1518945020", "1518945420"
*/

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
    
    mapping (address => string) urlKey1;
    mapping (address => string) urlKey2;
    mapping (address => string) urlKey3;

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



   function proveCommitment() public payable {

     // require ((endTime < now) &&(now < executeTime));
     // require (isParticipant[msg.sender]);

    /*
    address senderAddr = parseAddr(senderAddrString);
    address nodeAddr = parseAddr(nodeAddrString);
    uint endTimeVal = stringToUint(endTimeString);
    uint executeTimeVal = stringToUint(executeTimeString);
    */

    string memory test_url3 = strConcat(urlKey1[msg.sender], urlKey2[msg.sender]);
    logStr(test_url3);

    urlKey3[msg.sender] = test_url3;

    // Necessary checks for later
    /*
    if ((senderAddr == msg.sender) && (nodeAddr == nodeAddress)) {
        if ((endTimeVal == endTime) && (executeTimeVal == executeTime)) {
            logStr("Success!");
        }
    }*/

    //oraclize_query("URL", query_url2);
   }


function submitCommitment() payable {
    // insert more require checks here
    
    oraclize_query("URL", urlKey3[msg.sender]);
}



function makeStr1(string senderAddrString, string nodeAddrString) public payable {
    string memory base_url = "https://geoproof.herokuapp.com/api/confirm?userAddress=";
    string memory node_url = "&nodeAddress=";
    string memory str_url = strConcat(base_url, senderAddrString, node_url, nodeAddrString);
    logStr(str_url);
    urlKey1[msg.sender] = str_url;
}



function makeStr2(string endTimeString, string executeTimeString) public payable {
    string memory begin_url = "&beginTime=";
    string memory end_url = "&endTime=";
    string memory str_url = strConcat(begin_url, endTimeString, end_url, executeTimeString);
    urlKey2[msg.sender] = str_url;
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
       
       address provenAddr = parseAddr(result);
       if (isParticipant[provenAddr] && (! isProven[provenAddr])) {
           isProven[provenAddr] = true;
           actualAddresses.push(provenAddr);
       }
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
