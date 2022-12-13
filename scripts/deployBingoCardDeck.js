require("dotenv").config();
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  const [owner, ..._] = await ethers.getSigners();
  const bingoAddress = "0x0FAa1f590B0411b18455E0827c4e9070C110EECD"

  const bingoCardDeckFactory = await hre.ethers.getContractFactory("BingoCardDeck");
  const BingoCardDeck = await bingoCardDeckFactory.deploy(ethers.utils.parseEther("0.00001"));

  await BingoCardDeck.deployed();

  console.log(
    `BingoCardDeck deployed to ${BingoCardDeck.address}`
  );
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
