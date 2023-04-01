import { provider } from "./provider.js"
import { Ed25519Keypair, RawSigner, fromB64, TransactionArgument, TransactionBlock } from '@mysten/sui.js';
import { getCoin } from './_utils/coin.utils.js';

/**
 * Account param should be an object like single config.js account
 * @param {*} account 
 * @param {*} packageObjectId 
 * @param {*} gameBoardObjectId 
 * @param {*} betAmount 
 */
export const join = async (account, packageObjectId, gameBoardObjectId, betAmount) => {
    const keypair = Ed25519Keypair.deriveKeypair(account.mnemonic, "m/44'/784'/0'/0'/0'");
    const signer = new RawSigner(keypair, provider);
    const coinForBet = await getCoin(account.addr, betAmount, signer);
    const tx = new TransactionBlock();
    tx.setGasBudget(10000);
    tx.moveCall({
        target: `${packageObjectId}::memotest::join`,
        arguments: [
            tx.pure(gameBoardObjectId),
            tx.pure(coinForBet)
        ]
    });
    const res = await signer.signAndExecuteTransactionBlock({ transactionBlock: tx });
    console.log("[Join]", res.effects.status);
}