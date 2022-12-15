'reach 0.1';

const Player = {
  getHand: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
};

export const main = Reach.App(() => {
  const Alice = Participant('Alice', {
    ...Player,
    wager: UInt, //Only Alice can provide this data
  });
  const Bob   = Participant('Bob', {
    ...Player,
    acceptWager: Fun([UInt], Null), //Mirroring the front end function, it needs to be there in both frontend and backend
  });
  init();

  Alice.only(() => {
    const wager = declassify(interact.wager); //Calling the setting of the wager
    const handAlice = declassify(interact.getHand());
  });
  Alice.publish(wager, handAlice)
    .pay(wager); //Alice is paying an amount(wager) into the cotract
  commit();

  Bob.only(() => {
    interact.acceptWager(wager); //Interacting with the frontend function
    const handBob = declassify(interact.getHand());
  });
  Bob.publish(handBob)
    .pay(wager); //Bob also pays, the contract now holds 2 amounts of the wager

  const outcome = (handAlice + (4 - handBob)) % 3;
  const            [forAlice, forBob] = //We use this to be able to pay the users
    outcome == 2 ? [       2,      0] : //2 portions of the wager
    outcome == 0 ? [       0,      2] :
    /* tie      */ [       1,      1];
  transfer(forAlice * wager).to(Alice); //Transfer takes tokens out of the contract and sends them to the user
   transfer(forBob   * wager).to(Bob);
  commit();

  each([Alice, Bob], () => {
    interact.seeOutcome(outcome); //Lets Alice and Bob see the outcome of the game
  });
});