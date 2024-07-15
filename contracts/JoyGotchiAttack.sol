// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IJoyGotchi.sol";
import "./helper/JoyGotchiEnum.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract JoyGotchiAttack {
    using FixedPointMathLib for uint256;
    using SafeMath for uint256;

    IJoyGotchi public joyGotchiNFT;

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
        address _joyGotchiNFT
    ) {
        joyGotchiNFT = IJoyGotchi(_joyGotchiNFT);
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

        (
            uint256 winner,
            uint256 loser,
            uint256 prizeScore
        ) = _caculateOddsAndDeclareWinner(fromId, toId, pct, odds);

        joyGotchiNFT.setPetInfoAfterAttack(winner, loser, prizeScore);

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

        pct = 5; //0.5%
        canAttack = true; //can attack
        uint256 attackedPoints = joyGotchiNFT.getPetAttackPoints(fromId);
        uint256 defensePoints = joyGotchiNFT.getPetDefensePoints(toId);

        if (attackedPoints == 0) {
            canAttack = false;
            return (pct, 0, canAttack);
        }
        // Here is the formula to decide your win probability: (Attacker’s AP) / (Attacker’s AP + Defender’s DP)
        // Since solidity can't work with float, we multiply by 100 to get a percentage
        odds = (attackedPoints * 100) / (attackedPoints + defensePoints);
    }

    function _caculateOddsAndDeclareWinner(
        uint256 fromId,
        uint256 toId,
        uint256 pct,
        uint256 odds
    ) internal returns (uint256 winner, uint256 loser, uint256 prizeScore) {
        // Random a number from 0 to 100 to determine the winner
        uint256 _random = random(fromId + toId) % 101;
        // If the random number is greater than the odds of winning, the attacker loses
        if (_random > odds) {
            winner = toId;
            loser = fromId;
        } else {
            winner = fromId;
            loser = toId;
        }

        uint256 feePercentage = PRECISION.mulDivDown(pct, 1000); // 0.5 pct

        uint256 targetMaxLoss = joyGotchiNFT.petScore(toId).mulDivDown(
            feePercentage,
            PRECISION
        );

        uint256 myMaxLoss = joyGotchiNFT.petScore(fromId).mulDivDown(
            feePercentage,
            PRECISION
        );

        // if I attack with odds of winning greater or equal to 50%
        // if I lose, I can lose 0.5% of target points + odds * target loss (capped to my 0.5%)
        // if I win, I can win .5% of my points + 60% * my loss points (capped at 0.5% of target points)
        if (odds >= 50) {
            if (loser == fromId) {
                prizeScore = targetMaxLoss + odds.mul(targetMaxLoss);
                if (prizeScore > myMaxLoss) {
                    prizeScore = myMaxLoss;
                }
            } else {
                uint256 winPercentage = PRECISION.mulDivDown(60, 100); // 60%
                prizeScore =
                    myMaxLoss +
                    winPercentage.mulDivDown(myMaxLoss, PRECISION);
                if (prizeScore > targetMaxLoss) {
                    prizeScore = targetMaxLoss;
                }
            }
        }
        // if I attack with odds of winning less than 50%
        // if I lose, I lose .5% of target points + (50 - odds) * target loss + 60% * target loss (capped at 0.5% of my points)
        // if I win, I can win .5% of my points + (50 - odds) * my loss + 60% * my loss points (capped at 0.5% of target points)
        else {
            uint256 sixtyPercentWithPrecision = PRECISION.mulDivDown(60, 100);
            if (loser == fromId) {
                prizeScore = targetMaxLoss + (50 - odds).mul(targetMaxLoss);
                prizeScore += sixtyPercentWithPrecision.mulDivDown(
                    targetMaxLoss,
                    PRECISION
                );

                if (prizeScore > myMaxLoss) {
                    prizeScore = myMaxLoss;
                }
            } else {
                prizeScore = myMaxLoss + (50 - odds).mul(myMaxLoss);
                prizeScore += sixtyPercentWithPrecision.mulDivDown(
                    myMaxLoss,
                    PRECISION
                );

                if (prizeScore > targetMaxLoss) {
                    prizeScore = targetMaxLoss;
                }
            }
        }
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
