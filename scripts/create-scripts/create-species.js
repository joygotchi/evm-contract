const hre = require("hardhat");
const { getContracts } = require("../utils");

// Example of creating a species
const SPECIES_EVOLUTIONS = [
  {
    image: "https://www.pinterest.com/pin/695735842470093598/",
    name: "Species A First Evolution Name",
    attackPoints: 100,
    defensePoints: 100,
    nextEvolutionLevel: 2,
  },
  {
    image: "https://www.pinterest.com/pin/695735842470093598/",
    name: "Species A Second Evolution Name",
    attackPoints: 200,
    defensePoints: 200,
    nextEvolutionLevel: 3,
  },
  {
    image: "https://www.pinterest.com/pin/695735842470093598/",
    name: "Species A Third Evolution Name",
    attackPoints: 300,
    defensePoints: 300,
    nextEvolutionLevel: 0, // This is not important since species has reach it max evolution
  },
];

const SPECIES_DEFAULT_ATTRIBUTES = {
  skinColor: 1,
  hornStyle: 1,
  wingStyle: 1,
};

const SPECIES_MAX_POPULATION = 100; // Maximum number of pets that can be created for this species

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const GenePool = await hre.ethers.getContractFactory("GenePool");
  const genePool = GenePool.attach(contracts.genePool);

  // Create species
  // Species has multiple phase of evolution and default attribute
  await genePool.createSpecies(
    SPECIES_EVOLUTIONS,
    SPECIES_DEFAULT_ATTRIBUTES,
    SPECIES_MAX_POPULATION
  );

  const RaiGotchiItems = await hre.ethers.getContractFactory("RaiGotchiItems");
  const raiGotchiItems = RaiGotchiItems.attach(contracts.raiGotchiItems);

  const ATTACK_POINTS = "100"; // Attack points of the species
  const DEFENSE_POINTS = "100"; // Defense points of the species

  // Add species attack and defense points
  await raiGotchiItems.addSpeciesAttackAndDefensePoints(
    ATTACK_POINTS,
    DEFENSE_POINTS
  );

  console.log("Done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
