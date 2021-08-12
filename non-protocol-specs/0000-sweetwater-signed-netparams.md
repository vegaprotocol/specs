# Network Parameters Signed for Sweetwater

There are certain parameters within Vega that influence the behaviour of the system and are changeable by on-chain [governance](./0028-governance.md). They are initialised to initial values during network launch. For more info see [network paramters](../protocol/0054-network-parameters.md)

On [Sweetwater Release](./milestones/2.5-Sweetwater.md) Vega Team wishes to control how certain parameters are initialised while letting validators change others as they see fit. 
As the process of decentalisation progresses Vega Team the number of such parameters will be reduced.

## Signing

The Vega binary will include a public key that Vega team controls. 
The configuration of the network parameters defined here will be signed and verified as part of the Vega network initialisation for Sweetwater. 

## Parameters to be signed 

The values to be specified as a PR against ??? repo. 

| Name                                                     | Comment                                                            |
|----------------------------------------------------------|:------------------------------------------------------------------:|
| `???? where is governance and staking token set ????`    | We need to lock that so that Vega token has utility.               |
|`blockchains.ethereumConfig`                              | Sets collateral and staking bridge adderesses.                     | 
|`governance.proposal.asset.minEnact`                      | Can prevent asset creation before certain date.                    |
|`governance.proposal.market.minEnact`                     | Can prevent market creation before certain date.                   | 
|`network.checkpoint.chainEndOfLifeDate`                   | Can enforce code upgrade by setting this not too far ahead.        |



