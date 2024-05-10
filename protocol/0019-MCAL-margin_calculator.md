# Margin Calculator

## Acceptance Criteria (Cross margin)

- Get four margin levels for one or more parties (<a name="0019-MCAL-001" href="#0019-MCAL-001">0019-MCAL-001</a>)

- Margin levels are correctly calculated against riskiest long and short positions (<a name="0019-MCAL-002" href="#0019-MCAL-002">0019-MCAL-002</a>)

- Zero position and zero orders results in all zero margin levels (<a name="0019-MCAL-003" href="#0019-MCAL-003">0019-MCAL-003</a>)

- A feature test that checks margin in case market PDP > 0 is created and passes. (<a name="0019-MCAL-008" href="#0019-MCAL-008">0019-MCAL-008</a>)

- For each market and each party which has either orders or positions on the market, the API provides the 4 margin levels.  (<a name="0019-MCAL-009" href="#0019-MCAL-009">0019-MCAL-009</a>)

- A feature test that checks margin in case market PDP < 0 is created and passes. (<a name="0019-MCAL-010" href="#0019-MCAL-010">0019-MCAL-010</a>)

- If a party is short `1` unit and the mark price is `15 900` and `market.linearSlippageFactor = 0.25` and `RF short = 0.1` and order book is

    ```book
    buy 1 @ 15 000
    buy 10 @ 14 900
    and
    sell 1 @ 100 000
    sell 10 @ 100 100
    ```

    then the maintenance margin for the party is `15900 x 0.25 x 1 + 0.1 x 1 x 15900 = 5565`. (<a name="0019-MCAL-210" href="#0019-MCAL-210">0019-MCAL-210</a>)

- In the same situation as above, if `market.linearSlippageFactor = 100`, (i.e. 10 000%) instead, then the margin for the party is `15900 x 100 x 1 + 0.1 x 1 x 15900 = 85690`. (<a name="0019-MCAL-211" href="#0019-MCAL-211">0019-MCAL-211</a>)

- If the `market.linearSlippageFactor` is updated via governance then it will be used at the next margin evaluation i.e. at the first mark price update following the parameter update. (<a name="0019-MCAL-013" href="#0019-MCAL-013">0019-MCAL-013</a>)

- For a perpetual future market, the maintenance margin is equal to the maintenance margin on an equivalent dated future market, plus a component related to the expected upcoming margin funding payment. Specifically:
  - If a party is long `1` unit and the mark price is `15 900` and `market.linearSlippageFactor = 0.25` and `RF long = 0.1` and order book is

    ```book
    buy 1 @ 15 000
    buy 10 @ 14 900
    and
    sell 1 @ 100 000
    sell 10 @ 100 100
    ```

    then the dated future maintenance margin component for the party is `15900 x 0.25 x 1 + 0.1 x 1 x 15900 = 5565`. The current accrued funding payment for the perpetual component is calculated using

    ```book
    delta_t = funding_period_end - max(funding_period_start, internal_data_points[0].t)
    funding_payment = f_twap - s_twap + min(clamp_upper_bound*s_twap,max(clamp_lower_bound*s_twap, (1 + delta_t * interest_rate)*s_twap-f_twap))
    ```

    Where `f_twap` represents the internal mark price TWAP and `s_twap` represents the TWAP from the external oracle feed. When clamp bounds are large we use:

    ```book
    funding_payment = f_twap - s_twap + (1 + delta_t * interest_rate)*s_twap-f_twap
                    = s_twap * delta_t * interest_rate
    ```

    - If `s_twap = 1600`, `f_twap = 1590` `delta_t = 0.002` and `interest_rate = 0.05` then `funding_payment = 1600 * 0.002 * 0.05 = 0.16`.
      - Thus, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 556.5 + 0.5 * 0.16 * 1 = 556.58` (<a name="0019-MCAL-026" href="#0019-MCAL-026">0019-MCAL-026</a>)

    - If instead
      - `clamp_upper_bound*s_twap < max(clamp_lower_bound*s_twap, (1 + delta_t * interest_rate)*s_twap-f_twap)`
      - `funding payment = f_twap - s_twap + clamp_upper_bound*s_twap = f_twap + s_twap * (clamp_upper_bound - 1)`.
      - Then with `s_twap = 1600`, `clamp_upper_bound = 0.05` and `f_twap = 1500`, `funding_payment = 1500 + 1600 * (0.05 - 1) = -20`
      - Thus, with `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 525 + 0.5 * max(0, -20 * 1) = 525` (<a name="0019-MCAL-027" href="#0019-MCAL-027">0019-MCAL-027</a>)
      - However is position is instead `-1`, with the same margin requirement, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 525 + 0.5 * max(0, -20 * -1 = 535)`(<a name="0019-MCAL-030" href="#0019-MCAL-030">0019-MCAL-030</a>)

    - If instead
      - `clamp_upper_bound*s_twap > clamp_lower_bound*s_twap > (1 + delta_t * interest_rate)*s_twap-f_twap)`
      - `funding payment = f_twap - s_twap + clamp_lower_bound*s_twap = f_twap + s_twap * (clamp_lower_bound - 1)`.
      - Then with `s_twap = 1600`, `clamp_lower_bound = -0.05` and `f_twap = 1700`, `funding_payment = 1700 + 1600 * (-0.05 - 1) = 20`
      - Thus, with `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 595 + 0.5 * max(0, 20 * 1) = 605` (<a name="0019-MCAL-028" href="#0019-MCAL-028">0019-MCAL-028</a>)
      - However is position is instead `-1`, with the same margin requirement, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 595 + 0.5 * max(0, 20 * -1) = 595`(<a name="0019-MCAL-029" href="#0019-MCAL-029">0019-MCAL-029</a>)

    - When placing an order to buy `10` at a price of `3` on a market in an opening auction with an indicative uncrossing price of `100` and a long risk factor of `0.1`, the resulting margin is `100` (<a name="0019-MCAL-234" href="#0019-MCAL-234">0019-MCAL-234</a>)

## Acceptance Criteria (Isolated-margin)

**When party has a newly created short position:**

- If a party has a newly created short position of `1` and the mark price is `15 900` and `market.linearSlippageFactor = 0.25`, `RF short = 0.1` and `Initial margin factor = 1.5` and order book is

    ```book
    buy 1 @ 15 000
    buy 10 @ 14 900
    and
    sell 1 @ 100 000
    sell 10 @ 100 100
    ```

- When switching to isolated-margin mode and the `margin factor short = 0.11`, the maintenance margin should be updated to `average entry price x current position x new margin factor = 57500 x 1 x 0.11 = 6325`, the switching will be rejected with message "required position margin must be greater than initial margin". (<a name="0019-MCAL-032" href="#0019-MCAL-032">0019-MCAL-032</a>)

- When switching to isolated-margin mode and the `margin factor short = 0.9`, the maintenance margin should be updated to `average entry price x current position x new margin factor = 15900 x 1 x 0.9 = 14310`, and margin account should be updated to `14310`. (<a name="0019-MCAL-033" href="#0019-MCAL-033">0019-MCAL-033</a>)

- When decreasing the `margin factor short` from `0.9` to `0.7`, the maintenance margin should be updated to `average entry price x current position x new margin factor = 15900 x 1 x 0.7 = 11130`, and margin account should be updated to `11130`. (<a name="0019-MCAL-031" href="#0019-MCAL-031">0019-MCAL-031</a>)

- When increasing the `margin factor short` from `0.7` to `0.9`, the maintenance margin should be updated to `average entry price x current position x new margin factor = 15900 x 1 x 0.9 = 14310`, and margin account should be updated to `14310`. (<a name="0019-MCAL-059" href="#0019-MCAL-059">0019-MCAL-059</a>)

- Switching to isolated margin mode will be rejected if the party does not have enough asset in the general account to top up the margin account to the new required level (<a name="0019-MCAL-066" href="#0019-MCAL-066">0019-MCAL-066</a>)

**When party has a position and an order which does not offset the position:**

- When the party places a new short order of `10` with price `15910` which does not offset the existing position, and the market is in continuous trading.
There should be an additional amount `limit price x size x margin factor = 15910 x 10 x 0.9 = 143190` transferred into "order margin" account if the party has enough asset in the general account(<a name="0019-MCAL-034" href="#0019-MCAL-034">0019-MCAL-034</a>)

- The order will be rejected if the party does not have enough asset in the general account (<a name="0019-MCAL-035" href="#0019-MCAL-035">0019-MCAL-035</a>)

- The party amends the order size to `5`, and the amount `limit price x size x margin factor = 15912 x 5 x 0.9 = 71604` will be transferred from "order margin" account into general account (<a name="0019-MCAL-060" href="#0019-MCAL-060">0019-MCAL-060</a>)

- Another trader places a buy order of `3` with price `15912`, party's position changes from `1` to `4`, party's margin account should have additional `15912 x 3 x 0.9 =42962` transferred from general account and order margin should be reduced to `15912x 2 x 0.9 = 28642`since party's order size has been reduced from `5` to `2` after the trade  (<a name="0019-MCAL-061" href="#0019-MCAL-061">0019-MCAL-061</a>)

- Switch margin mode from isolated margin to cross margin when party holds position only, the margin account should be updated to initial margin level in cross margin mode(<a name="0019-MCAL-065" href="#0019-MCAL-065">0019-MCAL-065</a>)

- Switch from cross margin to isolated margin mode, both margin account and order margin should be updated (<a name="0019-MCAL-064" href="#0019-MCAL-064">0019-MCAL-064</a>)

- When the party has no orders, their order margin account should be `0` (<a name="0019-MCAL-062" href="#0019-MCAL-062">0019-MCAL-062</a>)

- When the mark price moves, the margin account should be updated while order margin account should not (<a name="0019-MCAL-067" href="#0019-MCAL-067">0019-MCAL-067</a>)

- Amend the order (change size) so that new side margin + margin account balance < maintenance margin, the remaining should be stopped (<a name="0019-MCAL-068" href="#0019-MCAL-068">0019-MCAL-068</a>)

**When a party has a position and an order which offsets the position:**

- When the party places a new long order of `2` with price `15912` which offsets the existing position, and the market is in continuous trading. The margin account should not change as no additional margin is required (<a name="0019-MCAL-038" href="#0019-MCAL-038">0019-MCAL-038</a>)

- When the party switches to cross margin mode, the margin accounts will not be updated until the next MTM (<a name="0019-MCAL-036" href="#0019-MCAL-036">0019-MCAL-036</a>)

- The order will be rejected if the party does not have enough asset in the general account (<a name="0019-MCAL-037" href="#0019-MCAL-037">0019-MCAL-037</a>)

- When the party place a new long order of `10` with price `145000` and the party has existing short position of `3`, and the market is in continuous trading. The margin account should have additional amount `limit price * size * margin factor = 145000 x (10-3) x 0.9 = 913500` added if the party has enough asset in the general account(<a name="0019-MCAL-039" href="#0019-MCAL-039">0019-MCAL-039</a>)

- When increasing the `margin factor` and the party does not have enough asset in the general account to cover the new maintenance margin, then the new margin factor will be rejected (<a name="0019-MCAL-040" href="#0019-MCAL-040">0019-MCAL-040</a>)

**Amending order:**

- When the party submit a pegged order, it should be rejected(<a name="0019-MCAL-049" href="#0019-MCAL-049">0019-MCAL-049</a>)

- When the party submit a iceberg pegged order, it should be rejected(<a name="0019-MCAL-052" href="#0019-MCAL-052">0019-MCAL-052</a>)

- When the party has pegged orders and switches from cross margin mode to isolated margin mode, all the pegged orders will be cancelled. (<a name="0019-MCAL-050" href="#0019-MCAL-050">0019-MCAL-050</a>)

- When the party has iceberg pegged orders and switches from cross margin mode to isolated margin mode, all the iceberg pegged orders will be cancelled. (<a name="0019-MCAL-051" href="#0019-MCAL-051">0019-MCAL-051</a>)

- A party with multiple types of orders in cross margin mode switches to isolated margin only their pegged orders are cancelled. (<a name="0019-MCAL-057" href="#0019-MCAL-057">0019-MCAL-057</a>)

- A market in continuous trading and a party with a partially filled pegged order in cross margin mode switches to isolated margin mode the unfilled portion of the pegged order is cancelled (<a name="0019-MCAL-075" href="#0019-MCAL-075">0019-MCAL-075</a>)

- A market in continuous trading and a party with a partially filled iceberg pegged order in cross margin mode switches to isolated margin mode the unfilled portion of the pegged order is cancelled (<a name="0019-MCAL-078" href="#0019-MCAL-078">0019-MCAL-078</a>)

- A market in auction trading and a party with a partially filled pegged order in cross margin mode switches to isolated margin mode the unfilled portion of the pegged order is cancelled (<a name="0019-MCAL-147" href="#0019-MCAL-147">0019-MCAL-147</a>)

- A market in auction trading and a party with a partially filled iceberg pegged order in cross margin mode switches to isolated margin mode the unfilled portion of the pegged order is cancelled (<a name="0019-MCAL-148" href="#0019-MCAL-148">0019-MCAL-148</a>)

- A party with a parked pegged order switches from cross margin mode to isolated margin mode, the parked pegged order is cancelled (<a name="0019-MCAL-149" href="#0019-MCAL-149">0019-MCAL-149</a>)

- A party with a parked iceberg pegged order switches from cross margin mode to isolated margin mode, the parked iceberg pegged order is cancelled (<a name="0019-MCAL-144" href="#0019-MCAL-144">0019-MCAL-144</a>)

- A market in auction and party with a partially filled pegged order switches from cross margin mode to isolated margin mode the unfilled portion of the pegged order is cancelled (<a name="0019-MCAL-145" href="#0019-MCAL-145">0019-MCAL-145</a>)

- A market in an auction and party with a partially filled iceberg pegged order switches from cross margin mode to isolated margin mode the unfilled portion of the iceberg pegged order is cancelled (<a name="0019-MCAL-146" href="#0019-MCAL-146">0019-MCAL-146</a>)

- When a party holds only orders, increases the orders price, the orders will not uncross (<a name="0019-MCAL-160" href="#0019-MCAL-160">0019-MCAL-160</a>)

- When a party holds orders and positions, and increases the orders price, the orders will not uncross (<a name="0019-MCAL-161" href="#0019-MCAL-161">0019-MCAL-161</a>)

- When a party holds only orders, increases the orders size, the orders will not uncross (<a name="0019-MCAL-162" href="#0019-MCAL-162">0019-MCAL-162</a>)

- When a party holds orders and positions, increases the order size, the orders will not uncross (<a name="0019-MCAL-163" href="#0019-MCAL-163">0019-MCAL-163</a>)

- When a party holds only orders, decreases the orders price, the orders will not uncross (<a name="0019-MCAL-164" href="#0019-MCAL-164">0019-MCAL-164</a>)

- When a party holds orders and positions, and decreases the orders price, the orders will not uncross (<a name="0019-MCAL-165" href="#0019-MCAL-165">0019-MCAL-165</a>)

- When a party holds only orders, decreases the orders size, the orders will not uncross (<a name="0019-MCAL-166" href="#0019-MCAL-166">0019-MCAL-166</a>)

- When a party holds orders and positions, decreases the order size, the orders will not uncross (<a name="0019-MCAL-167" href="#0019-MCAL-167">0019-MCAL-167</a>)

- When a party holds orders and positions, increase the order size, the order will be stopped (because their margin balance will be less than the margin maintenance level) (<a name="0019-MCAL-168" href="#0019-MCAL-168">0019-MCAL-168</a>)

- When a party holds orders and positions, decreases the orders size, the order and order margin will be update (<a name="0019-MCAL-169" href="#0019-MCAL-169">0019-MCAL-169</a>)

- When a party holds orders and positions, decreases the orders price, the order will be fully filled (<a name="0019-MCAL-172" href="#0019-MCAL-172">0019-MCAL-172</a>)

- When a party holds orders and positions, decreases the orders price, the order will be partially filled (<a name="0019-MCAL-173" href="#0019-MCAL-173">0019-MCAL-173</a>)

- When a party holds orders and positions, decreases the orders price, the order will be stopped (because if the orders is fully filled and then their margin balance will be less than the margin maintenance level) (<a name="0019-MCAL-174" href="#0019-MCAL-174">0019-MCAL-174</a>)

- When a party holds orders and positions, decreases the orders price, the order will be stopped (because if the orders is partially filled and then their margin balance will be less than the margin maintenance level) (<a name="0019-MCAL-175" href="#0019-MCAL-175">0019-MCAL-175</a>)

- When a party holds orders and positions, amend the orders price, the order will be partially filled but order margin level will increase, so the rest of the order is cancelled (<a name="0019-MCAL-176" href="#0019-MCAL-176">0019-MCAL-176</a>)

**When a party is distressed:**

- Open positions should be closed in the case of open positions dropping below maintenance margin level, active orders will remain active if closing positions does not lead order margin level to increase.(<a name="0019-MCAL-070" href="#0019-MCAL-070">0019-MCAL-070</a>)

- Open positions should be closed in the case of open positions dropping below maintenance margin level, active orders will be cancelled if closing positions lead order margin level to increase.(<a name="0019-MCAL-071" href="#0019-MCAL-071">0019-MCAL-071</a>)

- When a party (who holds open positions and bond account) gets distressed, open positions will be closed, the bond account will be emptied (<a name="0019-MCAL-072" href="#0019-MCAL-072">0019-MCAL-072</a>)

- When a party (who holds open positions, open orders and bond account) gets distressed, the bond account will be treated as in cross margin mode, however active orders will remain active if closing positions does not lead order margin level to increase. (<a name="0019-MCAL-073" href="#0019-MCAL-073">0019-MCAL-073</a>)

- When a party (who holds open positions, open orders and bond account) gets distressed, the bond account will be emptied, active orders will be cancelled if closing positions lead order margin level to increase. (<a name="0019-MCAL-074" href="#0019-MCAL-074">0019-MCAL-074</a>)

**Switch between margin modes:**

- switch to isolated margin with no position and no order (before the first order ever has been sent) in continuous mode(<a name="0019-MCAL-100" href="#0019-MCAL-100">0019-MCAL-100</a>)

- switch back to cross margin with no position and no order in continuous mode(<a name="0019-MCAL-101" href="#0019-MCAL-101">0019-MCAL-101</a>)

- switch to isolated margin with no position and no order (before the first order ever has been sent) in auction(<a name="0019-MCAL-102" href="#0019-MCAL-102">0019-MCAL-102</a>)

- switch back to cross margin with no position and no order in continuous mode in auction(<a name="0019-MCAL-103" href="#0019-MCAL-103">0019-MCAL-103</a>)

- switch to isolated margin with position and no orders with margin factor such that position margin is < initial should fail in continuous(<a name="0019-MCAL-104" href="#0019-MCAL-104">0019-MCAL-104</a>)

- switch to isolated margin with position and no orders with margin factor such that position margin is < initial should fail in auction(<a name="0019-MCAL-105" href="#0019-MCAL-105">0019-MCAL-105</a>)

- switch to isolated margin without position and with orders with margin factor such that position margin is < initial should fail in continuous(<a name="0019-MCAL-106" href="#0019-MCAL-106">0019-MCAL-106</a>)

- switch to isolated margin without position and with orders with margin factor such that position margin is < initial should fail in auction(<a name="0019-MCAL-107" href="#0019-MCAL-107">0019-MCAL-107</a>)

- switch to isolated margin with position and with orders with margin factor such that position margin is < initial should fail in continuous(<a name="0019-MCAL-108" href="#0019-MCAL-108">0019-MCAL-108</a>)

- switch to isolated margin with position and with orders with margin factor such that position margin is < initial should fail in auction(<a name="0019-MCAL-109" href="#0019-MCAL-109">0019-MCAL-109</a>)

- switch to isolated margin without position and no orders with margin factor such that there is insufficient balance in the general account in continuous mode(<a name="0019-MCAL-110" href="#0019-MCAL-110">0019-MCAL-110</a>)

- switch to isolated margin with position and no orders with margin factor such that there is insufficient balance in the general account in continuous mode(<a name="0019-MCAL-112" href="#0019-MCAL-112">0019-MCAL-112</a>)

- switch to isolated margin with position and no orders with margin factor such that there is insufficient balance in the general account in auction mode(<a name="0019-MCAL-113" href="#0019-MCAL-113">0019-MCAL-113</a>)

- switch to isolated margin with position and with orders with margin factor such that there is insufficient balance in the general account in continuous mode(<a name="0019-MCAL-114" href="#0019-MCAL-114">0019-MCAL-114</a>)

- switch to isolated margin with position and with orders with margin factor such that there is insufficient balance in the general account in auction mode(<a name="0019-MCAL-142" href="#0019-MCAL-142">0019-MCAL-142/a>)
- switch to isolate margin with out of range margin factor(<a name="0019-MCAL-115" href="#0019-MCAL-115">0019-MCAL-115</a>)

- submit update margin mode transaction with no state change (already in cross margin, "change" to cross margin, or already in isolated, submit with same margin factor)(<a name="0019-MCAL-116" href="#0019-MCAL-116">0019-MCAL-116</a>)

- update margin factor when already in isolated mode to the same cases as in switch to isolated failures.(<a name="0019-MCAL-117" href="#0019-MCAL-117">0019-MCAL-117</a>)

- switch to isolated margin without position and no orders successful in auction(<a name="0019-MCAL-119" href="#0019-MCAL-119">0019-MCAL-119</a>)

- switch to isolated margin with position and no orders successful in continuous mode(<a name="0019-MCAL-120" href="#0019-MCAL-120">0019-MCAL-120</a>)

- switch to isolated margin with position and no orders successful in auction(<a name="0019-MCAL-121" href="#0019-MCAL-121">0019-MCAL-121</a>)

- switch to isolated margin without position and with orders successful in continuous mode(<a name="0019-MCAL-122" href="#0019-MCAL-122">0019-MCAL-122</a>)

- switch to isolated margin without position and with orders successful in auction(<a name="0019-MCAL-123" href="#0019-MCAL-123">0019-MCAL-123</a>)

- switch to isolated margin with position and with orders successful in continuous mode(<a name="0019-MCAL-124" href="#0019-MCAL-124">0019-MCAL-124</a>)

- switch to isolated margin with position and with orders successful in auction(<a name="0019-MCAL-125" href="#0019-MCAL-125">0019-MCAL-125</a>)

- increase margin factor in isolated margin without position and no orders successful in continuous mode(<a name="0019-MCAL-126" href="#0019-MCAL-126">0019-MCAL-126</a>)

- increase margin factor in isolated margin without position and no orders successful in auction(<a name="0019-MCAL-127" href="#0019-MCAL-127">0019-MCAL-127</a>)

- increase margin factor in isolated margin with position and no orders successful in continuous mode(<a name="0019-MCAL-128" href="#0019-MCAL-128">0019-MCAL-128</a>)

- increase margin factor in isolated margin with position and no orders successful in auction(<a name="0019-MCAL-129" href="#0019-MCAL-129">0019-MCAL-129</a>)

- increase margin factor in isolated margin without position and with orders successful in continuous mode(<a name="0019-MCAL-130" href="#0019-MCAL-130">0019-MCAL-130</a>)

- increase margin factor in isolated margin without position and with orders successful in auction(<a name="0019-MCAL-131" href="#0019-MCAL-131">0019-MCAL-131</a>)

- increase margin factor in isolated margin with position and with orders successful in continuous mode(<a name="0019-MCAL-132" href="#0019-MCAL-132">0019-MCAL-132</a>)

- increase margin factor in isolated margin with position and with orders successful in auction(<a name="0019-MCAL-133" href="#0019-MCAL-133">0019-MCAL-133</a>)

- In cross margin mode for a market with no price monitoring, a party `short 1`, `mark price = 15 900`, `market.linearSlippageFactor = 0.25`, `RF short = 0.1` and order book is

  ```book
  buy 1 @ 15 000
  buy 10 @ 14 900
  and
  sell 1 @ 100 000
  sell 10 @ 100 100
  ```

  the maintenance margin for the party is `159 00 x 0.25 x 1 + 0.1 x 1 x 159 00 = 5565` for this market the party switches to isolated margin with `margin factor=0.9` then the party will have margin account balance of `average entry price x current position x new margin factor = 57 500 x 1 x 0.9 = 6325` the difference topped up from the party’s general account(<a name="0019-MCAL-233" href="#0019-MCAL-233">0019-MCAL-233</a>)

- In isolated margin mode, a party `short 1@15 900`, `margin factor=0.9` and order book is

  ```book
  buy 1 @ 15 000
  buy 10 @ 14 900
  and
  sell 1 @ 100 000
  sell 10 @ 100 100
  ```

  the margin account will hold `average entry price x current position x new margin factor = 57 500 x 1 x 0.9 = 6325`

  for this market the party switches to cross margin and the market has `market.linearSlippageFactor = 0.25`, `RF short = 0.1` then the maintenance margin for the party is `159 00 x 0.25 x 1 + 0.1 x 1 x 159 00 = 5565`
  but if `5565 < collatoral release level` the maintenance margin will remain unchanged at `6325`

  the difference topped up from the party’s general account(<a name="0019-MCAL-232" href="#0019-MCAL-232">0019-MCAL-232</a>)

- switch to cross margin without position and no orders successful in continuous mode(<a name="0019-MCAL-134" href="#0019-MCAL-134">0019-MCAL-134</a>)

- switch to cross margin without position and no orders successful in auction(<a name="0019-MCAL-135" href="#0019-MCAL-135">0019-MCAL-135</a>)

- switch to cross margin with position and no orders successful in continuous mode(<a name="0019-MCAL-136" href="#0019-MCAL-136">0019-MCAL-136</a>)

- switch to cross margin with position and no orders successful in auction(<a name="0019-MCAL-137" href="#0019-MCAL-137">0019-MCAL-137</a>)

- switch to cross margin without position and with orders successful in continuous mode(<a name="0019-MCAL-138" href="#0019-MCAL-138">0019-MCAL-138</a>)

- switch to cross margin without position and with orders successful in auction(<a name="0019-MCAL-139" href="#0019-MCAL-139">0019-MCAL-139</a>)

- switch to cross margin with position and with orders successful in continuous mode(<a name="0019-MCAL-140" href="#0019-MCAL-140">0019-MCAL-140</a>)

- switch to cross margin with position and with orders successful in auction(<a name="0019-MCAL-141" href="#0019-MCAL-141">0019-MCAL-141</a>)

- when switch to isolated margin mode, valid value of the margin factor must be greater than 0, and also greater than `max(risk factor long, risk factor short) + linear slippage factor`(<a name="0019-MCAL-208" href="#0019-MCAL-208">0019-MCAL-208</a>)

- when amend margin factor during isolated margin mode, margin factor greater than 1 should be not rejected (<a name="0019-MCAL-209" href="#0019-MCAL-209">0019-MCAL-209</a>)

**Check order margin:**

- when party has no position, and place 2 short orders during auction, order margin should be updated(<a name="0019-MCAL-200" href="#0019-MCAL-200">0019-MCAL-200</a>)

- when party has no position, and place short orders size -3 during auction, and long order size 1 which can offset, order margin should be updated using max(price, mark Price, indicative Price)(<a name="0019-MCAL-201" href="#0019-MCAL-201">0019-MCAL-201</a>)

- when party has no position, and place short orders size -3 during auction, and long orders size 2 which can offset, order margin should be updated using max(price, mark Price, indicative Price)(<a name="0019-MCAL-202" href="#0019-MCAL-202">0019-MCAL-202</a>)

- when party has no position, and place short orders size -3 during auction, and long orders size 3 which can offset, order margin should be updated using max(price, mark Price, indicative Price)(<a name="0019-MCAL-203" href="#0019-MCAL-203">0019-MCAL-203</a>)

- when party has no position, and place short orders size -3 during auction, and long orders size 4, which is over the offset size, order margin should be updated using max(price, mark Price, indicative Price)(<a name="0019-MCAL-204" href="#0019-MCAL-204">0019-MCAL-204</a>)

- When the party changes the order price during auction, order margin should be updated using max(price, mark Price, indicative Price)(<a name="0019-MCAL-205" href="#0019-MCAL-205">0019-MCAL-205</a>)

- When the party reduces the order size only during auction, the order margin should be reduced (<a name="0019-MCAL-206" href="#0019-MCAL-206">0019-MCAL-206</a>)

- when party has no position, and place 2 short orders size 3 and 4 long orders of size 4, which is over the offset size, order margin should be updated using max(price, mark Price, indicative Price)(<a name="0019-MCAL-207" href="#0019-MCAL-207">0019-MCAL-207</a>)

- GFA order added during auction should not be used to count order margin in continuous(<a name="0019-MCAL-220" href="#0019-MCAL-220">0019-MCAL-220</a>)

- when party has no position, and place 2 short orders during auction, order margin should be updated(<a name="0019-MCAL-221" href="#0019-MCAL-221">0019-MCAL-221</a>)

- When the party cancel one of the two orders during continuous, order margin should be reduced. When the party increases the order price during continuous, order margin should increase(<a name="0019-MCAL-222" href="#0019-MCAL-222">0019-MCAL-222</a>)

- When the party decreases the order price during continuous, order margin should decrease(<a name="0019-MCAL-223" href="#0019-MCAL-223">0019-MCAL-223</a>)

- When the party decreases the order volume during continuous, order margin should decrease(<a name="0019-MCAL-224" href="#0019-MCAL-224">0019-MCAL-224</a>)

- When the party increases the order volume while decrease price during continuous, order margin should update accordingly(<a name="0019-MCAL-225" href="#0019-MCAL-225">0019-MCAL-225</a>)

- When the party's order is partially filled during continuous, order margin should update accordingly(<a name="0019-MCAL-226" href="#0019-MCAL-226">0019-MCAL-226</a>)

- When the party cancel one of the two orders during continuous, order margin should be reduced(<a name="0019-MCAL-227" href="#0019-MCAL-227">0019-MCAL-227</a>)

- place a GFA order during continuous, order should be rejected(<a name="0019-MCAL-228" href="#0019-MCAL-228">0019-MCAL-228</a>)

- When the party has position -1 and order -3, and new long order with size 1 will be offset(<a name="0019-MCAL-229" href="#0019-MCAL-229">0019-MCAL-229</a>)

- When the party has position -1 and order -3, and new long orders with size 2 will be offset(<a name="0019-MCAL-230" href="#0019-MCAL-230">0019-MCAL-230</a>)

- When the party has position -1 and order -3, and new long orders with size 3 will be offset(<a name="0019-MCAL-231" href="#0019-MCAL-231">0019-MCAL-231</a>)

**Check decimals:**

- A feature test that checks margin in case market PDP > 0 is created and passes. (<a name="0019-MCAL-090" href="#0019-MCAL-090">0019-MCAL-090</a>)

- A feature test that checks margin in case market PDP < 0 is created and passes. (<a name="0019-MCAL-091" href="#0019-MCAL-091">0019-MCAL-091</a>)

**Check API:**

- For each market and each party which has positions or has switched between margin modes on the market, the API provides the maintenance margin levels. (<a name="0019-MCAL-092" href="#0019-MCAL-092">0019-MCAL-092</a>)

- For each market and each party which has orders only and no positions or has switched between margin modes on the market
  - cross margin to isolated margin, the API provides maintenance margin level of zero. (<a name="0019-MCAL-150" href="#0019-MCAL-150">0019-MCAL-150</a>)
  - isolated margin to cross margin, the API provides expected maintenance margin level . (<a name="0019-MCAL-151" href="#0019-MCAL-151">0019-MCAL-151</a>)

- For each market and each party which has either orders or positions on the market, the API provides the current margin mode and, when in isolated margin mode, margin factor.  (<a name="0019-MCAL-143" href="#0019-MCAL-143">0019-MCAL-143</a>)

## Acceptance Criteria (perpetual market in isolated margin mode)

- For a perpetual future market, the maintenance margin is equal to the maintenance margin on an equivalent dated future market, plus a component related to the expected upcoming margin funding payment. Specifically:
  - If a party is long `1` unit and the mark price is `15 900` and `market.linearSlippageFactor = 0.25` and `RF long = 0.1` and order book is

    ```book
    buy 1 @ 15 000
    buy 10 @ 14 900
    and
    sell 1 @ 100 000
    sell 10 @ 100 100
    ```

    then the dated future maintenance margin component for the party is `15900 x 0.25 x 1 + 0.1 x 1 x 15900 = 5565`. The current accrued funding payment for the perpetual component is calculated using

    ```book
    delta_t = funding_period_end - max(funding_period_start, internal_data_points[0].t)
    funding_payment = f_twap - s_twap + min(clamp_upper_bound*s_twap,max(clamp_lower_bound*s_twap, (1 + delta_t * interest_rate)*s_twap-f_twap))
    ```

    Where `f_twap` represents the internal mark price TWAP and `s_twap` represents the TWAP from the external oracle feed. When clamp bounds are large we use:

    ```book
    funding_payment = f_twap - s_twap + (1 + delta_t * interest_rate)*s_twap-f_twap
                    = s_twap * delta_t * interest_rate
    ```

    - If `s_twap = 1600`, `f_twap=1590`, `delta_t = 0.002` and `interest_rate = 0.05` then `funding_payment = 1600 * 0.002 * 0.05 = 0.16`.
      - Thus, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 556.5 + 0.5 * 0.16 * 1 = 556.58` (<a name="0019-MCAL-053" href="#0019-MCAL-053">0019-MCAL-053</a>)

    - If instead
      - `clamp_upper_bound*s_twap < max(clamp_lower_bound*s_twap, (1 + delta_t * interest_rate)*s_twap-f_twap)`
      - `funding payment = f_twap - s_twap + clamp_upper_bound*s_twap = f_twap + s_twap * (clamp_upper_bound - 1)`.
      - Then with `s_twap = 1600`, `clamp_upper_bound = 0.05` and `f_twap = 1550`, `funding_payment = 1590 + 1600 * (0.05 - 1) = 1590 - 1520 = 70`
      - Thus, with `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * 70 * 1 = 5600` (<a name="0019-MCAL-058" href="#0019-MCAL-058">0019-MCAL-058</a>)
      - However is position is instead `-1`, with the same margin requirement, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * max(0, 70 * -1) = 5565`(<a name="0019-MCAL-054" href="#0019-MCAL-054">0019-MCAL-054</a>)

    - If instead
      - `clamp_upper_bound*s_twap > clamp_lower_bound*s_twap > (1 + delta_t * interest_rate)*s_twap-f_twap)`
      - `funding payment = f_twap - s_twap + clamp_lower_bound*s_twap = f_twap + s_twap * (clamp_lower_bound - 1)`.
      - Then with `s_twap = 1600`, `clamp_lower_bound = -0.05` and `f_twap = 1700`, `funding_payment = 1700 + 1600 * (-0.05 - 1) = 20`
      - Thus, with `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 595 + 0.5 * max(0, 20 * 1) = 605` (<a name="0019-MCAL-055" href="#0019-MCAL-055">0019-MCAL-055</a>)
      - However is position is instead `-1`, with the same margin requirement, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 595 + 0.5 * max(0, 20 * -1) = 595`(<a name="0019-MCAL-056" href="#0019-MCAL-056">0019-MCAL-056</a>)


## Acceptance Criteria  (Protocol upgrade)

- All order margin balances are restored after a protocol upgrade (<a name="0019-MCAL-152" href="#0019-MCAL-152">0019-MCAL-152</a>).
- The `margin mode` and `margin factor` of any given party must be preserved after a protocol upgrade (<a name="0019-MCAL-153" href="#0019-MCAL-153">0019-MCAL-153</a>).

## Acceptance Criteria (Fully collateralised mode)

Assume a [capped future](./0093-CFUT-product_builtin_capped_future.md) market with a `max price = 100` and mark-to-market cashflows being exchanged every block:

- Party A posts an order to buy `10` contracts at a price of `30`, there's no other volume in that price range so the order lands on the book and the  maintenance and initial margin levels for the party and order margin account balance are all equal to `300`. (<a name="0019-MCAL-154" href="#0019-MCAL-154">0019-MCAL-154</a>)
- Party B posts an order to sell `15` contracts at a price of `20`, a trade is generated for `10` contracts at price of `30` with party A. The maintenance and initial margin levels party A remains at `300`, order margin account balance is now `0` and margin account balance is `300`, the position is `10` and there are no open orders. The  maintenance and initial margin levels for party B are equal to `10 * (100 - 30) + 5 * (100 - 20) = 1100`, the margin account balance is `700`, order margin account balance is `400`, the position is `-10` and the remaining volume on the book from this party is `5` at a price of `20`. (<a name="0019-MCAL-155" href="#0019-MCAL-155">0019-MCAL-155</a>)
- Party B posts an order to buy `10` contracts at a price of `18`, the orders get placed on the book and margin levels as well margin account balances and position remain unchanged. (<a name="0019-MCAL-156" href="#0019-MCAL-156">0019-MCAL-156</a>)
- Party B posts an order to buy `30` contracts at a price of `16`, the orders get placed on the book, the maintenance and initial margin levels for party B grow to `1180`, and the margin account balance remains unchanged at `700` and the order margin account balance grows to `480 = max (5 * (100 - 20), 30 * 16)`. The position remains unchanged at `-10`. (<a name="0019-MCAL-157" href="#0019-MCAL-157">0019-MCAL-157</a>)
- Party A posts an order to sell `20` contracts at a price of `17`. A trade is generated for `10` contracts at a price of `18` with party B. A sell order for `10` contracts at a price of `17` from party A gets added to the book. The maintenance and initial margin levels for party A is now `10 * (100 - 17) = 830`, the position is `0` and the remaining volume on the book from this party is `10` at a price of `18`. Party A lost `120` on its position, hence `830 - (300 - 120) = 410` additional funds get moved from the general account as part of the transaction which submitted the order to sell `20` at `17`. Party B now has a position of `0` and following orders open on the book: sell `5` at `20` and buy `30` at `16`. The maintenance and initial margin levels are `max(5 * (100 - 20), 30 * 16) = 480`. The margin account momentarily becomes `820` (`700` + `120` of gains from the now closed position of `-10`), order margin account balance is `480`, hence `820` gets released back into the general account and margin account becomes `0`. (<a name="0019-MCAL-158" href="#0019-MCAL-158">0019-MCAL-158</a>)

## Summary

The *margin calculator* returns the set of margin levels for a given *actual position*, along with the amount of additional margin (if any) required to support the party's *potential position* (i.e. active orders including any that are parked/untriggered/undeployed).


### Margining modes

#### Partially-collateralised

The system can operate in one of two partially-collateralised margining modes for each position.
The current mode will be stored alongside of party's position record.

1. **Cross-margin mode (default)**: this is the mode used by all newly created positions.
When in cross-margin mode, margin is dynamically acquired and released as a position is marked to market, allowing profitable positions to offset losing positions for higher capital efficiency (especially with e.g. pairs trades).

1. **Isolated margin mode**: this mode sacrifices capital efficiency for predictability and risk management by segregating positions.
In this mode, the entire margin for any newly opened position volume is transferred to the margin account when the trade is executed.
This includes completely new positions and increases to position size. Other than at time of future trades, the general account will then
*never* be searched for additional funds (a position will be allowed to be closed out instead), nor will profits be moved into the
general account from the margin account.

#### Fully-collateralised

For certain derivatives markets it may be possible to collateralise the position in full so that there's no default risk for any party.

If a product specifies an upper bound on price (`max price`) (e.g. [capped future](./0093-CFUT-product_builtin_capped_future.md)) then a fully-collateralised [wrapped risk model](./0018-RSKM-quant_risk_models.ipynb) can be specified for the market. If such a risk model is chosen then, it's mandatory for all parties (it's not possible to self-select any of the above partially-collateralised margining modes).

In this mode long positions provide `position size * average entry price` in initial margin, whereas shorts provide `postion size * (max price - average entry price)`. The initial margin level is only re-evaluated when party changes their position. The [mark-to-market](./0003-MTMK-mark_to_market_settlement.md) is carried out as usual. Maintenance and initial margin levels should be set to the same value.  Margin search and release levels are set to `0` and never used.

In this mode it is not possible for a party to be liquidated. Even if the price moves to the extremes of zero or the `max price` and parties may therefore have zero in their margin account, the parties must not be liquidated. Fully collateralised means that the posted collateral explicitly covers all eventualities and positions will only be closed at final settlement at maturity.

Order margin is calculated as per [isolated margin mode](#placing-an-order) with:

- `side margin = limit price * size` for buy orders
- `side margin = (max price - limit price) * size` for sell orders.

Same calculation should be applied during auction (unlike in isolated margin mode).

### Actual position margin levels

1. **Maintenance margin**: the minimum margin a party must have in their margin account to avoid the position being liquidated.

1. **Collateral search level**: when in cross-margin mode, the margin account balance below which the system will seek to recollateralise the margin account back to the initial margin level.

1. **Initial margin**: when in cross-margin mode, the margin account balance initially allocated for the position, and the balance that will be returned to the margin account after collateral search and release, if possible. When in isolated margin mode, the margin account balance initially allocated for the position. The balance will not be returned to the margin account while the position is open, as there is no collateral search and release.

1. **Collateral release level**: when in cross-margin mode, the margin account balance above which the system will return collateral from a profitable position to the party's general account for potential use elsewhere.

The protocol is designed such that ***Maintenance margin < Collateral search level < Initial margin < Collateral release level***.

### Potential position margin level

1. **Order margin**: the amount of additional margin on top of the amount in the margin account that is required for the party's current active orders.
Note that this may be zero if the active orders can only decrease the position size.


Margin levels are used by the protocol to ascertain whether a trader has sufficient collateral to maintain a margined trade. When the trader enters an open position, this required amount is equal to the *initial margin*. Subsequently, throughout the life of this open position, the minimum required amount is the *maintenance margin*. As a trader's collateral level dips below the *collateral search level* the protocol will automatically search for more collateral to be assigned to support this open position from the trader's general collateral accounts. In the event that a trader has collateral that is above the *collateral release level* the protocol will automatically release collateral to a trader's general collateral account for the relevant asset.

**Whitepaper reference:** 6.1, section "Margin Calculation"

In future there can be multiple margin calculator implementations that would be configurable in the market framework. This spec describes one implementation.

## Isolated margin mode

When in isolated margin mode, the position on the market has an associated margin factor.
The margin factor must be greater than 0, and also greater than `max(risk factor long, risk factor short) + linear slippage factor`.

Isolated margin mode can be enabled by placing an *update margin mode* transaction.
The protocol will attempt to set the funds within the margin account equal to `average entry price * current position * new margin factor`.
This value must be above the `initial margin` for the current position or the transaction will be rejected.

The default when placing an order with no change to margin mode specified must be to retain the current margin mode of the position.

### Placing an order

When submitting, amending, or deleting an order in isolated margin mode and continuous trading, a two step process will be followed:

   1. First, the core will check whether the order will trade, either fully or in part, immediately upon entry. If so:
      1. If the trade would increase the party's position, the required additional funds as specified in the Increasing Position section will be calculated. The total expected margin balance (current plus new funds) will then be compared to the `maintenance margin` for the expected position, if the margin balance would be less than maintenance, instead reject the order in it's entirety. If the margin will be greater than the maintenance margin their general account will be checked for sufficient funds.
         1. If they have sufficient, that amount will be moved into their margin account and the immediately matching portion of the order will trade.
         1. If they do not have sufficient, the order will be rejected in it's entirety for not meeting margin requirements.
      1. If the trade would decrease the party's position, that portion will trade and margin will be released as in the Decreasing Position section
   1. If the order is not persistent this is the end, if it is persistent any portion of the order which has not traded in step 1 will move to being placed on the order book.
      1. At this point, the party's general account will be checked for margin to cover the additional amount required for the new orders. Each side can be checked individually and the maximum for either side taken into the order margin pool. This calculation must be rerun every time the party's orders or position change. For each side:
         1. Sort all orders by price, starting from first to execute (highest price for buying, lowest price for selling).
         1. If the party currently has a position `x`, assign `0` margin requirement the first-to-trade `x` of volume on the opposite side as this would reduce their position (for example, if a party had a long position `10` and sell orders of `15` at a price of `$100` and `10` at a price of `$150`, the first `10` of the sell order at `$100` would not require any order margin).
         1. For any remaining volume, sum `side margin = limit price * size * margin factor` for each price level, as this is the worst-case trade price of the remaining component.
      2. Take the maximum margin from the two `side margin`s as the margin required in the order margin account. If the party's `general` account does not contain sufficient funds to cover any increases to the `order margin` account to be equal to `side margin` then:
         1. If a newly placed order is being evaluated, that order is `stopped`
         2. If the evaluation is the result of any other position/order update, all open orders are `stopped` and margin re-evaluated.
      3. The `order margin` account is now updated to the new `side margin` value and any new orders can be placed on the book.

NB: This means that a party's order could partially match, with a trade executed and some funds moved to the margin account with correct leverage whilst the rest of the order is immediately stopped.

When submitting, amending, or deleting an order in isolated margin mode and an auction is active there is no concept of an order trading immediately on entry, however the case of someone putting in a sell order for a very low price must be handled (as it is likely to execute at a much higher price). To handle this, when in an auction the amount taken into the order margin account should be the larger of either `limit price * size * margin factor` or `max(mark price, indicative uncrossing price) * size * margin factor`. After uncrossing, all remaining open order volume should be rebased back to simply `limit price * size * margin factor` in the order margin account. All other steps are as above.

Pegged orders are not supported in isolated margin mode.

### Increasing Position

When an order trades which increases the position (increasing the absolute value of the trader's position), the target amount to be transferred is calculated as:

$$
\text{margin to add} = \text{margin factor} \cdot \text{sum across executed trades}(|\text{trade size}| \cdot \text{trade price})
$$

This will be taken by performing three steps:

 1. The margin to add as calculated here is compared to the margin which would have been placed into the order margin account for this order, `limit price * total traded size * margin factor`.
 2. If it is equal, this amount is taken from the order margin account and placed into the margin account
 3. If the order traded at a price which means less margin should be taken then the amount `margin to add` above is taken from the order margin account into the margin account and the excess is returned from the order margin account to the general account

NB: In implementation, for any volume that trades immediately on entry, the additional margin may be transferred directly from the general account to the margin account.

### Reducing Position

When an order trades which reduces the trader's current position the amount to be withdrawn from the margin account is determined by the fraction of the position which is being closed. If the entire position is being closed (either as a result of changing sides as below or just moving to `0`) then the entirety of the margin balance will be moved back to the general account.

However, if only a fraction is being closed then this fraction should also take into account that the entire position's margin may be due to change, since the current trading price may have diverged from the last mark price update. As such the margin released should be calculated by first calculating what the `theoretical account balance` of the margin account would be if the entire pre-existing position (i.e. the position prior to any reduction) were margined at the VWAP of the executed trade, then taking the proportion of that corresponding to the proportion of the position closed.

$$
\text{margin to remove} = \text{theoretical account balance} \cdot \frac{|\text{total size of new trades}|}{|\text{entire position prior to trade}|}
$$

Concretely, this should resolve to:

$$
\text{margin to remove} = (\text{balance before}  + \text{position before} \cdot (\text{new trade VWAP} -  \text{mark price})) \cdot \frac{|\text{total size of new trades}|}{|\text{entire position prior to trade}|}
$$

Note: This requires a calculation of the position's margin at trade time.

### Changing Sides

A single order could move a trader from a short to a long position (or vice versa) which either increases or decreases the required margin. When this occurs, the trade should be seen as two steps. One in which the position is reduced to zero (and so margin can be released) followed immediately by one which increases to the new position. (Note that these should *not* be two separate trades, merely modelled as such. The two account movements should occur at once with no other changes allowed between them).


### Position Resolution

Isolated margin acts slightly differently to cross margining mode at times when the position becomes distressed. In the case of an open position dropping below maintenance margin levels active orders will remain active as these are margined separately and will not be cancelled.

However in addition at each margin calculation update the returned `order margin` from the calculator should be compared to the balance in the `order margin account`. If the margin calculator `order margin > order margin account balance` all orders should be cancelled and the funds returned to the general account (any active positions will remain untouched and active).

### Setting margin mode

When isolated margin mode is enabled, amount to be transferred is a fraction of the position's notional size that must be specified by the user when enabling isolated margin mode.

The transaction to update/change margin mode can be included in a batch transaction in order to allow updates when placing an order.

When in isolated margin mode, it is possible to request to both increase or decrease the margin factor setting:

- The protocol will attempt to set the funds within the margin account equal to `average entry price * current position * new margin factor`. This value must be above the `initial margin` for the current position or the transaction will be rejected.
  - If this is less than the balance currently in the margin account, the difference will be moved from the margin account to the general account
  - If this is larger than the balance currently in the margin account, the difference will be moved from the general account to the margin account. If there are not enough funds to complete this transfer, the transaction will be rejected and no change of margin factor will occur.

When switching to isolated margin mode, the following steps will be taken:

  1. For any active position, calculate `average entry price * abs(position) * margin factor`. Calculate the amount of funds which will be added to, or subtracted from, the general account in order to do this. If additional funds must be added which are not available, reject the transaction immediately.
  2. For any active orders, calculate the quantity `limit price * remaining size * margin factor` which needs to be placed in the order margin account. Add this amount to the difference calculated in step 1. If this amount is less than or equal to the amount in the general account, perform the transfers (first move funds into/out of margin account, then move funds into the order margin account). If there are insufficient funds, reject the transaction.
  3. Move account to isolated margin mode on this market

When switching from isolated margin mode to cross margin mode, the following steps will be taken:

   1. Any funds in the order margin account will be moved to the margin account.
   2. At this point trading can continue with the account switched to the cross margining account type. If there are excess funds in the margin account they will be freed at the next margin release cycle.

## Reference Level Explanation

The calculator takes as inputs:

- position record = [`open_volume`, `buy_orders`, `sell_orders`] where `open_volume` refers to size of open position (`+ve` is long, `-ve` is short), `buy_orders` / `sell_orders` refer to size of all orders on the buy / sell side (`+ve` is long, `-ve` is short). See [positions core specification](./0006-POSI-positions_core.md).
- `mark price`
- `scaling levels` defined in the risk parameters for a market
- `quantitative risk factors`
- `market.linearSlippageFactor` which is decimal optional market creation parameter with a default of `0.1` i.e. `10%` with the following validation: `0 <= market.linearSlippageFactor <= 1 000 000`.

Note: `open_volume` may be fractional, depending on the `Position Decimal Places` specified in the [Market Framework](./0001-MKTF-market_framework.md). If this is the case, it may also be that order/positions sizes and open volume are stored as integers (i.e. int64). In this case, **care must be taken** to ensure that the actual fractional sizes are used when calculating margins. For example, if Position Decimals Places (PDP) = 3, then an open volume of 12345 is actually 12.345 (`12345 / 10^3`). This is important to avoid margins being off by orders of magnitude. It is notable because outside of margin calculations, and display to end users, the integer values can generally be used as-is.
Note also that if PDP is negative e.g. PDP = -2 then an integer open volume of 12345  is actually 1234500.

and returns 5 margin requirement levels

1. Maintenance margin
1. Order margin
1. Collateral search level
1. Initial margin
1. Collateral release level

## Steps to calculate margins

1. Calculate the maintenance margin for the riskiest long position.
1. Calculate the maintenance margin for the riskiest short position.
1. Select the maintenance margin that is highest out of steps 1 & 2.
1. Scale this maintenance margin by the margin level scaling factors.
1. Return 5 numbers: the maintenance margin, order margin, collateral search level, initial margin and collateral release level.

## Calculation of riskiest long and short positions

The protocol calculates the margin requirements for the `riskiest long` and `riskiest short` positions.

`riskiest long` = max( `open_volume` + `buy_orders` , 0 )

`riskiest short` = min( `open_volume` + `sell_orders`, 0 )

## Limit order book linearised calculation

In this simple methodology, a linearised margin formula is used to return the margin requirement levels, using risk factors returned by the [quantitative model](./0018-RSKM-quant_risk_models.ipynb).

### **Step 1**

If `riskiest long == 0` then `maintenance_margin_long = 0`.

In this simple methodology, a linearised margin formula is used to return the maintenance margin, using risk factors returned by the [quantitative model](./0018-RSKM-quant_risk_models.ipynb).

with

```formula
maintenance_margin_long
    = max(product.value(market_observable) * riskiest_long * market.linearSlippageFactor, 0)
    +  max(open_volume, 0) * [quantitative_model.risk_factors_long] * [Product.value(market_observable)] + buy_orders * [ quantitative_model.risk_factors_long ] * [ Product.value(market_observable)]`,
```

where

`market_observable` = `settlement_mark_price` if in continuous trading, refer to [auction subsection](#margin-calculation-for-auctions) for details of the auction behaviour.

`settlement_mark_price` refers to the mark price most recently utilised in [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md). If no previous mark to market settlement has occurred, the initial mark price, as defined by a market parameter, should be used.

### **Step 2**

If `riskiest short == 0` then `maintenance_margin_short = 0`.

Else

```formula
maintenance_margin_short
    = max(product.value(market_observable) * abs(riskiest short) * market.linearSlippageFactor, 0)
    + abs(min(open_volume, 0)) * [quantitative_model.risk_factors_short] * [Product.value(market_observable)] + abs
    (sell_orders) * [quantitative_model.risk_factors_short] * [Product.value(market_observable)]`
```

where meanings of terms in Step 1 apply

### **Step 3**

If `open_volume > 0`:

`maintenance_margin = max(product.value(market_observable) * (open_volume * market.linearSlippageFactor), 0)
    +  open_volume * [quantitative_model.risk_factors_long] * [Product.value(market_observable) ]`

If `open_volume < 0`:

```formula
maintenance_margin
    = max(product.value(market_observable) * (abs(open_volume) * market.linearSlippageFactor), 0)
    + abs(open_volume) * [quantitative_model.risk_factors_short] * [Product.value(market_observable) ]`
```

If `open_volume == 0`:

`maintenance_margin = 0`

### **Step 4**

`maintenance_margin_with_orders = max(maintenance_margin_long, maintenance_margin_short)`

`order_margin = maintenance_margin_with_orders - maintenance_margin`

## Margin calculation for auctions

We are assuming that:

- mark price never changes during an auction, so it's the last mark price from before auction,
- during an auction we never release money from the margin account, however we top-it-up as required,
- no closeouts during auctions

Use the same calculation as above with the following re-defined:

- For the orders part of the margin: use `market_observable` = max(volume weighted average price of the party's long / short orders, sum of volumes of party's long / short orders * auction price), where `auction price` = max(mark price, indicative uncrossing price). If any of the values is unavailable at the time of calculation assume it's equal to `0`

## Scaling other margin levels

### **Step 5**

The other three margin levels are scaled relative to the maintenance margin level, using scaling levels defined in the risk parameters for a market.

`search_level = margin_maintenance * search_level_scaling_factor`

`initial_margin = margin_maintenance * initial_margin_scaling_factor`

`collateral_release_level = margin_maintenance * collateral_release_scaling_factor`

where the scaling factors are set as risk parameters ( see [market framework](./0001-MKTF-market_framework.md) ).

## Positive and Negative numbers

Positive margin numbers represent a liability for a trader. Therefore, if comparing two margin numbers, the greatest liability (i.e. 'worst' margin number for the trader) is the most positive number. All margin levels returned are positive numbers.

## Pseudo-code / Examples

### EXAMPLE 1 - full worked example

```go
Current order book:

asks: [
    {volume: 3, price: $258},
    {volume: 5, price: $240},
    {volume: 3, price: $188}
]

bids: [
    {volume: 1, price: $120},
    {volume: 4, price: $110},
    {volume: 7, price: $108}
]

market.linearSlippageFactor = 0.25

risk_factor_short = 0.11
risk_factor_long = 0.1

mark_price = $144

search_level_scaling_factor = 1.1
initial_margin_scaling_factor = 1.2
collateral_release_scaling_factor = 1.3

Trader1_futures_position = {open_volume: 10, buys: 4,  sells: 8}

getMargins(Trader1_position)

riskiest_long  = max( open_volume + buy_orders, 0 ) = max( 10 + 4, 0 ) = 14
riskiest_short = min( open_volume + sell_orders, 0 ) =  min( 10 - 8, 0 ) = 0

# Step 1

maintenance_margin_long =max(product.value(market_observable)  * (riskiest_long * market.linearSlippageFactor), 0)
 + max(open_volume, 0 ) * [quantitative_model.risk_factors_long] . [Product.value(market_observable)] + buy_orders * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]
=  max(144*(14 * 0.25), 0) + 10 * 0.1 * 144 + 4 * 0.1 * 144 = 705.6

# Step 2

Since riskiest short == 0 then maintenance_margin_short = 0

# Step 3

Since open_volume == 10

maintenance_margin = max(product.value(market_observable) * (open_volume * market.maxSlippageFraction[1]), 0)
    +  open_volume * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]
 =  max(144*(14 * 0.25), 0) + 10 * 0.1 * 144 = 648

# Step 4

maintenance_margin_with_orders = max (705.6, 0) = 677.6
order_margin = 705.6 - 648 = 47.6

# Step 5

collateral_release_level = 705.6 * collateral_release_scaling_factor = 705.6 * 1.1
initial_margin = 705.6 * initial_margin_scaling_factor = 705.6 * 1.2
search_level = 705.6 * search_level_scaling_factor = 705.6 * 1.3

```

### EXAMPLE 2 - calculating correct slippage volume

Given the following trader positions:

| Tables        | Open           | Buys  | Sells |
| ------------- |:-------------:| -----:| -----:|
| case-1      | 1 | 1 | -2 |
| case-2      | -1 | 2| 0 |
| case-3 | 1 | 0 | -2 |

#### *case-1*

riskiest long: 2

riskiest short: -1

#### *case-2*

riskiest long: 1

riskiest short: -1

#### *case-3*

riskiest long: 1

riskiest short: -1

## SCENARIOS

Scenarios found [here](https://docs.google.com/spreadsheets/d/1VXMdpgyyA9jp0hoWcIQTUFrhOdtu-fak/edit#gid=1586131462)

