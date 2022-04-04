import { loadStdlib } from "@reach-sh/stdlib";
import * as backend from "./build/index.main.mjs";
const stdlib = loadStdlib();

const startingBalance = stdlib.parseCurrency(100);
const accAlice = await stdlib.newTestAccount(startingBalance);
const accBob = await stdlib.newTestAccount(startingBalance);

const fmt = (x) => stdlib.formatCurrency(x, 4);
const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
const beforeAlice = await getBalance(accAlice);
const beforeBob = await getBalance(accBob);

const ctcAlice = accAlice.contract(backend);
const ctcBob = accBob.contract(backend, ctcAlice.getInfo());

const HAND = ["Rock", "Paper", "Scissors"];
const OUTCOME = ["Bob wins", "Draw", "Alice wins"];

const Player = (Who) => ({
  ...stdlib.hasRandom,
  getHand: () => {
    const hand = Math.floor(Math.random() * 3);
    console.log(`${Who} played ${HAND[hand]}`);
    return hand;
  },
  seeOutcome: (outcome) => {
    console.log(`${Who} saw outcome ${OUTCOME[outcome]}`);
  },
  informTimeout: () => {
    console.log(`${Who} observed a timeout`);
  },
});

await Promise.all([
  ctcAlice.p.Alice({
    ...Player("Alice"), // splices the common Player interface into Alice's interface
    wager: stdlib.parseCurrency(5), // defines her wager as 5 units of the network token. This is an example of using a concrete value, rather than a function, in a participant interact interface.
    deadline: 10,
  }),
  ctcBob.p.Bob({
    ...Player("Bob"),
    // redefine Bob's acceptWager method as an asynchronous function, where half of the time it will take at least ten blocks on the Ethereum network by waiting for ten units of time to pass. We know that ten is the value of deadline, so this will cause a timeout
    acceptWager: async (amt) => {
      if (Math.random() <= 0.5) {
        for (let i = 0; i < 10; i++) {
          console.log(`Bob takes his sweet time...`);
          await stdlib.wait(1);
        }
      } else {
        console.log(`Bob accepts the wager of ${fmt(amt)}.`);
      }
    },
  }),
]);

const afterAlice = await getBalance(accAlice);
const afterBob = await getBalance(accBob);

console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`);
console.log(`Bob went from ${beforeBob} to ${afterBob}.`);
