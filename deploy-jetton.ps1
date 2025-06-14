import { TonClient, WalletContractV4, toNano } from "ton";
import { mnemonicToPrivateKey } from "ton-crypto";
import { APISBULL } from "../build/APISBULL/tact_APISBULL";
import dotenv from "dotenv";

dotenv.config();

async function deployJetton() {
    const endpoint = process.env.TESTNET_ENDPOINT!;
    const apiKey = process.env.TESTNET_API_KEY!;
    const mnemonic = process.env.MNEMONIC!;

    const client = new TonClient({ endpoint, apiKey });
    const key = await mnemonicToPrivateKey(mnemonic.split(" "));
    const wallet = WalletContractV4.create({ 
        publicKey: key.publicKey, 
        workchain: 0 
    });
    const walletContract = client.open(wallet);
    
    // Contract parameters
    const totalSupply = toNano("1000000000000000"); // 1 quadrillion tokens
    const burnTax = 5; // 5% tax
    const symbol = "APIS";
    const decimals = 9;
    
    // Create contract
    const apisbull = APISBULL.createForDeploy(
        totalSupply,
        burnTax,
        walletContract.address, // Pharaoh address
        walletContract.address, // Treasury address
        symbol,
        decimals
    );
    
    const apisbullContract = client.open(apisbull);
    
    // Deploy contract
    const seqno = await walletContract.getSeqno();
    await walletContract.sendTransfer({
        secretKey: key.secretKey,
        seqno: seqno,
        messages: [{
            address: apisbullContract.address,
            amount: toNano("0.5"),
            init: apisbull.init,
            body: new Cell() // Empty body
        }]
    });
    
    console.log(`🐂 APISBULL deployed to: ${apisbullContract.address.toString()}`);
    console.log(`🔗 Explorer: https://testnet.tonscan.org/address/${apisbullContract.address.toString()}`);
    
    // Return contract address for use in presale deployment
    return apisbullContract.address.toString();
}

deployJetton().catch(console.error);