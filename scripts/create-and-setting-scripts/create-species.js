const hre = require("hardhat");
const { getContracts } = require("../utils");

// Example of creating a species
const species = [
  {
    species_default_attrs: {
      skinColor: 0,
      hornStyle: 0,
      wingStyle: 0,
    },
    pet_evolution: [
      {
        image:
          "https://bafkreigw3j7bn3yhkbqt2ercytjhghzn462n5pxzyig4lptuyv4zv6gn6y.ipfs.nftstorage.link/",
        name: "Baby Juvenile Black Dragon",
        attackPoints: 20,
        defensePoints: 10,
        nextEvolutionLevel: 1,
      },
      {
        image:
          "https://bafkreiaqk7mr45wnjwtb4lyv4gpy5rloma3sxq3fq2t6s43tcy3ovnki4m.ipfs.nftstorage.link/",
        name: "Adult Juvenile Black Dragon",
        attackPoints: 25,
        defensePoints: 15,
        nextEvolutionLevel: 2,
      },
      {
        image:
          "https://bafkreibxsv2zfwsftq5yg42rtbersqz6xdnqkohu5eomtdwikbv5uglhmu.ipfs.nftstorage.link/",
        name: "Great Juvenile Black Dragon",
        attackPoints: 35,
        defensePoints: 20,
        nextEvolutionLevel: 3,
      },
    ],
    speciesMaxPopulation: 100,
    petCardAttackPoints: 100,
    petCardDefensePoints: 100,
  },
  {
    species_default_attrs: {
      skinColor: 1,
      hornStyle: 1,
      wingStyle: 1,
    },
    pet_evolution: [
      {
        image:
          "https://bafkreid32fvsd54vejrhsp26zebufsdqnx7jjgtg7j5odp6vyc3b4joecm.ipfs.nftstorage.link/",
        name: "Baby Green Dragon",
        attackPoints: 20,
        defensePoints: 10,
        nextEvolutionLevel: 1,
      },
      {
        image:
          "https://bafkreiapb7ryik6hqe3hj2sd5fjfsexfvuumyxf7jhlzhv64zjmvdp456q.ipfs.nftstorage.link/",
        name: "Adult Green Dragon",
        attackPoints: 25,
        defensePoints: 15,
        nextEvolutionLevel: 2,
      },
      {
        image:
          "https://bafkreig77ufvn7jmr4macehsuww7lz5xflwyb2e75esli6sz5ywfxzhsha.ipfs.nftstorage.link/",
        name: "Great Green Wyrm",
        attackPoints: 35,
        defensePoints: 20,
        nextEvolutionLevel: 3,
      },
    ],
    speciesMaxPopulation: 50,
    petCardAttackPoints: 100,
    petCardDefensePoints: 100,
  },
];

async function main() {
  const network = hre.network.name;
  const contracts = getContracts(network);

  const GenePool = await hre.ethers.getContractFactory("GenePool");
  const genePool = GenePool.attach(contracts.genePool);

  const RaiGotchiItems = await hre.ethers.getContractFactory("RaiGotchiItems");
  const raiGotchiItems = RaiGotchiItems.attach(contracts.raiGotchiItems);

  // Create species
  // Species has multiple phase of evolution and default attribute
  for (let i = 0; i < species.length; i++) {
    const specie = species[i];
    const speciesDefaultAttrs = specie.species_default_attrs;
    const petEvolution = specie.pet_evolution;
    const speciesMaxPopulation = specie.speciesMaxPopulation;
    const petCardAttackPoints = specie.petCardAttackPoints;
    const petCardDefensePoints = specie.petCardDefensePoints;

    await genePool.createSpecies(
      petEvolution,
      speciesDefaultAttrs,
      speciesMaxPopulation
    );

    console.log("Species created", i);

    // Add species attack and defense points
    await raiGotchiItems.addSpeciesAttackAndDefensePoints(
      petCardAttackPoints,
      petCardDefensePoints
    );

    console.log("Species attack and defense points added", i);
  }

  console.log("Done");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
