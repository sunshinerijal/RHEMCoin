const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TradingModule", function () {
    let TradingModule, trading, RHEM, rhem, Platform, platform, multiSig, dao, devWallet, user;
    beforeEach(async () => {
        [owner, multiSig, dao, devWallet, user] = await ethers.getSigners();
        RHEM = await ethers.getContractFactory("RhesusMacaqueCoin");
        rhem = await RHEM.deploy(multiSig.address, multiSig.address, multiSig.address, "0x0", multiSig.address);
        Platform = await ethers.getContractFactory("RHEMPlatform");
        platform = await Platform.deploy(dao.address, rhem.address, multiSig.address, devWallet.address, multiSig.address, multiSig.address);
        TradingModule = await ethers.getContractFactory("TradingModule");
        trading = await TradingModule.deploy(multiSig.address, rhem.address, platform.address, devWallet.address);
    });

    it("should execute trade and track history", async () => {
        const amount = ethers.utils.parseEther("100");
        const price = ethers.utils.parseEther("1");
        await rhem.connect(owner).transfer(user.address, amount);
        await rhem.connect(user).approve(trading.address, amount);
        await trading.connect(user).executeTrade(amount, price, true);
        const history = await trading.getTradeHistory(user.address);
        expect(history[0].amount).to.equal(amount);
        expect(history[0].price).to.equal(price);
        expect(history[0].isBuy).to.be.true;
        expect(await rhem.balanceOf(devWallet.address)).to.equal(amount / 100); // 1% fee
    });

    it("should respect platform restrictions", async () => {
        await platform.connect(multiSig).freezeAccount(user.address);
        await expect(trading.connect(user).executeTrade(ethers.utils.parseEther("100"), ethers.utils.parseEther("1"), true))
            .to.be.revertedWith("Account frozen");
    });
});