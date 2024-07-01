Certainly! I'll adjust the README to reflect that the project is being developed for Berachain. Here's an updated version:

```markdown
# Memecoin Launcher Smart Contracts for Berachain

This project contains the smart contracts for a decentralized memecoin launcher platform built using Foundry and designed for deployment on Berachain. Users can create, buy, and sell memecoins using a bonding curve mechanism, leveraging Berachain's unique features.

## Contracts

### MemecoinFactory

The main contract responsible for creating new memecoin instances on Berachain.

Key functions:
- `createMemecoin(string name, string symbol, uint256 initialSupply, uint256 targetMarketCap)`
- `getDeployedMemecoins()`

### Memecoin

Individual ERC20 token contract for each memecoin, compatible with Berachain's EVM.

Key features:
- Implements ERC20 standard
- Uses bonding curve for price calculation
- Manages its own launch process
- Integrates with Berachain's native features (e.g., BGT interactions if applicable)

Key functions:
- `buy(uint256 amount)`
- `sell(uint256 amount)`
- `currentPrice()`

### BondingCurve (Library)

Implements the bonding curve logic used by Memecoin contracts.

Key functions:
- `calculatePrice(uint256 supply, uint256 amount)`
- `calculateTokenAmount(uint256 supply, uint256 bgtAmount)`

## Setup

1. Install Foundry:
   ```
curl -L https://foundry.paradigm.xyz | bash
foundryup
   ```

2. Clone the repository:
   ```
git clone <your-repo-url>
cd <your-repo-name>
   ```

3. Install dependencies:
   ```
forge install
   ```

4. Build the project:
   ```
forge build
   ```

## Testing

Run the test suite:

```
forge test
```

For more verbose output:

```
forge test -vv
```
