require("@nomiclabs/hardhat-ethers");
module.exports = {
    solidity: "0.8.20",
    paths: {
        sources: "./contracts",
        tests: "./tests",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    sources: ["./contracts", "./interfaces"]
};
