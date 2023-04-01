import { config } from "./config.js"
import { provider } from "./provider.js"
import { Ed25519Keypair, RawSigner, fromB64, TransactionBlock } from '@mysten/sui.js';
import { getCoin } from './_utils/coin.utils.js';
import { fund } from './_utils/fund.utils.js';

const keypair = Ed25519Keypair.deriveKeypair(config.GAME_CREATOR.mnemonic, "m/44'/784'/0'/0'/0'");
const signer = new RawSigner(keypair, provider);

export const newGame = async (packageObjectId, configObjectId, amountToBet) => {
    // split coin of the game creator with the required amount to bet
    await fund("0x" + keypair.getPublicKey().toSuiAddress());
    const coinForBet = await getCoin(config.GAME_CREATOR.addr, amountToBet, signer);
    const tx = new TransactionBlock();
    tx.moveCall({
        target: `${packageObjectId}::memotest::new_game`,
        arguments: [
            tx.pure(configObjectId),
            tx.pure(coinForBet)
        ]
    })
    tx.setGasBudget(10000);
    const res = await signer.signAndExecuteTransactionBlock({ transactionBlock: tx });
    return res.effects.created[0].reference.objectId;
}