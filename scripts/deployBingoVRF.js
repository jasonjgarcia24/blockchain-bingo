require("dotenv").config();
const hre = require("hardhat");

async function main() {
  const subscriptionId = 7528

  const bingoFactory = await hre.ethers.getContractFactory("BingoVRF");
  const BingoVRF = await bingoFactory.deploy(subscriptionId, process.env.VRF_COORDINATOR_GOERLI);

  await BingoVRF.deployed();

  console.log(
    `BingoVRF deployed to ${BingoVRF.address}`
  );
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
