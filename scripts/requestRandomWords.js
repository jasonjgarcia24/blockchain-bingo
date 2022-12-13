require("dotenv").config()
const { ethers } = require("hardhat");

async function main() {
    const [owner, ..._] = await ethers.getSigners();
    // const bingoAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
    const bingoAddress = "0x0FAa1f590B0411b18455E0827c4e9070C110EECD";
    const Bingo = await ethers.getContractAt("Bingo", bingoAddress, owner);

    await Bingo.requestRandomWords();
}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});