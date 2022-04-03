"reach 0.1";

const Player = {
  getHand: Fun([], UInt),
  seeOutcome: Fun([UInt], Null),
};

export const main = Reach.App(() => {
  const Alice = Participant("Alice", {
    ...Player, // define Alice's interface as the Player interface
    wager: UInt,
  });
  const Bob = Participant("Bob", {
    ...Player,
    acceptWager: Fun([UInt], Null),
  });
  init();

  Alice.only(() => {
    const wager = declassify(interact.wager); // declassify the wager for transmission
    const handAlice = declassify(interact.getHand());
  });
  Alice.publish(wager, handAlice) // Alice shares the wager amount with Bob
    .pay(wager); // has her transfer the amount as part of her publication. The Reach compiler would throw an exception if wager did not appear on line 23, but did appear on line 24. Change the program and try it. This is because the consensus network needs to be able to verify that the amount of network tokens included in Alice's publication match some computation available to consensus network
  commit();

  unknowable(Bob, Alice(handAlice));
  Bob.only(() => {
    interact.acceptWager(wager); // has Bob accept the wager. If he doesn't like the terms, his frontend can just not respond to this method and the DApp will stall
    const handBob = declassify(interact.getHand());
  });
  Bob.publish(handBob).pay(wager); // has Bob pay the wager as well

  const outcome = (handAlice + (4 - handBob)) % 3;
  const [forAlice, forBob] =
    outcome == 2 ? [1, 0] : outcome == 0 ? [0, 2] : /* tie */ [1, 1];
  transfer(forAlice * wager).to(Alice);
  transfer(forBob * wager).to(Bob);
  commit();

  each([Alice, Bob], () => {
    interact.seeOutcome(outcome);
  });
});
