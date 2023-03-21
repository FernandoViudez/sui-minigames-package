import { provider } from "./provider.js"
import { Ed25519Keypair, RawSigner, fromB64 } from '@mysten/sui.js';

export const turn_over_card = async (packageObjectId, gameBoardObjectId, account, cardId, cardsLocation) => {
    const keypair = Ed25519Keypair.fromSeed(fromB64(account.pk).slice(1));
    const signer = new RawSigner(keypair, provider);

    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId,
        module: 'memotest',
        function: 'turn_card_over',
        typeArguments: [],
        arguments: [
            gameBoardObjectId,
            cardId,
            cardsLocation
        ],
        gasBudget: 10000,
    });
    console.log("[Turn Over Card]", moveCallTxn.effects.effects.status);
}