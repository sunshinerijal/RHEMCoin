import { ethers } from "ethers";
import { Line } from "react-chartjs-2";
async function TradeChart({ tradingContract, userAddress }) {
    const trades = await tradingContract.getTradeHistory(userAddress);
    const data = {
        labels: trades.map(t => new Date(t.timestamp * 1000).toLocaleString()),
        datasets: [{ label: "Price", data: trades.map(t => ethers.utils.formatEther(t.price)) }],
    };
    return <Line data={data} />;
}