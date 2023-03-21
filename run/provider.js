import { JsonRpcProvider } from "@mysten/sui.js";
export const provider = new JsonRpcProvider('http://127.0.0.1:9000', {
    faucetURL: 'http://127.0.0.1:9123'
});