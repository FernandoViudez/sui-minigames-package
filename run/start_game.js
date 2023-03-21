import { Ed25519Keypair, RawSigner, fromB64 } from '@mysten/sui.js';
import { config } from "./config.js";
import { provider } from "./provider.js";

const keypair = Ed25519Keypair.fromSeed(fromB64(config.GAME_CREATOR.pk).slice(1));
const signer = new RawSigner(keypair, provider);

export const startGame = async (packageObjectId, gameBoardObjectId) => {
    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId,
        module: 'memotest',
        function: 'start_game',
        typeArguments: [],
        arguments: [
            gameBoardObjectId
        ],
        gasBudget: 10000,
    });
    console.log("[Start Game]", moveCallTxn.effects.effects.status);
}