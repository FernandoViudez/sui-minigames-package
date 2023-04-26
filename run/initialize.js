import { Ed25519Keypair, RawSigner, TransactionBlock } from '@mysten/sui.js';
import { config } from "./config.js";
import { provider } from "./provider.js";

const keypair = Ed25519Keypair.deriveKeypair(config.DEPLOYER.mnemonic, "m/44'/784'/0'/0'/0'");
const signer = new RawSigner(keypair, provider);

/**
 * First two args are deps
 * The third arg is the SUI token minimum bet amount 
 * @param {*} packageObjectId 
 * @param {*} configObjectId 
 * @param {*} betAmount 
*/
export const initialize = async (packageObjectId, configObjectId, minimumBetAmount) => {
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageObjectId}::memotest::initialize`,
        arguments: [
            tx.pure(configObjectId),
            tx.pure(minimumBetAmount),
            tx.pure(config.MEMOTEST_AUTHORIZED_ADDR.addr)
        ]
    })
    try {
        const result = await signer.signAndExecuteTransactionBlock({ transactionBlock: tx, }) // options: { showEffects: true }
    } catch (error) {
        console.log({ error });
    }
    console.log("[Initialize] succeed");
}