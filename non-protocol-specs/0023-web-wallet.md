# Web Wallet

This file describes the requirements for web based wallet infrastrcuture, including an entirely in-browser wallet library and UI, and a library to standardise conecting to Vega wallets of any type.


## In-browser wallet

- User can create an in-browser wallet with new randomly generated keys
- User can backup an in-browser wallet by taking note of the seed phrase (TBC if this should be possible after initialisation or only during initialisation)
- User can restore an in-browser wallet from a seed phrase
- User can use the in browser wallet to interact with the Vega network via dapps such as Console and the Token Frontend (as well as 3rd party dapps built using the same library, see below)
- Web wallet should be able to be used with any dapp which wants to offer access to the Vega network
- Web Wallet data should be secured at rest, i.e. stored in an encrypted form in localstorage or similar, with the password held only by the user
- Web Wallet should persist wallet data between sessions
- The in-browser wallet should give the same outputs as the go wallet for the same seed phrase and input data
- Web wallet should support HD (hierarchical deterministic) wallets
- Web wallet should support multiple wallets (separate seed phrases) and multiple keys within a wallet


## Javascript library

- There should be a JS library that exposes a standardised interface for interacting with the Vega network.
- A dapp that wishes to interact with Vega should be able to use this library and allow users to use other the web wallet or a command line wallet running the wallet service
- Define a standardised URL format for transactions to prefill key fields
- Should be designed with future hardware wallet support in mind