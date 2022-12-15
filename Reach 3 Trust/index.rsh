'reach 0.1';

//Defining enumerations for the hands that may be played, as well as the outcomes
const [ isHand, ROCK, PAPER, SCISSORS ] = makeEnum(3);
const [ isOutcome, B_WINS, DRAW, A_WINS ] = makeEnum(3);

const winner = (handAlice, handBob) => //Computes the winner of the game
  ((handAlice + (4 - handBob)) % 3);

assert(winner(ROCK, PAPER) == B_WINS); //Making an assertion that when Alice plays Rock and Bob plays Paper, Bob wins as expected
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(ROCK, ROCK) == DRAW);

forall(UInt, handAlice =>
  forall(UInt, handBob =>
    assert(isOutcome(winner(handAlice, handBob))))); //No matter the values for handAlice and handBob, winner will always provide a valid outcome

forall(UInt, (hand) =>
  assert(winner(hand, hand) == DRAW)); //If the hand values are the same, the outcome is always a draw

const Player = {
  ...hasRandom, // <--- new! We will use this to generate a random number to protect Alice`s hand
  getHand: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
};

export const main = Reach.App(() => {
  const Alice = Participant('Alice', {
    ...Player,
    wager: UInt,
  });
  const Bob   = Participant('Bob', {
    ...Player,
    acceptWager: Fun([UInt], Null),
  });
  init();

  Alice.only(() => {
    const wager = declassify(interact.wager);
    const _handAlice = interact.getHand(); //This value is hashed, so it stays secret
    const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice); //Makes sure that Alice cannot change her hand later, but her hand is not known
    const commitAlice = declassify(_commitAlice);
  });
  Alice.publish(wager, commitAlice)
    .pay(wager);
  commit();

  unknowable(Bob, Alice(_handAlice, _saltAlice)); //We make sure that Bob does not know _handAlice or _saltAlice, which are private values
  Bob.only(() => {
    interact.acceptWager(wager);
    const handBob = declassify(interact.getHand());
  });
  Bob.publish(handBob)
    .pay(wager);
  commit();

  Alice.only(() => { //Alice here reveals her private values so they can now be used
    const saltAlice = declassify(_saltAlice);
    const handAlice = declassify(_handAlice);
  });
  Alice.publish(saltAlice, handAlice); //Alice publishes this information
  checkCommitment(commitAlice, saltAlice, handAlice); //Checks that the published values match the original values

  const outcome = winner(handAlice, handBob);
  const                 [forAlice, forBob] =
    outcome == A_WINS ? [       2,      0] :
    outcome == B_WINS ? [       0,      2] :
    /* tie           */ [       1,      1];
  transfer(forAlice * wager).to(Alice);
  transfer(forBob   * wager).to(Bob);
  commit();

  each([Alice, Bob], () => {
    interact.seeOutcome(outcome);
  });
});