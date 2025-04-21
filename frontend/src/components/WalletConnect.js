import { useAccount, useConnect, useDisconnect } from 'wagmi';
import { InjectedConnector } from 'wagmi/connectors/injected';
import { Button } from '@chakra-ui/react';

function WalletConnect() {
    const { address, isConnected } = useAccount();
    const { connect } = useConnect({ connector: new InjectedConnector() });
    const { disconnect } = useDisconnect();

    return (
        <div>
            {isConnected ? (
                <>
                    <p>Connected: {address}</p>
                    <Button onClick={disconnect}>Disconnect</Button>
                </>
            ) : (
                <Button onClick={() => connect()}>Connect Wallet</Button>
            )}
        </div>
    );
}
export default WalletConnect;