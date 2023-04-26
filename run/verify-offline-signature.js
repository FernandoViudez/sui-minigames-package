import { Ed25519PublicKey } from '@mysten/sui.js'
import * as tweetnacl from 'tweetnacl';

(async () => {
    const publicKey = new Ed25519PublicKey(
        Buffer.from('yGUXMKo6GYd6Q7bMRbrJSKtNHfo+Hj1YgNBELXi5k64=', 'base64'),
    );
    const address = publicKey.toSuiAddress();
    const messageBytes = new TextEncoder().encode(address + ':' + 'daAerEK4fqf9pvAOAABP');
    const isValid = tweetnacl.sign.detached.verify(
        messageBytes,
        fromB64('ALGVeIcA+FGS7ACI1Oq51xxUW4uzfLS/SpMNx6zQBKXhZzNULSQBcNMxtCjJ7Wm2Ma5u4X5a+QZKo2qeFUveJAzIZRcwqjoZh3pDtsxFuslIq00d+j4ePViA0EQteLmTrg=='),
        publicKey.toBytes(),
    );
    console.log(isValid)
})()
