require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
    const [owner, ..._] = await ethers.getSigners();
    const bingoAddress = "0x0FAa1f590B0411b18455E0827c4e9070C110EECD";
    const Bingo = await ethers.getContractAt("Bingo", bingoAddress, owner);

    const requestId = await Bingo.lastRequestId();
    console.log(requestId);
}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});