import { Ed25519Keypair, RawSigner, fromB64 } from '@mysten/sui.js';
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
    const keypair = Ed25519Keypair.fromSeed(fromB64(config.DEPLOYER.pk).slice(1));
    const signer = new RawSigner(keypair, provider);
    await fund(
        await signer.getAddress()
    );
    const compiledModulesAndDeps = JSON.parse(
        execSync(
            `sui move build --dump-bytecode-as-base64 --path ../`,
            { encoding: 'utf-8' },
        ),
    );
    const publishTxn = await signer.publish({
        compiledModules: compiledModulesAndDeps,
        gasBudget: 10000,
    });
    return publishTxn.effects.effects.created
}