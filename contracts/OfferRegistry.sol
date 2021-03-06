pragma solidity ^0.4.23;
import "./OfferMultiSig.sol";
import "./OfferLib.sol";

/// @title Creates new Offer Channel contracts and keeps track of them 
contract OfferRegistry {

    struct OfferChannel {
        address msig;
        address ambassador;
        address expert;
    }

    event InitializedChannel(
        address msig,
        address ambassador,
        address expert,
        uint128 guid
    );

    uint128[] public channelsGuids;
    mapping (bytes32 => address) public participantsToChannel;
    mapping (uint128 => OfferChannel) public guidToChannel;

    address public offerLib;
    address public nectarAddress;

    constructor(address _nectarAddress) {
        require(_nectarAddress != address(0));

        offerLib = new OfferLib();
        nectarAddress = _nectarAddress;
    }

    /**
     * Function called by ambassador to initialize an offer contract
     * It deploys a new offer multi sig and saves it for each participant
     * 
     * @param _ambassador address of ambassador
     * @param _expert address of expert
     * @param _settlementPeriodLength how long the parties have to dispute the settlement offer channel
     */

    function initializeOfferChannel(uint128 guid, address _ambassador, address _expert, uint _settlementPeriodLength) external {

        require(address(0) != _expert);
        require(address(0) != _ambassador);
        require(msg.sender == _ambassador);

        bytes32 key = getParticipantsHash(_ambassador, _expert);
        
        if (participantsToChannel[key] != address(0)) {
            /// @dev check to make sure the participants don't already have an open channel
            require(OfferMultiSig(participantsToChannel[key]).isChannelOpen() == false);
        }

        address msig = new OfferMultiSig(offerLib, nectarAddress, _ambassador, _expert, _settlementPeriodLength);

        participantsToChannel[key] = msig;

        guidToChannel[guid].msig = msig;
        guidToChannel[guid].ambassador = _ambassador;
        guidToChannel[guid].expert = _expert;

        channelsGuids.push(guid);

        emit InitializedChannel(msig, _ambassador, _expert, guid);
    }

    /**
     * Get the total number of offer channels tracked by the contract
     *
     * @return total number of offer channels
     */

    function getNumberOfOffers() external view returns (uint) {
        return channelsGuids.length;
    }

    /**
     * Function to get channel participants are on
     * 
     * @param _ambassador the address of ambassador
     * @param _expert the address of ambassador
     */

    function getParticipantsChannel(address _ambassador, address _expert) external view returns (address) {
        bytes32 key = getParticipantsHash(_ambassador, _expert);

        require(participantsToChannel[key] != address(0));
        
        return participantsToChannel[key];
    }

    /**
     * Gets all the created channelsGuids
     *
     * @return list of every channel registered
     */

    function getChannelsGuids() external constant returns (address[]) {
        require(channelsGuids.length != 0);
        
        address[] memory registeredChannelsGuids = new address[](channelsGuids.length);

        for (uint i = 0; i < channelsGuids.length; i++) {
            registeredChannelsGuids[i] = channelsGuids[i];
        }

        return registeredChannelsGuids;
    }

    // Internals

    /**
     * Utility function to get hash
     * 
     * @param _ambassador address of ambassador
     * @param _expert address of expert
     * @return hash of ambassador and expert
     */

    function getParticipantsHash(address _ambassador, address _expert) internal pure returns (bytes32) {
        string memory str_ambassador = toString(_ambassador);
        string memory str_expert = toString(_expert);

        return keccak256(strConcat(str_ambassador, str_expert));
    }

    function toString(address x) internal pure returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }

    function strConcat(string _a, string _b) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        return string(babcde);
    }

    function() payable public {
        revert();
    }
}
