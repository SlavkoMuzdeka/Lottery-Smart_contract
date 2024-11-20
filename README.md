# Raffle Smart Contract

The `Raffle` smart contract implements a decentralized lottery system where participants can enter by paying a specified fee. The winner is selected randomly and fairly using **Chainlink VRF (Verifiable Random Function)**, while **Chainlink Automation** ensures the raffle operates seamlessly without manual intervention.

---

## **Purpose**
The purpose of the `Raffle` smart contract is to provide a decentralized, transparent, and automated lottery system. It ensures:
- A provably fair and unbiased winner selection process.
- Automation of key operations, including winner selection and reward distribution.

---

## **Core Functionalities**

### 1. **Entry into the Raffle**
Participants join the raffle by sending the required entry fee to the contract. Each entry is securely recorded on the blockchain, and the participant's address is added to the list of players.

---

### 2. **Winner Selection with Chainlink VRF**
To ensure fairness and transparency, the smart contract integrates **Chainlink VRF** for generating a random number. This randomness is used to select a winner from the list of participants. Chainlink VRF guarantees that the random number is tamper-proof and verifiable on-chain.

---

### 3. **Automation with Chainlink Automation**
The contract leverages **Chainlink Automation** to handle routine tasks automatically, such as:
- Triggering the winner selection process when certain conditions are met (e.g., a specific time interval or number of participants).
- Resetting the raffle after each round to prepare for new entries.

This eliminates the need for manual interventions and ensures consistent operation of the raffle.

---

### 4. **Reward Distribution**
The total funds collected during the raffle are distributed to the winner after deducting any fees specified in the contract. The payout is automated as part of the winner selection process, ensuring a seamless experience for participants.

---

## **Benefits**
- **Transparency**: All transactions and operations are recorded on the blockchain.
- **Fairness**: The use of Chainlink VRF ensures unbiased and verifiable random winner selection.
- **Automation**: Chainlink Automation handles repetitive tasks, reducing the risk of errors and delays.
- **Decentralization**: The system operates without relying on a central authority.

---

## **Requirements**
- Participants must pay the specified entry fee to join the raffle.
- The contract must be funded with LINK tokens to cover Chainlink VRF and Automation costs.

---

## **Workflow**
1. Participants enter the raffle by sending the entry fee.
2. Once a predefined condition is met (e.g., time elapsed or a set number of participants), Chainlink Automation triggers the winner selection process.
3. Chainlink VRF generates a random number to select the winner.
4. The winner is awarded the prize, and the raffle resets for the next round.
