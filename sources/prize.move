module games::prize {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    struct Prize has store {
        winner: address,
        reserve_coin: Coin<SUI>,
        claimed: bool,
    }

    public fun build_prize(winner: address, coin: Coin<SUI>, claimed: bool): Prize {
        Prize {
            winner,
            reserve_coin: coin,
            claimed
        }
    }

    public fun update_balance(prize: &mut Prize, bet: &mut Coin<SUI>, ctx: &mut TxContext) {
        let balance = coin::balance_mut(bet);
        let bet_amount = balance::value(balance);
        let new_coin = coin::take<SUI>(
            balance,
            bet_amount,
            ctx,
        );
        coin::join(&mut prize.reserve_coin, new_coin);
    }
}