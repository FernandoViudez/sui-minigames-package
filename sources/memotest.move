module games::memotest {
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::balance::{Self, Balance};
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

    struct Player has store {
        id: u8,
        addr: address
    }

    struct GameBoard has key {
        id: UID,
        room: String,
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
        transfer::share_object(config);
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

    entry fun new_game(config: &mut GameConfig, room: vector<u8>, bet: &mut Coin<SUI>, ctx: &mut TxContext) {
        assert!(config.minimum_bet_amount != 0, EContractNotInitialized);

        let sender = tx_context::sender(ctx);

        let balance = coin::balance_mut(bet);

        let bet_amount = balance::value(balance);

        assert!(bet_amount >= config.minimum_bet_amount, EInvalidBalance);
        
        let new_coin = coin::take(balance, bet_amount, ctx);

        let prize = prize::build_prize(@0x0, new_coin, false);

        let gameBoard = GameBoard {
            id: object::new(ctx),
            room: string::utf8(room),
            cards: create_empty_cards(),
            players: vector[Player {
                id: 1,
                addr: sender
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
        transfer::share_object(gameBoard);
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

    /*
        Client sends:
            - gameBoard object id
            - card_id: first turned over card by client
            - cards_location: location of the first and second cards turned over 
    */
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
        };
        
        if(gameBoard.cards_found == 8) {
            gameBoard.status = string::utf8(b"finished");
        };

        // change turn
        if((gameBoard.who_plays as u64) == vector::length(&gameBoard.players)) {
            gameBoard.who_plays = 1;
        } else {
            gameBoard.who_plays = gameBoard.who_plays + 1;
        };
    }

    entry fun change_turn(gameBoard: &mut GameBoard, ctx: &mut TxContext) {
        assert!(gameBoard.status == string::utf8(b"playing"), EInvalidActionForCurrentState);

        let sender = tx_context::sender(ctx);
        assert!(gameBoard.config.authorized_addr == sender, EUnauthorized);
        if(gameBoard.who_plays == 4) {
           gameBoard.who_plays = 1; 
        } else {
            gameBoard.who_plays = gameBoard.who_plays + 1;
        };
    }


}