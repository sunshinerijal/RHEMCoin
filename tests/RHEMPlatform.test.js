const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RHEMPlatform", function () {
    let RHEMPlatform, platform, RHEM, rhem, multiSig, dao, devWallet, burnAddress;
    beforeEach(async () => {
        [owner, multiSig, dao, devWallet, burnAddress] = await ethers.getSigners();
        RHEM = await ethers.getContractFactory("RhesusMacaqueCoin");
        rhem = await RHEM.deploy(multiSig.address, multiSig.address, multiSig.address, "0x0", multiSig.address);
        await rhem.deployed();

        RHEMPlatform = await ethers.getContractFactory("RHEMPlatform");
        platform = await RHEMPlatform.deploy(
            dao.address,
            rhem.address,
            multiSig.address, // Mock timelock
            devWallet.address,
            burnAddress.address,
            multiSig.address
        );
        await platform.deployed();
    });

    it("should register a module", async () => {
        const timelockId = ethers.utils.id("test");
        await platform.connect(dao).registerModule("Staking", multiSig.address, timelockId);
        expect(await platform.getModule("Staking")).to.equal(multiSig.address);
    });

    it("should collect platform fee", async () => {
        const amount = ethers.utils.parseEther("10");
        await rhem.connect(owner).transfer(dao.address, amount);
        await rhem.connect(dao).approve(platform.address, amount);
        await platform.connect(dao).collectPlatformFee(dao.address, amount);
        expect(await rhem.balanceOf(devWallet.address)).to.equal(amount / 2);
        expect(await rhem.balanceOf(burnAddress.address)).to.equal(amount / 2);
    });

    it("should pause and unpause", async () => {
        await platform.connect(multiSig).pause();
        await expect(platform.connect(dao).registerModule("Test", multiSig.address, ethers.utils.id("test")))
            .to.be.revertedWith("Pausable: paused");
        await platform.connect(multiSig).unpause();
        await platform.connect(dao).registerModule("Test", multiSig.address, ethers.utils.id("test"));
    });

    it("should restrict access by role", async () => {
        await expect(platform.connect(owner).pause()).to.be.revertedWith("Access denied");
        await platform.connect(multiSig).pause(); // multiSig has OWNER_ROLE
    });
});