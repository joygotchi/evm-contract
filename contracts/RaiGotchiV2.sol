// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ERC721} from "solmate/src/tokens/ERC721.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IGenePool} from "./interfaces/IGenePool.sol";
import {QRNG} from "./QRNG.sol";
import "./interfaces/IToken.sol";
import "./helper/RaiGotchiEnum.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

// ERC721,
contract RaiGotchiV2 is QRNG, ERC721, Pausable {
    using SafeTransferLib for address payable;
    using FixedPointMathLib for uint256;
    using SafeMath for uint256;

    uint public mintPrice = 1 ether;

    uint256 PRECISION = 1 ether;

    IToken public token;
    IGenePool public genePool;

    address public breedContract;
    address public attackContract;
    address public immidiateUseItemsContract;
    address public treasury;

    uint256 public la = 2;
    uint256 public lb = 2;

    // Count pet id
    uint256 public _tokenIds;

    // pet properties
    mapping(uint256 => string) public petName;
    mapping(uint256 => uint256) public timeUntilStarving;
    mapping(uint256 => uint256) public petScore;
    mapping(uint256 => uint256) public timePetBorn;
    mapping(uint256 => uint256) public petSpecies;
    mapping(uint256 => uint256) public petSex;
    mapping(uint256 => uint256) public petSkinColor;
    mapping(uint256 => uint256) public petHornStyle;
    mapping(uint256 => uint256) public petWingStyle;
    mapping(uint256 => uint256) public petEvolutionPhase;
    mapping(uint256 => bool) public petHasParents;
    mapping(uint256 => uint256[2]) public petParentsId;
    mapping(uint256 => uint256) public petShield;
    mapping(uint256 => bool) public isPetLocked;
    mapping(uint256 => uint256) private _petPendingStarvingTime;
    mapping(uint256 => PetStatus) private _lockedPetStatus;

    // vritual staking
    mapping(uint256 => uint256) public ethOwed;
    mapping(uint256 => uint256) public petRewardDebt;

    uint256 public ethAccPerShare;

    uint256 public totalScores = 0;

    uint256 public hasTheDiamond;

    /*//////////////////////////////////////////////////////////////
                             Events
    //////////////////////////////////////////////////////////////*/
    event PetKilled(
        uint256 deadId,
        string loserName,
        uint256 reward,
        address killer
    );

    event RedeemRewards(uint256 indexed petId, uint256 reward);

    event Pass(uint256 from, uint256 to);

    event NewPetBreeded(
        uint256 petSpecies,
        uint256 petSkinColor,
        uint256 petHornStyle,
        uint256 petWingStyle,
        uint256 petSex,
        bool petHasParents,
        uint256[2] petParentsId,
        uint256 timeUntilStarving,
        uint256 timePetBorn
    );

    constructor(
        address _token,
        address _qrngAirnode,
        address _treasury
    ) QRNG(_qrngAirnode) ERC721("Rai Gotchi Pet", "Rai Gotchi") {
        token = IToken(_token);
        treasury = _treasury;
    }

    modifier isApproved(uint256 id) {
        require(
            ownerOf(id) == msg.sender || getApproved[id] == msg.sender,
            "Not approved"
        );

        _;
    }

    modifier isAuthorized() {
        require(
            msg.sender == breedContract ||
                msg.sender == attackContract ||
                msg.sender == immidiateUseItemsContract,
            "Not authorized"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        Game Actions
    //////////////////////////////////////////////////////////////*/

   function mint(uint256 desiredSpecies) public whenNotPaused {
    // Check if the token ID is within the allowed limit
    require(_tokenIds < 20_000, "Over the limit");

    // Check if the specified species has been initialized
    require(genePool.isSpeciesGeneInitialized(desiredSpecies), "Species not initialized");

    // Check if the specified species is available in the Gene Pool
    // require(genePool.isSpeciesGeneAvailableInGenePool(desiredSpecies), "Species not available in gene pool");

    // Transfer the mint price from the caller to the treasury
    token.transferFrom(msg.sender, treasury, mintPrice);

    // Set the time until the pet becomes starving and the time of birth
    timeUntilStarving[_tokenIds] = block.timestamp + 1 days;
    timePetBorn[_tokenIds] = block.timestamp;

    // Determine the sex of the new pet (this logic can be modified as needed)
    uint256 newPetSex = (desiredSpecies % 2); // Assuming sex is based on the index

    // Retrieve the default attributes for the specified species
    IGenePool.SpeciesDefaultAttrs memory speciesDefaultAttrs = genePool.speciesDefaultAttrs(desiredSpecies);

    // Join the population count for the species
    genePool.newMemberJoinSpecies(desiredSpecies);

    // Assign the attributes to the new pet
    petSpecies[_tokenIds] = desiredSpecies;
    petSkinColor[_tokenIds] = speciesDefaultAttrs.skinColor;
    petHornStyle[_tokenIds] = speciesDefaultAttrs.hornStyle;
    petWingStyle[_tokenIds] = speciesDefaultAttrs.wingStyle;
    petSex[_tokenIds] = newPetSex;

    // Check and remove the species if the population has reached its maximum
    if (
        genePool.currentSpeciesPopulation(desiredSpecies) ==
        genePool.speciesMaxPopulation(desiredSpecies)
    ) {
        genePool.removeSpeciesFromGenePool(desiredSpecies);
    }

    // Mint the NFT for the new pet
    _mint(msg.sender, _tokenIds);
    _tokenIds++;
}


    // kill and burn pets.
    function kill(uint256 _deadId) external whenNotPaused {
        require(
            !isPetAlive(_deadId),
            "The pet has to be starved to claim his points"
        );

        require(
            ownerOf(_deadId) == msg.sender,
            "You are not the owner of this pet"
        );

        require(
            hasTheDiamond != _deadId,
            "Pet has diamond, please pass it before kill"
        );

        uint256 speciesOfDead = petSpecies[_deadId];
        address ownerOfDead = ownerOf(_deadId);

        if (
            genePool.currentSpeciesPopulation(speciesOfDead) ==
            genePool.speciesMaxPopulation(speciesOfDead)
        ) {
            genePool.reducePopulationAndAddSpeciesToGenePool(speciesOfDead);
        }

        _burn(_deadId);
        uint256 pending = pendingEth(_deadId);
        // redeem for dead pet
        _redeem(_deadId, ownerOfDead);

        totalScores -= petScore[_deadId];
        petScore[_deadId] = 0;

        _getWalletSeedAndUpdateIfNeeded();

        emit PetKilled(_deadId, petName[_deadId], pending, msg.sender);
    }

    function setPetName(
        uint256 _id,
        string memory _name
    ) external isApproved(_id) whenNotPaused {
        petName[_id] = _name;
    }

    function checkPetEvoleAndUpdateIfNeeded(
        uint256 _nftId
    ) external isAuthorized whenNotPaused {
        _evolvePetIfNeeded(_nftId);
    }

    function createNewPetAfterBreed(
        uint256 _random,
        uint256 _newPetSpecies,
        uint256 _parent1Id,
        uint256 _parent2Id
    ) external whenNotPaused {
        require(
            msg.sender == breedContract,
            "Only breed contract can create new pet"
        );
        uint256 _newPetSkinColor = (_random + 2) % genePool.skinColorGeneNum();
        uint256 _newPetHornStyle = (_random + 3) % genePool.hornStyleGeneNum();
        uint256 _newPetWingStyle = (_random + 4) % genePool.wingStyleGeneNum();
        uint256 _newPetSex = (_random + 5) % 2;

        genePool.newMemberJoinSpecies(_newPetSpecies);
        petSpecies[_tokenIds] = _newPetSpecies;
        petSkinColor[_tokenIds] = _newPetSkinColor;
        petHornStyle[_tokenIds] = _newPetHornStyle;
        petWingStyle[_tokenIds] = _newPetWingStyle;
        petSex[_tokenIds] = _newPetSex;
        petHasParents[_tokenIds];
        petParentsId[_tokenIds] = [_parent1Id, _parent2Id];
        timeUntilStarving[_tokenIds] = block.timestamp + 1 days;
        timePetBorn[_tokenIds] = block.timestamp;

        if (
            genePool.currentSpeciesPopulation(_newPetSpecies) ==
            genePool.speciesMaxPopulation(_newPetSpecies)
        ) {
            genePool.removeSpeciesFromGenePool(_newPetSpecies);
        }

        // mint NFT
        _mint(msg.sender, _tokenIds);
        _tokenIds++;
    }

    function reducePetShield(uint256 _nftId) external whenNotPaused {
        require(msg.sender == attackContract, "Not authorized");
        petShield[_nftId] -= 1;
    }

    function setPetInfoAfterAttack(
        uint256 winnerId,
        uint256 loserId,
        uint256 _score,
        uint256 _debt
    ) external whenNotPaused {
        require(msg.sender == attackContract, "Not authorized");

        petScore[loserId] -= _score;
        petRewardDebt[loserId] -= _debt;

        petScore[winnerId] += _score;
        petRewardDebt[winnerId] += _debt;
    }

    function currentSpeciesPopulation(
        uint256 _species
    ) external view returns (uint256) {
        uint256 current = genePool.currentSpeciesPopulation(_species);
        return current;
    }

    function speciesMaxPopulation(
        uint256 _species
    ) external view returns (uint256) {
        uint256 max = genePool.speciesMaxPopulation(_species);
        return max;

    }

    function lockPet(uint256 _nftId) external isAuthorized whenNotPaused {
        require(isPetAlive(_nftId), "Can't lock dead pet");
        isPetLocked[_nftId] = true;
        if (timeUntilStarving[_nftId] > block.timestamp) {
            _petPendingStarvingTime[_nftId] =
                timeUntilStarving[_nftId] -
                block.timestamp;
        } else {
            _petPendingStarvingTime[_nftId] = 0;
        }
        _lockedPetStatus[_nftId] = getStatus(_nftId);
    }

    function unlockPet(uint256 _nftId) external isAuthorized whenNotPaused {
        isPetLocked[_nftId] = false;
        timeUntilStarving[_nftId] =
            block.timestamp +
            _petPendingStarvingTime[_nftId];
        _petPendingStarvingTime[_nftId] = 0;
        _lockedPetStatus[_nftId] = PetStatus.DEAD;
    }

    function _evolvePetIfNeeded(uint256 _nftId) internal {
        uint256 currentEvolutionPhase = petEvolutionPhase[_nftId];

        uint256 nextEvolutionPhase = getPetEvolutionPhase(_nftId);

        if (currentEvolutionPhase < nextEvolutionPhase) {
            petEvolutionPhase[_nftId] = nextEvolutionPhase;
        }
    }

    // just side quest for later to add to ui, one thing in the game that can be passed to other players
    function pass(
        uint256 from,
        uint256 to
    ) external isApproved(from) whenNotPaused {
        require(hasTheDiamond == from, "you don't have it");
        require(ownerOf(to) != address(0x0), "don't burn it");

        hasTheDiamond = to;

        emit Pass(from, to);
    }

    function onConsumeImmidiateUseItem(
        uint256 _nftId,
        uint256 _itemTimeExtension,
        uint256 _itemShield,
        uint256 _itemPoints
    ) external whenNotPaused {
        require(msg.sender == immidiateUseItemsContract, "Not authorized");

        // recalculate time until starving
        if (isPetLocked[_nftId]) {
            _petPendingStarvingTime[_nftId] += _itemTimeExtension;
        } else {
            timeUntilStarving[_nftId] += _itemTimeExtension;
        }

        petShield[_nftId] += _itemShield;

        if (petScore[_nftId] > 0) {
            ethOwed[_nftId] = pendingEth(_nftId);
        }

        petScore[_nftId] += _itemPoints;
        petRewardDebt[_nftId] = petScore[_nftId].mulDivDown(
            ethAccPerShare,
            PRECISION
        );
        totalScores += _itemPoints;

        _evolvePetIfNeeded(_nftId);
    }

    /*//////////////////////////////////////////////////////////////
                        Game Getters
    //////////////////////////////////////////////////////////////*/
    function getPetEvolutionPhase(
        uint256 _nftId
    ) public view returns (uint256) {
        uint256 _species = petSpecies[_nftId];
        uint256 _evolutionPhase = petEvolutionPhase[_nftId];
        uint256 speciesMaxEvolutionPhase = genePool.speciesMaxEvolutionPhase(
            _species
        );
        if (_evolutionPhase < speciesMaxEvolutionPhase) {
            return _getPetEvolutionPhase(_nftId, _evolutionPhase);
        } else {
            return speciesMaxEvolutionPhase;
        }
    }


    function petEvolutionPhaseExternal(
        uint256 _nftId
    ) external view returns (uint256) {
        uint256 _species = petSpecies[_nftId];
        uint256 _evolutionPhase = petEvolutionPhase[_nftId];
        uint256 speciesMaxEvolutionPhase = genePool.speciesMaxEvolutionPhase(
            _species
        );
        if (_evolutionPhase < speciesMaxEvolutionPhase) {
            return _getPetEvolutionPhase(_nftId, _evolutionPhase);
        } else {
            return speciesMaxEvolutionPhase;
        }
    }

   function getPetsByOwner(address owner) public view returns (uint256[] memory) {
        // Get total number of pets owned
        uint256 balance = balanceOf(owner);
        
        // Create array to store pet IDs
        uint256[] memory pets = new uint256[](balance);
        
        // Track current index in pets array
        uint256 currentIndex = 0;
        
        // Iterate through all possible tokens
        for (uint256 id = 0; id < _tokenIds; id++) {
            // Check if the token exists and belongs to the owner
            if (currentIndex < balance && ownerOf(id) == owner) {
                pets[currentIndex] = id;
                currentIndex++;
            }
        }

        return pets;
    }

    

    function speciesMaxEvolutionPhase(
        uint256 _species
    ) external view returns (uint256) {

        uint256 speciesMaxEvolutionPhase = genePool.speciesMaxEvolutionPhase(
            _species
        );
        return speciesMaxEvolutionPhase;

    }

    function getStatus(uint256 pet) public view returns (PetStatus _health) {
        if (isPetLocked[pet]) {
            return _lockedPetStatus[pet];
        }

        if (!isPetAlive(pet)) {
            return PetStatus.DEAD;
        }

        if (timeUntilStarving[pet] > block.timestamp + 16 hours)
            return PetStatus.HAPPY;
        if (
            timeUntilStarving[pet] > block.timestamp + 12 hours &&
            timeUntilStarving[pet] < block.timestamp + 16 hours
        ) return PetStatus.HUNGRY;

        if (
            timeUntilStarving[pet] > block.timestamp + 8 hours &&
            timeUntilStarving[pet] < block.timestamp + 12 hours
        ) return PetStatus.STARVING;

        if (timeUntilStarving[pet] < block.timestamp + 8 hours)
            return PetStatus.DYING;
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
            PetStatus _status,
            uint256 _score,
            uint256 _level,
            uint256 _timeUntilStarving,
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

        IGenePool.Evolution memory speciesToEvolutions = genePool
            .getSpeciesEvolutionPhaseInfo(_species, _evolutionPhase);

        _maxEvolutionPhase = genePool.speciesMaxEvolutionPhase(_species);
        _image = speciesToEvolutions.image;
        _speciesName = speciesToEvolutions.name;
        _attackPoints = speciesToEvolutions.attackPoints;
        _defensePoints = speciesToEvolutions.defensePoints;
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
        _attackPoints = genePool
            .getSpeciesEvolutionPhaseInfo(_species, _evolutionPhase)
            .attackPoints;
    }

    function getPetDefensePoints(
        uint256 _nftId
    ) public view returns (uint256 _defensePoints) {
        uint256 _species = petSpecies[_nftId];
        uint256 _evolutionPhase = petEvolutionPhase[_nftId];
        _defensePoints = genePool
            .getSpeciesEvolutionPhaseInfo(_species, _evolutionPhase)
            .defensePoints;
    }

    function getPetImage(
        uint256 _nftId
    ) public view returns (string memory _image) {
        uint256 _species = petSpecies[_nftId];
        uint256 _evolutionPhase = petEvolutionPhase[_nftId];
        _image = genePool
            .getSpeciesEvolutionPhaseInfo(_species, _evolutionPhase)
            .image;
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
                                '{"name":"Rai Gotchi Pet #',
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
        PetStatus status = getStatus(id);

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

        ethOwed[petId] = 0;
        petRewardDebt[petId] = petScore[petId].mulDivDown(
            ethAccPerShare,
            PRECISION
        );

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

    function setAttackContract(address _attackContract) external onlyOwner {
        attackContract = _attackContract;
    }

    function setTreasuryAddress(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setGenePool(address _genePool) external onlyOwner {
        genePool = IGenePool(_genePool);
    }

    function setImmidiateUseItemsContract(
        address _immidiateUseItemsContract
    ) external onlyOwner {
        immidiateUseItemsContract = _immidiateUseItemsContract;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    /**
     * @dev Pauses the contract.
     * Only the contract owner can call this function.
     */
    function pause() external onlyOwner {
        super._pause();
    }

    /**
     * @dev Unpauses the contract.
     * Only the contract owner can call this function.
     */
    function unpause() external onlyOwner {
        super._unpause();
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
        uint256 _speciesMaxEvolutionPhase = genePool.speciesMaxEvolutionPhase(
            _species
        );
        if (currentEvoPhase == _speciesMaxEvolutionPhase) {
            return _speciesMaxEvolutionPhase;
        }
        uint256 evoLevel = genePool
            .getSpeciesEvolutionPhaseInfo(_species, currentEvoPhase)
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

    function getWalletSeedAndUpdateIfNeeded()
        external
        isAuthorized
        returns (uint256)
    {
        return _getWalletSeedAndUpdateIfNeeded();
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        require(!isPetLocked[tokenId], "Can't transfer locked pet");
        super.transferFrom(from, to, tokenId);
    }
}
