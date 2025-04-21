import { WagmiConfig, createConfig, mainnet } from 'wagmi';
import { createPublicClient, http } from 'viem';
import WalletConnect from './components/WalletConnect';
import StakeForm from './components/StakeForm';
import { ChakraProvider } from '@chakra-ui/react';

const config = createConfig({
    autoConnect: true,
    publicClient: createPublicClient({ chain: mainnet, transport: http() }),
});

function App() {
    return (
        <WagmiConfig config={config}>
            <ChakraProvider>
                <WalletConnect />
                <StakeForm />
            </ChakraProvider>
        </WagmiConfig>
    );
}
export default App;