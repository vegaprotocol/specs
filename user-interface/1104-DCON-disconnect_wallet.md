## Disconnect wallet via dapp

As a dApp developer I want to be able to disconnect from a wallet So a user can be assured the dApp no longer can talk to the wallet

- I can call client.disconnect_wallet after successfully calling client.connect_wallet (<a name="1104-DCON-001" href="#1104-DCON-001">1104-DCON-001</a>)
- I can call client.disconnect_wallet with no prior connection and get a null response (<a name="1104-DCON-002" href="#1104-DCON-002">1104-DCON-002</a>)
- A dapp can disconnect the current active connection (not it's pre-approved status i.e. the dapp can re-instate the connection without further approval) (<a name="1104-DCON-003" href="#1104-DCON-003">1104-DCON-003</a>)
