import { JsonRpcProvider, devnetConnection, Connection } from "@mysten/sui.js";
export const provider = new JsonRpcProvider(devnetConnection);


(async () => {
    console.log(
        (await provider.getObject({
            id: '0x13408d0e9e26bb0c4d63004cc3d9209a3ecfcf993c05571cf7b4c7de5768550c',
            options: {
                showContent: true
            }
        })).data.content.fields.cards
    )
})()