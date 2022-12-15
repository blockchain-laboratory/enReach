import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

const startingBalance = stdlib.parseCurrency(100);
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);

const fmt = (x) => stdlib.formatCurrency(x, 4); //This function formats the used currency to regular units from microunits
const getBalance = async (who) => fmt(await stdlib.balanceOf(who)); //This function gets the balance of a player
const beforeAlice = await getBalance(accAlice); //Gets the balance of Alice`s account before the game starts
const beforeBob = await getBalance(accBob); //Same as the previous

const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

const HAND = ['Rock', 'Paper', 'Scissors'];
const OUTCOME = ['Bob wins', 'Draw', 'Alice wins'];
const Player = (Who) => ({
  getHand: () => {
    const hand = Math.floor(Math.random() * 3);
    console.log(`${Who} played ${HAND[hand]}`);
    return hand;
  },
  seeOutcome: (outcome) => {
    console.log(`${Who} saw outcome ${OUTCOME[outcome]}`);
  },
});

await Promise.all([
  ctcAlice.p.Alice({
    ...Player('Alice'),
    wager: stdlib.parseCurrency(5), //We set the wager to 5 microunits
  }),
  ctcBob.p.Bob({
    ...Player('Bob'),
    acceptWager: (amt) => {
      console.log(`Bob accepts the wager of ${fmt(amt)}.`); //Bob accepts Alice`s wager, and shows the user the wager amount
    },
  }),
]);

const afterAlice = await getBalance(accAlice); //Getting account balance information after
const afterBob = await getBalance(accBob);

console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`); //Seeing in the console how the balances changed from the before to after
console.log(`Bob went from ${beforeBob} to ${afterBob}.`);