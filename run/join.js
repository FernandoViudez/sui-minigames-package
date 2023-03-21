import { provider } from "./provider.js"
import { Ed25519Keypair, RawSigner, fromB64 } from '@mysten/sui.js';
import { getCoin } from './_utils/coin.utils.js';

/**
 * Account param should be an object like single config.js account
 * @param {*} account 
 * @param {*} packageObjectId 
 * @param {*} gameBoardObjectId 
 * @param {*} betAmount 
 */
export const join = async (account, packageObjectId, gameBoardObjectId, betAmount) => {
    const keypair = Ed25519Keypair.fromSeed(fromB64(account.pk).slice(1));
    const signer = new RawSigner(keypair, provider);
    const coinForBet = await getCoin(account.addr, betAmount, signer);
    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId,
        module: 'memotest',
        function: 'join',
        typeArguments: [],
        arguments: [
            gameBoardObjectId,
            coinForBet
        ],
        gasBudget: 10000,
    });
    console.log("[Join]", moveCallTxn.effects.effects.status);
}