'reach 0.1'; //reach version that is going to be used

const Player = {  //storing functions getHand and seeOutcome in the object Player
  getHand: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
};

export const main = Reach.App(() => { //this makes a Reach App
  const Alice = Participant('Alice', { //Defining participants
    // specify Alice`s interact interface here
    ...Player, //user can use all of the functions form Player
  });
  const Bob   = Participant('Bob', {
    ...Player,
  });
  init();
// write program here
  Alice.only(() => { //Alice enters a local step and saves her hand in handAlice
    const handAlice = declassify(interact.getHand()); //We use a frontend function so we have to interact. with it, also it is hashed so we use declassify to use it
  });
  Alice.publish(handAlice); //Writing Alice`s hand to the blockchain, entering Consensus step
  commit(); //Moving to the next step

  Bob.only(() => {
    const handBob = declassify(interact.getHand());
  });
  Bob.publish(handBob);

  const outcome = (handAlice + (4 - handBob)) % 3; //Determining the outcome of the game
  commit();

  each([Alice, Bob], () => { //Alice and Bob start a local step together and do the same thing
    interact.seeOutcome(outcome);
  });
});