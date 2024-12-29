# CryptoNest: Stablecoin Savings Protocol

CryptoNest is a decentralized savings protocol built on the Stacks blockchain that allows users to deposit stablecoins and earn yield. The protocol features:

- Deposit and withdrawal of stablecoins
- Interest accrual based on deposit time 
- Real-time balance tracking
- Admin controls for interest rate management

## Contract Interface

The main functions available are:
- `deposit`: Deposit stablecoins into the savings vault
- `withdraw`: Withdraw stablecoins plus earned interest
- `get-balance`: Check current balance including accrued interest
- `get-interest-rate`: Get the current interest rate
- `update-interest-rate`: Admin function to update the interest rate

## Getting Started

1. Clone the repository
2. Install dependencies with `clarinet install`
3. Run tests with `clarinet test`

## Security

The contract includes safety checks for:
- Overflow protection on deposits/withdrawals
- Admin-only functions
- Minimum/maximum deposit amounts