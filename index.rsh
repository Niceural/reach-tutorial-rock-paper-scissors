"reach 0.1";

const Player = {
    getHand: Fun([], UInt),
    seeOutcome: Fun([UInt], Null),
};

export const main = Reach.App(() => {
    const Alice = Participant("Alice", {
        ...Player,
    });
    const Bob = Participant("Bob", {
        ...Player,
    });
    init();
});
