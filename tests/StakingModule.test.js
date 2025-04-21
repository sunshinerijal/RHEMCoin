const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StakingModule", function () {
    let Staking, staking, RewardPool, rewardPool, RHEM, rhem, owner, user, multiSig;
    const lockPeriods = [7 * 86400, 14 * 86400, 30 * 86400, 30 * 86400, 3 * 30 * 86400, 6 * 30 * 86400, 9 * 30 * 86400, 12 * 30 * 86400];

    beforeEach(async () => {
        [owner, user, multiSig] = await ethers.getSigners();
        RHEM = await ethers.getContractFactory("RhesusMacaqueCoin");
        rhem = await RHEM.deploy(multiSig.address, multiSig.address, multiSig.address, "0x0", multiSig.address);
        await rhem.deployed();

        RewardPool = await ethers.getContractFactory("RewardPool");
        rewardPool = await RewardPool.deploy(rhem.address, multiSig.address);
        await rewardPool.deployed();

        Staking = await ethers.getContractFactory("StakingModule");
        staking = await Staking.deploy(rhem.address, multiSig.address);
        await staking.deployed();

        await rewardPool.connect(multiSig).setStakingModule(staking.address);
        await staking.connect(multiSig).setRewardPool(rewardPool.address);
        await rhem.connect(owner).transfer(user.address, ethers.utils.parseEther("1000"));
        await rhem.connect(user).approve(staking.address, ethers.utils.parseEther("1000"));
        await rhem.connect(owner).transfer(rewardPool.address, ethers.utils.parseEther("10000"));
        await rewardPool.connect(multiSig).approveForStaking(ethers.utils.parseEther("10000"));
    });

    it("should stake and unstake with rewards", async () => {
        const amount = ethers.utils.parseEther("100");
        await staking.connect(user).stake(amount, 0);
        expect(await staking.totalStaked()).to.equal(amount);
        expect(await staking.totalUserStaked(user.address)).to.equal(amount);

        await ethers.provider.send("evm_increaseTime", [7 * 86400]);
        await ethers.provider.send("evm_mine");

        const initialBalance = await rhem.balanceOf(user.address);
        await staking.connect(user).unstake(0);
        const finalBalance = await rhem.balanceOf(user.address);
        expect(finalBalance).to.be.gt(initialBalance);
        expect(await staking.totalStaked()).to.equal(0);
    });

    it("should respect lock periods", async () => {
        await staking.connect(user).stake(ethers.utils.parseEther("100"), 1);
        await ethers.provider.send("evm_increaseTime", [7 * 86400]);
        await expect(staking.connect(user).unstake(0)).to.be.revertedWith("Still locked");
    });

    it("should pause and unpause", async () => {
        await staking.connect(multiSig).pause();
        await expect(staking.connect(user).stake(ethers.utils.parseEther("100"), 0)).to.be.revertedWith("Pausable: paused");
        await staking.connect(multiSig).unpause();
        await staking.connect(user).stake(ethers.utils.parseEther("100"), 0);
        expect(await staking.totalStaked()).to.equal(ethers.utils.parseEther("100"));
    });

    it("should update reward multiplier", async () => {
        await staking.connect(multiSig).setRewardMultiplier(0, 200);
        expect(await staking.rewardMultipliers(0)).to.equal(200);
        await staking.connect(user).stake(ethers.utils.parseEther("100"), 0);
        await ethers.provider.send("evm_increaseTime", [7 * 86400]);
        const rewards = await staking.calculateRewards(user.address, 0);
        expect(rewards).to.be.gt(ethers.utils.parseEther("100"));
    });

    it("should fail with invalid inputs", async () => {
        await expect(staking.connect(user).stake(0, 0)).to.be.revertedWith("Invalid amount");
        await expect(staking.connect(user).stake(ethers.utils.parseEther("100"), 8)).to.be.revertedWith("Invalid lock period");
        await expect(staking.connect(user).unstake(0)).to.be.revertedWith("Invalid stake index");
    });
});