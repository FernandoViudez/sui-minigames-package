import { provider } from "./provider.js"
import { Ed25519Keypair, RawSigner, TransactionBlock } from '@mysten/sui.js';

export const turn_over_card = async (packageObjectId, gameBoardObjectId, account, cardId, cardsLocation) => {
    const keypair = Ed25519Keypair.deriveKeypair(account.mnemonic, "m/44'/784'/0'/0'/0'");
    const signer = new RawSigner(keypair, provider);
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageObjectId}::memotest::turn_card_over`,
        arguments: [
            tx.pure(gameBoardObjectId),
            tx.pure(cardId),
            tx.pure(cardsLocation),
        ]
    });
    tx.setGasBudget(10000);
    const res = await signer.signAndExecuteTransactionBlock({ transactionBlock: tx });
    console.log("[Turn Over Card]", res.effects.status);
}