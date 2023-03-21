import { config } from './config.js';
import { deploy } from './deploy.js';
import { initialize } from './initialize.js';
import { join } from './join.js';
import { newGame } from './new_game.js';
import { provider } from './provider.js';
import { startGame } from './start_game.js';
import { turn_over_card } from './turn_over_card.js';
import { update_card } from './update_card.js';

var packageObjectId;
var configObjectId;
var gameBoardObjectId;

/**
 * Play game
 * Deploy & initialize contract
 * 
 * Create new game
 * Join with other two clients to the game
 * Turn over a card (simulating server)
 * 
 */
const play = async () => {
    const res = await deploy();
    packageObjectId = res.find(el => el.owner == 'Immutable').reference.objectId;
    configObjectId = res.find(el => el.owner["Shared"]).reference.objectId;

    await initialize(packageObjectId, configObjectId, config.minimumBalanceRequired);

    gameBoardObjectId = await newGame(packageObjectId, configObjectId, 1000);

    console.log("gameBoardObjectId ~> ", gameBoardObjectId);
    console.log("configObjectId ~> ", configObjectId);

    await join(config.JOINER_1, packageObjectId, gameBoardObjectId, 1500);
    try {
        // amount bet balance invalid (less than minimum balance required)
        await join(config.JOINER_2, packageObjectId, gameBoardObjectId, config.minimumBalanceRequired - 1);
    } catch (error) {
        console.log("Generated and handled error ~> ", error);
    }
    await join(config.JOINER_2, packageObjectId, gameBoardObjectId, 5000);

    await startGame(packageObjectId, gameBoardObjectId);

    // turn over first and last cards
    await turnCardsOver(config.GAME_CREATOR, 1, 2);

    // wait 3 seconds before calling turn card over again
    await new Promise((resolve, reject) => setTimeout(() => { resolve() }, 3000));
    await turnCardsOver(config.JOINER_1, 3, 4);

    await new Promise((resolve, reject) => setTimeout(() => { resolve() }, 3000));
    await turnCardsOver(config.JOINER_2, 5, 6);

    await new Promise((resolve, reject) => setTimeout(() => { resolve() }, 3000));
    await turnCardsOver(config.GAME_CREATOR, 7, 8);

    await new Promise((resolve, reject) => setTimeout(() => { resolve() }, 3000));
    await turnCardsOver(config.JOINER_1, 9, 10);

    await new Promise((resolve, reject) => setTimeout(() => { resolve() }, 3000));
    await turnCardsOver(config.JOINER_2, 11, 12);

    await new Promise((resolve, reject) => setTimeout(() => { resolve() }, 3000));
    await turnCardsOver(config.GAME_CREATOR, 13, 14);

    await new Promise((resolve, reject) => setTimeout(() => { resolve() }, 3000));
    await turnCardsOver(config.JOINER_1, 15, 16);
}

const turnCardsOver = async (fromAccount, position_1, position_2) => {
    // simulate server and get random card image
    const card_1 = await serverTurnOverCardProcess(fromAccount, position_1);
    const card_2 = await serverTurnOverCardProcess(fromAccount, position_2);

    console.log("[Turn card over]", {
        card_1,
        card_2,
        positions: [position_1, position_2],
    });
    console.log("[Turn card over]", card_1.id == card_2.id ? 'Match found' : "Not matches, keep trying");

    // once server updated card on-chain, call on-chain turn over card method
    await turn_over_card(packageObjectId, gameBoardObjectId, fromAccount, card_1.id, [position_1, position_2]);
}

// simulates getting a random card from gameBoard and returns image & card id
// ignoring security check like turn and other stuff for now
const serverTurnOverCardProcess = async (fromAccount, positionChosen) => {
    const gameBoard = await provider.getObject(gameBoardObjectId);
    let { cards, who_plays, players } = gameBoard.details.data.fields;

    const player_turn = players.find(player => player.fields.id == who_plays);
    if (player_turn.fields.addr != fromAccount.addr) {
        throw new Error("Incorrect turn");
    }

    cards = cards.map(card => card.fields);
    const possible_cards = cards.filter(card => card.found_by == '0x0000000000000000000000000000000000000000' && (!card.location || !card.per_location));
    let card = cards.find(card => card.location == positionChosen || card.per_location == positionChosen);

    if (!card) {
        // from that array of cards, choose randomly one card in case of new position chosen
        card = possible_cards[Math.floor(Math.random() * possible_cards.length)];
    }
    const modify_per = card.location != 0;
    const image = "ipfs://image-" + card.id;

    // update on-chain card 
    await update_card(packageObjectId, configObjectId, gameBoardObjectId, card.id, positionChosen, modify_per, image);
    return {
        id: card.id,
        image
    };
}

play();