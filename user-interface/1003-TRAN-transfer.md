# Transfer


## Transfer Window
- **Must** be able to open transfer window through transfer button under key ([0003-TRAN-001](#0003-TRAN-001))

- **Must** be able to close the window with the x ([0003-TRAN-002](#0003-TRAN-002))

- **Must** display a message showing obfuscated key that funds will be transferred from ([0003-TRAN-003](#0003-TRAN-003))

- **Must** each field has their label. Vega key, Asset, Amount ([0003-TRAN-004](#0003-TRAN-004))


## Vega Key

- **Must** 
if the user has multiple keys they must be able to swap between dropdown and manual entry ([0003-TRAN-005](#0003-TRAN-005))

- **Must** 
if the user has multiple keys they must be able to select from their list of keys([0003-TRAN-006](#0003-TRAN-006))

## Asset
- **Must** display a drop down with all assets in the portfolio ([0003-TRAN-007](#0003-TRAN-007))

- **Must** the holdings of each asset is displayed ([0003-TRAN-008](#0003-TRAN-008))

- **Must** i can select any available assets and selected asset is displayed ([0003-TRAN-009](#0003-TRAN-009))

- **Must** selected asset shortname is displayed in the amount field ([0003-TRAN-010](#0003-TRAN-010))


## Validation
- **Must** cannot choose amount over current collateral. Message is displayed ([0003-TRAN-011](#0003-TRAN-011))

- **Must** display "required" message on each field if left blank when clicking button "Confirm Transfer" ([0003-TRAN-012](#0003-TRAN-012))

- **Must** display "Invalid vega key" message on Vega Key field if entered key doesn't pass validation([0003-TRAN-013](#0003-TRAN-013))

- **Must** "Value below minimum" message is shown if amount is lower than minimum([0003-TRAN-014](#0003-TRAN-014))


## Transfer
- **Must** can select include transfer fee ([0003-TRAN-015](#0003-TRAN-015))

- **Must** display tooltip for "Include transfer fee" when hovered over.([0003-TRAN-016](#0003-TRAN-016))

- **Must** display tooltip for "Transfer fee when hovered over.([0003-TRAN-017](#0003-TRAN-017))

- **Must** display tooltip for "Amount to be transferred" when hovered over.([0003-TRAN-018](#0003-TRAN-018))

- **Must** display tooltip for "Total amount (with fee)" when hovered over.([0003-TRAN-019](#0003-TRAN-019))

- **Must** amount to be transferred and transfer fee update correctly when include transfer fee is selected ([0003-TRAN-020](#0003-TRAN-020))

- **Must** total amount with fee is correct with and without "Include transfer fee" selected ([0003-TRAN-021](#0003-TRAN-021))

- **Must** i cannot select include transfer fee unless amount is entered ([0003-TRAN-022](#0003-TRAN-022))

- **Must** With all fields entered correctly, clicking "confirm transfer" button will start transaction([0003-TRAN-023](#0003-TRAN-023))