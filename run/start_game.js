import { Ed25519Keypair, RawSigner, fromB64, TransactionBlock } from '@mysten/sui.js';
import { config } from "./config.js";
import { provider } from "./provider.js";

const keypair = Ed25519Keypair.deriveKeypair(config.GAME_CREATOR.mnemonic, "m/44'/784'/0'/0'/0'");
const signer = new RawSigner(keypair, provider);

export const startGame = async (packageObjectId, gameBoardObjectId) => {
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageObjectId}::memotest::start_game`,
        arguments: [
            tx.pure(gameBoardObjectId)
        ]
    })
    tx.setGasBudget(10000);
    const res = await signer.signAndExecuteTransactionBlock({ transactionBlock: tx });
    console.log("[Start Game]", res.effects.status);
}