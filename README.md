# TryTrade - Decentralized Fantasy Trading Platform

## Overview

TryTrade is a decentralized application (dApp) that enables users to participate in competitive fantasy trading leagues on the Ethereum blockchain. The platform combines the excitement of cryptocurrency trading with the competitive nature of fantasy sports, allowing users to test their trading strategies without financial risk while competing for real ETH prizes.

## Core Features

### League Management
- **League Creation**: Users can create custom trading leagues with configurable parameters
  - Start and end dates
  - Maximum player capacity
  - Entry fee requirements
- **League Discovery**: Browse and join existing leagues through an intuitive interface
- **Fixed Timeframe**: All leagues operate within predetermined start and end dates

### Staking and Prize Distribution
- **Entry Staking**: Participants stake ETH as entry fees when joining leagues
- **Prize Pool**: All staked ETH is automatically pooled for distribution to winners
- **Winner Rewards**: Prize distribution follows a structured payout system:
  - 1st Place: 50% of total prize pool
  - 2nd Place: 30% of total prize pool
  - 3rd Place: 20% of total prize pool

### Fantasy Trading System
- **Virtual Portfolio**: Each participant receives 100 virtual units for portfolio allocation
- **Token Selection**: Allocate units across various cryptocurrencies (ETH, BTC, and other supported tokens)
- **Risk-Free Trading**: No actual cryptocurrency purchases occur; purely simulation-based
- **Portfolio Management**: Real-time tracking of allocation percentages and amounts

### Performance Tracking
- **Real-Time Price Integration**: Platform continuously monitors actual cryptocurrency price movements
- **Performance Calculation**: Automated computation of portfolio returns based on real market data
- **Live Standings**: Dynamic leaderboard updates reflecting current performance rankings
- **Winner Determination**: Final rankings determined by total portfolio return percentage

## Technical Architecture

### Blockchain Integration
- Built on Ethereum using Scaffold-ETH 2 framework
- Smart contract-based league management and prize distribution
- Decentralized and trustless operation

### User Experience
- Intuitive web interface for league management and portfolio tracking
- Real-time updates and notifications
- Mobile-responsive design

## Security and Transparency
- All transactions and prize distributions executed through smart contracts
- Immutable league rules and parameters
- Transparent prize pool management
- Auditable performance tracking

## Future Enhancements
- Advanced scoring algorithms for enhanced competition mechanics
- Additional token support and trading pairs
- Social features and community engagement tools
- Advanced analytics and performance insights

---

*TryTrade represents the convergence of decentralized finance (DeFi) and competitive gaming, offering users a unique platform to showcase their trading acumen while competing for substantial rewards.*


## Requirements

Before you begin, you need to install the following tools:

- [Node (>= v20.18.3)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

## Quickstart

To get started with Scaffold-ETH 2, follow the steps below:

1. Install dependencies if it was skipped in CLI:

```
cd my-dapp-example
yarn install
```

2. Run a local network in the first terminal:

```
yarn chain
```

This command starts a local Ethereum network using Foundry. The network runs on your local machine and can be used for testing and development. You can customize the network configuration in `packages/foundry/foundry.toml`.

3. On a second terminal, deploy the test contract:

```
yarn deploy
```

This command deploys a test smart contract to the local network. The contract is located in `packages/foundry/contracts` and can be modified to suit your needs. The `yarn deploy` command uses the deploy script located in `packages/foundry/script` to deploy the contract to the network. You can also customize the deploy script.

4. On a third terminal, start your NextJS app:

```
yarn start
```

Visit your app on: `http://localhost:3000`. You can interact with your smart contract using the `Debug Contracts` page. You can tweak the app config in `packages/nextjs/scaffold.config.ts`.

Run smart contract test with `yarn foundry:test`

- Edit your smart contracts in `packages/foundry/contracts`
- Edit your frontend homepage at `packages/nextjs/app/page.tsx`. For guidance on [routing](https://nextjs.org/docs/app/building-your-application/routing/defining-routes) and configuring [pages/layouts](https://nextjs.org/docs/app/building-your-application/routing/pages-and-layouts) checkout the Next.js documentation.
- Edit your deployment scripts in `packages/foundry/script`
