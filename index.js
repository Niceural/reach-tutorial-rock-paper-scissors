import React from "react";
import AppViews from "./views/AppViews";
import DeployerViews from "./views/DeployerViews";
import AttacherViews from "./views/AttacherViews";
import { renderDOM, renderView } from "./views/render";
import "./index.css";
import * as backend from "./build/index.main.mjs";
import { loadStdlib } from "@reach-sh/stdlib";
const reach = loadStdlib(process.env);

const handToInt = { ROCK: 0, PAPER: 1, SCISSORS: 2 };
const intToOutcome = ["Bob wins!", "Draw!", "Alice wins!"];
const { standardUnit } = reach;
const defaults = { defaultFundAmt: "10", defaultWager: "3", standardUnit };

class App extends React.Component {
  constructor(props) {
    super(props);
    this.state = { view: "ConnectAccount", ...defaults }; // initialize the component state to display Connect Account dialog
  }
  // hook into React's componentDidMount lifecycle event, which is called when the component starts
  async componentDidMount() {
    const acc = await reach.getDefaultAccount(); // use getDefaultAccount, which accesses the default browser account. For example, when used with Ethereum, it can discover the currently-selected MetaMask account
    const balAtomic = await reach.balaceOf(acc);
    const bal = reach.formatCurrency(balAtomic, 4);
    this.setState({ acc, bal });
    //use canFundFromFaucet to see if we can access the Reach developer testing network faucet
    if (await reach.canFundFromFaucet()) {
      this.setState({ view: "FundAccount" });
    } else {
      this.setState({ view: "DeployerOrAttacher" });
    }
  }
  render() {
    return renderView(this, AppViews);
  }
}
