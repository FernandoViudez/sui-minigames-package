import { config } from "./config.js"
import { provider } from "./provider.js"
import { Ed25519Keypair, RawSigner, fromB64 } from '@mysten/sui.js';
import { getCoin } from './_utils/coin.utils.js';
import { fund } from './_utils/fund.utils.js';

const keypair = Ed25519Keypair.fromSeed(fromB64(config.GAME_CREATOR.pk).slice(1));
const signer = new RawSigner(keypair, provider);

export const newGame = async (packageObjectId, configObjectId, amountToBet) => {
    // split coin of the game creator with the required amount to bet
    await fund("0x" + keypair.getPublicKey().toSuiAddress());
    const coinForBet = await getCoin(config.GAME_CREATOR.addr, amountToBet, signer);
    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId,
        module: 'memotest',
        function: 'new_game',
        typeArguments: [],
        arguments: [
            configObjectId,
            coinForBet,
        ],
        gasBudget: 10000,
    });
    return moveCallTxn.effects.effects.created[0].reference.objectId;
}