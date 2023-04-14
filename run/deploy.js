import { Ed25519Keypair, RawSigner, TransactionBlock, normalizeSuiObjectId, fromB64 } from '@mysten/sui.js';
import { config } from "./config.js";
import { provider } from "./provider.js";
import { execSync } from 'child_process';
import { fund } from './_utils/fund.utils.js';
/**
 * Deploys the smart contract using DEPLOYER from config.js
 * Returns created objects
 * To get the objectId, read this schema:
    [
        {
            owner: { Shared: [Object] },
            reference: {
            objectId: string,
            version: number,
            digest: string
            }
        },
        {
            owner: 'Immutable',
            reference: {
            objectId: string,
            version: number,
            digest: string
            }
        }
    ]
*
* For this case, immutable refers to the package
* shared refers to the config object of the contract
*/
export const deploy = async () => {
    const keypair = Ed25519Keypair.deriveKeypair(config.DEPLOYER.mnemonic, "m/44'/784'/0'/0'/0'");
    const signer = new RawSigner(keypair, provider);
    const signerAddress = await signer.getAddress();
    // await fund(signerAddress);
    const compiledModulesAndDeps = JSON.parse(
        execSync(
            `sui move build --dump-bytecode-as-base64 --path ./`,
            { encoding: 'utf-8' },
        ),
    );
    const tx = new TransactionBlock();
    tx.setGasBudget(200000000);
    const res = tx.publish({
        dependencies: compiledModulesAndDeps.dependencies,
        modules: compiledModulesAndDeps.modules,
    }
    );
    tx.transferObjects([res], tx.pure(signerAddress));
    const result = await signer.signAndExecuteTransactionBlock({
        transactionBlock: tx,
        options: {
            showEffects: true,
        }
    });
    console.log("[Deploy] succeed");
    console.log(result.effects);
    return result.effects.created;
}