# Calibrators (WIP)

# Reference-level explanation

The calibrator calculates and/or sources a set of values (collectively, the calibration) that are used by the quantitative model. There can be multiple calibrators that can be used with each quantitative model, and each calibrator may be able to calibrate more than one quantitative model (i.e. `calibrator <--> model` is a many-to-many relationship). However, the set of values needed will vary between quantitative models, therefore not all calibrators will be applicable to all models.

Calibrators may use a combination of data available from oracles and from sources such at the market framework and order book for the market, and indeed other related markets (e.g. a spot or futures market may be used as a calibration source for options). 

In future: calibrators may also implement more complex logic, such as to create economic incentives for providing accurate and timely calibration, where the correct values cannot be easily calculated by Vega. In general this would be done as an extension to the oracle protocol, i.e. by providing hard coded calibrator logic that interprets oracle inputs from potential calibration providers, and distributes rewards from fees based on some set of rules (NOTE: in this case, the calibration fee will be included in fee calculations).

Eventually, some aspects of calibration logic and rules may be specified in the product definition language, though this is not currently a known requirement.

The quant model and calibrator will need to define and share a data structure/interface for the calibration data they require and produce respectively. This should be specified by the design of the model and calibrator themselves. 