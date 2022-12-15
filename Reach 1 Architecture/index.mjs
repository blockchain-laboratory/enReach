// this a modified JavaScript file (frontend)
import { loadStdlib } from '@reach-sh/stdlib'; //importing the standard Reach library
import * as backend from './build/index.main.mjs'; //importing backend from the other file, which is in the subfolder: main
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100); //creating a constant for starting balance
const accAlice = await stdlib.newTestAccount(startingBalance); // making test accounts
const accBob = await stdlib.newTestAccount(startingBalance);

const ctcAlice = accAlice.contract(backend); //Alice is one participant in this contract, she attaches to any contract
const ctcBob = accBob.contract(backend, ctcAlice.getInfo()); //Bob is attaching to the Alice`s contract, so he joins Alice`s contract

//Defining possible hand choices, and the possible outcomes
const HAND = ['Rock', 'Paper', 'Scissors'];
const OUTCOME = ['Bob wins', 'Draw', 'Alice wins'];
const Player = (Who) => ({
  getHand: () => {
    const hand = Math.floor(Math.random() * 3); //Storing the hand of that player, by assinging a random number (hand) to it
    console.log(`${Who} played ${HAND[hand]}`); //Showing Who chose which hand
    return hand;
  },
  seeOutcome: (outcome) => {
    console.log(`${Who} saw outcome ${OUTCOME[outcome]}`); //Just showing the outcome
  },
});

await Promise.all([
  ctcAlice.p.Alice({
    ...Player('Alice'), //Needs to mirror the backend logic
  }),
  ctcBob.p.Bob({
    ...Player('Bob'),
  }),
]);