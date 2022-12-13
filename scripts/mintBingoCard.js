require("dotenv").config();
const { ethers } = require("hardhat");


async function main() {
    const [owner, ..._] = await ethers.getSigners();
    const randomNumber = ethers.BigNumber.from("86863964708320851750000820703650028955378663379921458105738913875831713366418");

    const bingoCardDeckAddress = "0x9A676e781A523b5d0C0e43731313A708CB607508"
    const BingoCardDeck = await ethers.getContractAt("BingoCardDeck", bingoCardDeckAddress, owner);

    let tx = await BingoCardDeck.mint(owner.address, randomNumber, { value: ethers.utils.parseEther("0.00001") });
    let receipt = await tx.wait();
    const [__, tokenId, ___] = getPlayerAddedEvent(BingoCardDeck, receipt);
    console.log(tokenId);

    const bingoCardsStatus = await BingoCardDeck.bingoCardsStatus(tokenId);
    console.log("Bingo card status: ", bingoCardsStatus);

    tx = await BingoCardDeck.claimWinner();
    receipt = await tx.wait();
    getWinnerClaimedEvent(BingoCardDeck, receipt);
}


function getPlayerAddedEvent(contract, receipt) {
    const topic = contract.interface.getEventTopic("PlayerAdded");
    const logs = receipt.logs;
    const log = logs.find(x => x.topics.indexOf(topic) >= 0);
    const event = log ? contract.interface.parseLog(log) : undefined;

    if (event === undefined) { return; }

    const player = event.args['player'];
    const tokenId = event.args['tokenId'];
    const entryFee = event.args['entryFee'];

    return [player, tokenId, entryFee];
}


function getWinnerClaimedEvent(contract, receipt) {
    const topic = contract.interface.getEventTopic("WinnerClaimed");
    const logs = receipt.logs;
    const log = logs.find(x => x.topics.indexOf(topic) >= 0);
    const event = log ? contract.interface.parseLog(log) : undefined;

    if (event === undefined) { return; }

    const winner = event.args['winner'];
    const tokenId = event.args['tokenId'];
    const winningResults = event.args['winningResults'];

    console.log(winner);
    console.log(tokenId);
    console.log(winningResults);

    return [winner, tokenId, winningResults];
}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});