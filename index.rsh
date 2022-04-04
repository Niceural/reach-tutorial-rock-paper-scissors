"reach 0.1"; // usual Reach version header

// define enumerations for the hands that may be played, as well as the outcomes of the game
const [isHand, ROCK, PAPER, SCISSORS] = makeEnum(3);
const [isOutcome, B_WINS, DRAW, A_WINS] = makeEnum(3);

// define the function that computes the winner of the game
const winner = (handAlice, handBob) => (handAlice + (4 - handBob)) % 3;

// makes an assertion that when Alice plays Rock and Bob plays Paper, then Bob wins as expected
assert(winner(ROCK, PAPER) == B_WINS);
assert(winner(PAPER, ROCK) == A_WINS);
assert(winner(ROCK, ROCK) == DRAW);

// state that no matter what values are provided for handAlice and handBob, winner will always provide a valid outcome
forall(UInt, (handAlice) =>
  forall(UInt, (handBob) => assert(isOutcome(winner(handAlice, handBob))))
);

// specify that whenever the same value is provided for both hands, no matter what it is, winner always returns DRAW
forall(UInt, (hand) => assert(winner(hand, hand) == DRAW));

const Player = {
  ...hasRandom, // from reach standard library, to generate a random number to protect Alice's hand
  getHand: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
  informTimeout: Fun([], Null), // receives no arguments and returns no information. We'll call this function when a timeout occurs
};

export const main = Reach.App(() => {
  const Alice = Participant("Alice", {
    ...Player, // define Alice's interface as the Player interface
    wager: UInt,
    deadline: UInt, // adds the deadline field to Alice's participant interact interface. It is defined as some number of time delta units, which are an abstraction of the underlying notion of network time in the consensus network. In many networks, like Ethereum, this number is a number of blocks
  });
  const Bob = Participant("Bob", {
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
    const wager = declassify(interact.wager); // declassify the wager for transmission
    const deadline = declassify(interact.deadline);
  });
  Alice.publish(wager, deadline) // Alice shares the wager amount with Bob
    .pay(wager); // has her transfer the amount as part of her publication. The Reach compiler would throw an exception if wager did not appear on line 23, but did appear on line 24. Change the program and try it. This is because the consensus network needs to be able to verify that the amount of network tokens included in Alice's publication match some computation available to consensus network
  commit();

  //unknowable(Bob, Alice(handAlice, saltAlice));
  Bob.only(() => {
    interact.acceptWager(wager); // has Bob accept the wager. If he doesn't like the terms, his frontend can just not respond to this method and the DApp will stall
  });
  Bob.pay(wager).timeout(relativeTime(deadline), () =>
    closeTo(Alice, informTimeout)
  );

  var outcome = DRAW; // loop variable
  invariant(balance() == 2 * wager && isOutcome(outcome)); // states the invariant that the body of the loop does not change the balance in the contract account and that outcome is a valid outcome
  while (outcome == DRAW) {
    commit();

    Alice.only(() => {
      const _handAlice = interact.getHand();
      const [_commitAlice, _saltAlice] = makeCommitment(interact, _handAlice);
      const commitAlice = declassify(_commitAlice);
    });
    Alice.publish(commitAlice).timeout(relativeTime(deadline), () =>
      closeTo(Bob, informTimeout)
    );
    commit();

    unknowable(Bob, Alice(_handAlice, _saltAlice));
    Bob.only(() => {
      const handBob = declassify(interact.getHand());
    });
    Bob.publish(handBob).timeout(relativeTime(deadline), () =>
      closeTo(Alice, informTimeout)
    );
    commit();
    Alice.only(() => {
      const saltAlice = declassify(_saltAlice);
      const handAlice = declassify(_handAlice);
    });
    Alice.publish(saltAlice, handAlice).timeout(relativeTime(deadline), () =>
      closeTo(Bob, informTimeout)
    );
    checkCommitment(commitAlice, saltAlice, handAlice);

    outcome = winner(handAlice, handBob);
    continue;
  }

  assert(outcome == A_WINS || outcome == B_WINS);
  transfer(2 * wager).to(outcome == A_WINS ? Alice : Bob);
  commit();

  each([Alice, Bob], () => {
    interact.seeOutcome(outcome);
  });
});
