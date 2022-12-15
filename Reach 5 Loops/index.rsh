'reach 0.1';

const [ isHand, ROCK, PAPER, SCISSORS ] = makeEnum(3);
const [ isOutcome, B_WINS, DRAW, A_WINS ] = makeEnum(3);

const winner = (handAlice, handBob) =>
  ((handAlice + (4 - handBob)) % 3);

assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(ROCK, ROCK) == DRAW);

forall(UInt, handAlice =>
  forall(UInt, handBob =>
    assert(isOutcome(winner(handAlice, handBob)))));

forall(UInt, (hand) =>
  assert(winner(hand, hand) == DRAW));

const Player = {
  ...hasRandom,
  getHand: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
  informTimeout: Fun([], Null),
};

export const main = Reach.App(() => {
  const Alice = Participant('Alice', {
    ...Player,
    wager: UInt, // atomic units of currency
    deadline: UInt, // time delta (blocks/rounds)
  });
  const Bob   = Participant('Bob', {
    ...Player,
    acceptWager: Fun([UInt], Null),
  });
  init();

  const informTimeout = () => {
    each([Alice, Bob], () => {
      interact.informTimeout();
    });
  };

  Alice.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);
  });
  Alice.publish(wager, deadline)  //Alice is paying the wager and publishing a deadline
    .pay(wager);
  commit();

  Bob.only(() => {
    interact.acceptWager(wager); //Bob accepts wager
  });
  Bob.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout)); //Timeout

  var outcome = DRAW;    //Outcome variable which is equals to DRAW 
  invariant( balance() == 2 * wager && isOutcome(outcome) ); //Condition which has to be truth and it is not changing before, in nor after loop
  while ( outcome == DRAW ) {   //While loop - Looping as long as variable outcome is equal DRAW
    commit(); //Moving from consensus to local step

    Alice.only(() => {      
      const _handAlice = interact.getHand();  //What Alice showed
      const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice); //Unique relationship between value and commitment
      const commitAlice = declassify(_commitAlice); //What Alice showed is still hidden, only the commitment is revealed
    }); 
    Alice.publish(commitAlice)
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout)); //Timeout if Bob is not responding
    commit();

    unknowable(Bob, Alice(_handAlice, _saltAlice)); //Now we know that Bob can't know what private value Alice showed
    Bob.only(() => {
      const handBob = declassify(interact.getHand());
    });
    Bob.publish(handBob) //Bob is publishing what he showed
      .timeout(relativeTime(deadline), () => closeTo(Alice, informTimeout)); //Timeout
    commit();

    Alice.only(() => {    //Now we can reveal Alices values
      const saltAlice = declassify(_saltAlice); 
      const handAlice = declassify(_handAlice);
    });
    Alice.publish(saltAlice, handAlice)   //Alice is publishing info so we can use them
      .timeout(relativeTime(deadline), () => closeTo(Bob, informTimeout)); //Timeout (if she is not responding)
    checkCommitment(commitAlice, saltAlice, handAlice); //Checking if Alice tried to change what she showed at the begining

    outcome = winner(handAlice, handBob);   //Updating value of loop variable outcome (we are sending values to function Winner, which returns outcome)
    continue;   //Reach requires continue for WHILE loops (returning to loop condition)
  }   //End of loop

  assert(outcome == A_WINS || outcome == B_WINS);   //Checking if outcome is Alice won or Bob won
  transfer(2 * wager).to(outcome == A_WINS ? Alice : Bob);  //Transfer of a wager to the winner
  commit(); //Exit consensus

  each([Alice, Bob], () => {
    interact.seeOutcome(outcome); //Showing outcome for each
  });
});
