// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ERC721} from "solmate/src/tokens/ERC721.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IGameManager} from "./interfaces/IGameManager.sol";
import {IGenePool} from "./interfaces/IGenePool.sol";
import "./QRNG.sol";
import "./PetStatus.sol";
import "./interfaces/IToken.sol";

// ERC721,
contract JoyGotchiV2 is QRNG, ERC721 {
    using SafeTransferLib for address payable;
    using FixedPointMathLib for uint256;
    using SafeMath for uint256;

    uint public mintPrice = 1 ether;

    uint256 PRECISION = 1 ether;

    IToken public token;

    uint256 public _tokenIds;
    uint256 public _itemIds;

    uint256 public la = 2;
    uint256 public lb = 2;

    uint256 public speciesCount;

    struct Evolution {
        string image;
        string name;
        uint256 attackPoints;
        uint256 defensePoints;
        uint256 nextEvolutionLevel;
    }

    struct Species {
        uint256 id;
        uint256 genePoolNum;
    }

    struct SpeciesDefaultAttrs {
        uint256 skinColor;
        uint256 hornStyle;
        uint256 wingStyle;
    }

    mapping(uint256 => Species) public speciesList;
    mapping(uint256 => mapping(uint256 => Evolution))
        public speciesToEvolutions;
    mapping(uint256 => uint256) public speciesMaxEvolutionPhase;
    mapping(uint256 => uint256) public speciesMaxPopulation;
    mapping(uint256 => SpeciesDefaultAttrs) public speciesDefaultAttrs;
    mapping(uint256 => uint256) public currentSpeciesPopulation;

    // pet properties
    mapping(uint256 => string) public petName;
    mapping(uint256 => uint256) public timeUntilStarving;
    mapping(uint256 => uint256) public petScore;
    mapping(uint256 => uint256) public timePetBorn;
    mapping(uint256 => uint256) public lastAttackUsed;
    mapping(uint256 => uint256) public lastAttacked;
    mapping(uint256 => uint256) public petSpecies;
    mapping(uint256 => uint256) public petSex;
    mapping(uint256 => uint256) public petSkinColor;
    mapping(uint256 => uint256) public petHornStyle;
    mapping(uint256 => uint256) public petWingStyle;
    mapping(uint256 => uint256) public petEvolutionPhase;
    mapping(uint256 => bool) public petHasParents;
    mapping(uint256 => uint256[2]) public petParentsId;
    mapping(uint256 => uint256) public petShield;

    // vritual staking
    mapping(uint256 => uint256) public ethOwed;
    mapping(uint256 => uint256) public petRewardDebt;

    uint256 public ethAccPerShare;

    uint256 public totalScores = 0;

    // items/benefits for the pet, general so can be food or anything in the future.
    mapping(uint256 => uint256) public itemPrice;
    mapping(uint256 => uint256) public itemPriceDelta;
    mapping(uint256 => uint256) public itemStock;
    mapping(uint256 => uint256) public itemPoints;
    mapping(uint256 => string) public itemName;
    mapping(uint256 => uint256) public itemTimeExtension;
    mapping(uint256 => uint256) public itemShield;
    mapping(uint256 => uint256) public itemAttackBoost;
    mapping(uint256 => uint256) public itemDefenseBoost;
    mapping(uint256 => bool) public itemIsRevival;

    uint256 public hasTheDiamond;

    address public breedContract;
    IGameManager public gameManager; //way to expand the game mechanics.
    IGenePool public genePool;

    /*//////////////////////////////////////////////////////////////
                             Events
    //////////////////////////////////////////////////////////////*/

    event SpeciesCreated(
        uint256 id,
        uint256 genePoolNum,
        uint256 speciesMaxPopulation
    );

    event ItemConsumed(uint256 nftId, address giver, uint256 itemId);
    event PetKilled(
        uint256 nftId,
        uint256 deadId,
        string loserName,
        uint256 reward,
        address killer,
        string winnerName
    );
    event ItemCreated(
        uint256 id,
        string name,
        uint256 price,
        uint256 points,
        uint256 timeExtension,
        uint256 shield,
        uint256 itemAttackBoost,
        uint256 itemDefenseBoost,
        bool isRevival
    );
    event Attack(
        uint256 attacker,
        uint256 winner,
        uint256 loser,
        uint256 scoresWon
    );

    event AttackBlocked(uint256 fromId, uint256 toId);

    event RedeemRewards(uint256 indexed petId, uint256 reward);

    event Pass(uint256 from, uint256 to);

    constructor(
        address _token,
        address _qrngAirnode
    ) QRNG(_qrngAirnode) ERC721("Joy Gotchi", "Joy Gotchi") {
        token = IToken(_token);
    }

    modifier isApproved(uint256 id) {
        require(
            ownerOf(id) == msg.sender || getApproved[id] == msg.sender,
            "Not approved"
        );

        _;
    }

    modifier onlyBreed() {
        require(msg.sender == breedContract, "Unauthorized");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        Game Actions
    //////////////////////////////////////////////////////////////*/

    function mint() public {
        // require(_tokenIds < 20_000, "Over the limit");

        token.burnFrom(msg.sender, mintPrice);

        timeUntilStarving[_tokenIds] = block.timestamp + 1 days;
        timePetBorn[_tokenIds] = block.timestamp;

        (uint256 newPetSpecies, uint256 newPetSex) = genePool.generateGene(
            msg.sender,
            _tokenIds,
            _getWalletSeedAndUpdateIfNeeded()
        );
        currentSpeciesPopulation[newPetSpecies] += 1;
        petSpecies[_tokenIds] = newPetSpecies;
        petSkinColor[_tokenIds] = speciesDefaultAttrs[newPetSpecies].skinColor;
        petHornStyle[_tokenIds] = speciesDefaultAttrs[newPetSpecies].hornStyle;
        petWingStyle[_tokenIds] = speciesDefaultAttrs[newPetSpecies].wingStyle;
        petSex[_tokenIds] = newPetSex;

        // mint NFT
        _mint(msg.sender, _tokenIds);
        _tokenIds++;
    }

    function buyImidiateUseItem(
        uint256 nftId,
        uint256 itemId
    ) external payable isApproved(nftId) {
        require(itemExists(itemId), "This item doesn't exist");
        require(
            isPetAlive(nftId) || (!isPetAlive(nftId) && itemIsRevival[itemId]),
            "pet dead or not revival item"
        ); //no revives
        require(itemStock[itemId] > 0, "Out of stock");

        // bool shouldContinue = gameManager.onBuyAccessory(nftId, itemId);

        // if (!shouldContinue) return;

        uint256 amount = itemPrice[itemId];

        // recalculate time until starving
        timeUntilStarving[nftId] += itemTimeExtension[itemId];

        if (petScore[nftId] > 0) {
            ethOwed[nftId] = pendingEth(nftId);
        }

        petScore[nftId] += itemPoints[itemId];
        petShield[nftId] += itemShield[itemId];

        petRewardDebt[nftId] = petScore[nftId].mulDivDown(
            ethAccPerShare,
            PRECISION
        );

        totalScores += itemPoints[itemId];

        itemPrice[itemId] += itemPriceDelta[itemId];
        itemStock[itemId] -= 1;

        token.burnFrom(msg.sender, amount);

        _getWalletSeedAndUpdateIfNeeded();
        _evolvePetIfNeeded(nftId);

        emit ItemConsumed(nftId, msg.sender, itemId);
    }

    function attack(uint256 fromId, uint256 toId) external isApproved(fromId) {
        require(fromId != toId, "Can't hurt yourself");
        require(isPetAlive(fromId), "Your pet is dead");

        if (petShield[toId] > 0) {
            petShield[toId] -= 1;
            emit AttackBlocked(fromId, toId);
            return;
        }

        (uint256 pct, uint256 odds, bool canAttack) = gameManager.onAttack(
            fromId,
            toId
        );

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
        uint256 prizeScore = petScore[loser].mulDivDown(
            feePercentage,
            PRECISION
        );

        uint256 prizeDebt = petRewardDebt[loser].mulDivDown(
            feePercentage,
            PRECISION
        );

        petScore[loser] -= prizeScore;
        petRewardDebt[loser] -= prizeDebt;

        petScore[winner] += prizeScore;
        petRewardDebt[winner] += prizeDebt;

        _evolvePetIfNeeded(fromId);
        _evolvePetIfNeeded(toId);

        emit Attack(fromId, winner, loser, prizeScore);
    }

    // kill and burn pets and get in game stars.
    function kill(
        uint256 _deadId,
        uint256 _tokenId
    ) external isApproved(_tokenId) {
        require(
            !isPetAlive(_deadId),
            "The pet has to be starved to claim his points"
        );

        if (hasTheDiamond == _deadId) {
            hasTheDiamond = _tokenId;
        }

        uint256 speciesOfDead = petSpecies[_deadId];
        address ownerOfDead = ownerOf(_deadId);

        _burn(_deadId);
        currentSpeciesPopulation[speciesOfDead] -= 1;
        // redeem for dead pet
        _redeem(_deadId, ownerOfDead);
        _getWalletSeedAndUpdateIfNeeded();
        _evolvePetIfNeeded(_tokenId);

        emit PetKilled(
            _tokenId,
            _deadId,
            petName[_deadId],
            1,
            msg.sender,
            petName[_tokenId]
        );
    }

    function setPetName(
        uint256 _id,
        string memory _name
    ) external isApproved(_id) {
        petName[_id] = _name;
    }

    function checkEvolveBeforeBreed(uint256 _nftId) external onlyBreed {
        _evolvePetIfNeeded(_nftId);
    }

    function addPetScoreAfterBreed(
        uint256 _nftId,
        uint256 _score
    ) external onlyBreed {
        petScore[_nftId] += _score;
        totalScores += _score;
    }

    function createNewPetAfterBreed(
        uint256 _random,
        uint256 _newPetSpecies,
        uint256 _parent1Id,
        uint256 _parent2Id
    ) external onlyBreed {
        uint256 _newPetSkinColor = (_random + 2) % genePool.skinColorGeneNum();
        uint256 _newPetHornStyle = (_random + 3) % genePool.hornStyleGeneNum();
        uint256 _newPetWingStyle = (_random + 4) % genePool.wingStyleGeneNum();
        uint256 _newPetSex = (_random + 5) % 2;

        currentSpeciesPopulation[_newPetSpecies] += 1;
        petSpecies[_tokenIds] = _newPetSpecies;
        petSkinColor[_tokenIds] = _newPetSkinColor;
        petHornStyle[_tokenIds] = _newPetHornStyle;
        petWingStyle[_tokenIds] = _newPetWingStyle;
        petSex[_tokenIds] = _newPetSex;
        petHasParents[_tokenIds];
        petParentsId[_tokenIds] = [_parent1Id, _parent2Id];
        timeUntilStarving[_tokenIds] = block.timestamp + 1 days;
        timePetBorn[_tokenIds] = block.timestamp;

        // mint NFT
        _mint(msg.sender, _tokenIds);
        _tokenIds++;
    }

    function _evolvePetIfNeeded(uint256 _nftId) internal {
        uint256 currentEvolutionPhase = petEvolutionPhase[_nftId];

        uint256 nextEvolutionPhase = getPetEvolutionPhase(_nftId);

        if (currentEvolutionPhase < nextEvolutionPhase) {
            petEvolutionPhase[_nftId] = nextEvolutionPhase;
        }
    }

    // just side quest for later to add to ui, one thing in the game that can be passed to other players
    function pass(uint256 from, uint256 to) external isApproved(from) {
        require(hasTheDiamond == from, "you don't have it");
        require(ownerOf(to) != address(0x0), "don't burn it");

        hasTheDiamond = to;

        emit Pass(from, to);
    }

    /*//////////////////////////////////////////////////////////////
                        Game Getters
    //////////////////////////////////////////////////////////////*/
    function getPetEvolutionPhase(
        uint256 _nftId
    ) public view returns (uint256) {
        uint256 _species = petSpecies[_nftId];
        uint256 _evolutionPhase = petEvolutionPhase[_nftId];
        if (_evolutionPhase < speciesMaxEvolutionPhase[_species]) {
            return _getPetEvolutionPhase(_nftId, _evolutionPhase);
        } else {
            return speciesMaxEvolutionPhase[_species];
        }
    }

    function getStatus(uint256 pet) public view returns (Status _health) {
        if (!isPetAlive(pet)) {
            return Status.DEAD;
        }

        if (timeUntilStarving[pet] > block.timestamp + 16 hours)
            return Status.HAPPY;
        if (
            timeUntilStarving[pet] > block.timestamp + 12 hours &&
            timeUntilStarving[pet] < block.timestamp + 16 hours
        ) return Status.HUNGRY;

        if (
            timeUntilStarving[pet] > block.timestamp + 8 hours &&
            timeUntilStarving[pet] < block.timestamp + 12 hours
        ) return Status.STARVING;

        if (timeUntilStarving[pet] < block.timestamp + 8 hours)
            return Status.DYING;
    }

    function itemExists(uint256 itemId) public view returns (bool) {
        if (bytes(itemName[itemId]).length > 0) {
            return true;
        } else {
            return false;
        }
    }

    // check that Pet didn't starve
    function isPetAlive(uint256 _nftId) public view returns (bool) {
        uint256 _timeUntilStarving = timeUntilStarving[_nftId];
        if (_timeUntilStarving != 0 && _timeUntilStarving >= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function getItemInfo(
        uint256 _itemId
    )
        public
        view
        returns (
            string memory _name,
            uint256 _price,
            uint256 _points,
            uint256 _timeExtension
        )
    {
        _name = itemName[_itemId];
        _price = itemPrice[_itemId];
        _timeExtension = itemTimeExtension[_itemId];
        _points = itemPoints[_itemId];
    }

    function getPetGenes(
        uint256 _nftId
    ) public view returns (string memory genes) {
        genes = string(
            abi.encodePacked(
                _uint2str(petSpecies[_nftId]),
                _uint2str(petSkinColor[_nftId]),
                _uint2str(petHornStyle[_nftId]),
                _uint2str(petWingStyle[_nftId]),
                _uint2str(petSex[_nftId])
            )
        );
    }

    function getPetInfo(
        uint256 _nftId
    )
        public
        view
        returns (
            string memory _name,
            Status _status,
            uint256 _score,
            uint256 _level,
            uint256 _timeUntilStarving,
            uint256 _lastAttacked,
            uint256 _lastAttackUsed,
            address _owner,
            uint256 _rewards,
            string memory _genes
        )
    {
        _name = petName[_nftId];
        _status = getStatus(_nftId);
        _score = petScore[_nftId];
        _level = level(_nftId);
        _timeUntilStarving = timeUntilStarving[_nftId];
        _lastAttacked = lastAttacked[_nftId];
        _lastAttackUsed = lastAttackUsed[_nftId];
        _owner = !isPetAlive(_nftId) && _score == 0
            ? address(0x0)
            : ownerOf(_nftId);
        _rewards = pendingEth(_nftId);
        _genes = getPetGenes(_nftId);
    }

    function getPetEvolutionInfo(
        uint256 _nftId
    )
        external
        view
        returns (
            uint256 _species,
            uint256 _evolutionPhase,
            uint256 _maxEvolutionPhase,
            string memory _image,
            string memory _speciesName,
            uint256 _attackPoints,
            uint256 _defensePoints
        )
    {
        _species = petSpecies[_nftId];
        _evolutionPhase = petEvolutionPhase[_nftId];
        _maxEvolutionPhase = speciesMaxEvolutionPhase[petSpecies[_nftId]];
        _image = speciesToEvolutions[_species][_evolutionPhase].image;
        _speciesName = speciesToEvolutions[_species][_evolutionPhase].name;
        _attackPoints = speciesToEvolutions[_species][_evolutionPhase]
            .attackPoints;
        _defensePoints = speciesToEvolutions[_species][_evolutionPhase]
            .defensePoints;
    }

    function getPetAttributes(
        uint256 _nftId
    )
        public
        view
        returns (
            uint256 _species,
            uint256 _skinColor,
            uint256 _hornStyle,
            uint256 _wingStyle,
            uint256 _sex,
            uint256[2] memory _parentsId
        )
    {
        _species = petSpecies[_nftId];
        _skinColor = petSkinColor[_nftId];
        _hornStyle = petHornStyle[_nftId];
        _wingStyle = petWingStyle[_nftId];
        _sex = petSex[_nftId];
        _parentsId = petParentsId[_nftId];
    }

    function getPetAttackPoints(
        uint256 _nftId
    ) public view returns (uint256 _attackPoints) {
        uint256 _species = petSpecies[_nftId];
        uint256 _evolutionPhase = petEvolutionPhase[_nftId];
        _attackPoints = speciesToEvolutions[_species][_evolutionPhase]
            .attackPoints;
    }

    function getPetDefensePoints(
        uint256 _nftId
    ) public view returns (uint256 _defensePoints) {
        uint256 _species = petSpecies[_nftId];
        uint256 _evolutionPhase = petEvolutionPhase[_nftId];
        _defensePoints = speciesToEvolutions[_species][_evolutionPhase]
            .defensePoints;
    }

    function getPetImage(
        uint256 _nftId
    ) public view returns (string memory _image) {
        uint256 _species = petSpecies[_nftId];
        uint256 _evolutionPhase = petEvolutionPhase[_nftId];
        _image = speciesToEvolutions[_species][_evolutionPhase].image;
    }

    /*//////////////////////////////////////////////////////////////
                        Metadata
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view override returns (string memory) {
        // uint256 a = id;
        string memory image = getPetImage(id);
        string memory attributes = string(
            abi.encodePacked('", "attributes":[', _generateMetadata(id), "]}")
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    (
                        (
                            abi.encodePacked(
                                '{"name":"Joy Gotchi #',
                                _uint2str(id),
                                '","image": ',
                                '"',
                                image,
                                attributes
                            )
                        )
                    )
                )
            );
    }

    function _generateMetadata(
        uint256 id
    ) internal view returns (string memory) {
        uint256 _score = petScore[id];
        uint256 _level = level(id);
        Status status = getStatus(id);

        string memory metadata = string(
            abi.encodePacked(
                '{"trait_type": "Score","value":"',
                _uint2str(_score),
                '"},{"trait_type": "Level","value":"',
                _uint2str(_level),
                '"},{"trait_type": "Status","value":"',
                _uint2str(uint256(status)),
                '"}'
            )
        );
        return metadata;
    }

    // calculate level based on points
    function level(uint256 tokenId) public view returns (uint256) {
        // This is the formula L(x) = 2 * sqrt(x * 2)

        uint256 _score = petScore[tokenId] / 1e12;
        _score = _score / 100;
        if (_score == 0) {
            return 1;
        }
        uint256 _level = _sqrtu(_score * la);
        return (_level * lb);
    }

    /*//////////////////////////////////////////////////////////////
                         Virtual Staking Logic
    //////////////////////////////////////////////////////////////*/

    function pendingEth(uint256 petId) public view returns (uint256) {
        uint256 _ethAccPerShare = ethAccPerShare;

        //petRewardDebt can sometimes be bigger by 1 wei do to several mulDivDowns so we do extra checks
        if (
            petScore[petId].mulDivDown(_ethAccPerShare, PRECISION) <
            petRewardDebt[petId]
        ) {
            return ethOwed[petId];
        } else {
            return
                (petScore[petId].mulDivDown(_ethAccPerShare, PRECISION))
                    .sub(petRewardDebt[petId])
                    .add(ethOwed[petId]);
        }
    }

    function _redeem(uint256 petId, address _to) internal {
        uint256 pending = pendingEth(petId);

        totalScores -= petScore[petId];
        petScore[petId] = 0;
        ethOwed[petId] = 0;
        petRewardDebt[petId] = 0;

        payable(_to).safeTransferETH(pending);

        emit RedeemRewards(petId, pending);
    }

    function redeem(uint256 petId) public isApproved(petId) {
        _redeem(petId, ownerOf(petId));
    }

    /*//////////////////////////////////////////////////////////////
                        Admin Functions
    //////////////////////////////////////////////////////////////*/
    function setBreedContract(address _breedContract) external onlyOwner {
        breedContract = _breedContract;
    }

    function setGameManager(IGameManager _gameManager) external onlyOwner {
        gameManager = _gameManager;
    }

    function setGenePool(IGenePool _genePool) external onlyOwner {
        genePool = _genePool;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function createSpecies(
        Evolution[] memory _evolutions,
        uint256 _genePoolNum,
        SpeciesDefaultAttrs memory _defaultAttrs,
        uint256 _speciesMaxPopulation
    ) external onlyOwner {
        uint speciesId = speciesCount;
        speciesList[speciesCount] = Species(speciesId, _genePoolNum);
        for (uint256 i = 0; i < _evolutions.length; i++) {
            speciesToEvolutions[speciesId][i] = _evolutions[i];
        }

        speciesMaxEvolutionPhase[speciesId] = _evolutions.length - 1;
        speciesMaxPopulation[speciesId] = _speciesMaxPopulation;
        speciesDefaultAttrs[speciesId] = _defaultAttrs;

        genePool.addSpeciesToGenePool(speciesId, _genePoolNum);
        speciesCount++;
        emit SpeciesCreated(speciesId, _genePoolNum, _speciesMaxPopulation);
    }

    // add items
    function createItem(
        string calldata name,
        uint256 price,
        uint256 priceDelta,
        uint256 stock,
        uint256 points,
        uint256 timeExtension,
        uint256 shield,
        uint256 attackBoost,
        uint256 defenseBoost,
        bool isRevival
    ) external onlyOwner {
        uint256 newItemId = _itemIds;
        itemName[newItemId] = name;
        itemPrice[newItemId] = price;
        itemPriceDelta[newItemId] = priceDelta;
        itemStock[newItemId] = stock;
        itemPoints[newItemId] = points;
        itemTimeExtension[newItemId] = timeExtension;
        itemShield[newItemId] = shield;
        itemAttackBoost[newItemId] = attackBoost;
        itemDefenseBoost[newItemId] = defenseBoost;
        itemIsRevival[newItemId] = isRevival;

        _itemIds++;

        emit ItemCreated(
            newItemId,
            name,
            price,
            points,
            timeExtension,
            shield,
            attackBoost,
            defenseBoost,
            isRevival
        );
    }

    function editItem(
        uint256 _id,
        string calldata _name,
        uint256 _price,
        uint256 _priceDelta,
        uint256 _stock,
        uint256 _points,
        uint256 _timeExtension,
        uint256 _shield,
        bool _isRevival
    ) external onlyOwner {
        itemPrice[_id] = _price;
        itemPriceDelta[_id] = _priceDelta;
        itemStock[_id] = _stock;
        itemPoints[_id] = _points;
        itemName[_id] = _name;
        itemTimeExtension[_id] = _timeExtension;
        itemShield[_id] = _shield;
        itemIsRevival[_id] = _isRevival;
    }

    /**
     * Calculate the next evolution phase of a pet. If the pet is ready to evolve, the function will call itself recursively until the pet is not ready to evolve.
     * @param _nftId The NFT ID of the pet.
     * @param currentEvoPhase The current evolution phase of the pet.
     */
    function _getPetEvolutionPhase(
        uint256 _nftId,
        uint256 currentEvoPhase
    ) private view returns (uint256) {
        uint256 _species = petSpecies[_nftId];
        uint256 evoLevel = speciesToEvolutions[_species][currentEvoPhase]
            .nextEvolutionLevel;
        if (level(_nftId) >= evoLevel) {
            return _getPetEvolutionPhase(_nftId, currentEvoPhase + 1);
        }
        return currentEvoPhase;
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function _sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }

    function random(uint256 seed) private returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        seed,
                        block.prevrandao,
                        block.timestamp,
                        msg.sender,
                        _getWalletSeedAndUpdateIfNeeded()
                    )
                )
            );
    }

    function _uint2str(
        uint256 _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    receive() external payable {
        ethAccPerShare += msg.value.mulDivDown(PRECISION, totalScores);
    }
}
