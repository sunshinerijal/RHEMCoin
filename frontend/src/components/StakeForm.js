import { useState } from 'react';
import { ethers } from 'ethers';
import { useAccount } from 'wagmi';
import { Button, Input, Select } from '@chakra-ui/react';
import StakingModuleABI from '../contracts/StakingModule.json';

const STAKING_ADDRESS = "0xYOUR_STAKING_ADDRESS"; // Replace with deployed address

function StakeForm() {
    const { address } = useAccount();
    const [amount, setAmount] = useState('');
    const [lockPeriod, setLockPeriod] = useState('0');

    const stake = async () => {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();
        const staking = new ethers.Contract(STAKING_ADDRESS, StakingModuleABI, signer);
        const tx = await staking.stake(ethers.utils.parseEther(amount), lockPeriod);
        await tx.wait();
        alert('Staked successfully!');
    };

    return (
        <div>
            <Input placeholder="Amount (RHEM)" value={amount} onChange={(e) => setAmount(e.target.value)} />
            <Select value={lockPeriod} onChange={(e) => setLockPeriod(e.target.value)}>
                <option value="0">7 Days</option>
                <option value="1">14 Days</option>
                <option value="2">30 Days</option>
                <option value="3">1 Month</option>
                <option value="4">3 Months</option>
                <option value="5">6 Months</option>
                <option value="6">9 Months</option>
                <option value="7">12 Months</option>
            </Select>
            <Button onClick={stake} disabled={!address}>Stake</Button>
        </div>
    );
}
export default StakeForm;