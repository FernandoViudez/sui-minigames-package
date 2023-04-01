import { config } from './config.js';
import { deploy } from './deploy.js';
import { initialize } from './initialize.js';
(async () => {
    const res = await deploy();

    const packageObjectId = res.find(el => el.owner == 'Immutable').reference.objectId;
    const configObjectId = res.find(el => el.owner["Shared"]).reference.objectId;

    await initialize(packageObjectId, configObjectId, config.minimumBalanceRequired);

    console.log({
        packageObjectId,
        configObjectId,
    })
})()