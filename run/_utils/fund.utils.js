import { provider } from '../provider.js'

export const fund = async (address) => {
    // return;
    const res = await provider.requestSuiFromFaucet(address)
    console.log(res);
    console.log(address, " funded!");
    console.log(res.error == null ? 'Successfully funded account' : 'error funding account');
}