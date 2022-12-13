const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Bingo", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearBingoFixture() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

    const BingoedAmount = ONE_GWEI;
    const unBingoTime = (await time.latest()) + ONE_YEAR_IN_SECS;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Bingo = await ethers.getContractFactory("Bingo");
    const Bingo = await Bingo.deploy(unBingoTime, { value: BingoedAmount });

    return { Bingo, unBingoTime, BingoedAmount, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set the right unBingoTime", async function () {
      const { Bingo, unBingoTime } = await loadFixture(deployOneYearBingoFixture);

      expect(await Bingo.unBingoTime()).to.equal(unBingoTime);
    });

    it("Should set the right owner", async function () {
      const { Bingo, owner } = await loadFixture(deployOneYearBingoFixture);

      expect(await Bingo.owner()).to.equal(owner.address);
    });

    it("Should receive and store the funds to Bingo", async function () {
      const { Bingo, BingoedAmount } = await loadFixture(
        deployOneYearBingoFixture
      );

      expect(await ethers.provider.getBalance(Bingo.address)).to.equal(
        BingoedAmount
      );
    });

    it("Should fail if the unBingoTime is not in the future", async function () {
      // We don't use the fixture here because we want a different deployment
      const latestTime = await time.latest();
      const Bingo = await ethers.getContractFactory("Bingo");
      await expect(Bingo.deploy(latestTime, { value: 1 })).to.be.revertedWith(
        "UnBingo time should be in the future"
      );
    });
  });

  describe("Withdrawals", function () {
    describe("Validations", function () {
      it("Should revert with the right error if called too soon", async function () {
        const { Bingo } = await loadFixture(deployOneYearBingoFixture);

        await expect(Bingo.withdraw()).to.be.revertedWith(
          "You can't withdraw yet"
        );
      });

      it("Should revert with the right error if called from another account", async function () {
        const { Bingo, unBingoTime, otherAccount } = await loadFixture(
          deployOneYearBingoFixture
        );

        // We can increase the time in Hardhat Network
        await time.increaseTo(unBingoTime);

        // We use Bingo.connect() to send a transaction from another account
        await expect(Bingo.connect(otherAccount).withdraw()).to.be.revertedWith(
          "You aren't the owner"
        );
      });

      it("Shouldn't fail if the unBingoTime has arrived and the owner calls it", async function () {
        const { Bingo, unBingoTime } = await loadFixture(
          deployOneYearBingoFixture
        );

        // Transactions are sent using the first signer by default
        await time.increaseTo(unBingoTime);

        await expect(Bingo.withdraw()).not.to.be.reverted;
      });
    });

    describe("Events", function () {
      it("Should emit an event on withdrawals", async function () {
        const { Bingo, unBingoTime, BingoedAmount } = await loadFixture(
          deployOneYearBingoFixture
        );

        await time.increaseTo(unBingoTime);

        await expect(Bingo.withdraw())
          .to.emit(Bingo, "Withdrawal")
          .withArgs(BingoedAmount, anyValue); // We accept any value as `when` arg
      });
    });

    describe("Transfers", function () {
      it("Should transfer the funds to the owner", async function () {
        const { Bingo, unBingoTime, BingoedAmount, owner } = await loadFixture(
          deployOneYearBingoFixture
        );

        await time.increaseTo(unBingoTime);

        await expect(Bingo.withdraw()).to.changeEtherBalances(
          [owner, Bingo],
          [BingoedAmount, -BingoedAmount]
        );
      });
    });
  });
});
