import { Ed25519Keypair, RawSigner, fromB64 } from '@mysten/sui.js';
import { config } from "./config.js";
import { provider } from "./provider.js";

const keypair = Ed25519Keypair.fromSeed(fromB64(config.DEPLOYER.pk).slice(1));
const signer = new RawSigner(keypair, provider);

/**
 * First two args are deps
 * The third arg is the SUI token minimum bet amount 
 * @param {*} packageObjectId 
 * @param {*} configObjectId 
 * @param {*} betAmount 
*/
export const initialize = async (packageObjectId, configObjectId, minimumBetAmount) => {
    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId,
        module: 'memotest',
        function: 'initialize',
        typeArguments: [],
        arguments: [
            configObjectId,
            Number(minimumBetAmount).toString(),
            config.MEMOTEST_AUTHORIZED_ADDR.addr
        ],
        gasBudget: 10000,
    });
    console.log("[Initialize]", moveCallTxn.effects.effects.status);
}