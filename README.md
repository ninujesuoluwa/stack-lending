# StackLending: Decentralized Credit Protocol

**StackLending** is a decentralized, trustless lending protocol built on the [Stacks blockchain](https://www.stacks.co/) that brings **credit scoring** to DeFi. By tracking users’ on-chain borrowing and repayment behavior, StackLending enables **dynamic, credit-based lending** with transparent terms, automated loan management, and capital efficiency for reliable borrowers.

## Features

* **On-Chain Credit Scores**
  Users build a credit score by borrowing and repaying loans. Higher scores reduce collateral requirements and borrowing costs.

* **Dynamic Collateral Requirements**
  Required collateral is calculated based on the borrower's creditworthiness, encouraging responsible borrowing.

* **Risk-Based Interest Rates**
  Interest rates are adjusted according to the borrower's credit score, rewarding good repayment history.

* **Automated Settlements & Default Handling**
  Loans are tracked and managed on-chain with support for repayments, settlements, and default marking.

## How It Works

### Credit Scoring System

* **Initial Score**: Users start with a minimum score (e.g., 50).
* **Score Growth**: Successful repayments increase the score, unlocking better terms.
* **Defaults**: Failing to repay on time decreases the score.

### Borrowing a Loan

1. Users request a loan by specifying amount, collateral, and duration.
2. Required collateral is calculated based on their credit score.
3. Once provided, the loan amount is transferred to the user.
4. Loans must be repaid before the due block height with interest.

### Repayment

* Loans can be repaid partially or fully before the due date.
* Upon full repayment:

  * The user’s credit score is updated.
  * Collateral is returned.
  * The loan is marked as inactive.

### Defaulting

* If a loan is overdue, the **contract owner** can mark it as defaulted.
* Defaulting negatively impacts the borrower's credit score and forfeits the collateral.

## Smart Contract Structure

### Core Components

* **UserScores**: Stores credit scores and loan history.
* **Loans**: Tracks loan details such as amount, due date, interest rate, etc.
* **UserLoans**: Keeps track of active loans per user.

### Functions

#### Credit Score Management

* `initialize-score`: Registers a new user with a base credit score.

#### Loan Lifecycle

* `request-loan`: Request a loan based on your credit score and provide collateral.
* `repay-loan`: Repay the loan partially or fully.
* `mark-loan-defaulted`: Admin function to mark overdue loans as defaulted.

#### View Functions

* `get-user-score`: View a user’s current credit score and history.
* `get-loan`: Retrieve loan details by ID.
* `get-user-active-loans`: List of user's active loans.

## Error Codes

| Code | Error                      | Description                                     |
| ---- | -------------------------- | ----------------------------------------------- |
| u1   | `ERR-UNAUTHORIZED`         | Unauthorized access or action                   |
| u2   | `ERR-INSUFFICIENT-BALANCE` | Collateral below required threshold             |
| u3   | `ERR-INVALID-AMOUNT`       | Loan or repayment amount is invalid             |
| u4   | `ERR-LOAN-NOT-FOUND`       | Loan ID does not exist                          |
| u5   | `ERR-LOAN-DEFAULTED`       | Loan has already defaulted                      |
| u6   | `ERR-INSUFFICIENT-SCORE`   | User's score is below loan eligibility          |
| u7   | `ERR-ACTIVE-LOAN`          | User has too many active loans                  |
| u8   | `ERR-NOT-DUE`              | Loan is not yet eligible to be marked defaulted |
| u9   | `ERR-INVALID-DURATION`     | Invalid loan duration                           |
| u10  | `ERR-INVALID-LOAN-ID`      | Loan ID is not valid                            |

## Technical Highlights

* **Stacks Smart Contract Language**: Built using Clarity, a decidable and predictable smart contract language for Stacks.
* **No Oracles Needed**: Credit scoring and interest calculation are fully on-chain.
* **Security-First Design**: Loans and repayments are protected with validation logic and strict access control.

## Getting Started

To deploy and interact with StackLending:

1. Install the Stacks CLI and set up your development environment.
2. Deploy the smart contract to a local or testnet instance.
3. Use `initialize-score` to register a user.
4. Call `request-loan` with amount, collateral, and duration.
5. Use `repay-loan` to repay and build your credit.
6. Monitor and manage loans with `get-loan` and `get-user-score`.

## Future Improvements

* **Decentralized Governance**: Shift contract ownership and default management to a DAO.
* **Off-chain Credit Integrations**: Support importing real-world credit scores.
* **NFT Collateral Support**: Enable collateralization with digital assets.
* **Multi-token Lending Pools**: Extend beyond STX for other token types.

## Community & Contribution

Want to contribute? We welcome feedback and contributions!

* Submit issues and pull requests
* Join the Stacks developer community
* Help test the protocol on testnet

**StackLending: Redefining DeFi lending with trustless on-chain credit.**
