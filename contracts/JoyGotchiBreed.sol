// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/IJoyGotchi.sol";
import "./interfaces/IJoyGotchiItem.sol";
import "./interfaces/IToken.sol";
import "./PetStatus.sol";

contract JoyGotchiBreed {
    IJoyGotchi public joyGotchiNFT;
    IJoyGotchiItem public joyGotchiNFTItem;
    IToken public token;

    constructor(
        address _joyGotchiNFT,
        address _joyGotchiNFTItem,
        address _token
    ) {
        joyGotchiNFT = IJoyGotchi(_joyGotchiNFT);
        joyGotchiNFTItem = IJoyGotchiItem(_joyGotchiNFTItem);
        token = IToken(_token);
    }

    modifier isApprovedJoyGotchiNFT(uint256 id) {
        require(
            joyGotchiNFT.ownerOf(id) == msg.sender ||
                joyGotchiNFT.getApproved(id) == msg.sender,
            "Not approved"
        );
        _;
    }

    modifier isApprovedJoyGotchiNFTItem(uint256 id) {
        require(
            joyGotchiNFTItem.ownerOf(id) == msg.sender ||
                joyGotchiNFTItem.getApproved(id) == msg.sender,
            "Item not approved"
        );
        _;
    }

    function checkConditionBeforeBreed(
        uint256 _nftId,
        uint256 _nftId2,
        uint256 _itemId,
        uint256 species1,
        uint256 species2
    ) private {
        require(_nftId != _nftId2, "Can't breed with yourself");
        require(joyGotchiNFT.isPetAlive(_nftId), "Pet1 is dead");
        require(joyGotchiNFT.isPetAlive(_nftId2), "Pet2 is dead");
        require(
            joyGotchiNFT.petSex(_nftId) != joyGotchiNFT.petSex(_nftId2),
            "Same sex"
        );
        require(
            joyGotchiNFT.getStatus(_nftId) == Status.HAPPY,
            "Pet1 not happy"
        );
        require(
            joyGotchiNFT.getStatus(_nftId2) == Status.HAPPY,
            "Pet2 not happy"
        );

        joyGotchiNFT.checkEvolveBeforeBreed(_nftId);
        joyGotchiNFT.checkEvolveBeforeBreed(_nftId2);

        require(
            joyGotchiNFT.petEvolutionPhase(_nftId) ==
                joyGotchiNFT.speciesMaxEvolutionPhase(species1),
            "Pet1 not max evolution phase"
        );
        require(
            joyGotchiNFT.petEvolutionPhase(_nftId2) ==
                joyGotchiNFT.speciesMaxEvolutionPhase(species2),
            "Pet2 not max evolution phase"
        );

        require(
            joyGotchiNFT.currentSpeciesPopulation(species1) <
                joyGotchiNFT.speciesMaxPopulation(species1) &&
                joyGotchiNFT.currentSpeciesPopulation(species2) <
                joyGotchiNFT.speciesMaxPopulation(species2),
            "Species at max population"
        );

        require(joyGotchiNFTItem.isBreedItem(_itemId), "Not a breed item");
    }

    function breed(
        uint256 _nftId,
        uint256 _nftId2,
        uint256 _itemId
    )
        external
        isApprovedJoyGotchiNFT(_nftId)
        isApprovedJoyGotchiNFT(_nftId2)
        isApprovedJoyGotchiNFTItem(_itemId)
    {
        uint256 species1 = joyGotchiNFT.petSpecies(_nftId);
        uint256 species2 = joyGotchiNFT.petSpecies(_nftId2);

        checkConditionBeforeBreed(_nftId, _nftId2, _itemId, species1, species2);

        if (joyGotchiNFTItem.burnAfterUsed(_itemId)) {
            joyGotchiNFTItem.burn(_itemId);
        } else {
            joyGotchiNFTItem.lockToken(_itemId);
        }

        token.burnFrom(msg.sender, joyGotchiNFT.mintPrice());

        uint256 _random = random(_nftId + _nftId2);

        uint256 _newPetSpecies;

        if (
            joyGotchiNFT.currentSpeciesPopulation(species1) ==
            joyGotchiNFT.speciesMaxPopulation(species1)
        ) {
            _newPetSpecies = species2;
        } else if (
            joyGotchiNFT.currentSpeciesPopulation(species2) ==
            joyGotchiNFT.speciesMaxPopulation(species2)
        ) {
            _newPetSpecies = species1;
        } else {
            _newPetSpecies = _random % 2 == 0 ? species1 : species2;
        }

        joyGotchiNFT.createNewPetAfterBreed(
            _random,
            _newPetSpecies,
            _nftId,
            _nftId2
        );
    }

    function random(uint256 seed) private view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        seed,
                        block.prevrandao,
                        block.timestamp,
                        msg.sender
                    )
                )
            );
    }
}
