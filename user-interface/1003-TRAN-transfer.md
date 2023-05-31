# Transfer


## Transfer Window
- **Must** be able to open transfer window through transfer button under key, account history page and collateral options ([1003-TRAN-001](#1003-TRAN-001))

- **Must** be able to close the window with the x ([1003-TRAN-002](#1003-TRAN-002))

- **Must** display a message showing obfuscated key that funds will be transferred from ([1003-TRAN-003](#1003-TRAN-003))

- **Must** each field has their label. Vega key, Asset, Amount ([1003-TRAN-004](#1003-TRAN-004))


## Vega Key

- **Must** 
if the user has multiple keys they must be able to swap between dropdown and manual entry ([1003-TRAN-005](#1003-TRAN-005))

- **Must** 
if the user has multiple keys they must be able to select from their list of keys([1003-TRAN-006](#1003-TRAN-006))

## Asset
- **Must** display a drop down with all assets in the portfolio ([1003-TRAN-007](#1003-TRAN-007))

- **Must** the holdings of each asset is displayed ([1003-TRAN-008](#1003-TRAN-008))

- **Must** i can select any available assets and selected asset is displayed ([1003-TRAN-009](#1003-TRAN-009))

- **Must** selected asset shortname is displayed in the amount field ([1003-TRAN-010](#1003-TRAN-010))


## Validation
- **Must** cannot choose amount over current collateral. Message is displayed ([1003-TRAN-011](#1003-TRAN-011))

- **Must** display "required" message on each field if left blank when clicking button "Confirm Transfer" ([1003-TRAN-012](#1003-TRAN-012))

- **Must** display "Invalid vega key" message on Vega Key field if entered key doesn't pass validation([1003-TRAN-013](#1003-TRAN-013))

- **Must** "Value below minimum" message is shown if amount is lower than minimum([1003-TRAN-014](#1003-TRAN-014))


## Transfer
- **Must** can select include transfer fee ([1003-TRAN-015](#1003-TRAN-015))

- **Must** display tooltip for "Include transfer fee" when hovered over.([1003-TRAN-016](#1003-TRAN-016))

- **Must** display tooltip for "Transfer fee when hovered over.([1003-TRAN-017](#1003-TRAN-017))

- **Must** display tooltip for "Amount to be transferred" when hovered over.([1003-TRAN-018](#1003-TRAN-018))

- **Must** display tooltip for "Total amount (with fee)" when hovered over.([1003-TRAN-019](#1003-TRAN-019))

- **Must** amount to be transferred and transfer fee update correctly when include transfer fee is selected ([1003-TRAN-020](#1003-TRAN-020))

- **Must** total amount with fee is correct with and without "Include transfer fee" selected ([1003-TRAN-021](#1003-TRAN-021))

- **Must** i cannot select include transfer fee unless amount is entered ([1003-TRAN-022](#1003-TRAN-022))

- **Must** With all fields entered correctly, clicking "confirm transfer" button will start transaction([1003-TRAN-023](#1003-TRAN-023))