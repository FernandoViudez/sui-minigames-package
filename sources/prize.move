module games::prize {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self};
    use std::option::{Self, Option};
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

    public fun transfer_prize(to: address, amount: Option<u64>, prize: &mut Prize, ctx: &mut TxContext) {
        let balance = coin::balance_mut(&mut prize.reserve_coin);
        let full_amount = balance::value(balance);
        if(option::is_some(&amount)) {
            full_amount = option::extract<u64>(&mut amount);
        };
        let new_coin = coin::take<SUI>(
            balance,
            full_amount,
            ctx,
        );
        transfer::transfer(new_coin, to);
    }

    public fun update_prize(new_winner: address, prize: &mut Prize) {
        prize.winner = new_winner;
        prize.claimed = true;
    }

    public fun is_claimed(prize: &Prize): bool {
        return prize.claimed
    }
}