//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import {IEntropy} from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Entropy is IEntropyConsumer, Ownable {
    IEntropy public entropy;

    event RandomSeedRequested(uint64 indexed userRandomNumber, address wallet);
    event RandomSeedReceived(uint64 indexed userRandomNumber, uint256 response);

    // wallet's random seed
    mapping(address => uint256) public walletSeed;
    mapping(address => uint256) public walletLastSeedUpdate;
    mapping(uint64 => address) public sequenceNumberToWallet;
    uint256 public seedUpdateInterval = 1 hours;


    // @param entropyAddress The address of the entropy contract.
    constructor(address entropyAddress) {
        entropy = IEntropy(entropyAddress);
    }


    function getWalletSeedAndUpdateIfNeeded() external payable returns (uint256) {
        if (
            block.timestamp - walletLastSeedUpdate[msg.sender] >
            seedUpdateInterval
        ) {
        address entropyProvider = entropy.getDefaultProvider();
        uint256 fee = entropy.getFee(entropyProvider);

        bytes32 userSeed = keccak256(abi.encodePacked(msg.sender, block.timestamp));

        // Request the random number with the callback
        uint64 sequenceNumber = entropy.requestWithCallback{value: fee}(
            entropyProvider,
            userSeed
        );

        sequenceNumberToWallet[sequenceNumber] = msg.sender;
        emit RandomSeedRequested(sequenceNumber, msg.sender);
            walletLastSeedUpdate[msg.sender] = block.timestamp;
        }
        return walletSeed[msg.sender];
    }


    // @param sequenceNumber The sequence number of the request.
    // @param provider The address of the provider that generated the random number. If your app uses multiple providers, you can use this argument to distinguish which one is calling the app back.
    // @param randomNumber The generated random number.
    // This method is called by the entropy contract when a random number is generated.
    function entropyCallback(
        uint64 sequenceNumber,
        address provider,
        bytes32 randomNumber
    ) internal override {
        // Implement your callback logic here.
        require(msg.sender == address(entropy), "Unauthorized entropy callback");
        
        uint256 entropyUint256 = uint256(randomNumber);
        walletSeed[sequenceNumberToWallet[sequenceNumber]] = entropyUint256;
        emit RandomSeedReceived(sequenceNumber, entropyUint256);

    }

    // This method is required by the IEntropyConsumer interface.
    // It returns the address of the entropy contract which will call the callback.
    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }

    function setSeedUpdateInterval(
        uint256 _seedUpdateInterval
    ) external onlyOwner {
        seedUpdateInterval = _seedUpdateInterval;
    }
    function getRandomFee() public view returns (uint256 fee) {
        fee = entropy.getFee(entropy.getDefaultProvider());
    }

}
