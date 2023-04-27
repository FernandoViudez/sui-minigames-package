import { JsonRpcProvider, devnetConnection } from "@mysten/sui.js";
export const provider = new JsonRpcProvider(devnetConnection);