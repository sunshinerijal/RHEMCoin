const hre = require("hardhat");

async function main() {
    const [deployer, multiSig, dao, devWallet, burnAddress] = await hre.ethers.getSigners();
    const merkleRoot = "0x0000000000000000000000000000000000000000000000000000000000000000";

    const RHEM = await hre.ethers.getContractFactory("RhesusMacaqueCoin");
    const rhem = await RHEM.deploy(dao.address, devWallet.address, burnAddress.address, merkleRoot, multiSig.address);
    await rhem.deployed();
    console.log("RHEM deployed to:", rhem.address);

    const RHEMPlatform = await hre.ethers.getContractFactory("RHEMPlatform");
    const platform = await RHEMPlatform.deploy(
        dao.address,
        rhem.address,
        multiSig.address,
        devWallet.address,
        burnAddress.address,
        multiSig.address
    );
    await platform.deployed();
    console.log("RHEMPlatform deployed to:", platform.address);

    const TradingModule = await hre.ethers.getContractFactory("TradingModule");
    const trading = await TradingModule.deploy(multiSig.address, rhem.address, platform.address, devWallet.address);
    await trading.deployed();
    console.log("TradingModule deployed to:", trading.address);

    const timelockId = ethers.utils.id("test");
    await platform.connect(dao).registerModule("Trading", trading.address, timelockId);
    console.log("TradingModule registered");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});