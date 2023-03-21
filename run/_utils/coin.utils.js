import { provider } from "../provider.js"

// if there is no coin with the required amount to bet, join them. otherwise, split
export const getCoin = async (from, balanceRequired, signer) => {
    const { data } = await provider.getAllCoins(from);
    let coins = data;
    let totalFunds = 0;
    for (let [i, coin] of coins.entries()) {
        if (coin.balance >= balanceRequired) {
            const newCoin = await splitCoin(coin.coinObjectId, balanceRequired, signer);
            return newCoin;
        }
        if (totalFunds >= balanceRequired) {
            const newCoin = await mergeCoins(
                coins.slice(0, i).map(coin => coin.coinObjectId),
                balanceRequired,
                signer,
            );
            return newCoin;
        }
        totalFunds += coin.balance;
    }
    throw new Error("Not enough funds for bet amount");
}

const splitCoin = async (coinObjectId, requiredBalance, signer) => {
    const splitTxn = await signer.splitCoin({
        coinObjectId,
        splitAmounts: [requiredBalance],
        gasBudget: 1000,
    });
    return splitTxn.effects.effects.created[0].reference.objectId;
}

const mergeCoins = async (coinsObjectId, requiredBalance, signer) => {
    const primaryCoin = coinsObjectId.shift();
    const coinToMerge = coinsObjectId.shift();
    if (!coinToMerge) {
        return primaryCoin;
    }
    await signer.mergeCoin({
        primaryCoin,
        coinToMerge,
        gasBudget: 1000,
    });
    coinsObjectId.push(primaryCoin);
    await mergeCoins(coinsObjectId, requiredBalance, signer);
}