## Approve transaction request

As a browser wallet user I want to be able to approve a transaction request So that I can verify and complete the action I am trying to make on the vega dapp I'm using

- When I view a transaction request I can choose to approve it (<a name="1105-TRAN-001" href="#1105-TRAN-001">1105-TRAN-001</a>)
- When I approve a transaction the transaction gets signed and the approved status gets fed back to the dapp that requested it (<a name="1105-TRAN-002" href="#1105-TRAN-002">1105-TRAN-002</a>)
- When I approve a transaction after I have approved it we revert to the next transaction if there's a queue OR we revert to the key view (the front / homepage) (<a name="1105-TRAN-003" href="#1105-TRAN-003">1105-TRAN-003</a>)

## Reject transaction request

As a browser wallet user I want to be able to reject a transaction request So that I can prevent a transaction going through that I don't recognise as mine, or have changed my mind on / identified a mistake etc.

- When I view a transaction request I can choose to reject it(<a name="1105-TRAN-004" href="#1105-TRAN-004">1105-TRAN-004</a>)
- When I reject a transaction the transaction does not get signed and the rejected status gets fed back to the dapp that requested it (<a name="1105-TRAN-005" href="#1105-TRAN-005">1105-TRAN-005</a>)
- When I reject a transaction after I have rejected it we revert to the next transaction if there's a queue OR we revert to the key view (start / home page) (<a name="1105-TRAN-006" href="#1105-TRAN-006">1105-TRAN-006</a>)

## View trasaction request (generic)

As a user I want to recognise transactions that are not orders or withdraw / transfer requests with at least the bear minimum information needed to proceed So that I can continue my task (e.g. governing, staking)

- When the dapp requests a transaction with a key we don't know about, we don't see a request in the wallet but instead send an error back to the dapp(<a name="1105-TRAN-007" href="#1105-TRAN-007">1105-TRAN-007</a>)
- When the dapp requests a transaction type / or includes transaction details that we don't recognise, we don't present the transaction request in the wallet but provide an error to the dapp that feeds back that the transaction can not be processed (<a name="1105-TRAN-008" href="#1105-TRAN-008">1105-TRAN-008</a>)
- When the user opens the extension (or it has automatically opened) they can immediately see a transaction request (<a name="1105-TRAN-009" href="#1105-TRAN-009">1105-TRAN-009</a>)
- If the browser extension is closed during a transaction request, the request persists (<a name="1105-TRAN-010" href="#1105-TRAN-010">1105-TRAN-010</a>)
- For transactions that are not orders or withdraw / transfers, there is a standard template with the minimum information required i.e. (<a name="1105-TRAN-011" href="#1105-TRAN-011">1105-TRAN-011</a>)\
  \-- \[ ] Transaction title\
  \-- \[ ] Where it is from e.g. console.vega.xyz with a favicon\
  \-- \[ ] The key you are using to sign with a visual identifier\
  \-- \[ ] When it was received\
  \-- \[ ] Raw JSON details
- I can copy the raw json to my clipboard (<a name="1105-TRAN-012" href="#1105-TRAN-012">1105-TRAN-012</a>)
