import React from 'react';
import AppViews from './views/AppViews';
import DeployerViews from './views/DeployerViews';
import AttacherViews from './views/AttacherViews';
import {renderDOM, renderView} from './views/render';
import './index.css';
import * as backend from './build/index.main.mjs';
import { loadStdlib } from '@reach-sh/stdlib';
const reach = loadStdlib(process.env);

const handToInt = {'ROCK': 0, 'PAPER': 1, 'SCISSORS': 2}; //Referencing choice as UInt
const intToOutcome = ['Bob wins!', 'Draw!', 'Alice wins!']; //Converting number to string
const {standardUnit} = reach;
const defaults = {defaultFundAmt: '10', defaultWager: '3', standardUnit}; //Default values

class App extends React.Component {
  constructor(props) { //Class App constructor
    super(props);
    this.state = {view: 'ConnectAccount', ...defaults}; //Setting view and rendering default values
  }
  async componentDidMount() {
    const acc = await reach.getDefaultAccount();    //Choosing default account
    const balAtomic = await reach.balanceOf(acc);   //Asking account for a balance
    const bal = reach.formatCurrency(balAtomic, 4);
    this.setState({acc, bal});  
    if (await reach.canFundFromFaucet()) {
      this.setState({view: 'FundAccount'}); 
    } else {
      this.setState({view: 'DeployerOrAttacher'});
    }
  }
  async fundAccount(fundAmount) {     //If funding account
    await reach.fundFromFaucet(this.state.acc, reach.parseCurrency(fundAmount));
    this.setState({view: 'DeployerOrAttacher'});
  }
  async skipFundAccount() { this.setState({view: 'DeployerOrAttacher'}); }    //If not funding account
  selectAttacher() { this.setState({view: 'Wrapper', ContentView: Attacher}); } //If Attacher is chosen, view that will show
  selectDeployer() { this.setState({view: 'Wrapper', ContentView: Deployer}); } //If Deployer is chosen, view that will show
  render() { return renderView(this, AppViews); } //Rendering App section
}

class Player extends React.Component {  //Class Player
  random() { return reach.hasRandom.random(); } //Random function
  async getHand() { // Fun([], UInt) - no arguments and returns UInt
    const hand = await new Promise(resolveHandP => {
      this.setState({view: 'GetHand', playable: true, resolveHandP}); //Choosing what they will show
    });
    this.setState({view: 'WaitingForResults', hand}); //Showing to the player that we are waiting for result
    return handToInt[hand]; //Sending result to backend as Int
  }
  seeOutcome(i) { this.setState({view: 'Done', outcome: intToOutcome[i]}); } //Defining seeOutcome func for displaying results
  informTimeout() { this.setState({view: 'Timeout'}); } //Timeout
  playHand(hand) { this.state.resolveHandP(hand); } 
}

class Deployer extends Player { //Making class Deployer which extends class Player (This is Alice)
  constructor(props) { //Constructor
    super(props);
    this.state = {view: 'SetWager'}; //Asking for Alice to put wager
  }
  setWager(wager) { this.setState({view: 'Deploy', wager}); }
  async deploy() { //Deploying
    const ctc = this.props.acc.contract(backend);
    this.setState({view: 'Deploying', ctc}); //View we want to display (Deploying)
    this.wager = reach.parseCurrency(this.state.wager); // UInt
    this.deadline = {ETH: 10, ALGO: 100, CFX: 1000}[reach.connector]; // Deadline that Alice gave adapted for different networks 
    backend.Alice(ctc, this);
    const ctcInfoStr = JSON.stringify(await ctc.getInfo(), null, 2); //Taking contract info
    this.setState({view: 'WaitingForAttacher', ctcInfoStr}); //Setting state WaitingForAttacher
  }
  render() { return renderView(this, DeployerViews); } //Render of this view, for Alice
}
class Attacher extends Player { //Making class Attacher, which extends class Player (This is Bob)
  constructor(props) {
    super(props);
    this.state = {view: 'Attach'};
  }
  attach(ctcInfoStr) { //This only Bob can do, Attach
    const ctc = this.props.acc.contract(backend, JSON.parse(ctcInfoStr));
    this.setState({view: 'Attaching'}); //Displaying Attaching view
    backend.Bob(ctc, this);
  }
  async acceptWager(wagerAtomic) { // Fun([UInt], Null) - Accepting wager
    const wager = reach.formatCurrency(wagerAtomic, 4);
    return await new Promise(resolveAcceptedP => {  //Making promise and asking if they accept it
      this.setState({view: 'AcceptTerms', wager, resolveAcceptedP}); 
    });
  }
  termsAccepted() {     //What happens when we accept terms
    this.state.resolveAcceptedP(); //Setting state as Accepted
    this.setState({view: 'WaitingForTurn'});
  }
  render() { return renderView(this, AttacherViews); } //Render
}

renderDOM(<App />); //Render of class App