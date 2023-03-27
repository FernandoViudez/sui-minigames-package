import { Ed25519Keypair, RawSigner, fromB64 } from '@mysten/sui.js';
import { config } from "./config.js";
import { provider } from "./provider.js";
import { fund } from "./_utils/fund.utils.js";

const keypair = Ed25519Keypair.fromSeed(fromB64(config.MEMOTEST_AUTHORIZED_ADDR.pk).slice(1));
const signer = new RawSigner(keypair, provider);

export const update_card = async (
    packageObjectId,
    configObjectId,
    gameBoardObjectId,
    card_id,
    new_location,
    modify_per,
    new_image
) => {
    await fund("0x" + keypair.getPublicKey().toSuiAddress());
    const moveCallTxn = await signer.executeMoveCall({
        packageObjectId,
        module: 'memotest',
        function: 'update_card',
        typeArguments: [],
        arguments: [
            configObjectId,
            gameBoardObjectId,
            card_id,
            new_location,
            modify_per,
            new_image
        ],
        gasBudget: 10000,
    });
    console.log("[Server Update card]", moveCallTxn.effects.effects.status);
}