import { TonClient, WalletContractV4, toNano } from "ton";
import { APISBULL } from "../build/APISBULL/tact_APISBULL";
import { mnemonicToPrivateKey } from "ton-crypto";
import dotenv from "dotenv";

dotenv.config();

async function deploy() {
  const client = new TonClient({
    endpoint: process.env.TESTNET_ENDPOINT!
  });

  // Initialize wallet
  const mnemonic = process.env.MNEMONIC!.split(" ");
  const key = await mnemonicToPrivateKey(mnemonic);
  const wallet = WalletContractV4.create({ 
    publicKey: key.publicKey, 
    workchain: 0 
  });
  
  const contract = client.open(wallet);
  
  // Prepare APISBULL contract
  const apisbull = APISBULL.createForDeploy(
    toNano("1000000000000000"), // 1 quadrillion
    5, // 5% tax
    contract.address, // Pharaoh address
    contract.address  // Treasury address
  );
  
  // Deploy contract
  const seqno = await contract.getSeqno();
  await contract.sendTransfer({
    secretKey: key.secretKey,
    seqno: seqno,
    messages: [{
      address: apisbull.address,
      amount: toNano("0.5"),
      init: apisbull.init,
      body: new Cell()
    }]
  });
  
  console.log(`🐂 APISBULL deployed to: ${apisbull.address.toString()}`);
  console.log(`🔗 Explorer: https://testnet.tonscan.org/address/${apisbull.address.toString()}`);
}

deploy().catch(console.error);
