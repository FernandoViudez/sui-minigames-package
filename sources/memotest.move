module games::memotest {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::balance::{Self};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use std::vector;
    use games::prize::{Self, Prize};
    use std::option::{Self, Option};

    const EConfigAlreadyInitialized: u64 = 1;
    const EIncorrectMinimumBetAmount: u64 = 2;
    const EInvalidBalance: u64 = 3;
    const EContractNotInitialized: u64 = 4;
    const EMaxPlayersReached: u64 = 5;
    const EInvalidActionForCurrentState: u64 = 6;
    const ECantJoinTwice: u64 = 7;
    const ECardAlreadyFound: u64 = 8;
    const EPrizeAlreadyClaimed: u64 = 9;
    const EInvalidPlayerQuantity: u64 = 10;
    const ECantLeaveGame: u64 = 11;
    const EPlayerNotFound: u64 = 12;
    const EUnauthorized: u64 = 401;
    const EBadRequest: u64 = 400;

    const TOTAL_CARDS: u64 = 8;

    struct Card has store {
        id: u8,
        image: String,
        location: u8,
        per_location: u8,
        found_by: address
    }

    struct Player has store, drop {
        id: u8,
        addr: address,
        amount_betted: u64,
        found_amount: u8,
        can_play: bool,
    }

    struct GameBoard has key, store {
        id: UID,
        cards: vector<Card>,
        players: vector<Player>,
        status: String,
        cards_found: u8,
        prize: Prize,
        who_plays: u8,
        config: GameConfig,
    }
    
    // unique object, can be update only by the owner/creator and defines the configurations of this contract
    struct GameConfig has key, store {
        id: UID,
        creator: address,
        minimum_bet_amount: u64,
        authorized_addr: address,
    }

    fun init(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let config = GameConfig {
            id: object::new(ctx),
            minimum_bet_amount: 0,
            authorized_addr: sender,
            creator: sender,
        };
        transfer::public_share_object(config);
    }

    entry fun initialize(
        config: &mut GameConfig, 
        minimum_bet_amount: u64, 
        authorized_addr: address, 
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(sender == config.creator, EUnauthorized);
        assert!(config.minimum_bet_amount == 0, EConfigAlreadyInitialized); // config could be updated only one time
        assert!(minimum_bet_amount != 0, EIncorrectMinimumBetAmount);
        config.minimum_bet_amount = minimum_bet_amount;
        config.authorized_addr = authorized_addr;
    }

    entry fun update_card(
        config: &mut GameConfig, 
        game: &mut GameBoard, 
        card_id: u8, 
        new_location: u8, 
        modify_per: bool, 
        new_image: vector<u8>, 
        ctx: &mut TxContext
    ) {
        assert!(game.status == string::utf8(b"playing"), EInvalidActionForCurrentState);
        let sender = tx_context::sender(ctx);
        assert!(&config.authorized_addr == &sender, EUnauthorized);
        let card_to_update: &mut Card = vector::borrow_mut<Card>(&mut game.cards, (card_id as u64));
        if(modify_per) {
            card_to_update.per_location = new_location;
        } else {
            card_to_update.location = new_location;
        };
        card_to_update.image = string::utf8(new_image);
    }

    entry fun new_game(config: &mut GameConfig, bet: &mut Coin<SUI>, ctx: &mut TxContext) {
        assert!(config.minimum_bet_amount != 0, EContractNotInitialized);

        let sender = tx_context::sender(ctx);

        let balance = coin::balance_mut(bet);

        let bet_amount = balance::value(balance);

        assert!(bet_amount >= config.minimum_bet_amount, EInvalidBalance);
        
        let new_coin = coin::take(balance, bet_amount, ctx);

        let prize = prize::build_prize(@0x0, new_coin, false);

        let gameBoard = GameBoard {
            id: object::new(ctx),
            cards: create_empty_cards(),
            players: vector[Player {
                id: 1,
                addr: sender,
                amount_betted: bet_amount,
                found_amount: 0,
                can_play: true
            }],
            status: string::utf8(b"waiting"),
            cards_found: 0,
            prize,
            who_plays: 1,
            config: GameConfig {
                id: object::new(ctx),
                creator: sender,
                minimum_bet_amount: config.minimum_bet_amount,
                authorized_addr: config.authorized_addr,
            },
        };
        transfer::public_share_object(gameBoard);
    }

    fun create_empty_cards(): vector<Card> {
        let i: u64 = 0;
        let cards_vector = vector::empty<Card>();
        loop {
            let card = Card {
                id: (i as u8),
                image: string::utf8(vector[]),
                location: 0,
                per_location: 0,
                found_by: @0x0
            };
            vector::push_back<Card>(&mut cards_vector, card);
            if(i == (TOTAL_CARDS - 1)) {
                break
            };
            i = i + 1;
        };
        cards_vector
    }

    entry fun join(gameBoard: &mut GameBoard, bet: &mut Coin<SUI>, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let players_number = vector::length(&gameBoard.players);
        assert!(players_number < 4, EMaxPlayersReached);
        assert!(gameBoard.status == string::utf8(b"waiting"), EInvalidActionForCurrentState);
        
        let i: u64 = 0;
        loop {

            let player: &mut Player = vector::borrow_mut(&mut gameBoard.players, i);
            assert!(player.addr != sender, ECantJoinTwice);

            if(i == (players_number - 1)) {
                break
            };
            
            i = i + 1;
        };

        let balance = coin::balance_mut(bet);
        let bet_amount = balance::value(balance);
        assert!(bet_amount >= gameBoard.config.minimum_bet_amount, EInvalidBalance);

        let new_player = Player {
            id: (players_number as u8) + 1,
            addr: tx_context::sender(ctx),
            amount_betted: bet_amount,
            found_amount: 0,
            can_play: true
        };
        vector::push_back(&mut gameBoard.players, new_player);

        prize::update_balance(&mut gameBoard.prize, bet, ctx);
    }

    entry fun start_game(gameBoard: &mut GameBoard, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(sender == gameBoard.config.creator, EUnauthorized);
        assert!(gameBoard.status == string::utf8(b"waiting"), EInvalidActionForCurrentState);
        gameBoard.status = string::utf8(b"playing");
    }

    entry fun turn_card_over(gameBoard: &mut GameBoard, card_id: u8, cards_location: vector<u8>, ctx: &mut TxContext) {
        assert!(gameBoard.status == string::utf8(b"playing"), EInvalidActionForCurrentState);

        let sender = tx_context::sender(ctx);
        let players_turn: &mut Player = vector::borrow_mut(&mut gameBoard.players, (gameBoard.who_plays as u64) - 1);
        assert!(players_turn.addr == sender, EUnauthorized);

        let first_card_turned: &mut Card = vector::borrow_mut(&mut gameBoard.cards, (card_id as u64));
        assert!(first_card_turned.found_by == @0x0, ECardAlreadyFound);

        let second_card_position: u8 = vector::pop_back(&mut cards_location);
        let first_card_position: u8 = vector::pop_back(&mut cards_location);

        // check that the location for the first card sent is correct
        assert!(
            first_card_turned.location == first_card_position || 
            first_card_turned.per_location == first_card_position, 
            EBadRequest
        );
        assert!(
            first_card_position != second_card_position,
            EBadRequest
        );

        // check that the second position sent correspond to the same card
        if(
            first_card_turned.per_location == second_card_position || 
            first_card_turned.location == second_card_position
        ) {
            first_card_turned.found_by = sender;
            gameBoard.cards_found = gameBoard.cards_found + 1;
            players_turn.found_amount = players_turn.found_amount + 1;
        };
        
        if((gameBoard.cards_found as u64) == TOTAL_CARDS) {
            gameBoard.status = string::utf8(b"finished");
        };

        // change turn
        update_who_plays(gameBoard, ctx);
    }

    entry fun change_turn(gameBoard: &mut GameBoard, ctx: &mut TxContext) {
        assert!(gameBoard.status == string::utf8(b"playing"), EInvalidActionForCurrentState);
        let sender = tx_context::sender(ctx);
        assert!(gameBoard.config.authorized_addr == sender, EUnauthorized);
        update_who_plays(gameBoard, ctx);
    }
    
    entry fun disconnect_player(gameBoard: &mut GameBoard, player_id: u8, ctx: &mut TxContext) {
            let sender = tx_context::sender(ctx);
            assert!(sender == gameBoard.config.authorized_addr, EUnauthorized);
            let active_players = get_active_players_amount(&gameBoard.players);
            assert!(active_players > 1, ECantLeaveGame);
            let i = 0;
            loop {
                let player = vector::borrow_mut(&mut gameBoard.players, i);
                if(player.id == player_id) {
                    player.can_play = false;
                    if(active_players == 2) {
                        gameBoard.status = string::utf8(b"finished");
                    };
                    break
                };
                if(i == vector::length(&gameBoard.players)) {
                    break
                };
                i = i + 1;
            };
    }

    entry fun claim_prize(gameBoard: &mut GameBoard, ctx: &mut TxContext) {
        assert!(gameBoard.status == string::utf8(b"finished"), EInvalidActionForCurrentState);
        let sender = tx_context::sender(ctx);
        let winner = get_winner(&gameBoard.players);
        if(winner == @0x0) {

            // let each player claim the amount betted
            let player = get_player_from_address(&gameBoard.players, sender);
            assert!(player.amount_betted != 0, EPrizeAlreadyClaimed);

            prize::transfer_prize(player.addr,option::some(player.amount_betted), &mut gameBoard.prize, ctx);
            let player_mut = vector::borrow_mut(&mut gameBoard.players, (player.id as u64) - 1);
            player_mut.amount_betted = 0;

        } else {
            if(get_active_players_amount(&gameBoard.players) > 1) {
                assert!(sender == winner, EUnauthorized);
            };
            assert!(prize::is_claimed(&gameBoard.prize) == false, EPrizeAlreadyClaimed);
            prize::transfer_prize(sender, option::none(), &mut gameBoard.prize, ctx);
            prize::update_prize(sender, &mut gameBoard.prize);
        };
    }

    fun get_winner(players: &vector<Player>): address {
        let i = 0;
        let winner = @0x0;
        let aux = 0;
        loop {

            let player = vector::borrow(players, i);

            if(aux != 0 && player.found_amount == aux) {
                // tie, for now let all the players withdraw the coins
                winner = @0x0;
            } else if(player.found_amount > aux) {
                winner = player.addr;
                aux = player.found_amount;
            };

            if(i == (vector::length(players) - 1)) {
                break
            };
            i = i + 1;
        };
        return winner
    }

    fun get_player_from_address(players: &vector<Player>, sender: address): &Player {
        let i = 0;
        loop {
            let player_borrow: &Player = vector::borrow(players, i);
            if(player_borrow.addr == sender) {
                return player_borrow
            };
            if(i == vector::length(players)) {
                assert!(true == false, EPlayerNotFound);
                break
            };
            i = i + 1;
        };
        vector::borrow(players, 0)
    }

    fun update_who_plays(gameBoard: &mut GameBoard, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        assert!(get_active_players_amount(&gameBoard.players) >= 2, EInvalidPlayerQuantity);
        if((gameBoard.who_plays as u64) == vector::length(&gameBoard.players)) {
           gameBoard.who_plays = 1; 
        } else {
            gameBoard.who_plays = gameBoard.who_plays + 1;
        };
        let player = get_player_from_address(&gameBoard.players, sender);
        if(!player.can_play) {
            update_who_plays(gameBoard, ctx);
        };
    }

    fun get_active_players_amount(players: &vector<Player>): u64 {
        let active_players_amount = 0;
        let i = 0;
        loop {
            let player = vector::borrow(players, i);
            if(player.can_play) {
                active_players_amount = active_players_amount + 1;
            };
            if(vector::length(players) == i) {
                break
            };
            i = i + 1;
        };
        return active_players_amount
    }


}