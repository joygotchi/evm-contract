// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IJoyGotchi.sol";
import "./interfaces/IJoyGotchiItem.sol";
import "./interfaces/IToken.sol";
import "./JoyGotchiEnum.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract JoyGotchiBreed {
    using FixedPointMathLib for uint256;
    using SafeMath for uint256;

    IJoyGotchi public joyGotchiNFT;
    IJoyGotchiItem public joyGotchiNFTItem;
    IToken public token;
    address public treasury;

    uint256 PRECISION = 1 ether;

    mapping(uint256 => uint256) public lastAttackUsed;
    mapping(uint256 => uint256) public lastAttacked;

    event Attack(
        uint256 attacker,
        uint256 winner,
        uint256 loser,
        uint256 scoresWon
    );

    event AttackBlocked(uint256 fromId, uint256 toId);

    constructor(
        address _joyGotchiNFT,
        address _joyGotchiNFTItem,
        address _token,
        address _treasury
    ) {
        joyGotchiNFT = IJoyGotchi(_joyGotchiNFT);
        joyGotchiNFTItem = IJoyGotchiItem(_joyGotchiNFTItem);
        token = IToken(_token);
        treasury = _treasury;
    }

    modifier isApprovedJoyGotchiNFT(uint256 id) {
        require(
            joyGotchiNFT.ownerOf(id) == msg.sender ||
                joyGotchiNFT.getApproved(id) == msg.sender,
            "Not approved"
        );
        _;
    }

    function attack(
        uint256 fromId,
        uint256 toId
    ) external isApprovedJoyGotchiNFT(fromId) {
        require(fromId != toId, "Can't hurt yourself");
        require(joyGotchiNFT.isPetAlive(fromId), "Your pet is dead");
        require(
            joyGotchiNFT.isPetLocked(fromId) == false,
            "Your pet is locked"
        );
        require(joyGotchiNFT.isPetLocked(toId) == false, "Their pet is locked");

        if (joyGotchiNFT.petShield(toId) > 0) {
            joyGotchiNFT.reducePetShield(toId);
            emit AttackBlocked(fromId, toId);
            return;
        }

        (uint256 pct, uint256 odds, bool canAttack) = onAttack(fromId, toId);

        if (!canAttack) {
            return;
        }

        lastAttackUsed[fromId] = block.timestamp;
        lastAttacked[toId] = block.timestamp;

        uint256 loser;
        uint256 winner;

        uint256 _random = random(fromId + toId) % 100;

        if (_random > odds) {
            loser = fromId;
            winner = toId;
        } else {
            loser = toId;
            winner = fromId;
        }

        uint256 feePercentage = PRECISION.mulDivDown(pct, 1000); // 0.5 pct
        uint256 prizeScore = joyGotchiNFT.petScore(loser).mulDivDown(
            feePercentage,
            PRECISION
        );

        uint256 prizeDebt = joyGotchiNFT.petRewardDebt(loser).mulDivDown(
            feePercentage,
            PRECISION
        );

        joyGotchiNFT.setPetInfoAfterAttack(
            loser,
            winner,
            prizeScore,
            prizeDebt
        );

        joyGotchiNFT.checkPetEvoleAndUpdateIfNeeded(fromId);
        joyGotchiNFT.checkPetEvoleAndUpdateIfNeeded(toId);

        emit Attack(fromId, winner, loser, prizeScore);
    }

    function onAttack(
        uint256 fromId,
        uint256 toId
    ) internal view returns (uint256 pct, uint256 odds, bool canAttack) {
        require(
            block.timestamp >= lastAttackUsed[fromId] + 15 minutes ||
                lastAttackUsed[fromId] == 0,
            "You have one attack every 15 mins"
        );
        require(
            block.timestamp > lastAttacked[fromId] + 1 hours,
            "can be attacked once every hour"
        );

        require(
            joyGotchiNFT.level(fromId) < joyGotchiNFT.level(toId),
            "Only attack pets above your level"
        );

        pct = 5; //0.5%
        odds = joyGotchiNFT.getPetAttackPoints(fromId);
        canAttack = true; //can attack
    }

    function random(uint256 seed) private returns (uint) {
        uint256 walletSeed = joyGotchiNFT.getWalletSeedAndUpdateIfNeeded();
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        seed,
                        block.prevrandao,
                        block.timestamp,
                        msg.sender,
                        walletSeed
                    )
                )
            );
    }
}
