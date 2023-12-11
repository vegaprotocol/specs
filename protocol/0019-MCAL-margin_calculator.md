# Margin Calculator

## Acceptance Criteria (Cross margin)

- Get four margin levels for one or more parties (<a name="0019-MCAL-001" href="#0019-MCAL-001">0019-MCAL-001</a>)

- Margin levels are correctly calculated against riskiest long and short positions (<a name="0019-MCAL-002" href="#0019-MCAL-002">0019-MCAL-002</a>)

- Zero position and zero orders results in all zero margin levels (<a name="0019-MCAL-003" href="#0019-MCAL-003">0019-MCAL-003</a>)

- If `riskiest long > 0` and there are no bids on the order book, the `exit price` is equal to infinity and hence the slippage cap is used as the slippage component of the margin calculation. (<a name="0019-MCAL-014" href="#0019-MCAL-014">0019-MCAL-014</a>)

- If `riskiest long > 0 && 0 < *sum of volume of order book bids* < riskiest long`, the `exit price` is equal to infinity.  (<a name="0019-MCAL-015" href="#0019-MCAL-015">0019-MCAL-015</a>)

- If `riskiest short < 0 && 0 < *sum of absolute volume of order book offers* < abs(riskiest short)`, the `exit price` is equal to infinity. (<a name="0019-MCAL-016" href="#0019-MCAL-016">0019-MCAL-016</a>)

- If `riskiest long > 0 &&  riskiest long < *sum of volume of order book bids*`, the `exit price` is equal to the *volume weighted price of the order book bids* with cumulative volume equal to the riskiest long, starting from best bid.  (<a name="0019-MCAL-017" href="#0019-MCAL-017">0019-MCAL-017</a>)

- If `riskiest short < 0 && 0 abs(riskiest short) == *sum of absolute volume of order book offers* <`, the `exit price` is equal to the *volume weighted price of the order book offers*.  (<a name="0019-MCAL-018" href="#0019-MCAL-018">0019-MCAL-018</a>)

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

    then the maintenance margin for the party is `min(1 x (100000-15900), 15900 x 0.25 x 1) + 0.1 x 1 x 15900 = 5565`. (<a name="0019-MCAL-024" href="#0019-MCAL-024">0019-MCAL-024</a>)

- In the same situation as above, if `market.linearSlippageFactor = 100`, (i.e. 10 000%) instead, then the margin for the party is `min(1 x (100000-15900), 15900 x 100 x 1) + 0.1 x 1 x 15900 = 85690`. (<a name="0019-MCAL-025" href="#0019-MCAL-025">0019-MCAL-025</a>)

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

    then the dated future maintenance margin component for the party is `min(1 x (100000-15900), 15900 x 0.25 x 1) + 0.1 x 1 x 15900 = 5565`. The current accrued funding payment for the perpetual component is calculated using

    ```book
    delta_t = funding_period_end - max(funding_period_start, internal_data_points[0].t)
    funding_payment = f_twap - s_twap + min(clamp_upper_bound*s_twap,max(clamp_lower_bound*s_twap, (1 + delta_t * interest_rate)*s_twap-f_twap))
    ```

    Where `f_twap` represents the internal mark price TWAP and `s_twap` represents the TWAP from the external oracle feed. When clamp bounds are large we use:

    ```book
    funding_payment = f_twap - s_twap + (1 + delta_t * interest_rate)*s_twap-f_twap
                    = s_twap * delta_t * interest_rate
    ```

    - If `s_twap = 1600`, `delta_t = 0.002` and `interest_rate = 0.05` then `funding_payment = 1600 * 0.002 * 0.05 = 0.16`.
      - Thus, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * 0.16 * 1 = 5565.08` (<a name="0019-MCAL-026" href="#0019-MCAL-026">0019-MCAL-026</a>)

    - If instead
      - `clamp_upper_bound*s_twap < max(clamp_lower_bound*s_twap, (1 + delta_t * interest_rate)*s_twap-f_twap)`
      - `funding payment = f_twap - s_twap + clamp_upper_bound*s_twap = f_twap + s_twap * (clamp_upper_bound - 1)`.
      - Then with `s_twap = 1600`, `clamp_upper_bound = 0.05` and `f_twap = 1550`, `funding_payment = 1590 + 1600 * (0.05 - 1) = 1590 - 1520 = 70`
      - Thus, with `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * 70 * 1 = 5600` (<a name="0019-MCAL-027" href="#0019-MCAL-027">0019-MCAL-027</a>)
      - However is position is instead `-1`, with the same margin requirement, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * max(0, 70 * -1) = 5565`(<a name="0019-MCAL-030" href="#0019-MCAL-030">0019-MCAL-030</a>)

    - If instead
      - `clamp_upper_bound*s_twap > clamp_lower_bound*s_twap > (1 + delta_t * interest_rate)*s_twap-f_twap)`
      - `funding payment = f_twap - s_twap + clamp_lower_bound*s_twap = f_twap + s_twap * (clamp_lower_bound - 1)`.
      - Then with `s_twap = 1600`, `clamp_lower_bound = -0.05` and `f_twap = 1550`, `funding_payment = 1590 + 1600 * (-0.05 - 1) = 1590 - 1680 = -90`
      - Thus, with `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * max(0, -90 * 1) = 5565` (<a name="0019-MCAL-028" href="#0019-MCAL-028">0019-MCAL-028</a>)
      - However is position is instead `-1`, with the same margin requirement, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * max(0, -90 * -1) = 5610`(<a name="0019-MCAL-029" href="#0019-MCAL-029">0019-MCAL-029</a>)

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

**When a party has a position and an order which offsets the position:**

- When the party places a new long order of `2` with price `15912` which offsets the existing position, and the market is in continuous trading. The margin account should not change as no additional margin is required (<a name="0019-MCAL-038" href="#0019-MCAL-038">0019-MCAL-038</a>)

- When the party switches to cross margin mode, the margin accounts will not be updated until the next MTM (<a name="0019-MCAL-036" href="#0019-MCAL-036">0019-MCAL-036</a>)

- The order will be rejected if the party does not have enough asset in the general account (<a name="0019-MCAL-037" href="#0019-MCAL-037">0019-MCAL-037</a>)

- When the party place a new long order of `10` with price `145000` and the party has existing short position of `3`, and the market is in continuous trading. The margin account should have additional amount `limit price * size * margin factor = 145000 x (10-3) x 0.9 = 913500` added if the party has enough asset in the general account(<a name="0019-MCAL-039" href="#0019-MCAL-039">0019-MCAL-039</a>)

- When increasing the `margin factor` and the party does not have enough asset in the general account to cover the new maintenance margin, then the new margin factor will be rejected (<a name="0019-MCAL-040" href="#0019-MCAL-040">0019-MCAL-040</a>)

**Amending order:**

- When the party cancels all orders, the order margin should be `0`(<a name="0019-MCAL-041" href="#0019-MCAL-041">0019-MCAL-041</a>)

- When the party reduces the order size only, the order margin should be reduced (<a name="0019-MCAL-042" href="#0019-MCAL-042">0019-MCAL-042</a>)

- When the party reduces the order price only, the order margin should be reduced (<a name="0019-MCAL-043" href="#0019-MCAL-043">0019-MCAL-043</a>)

- When the party increases the order size and the party's general account does not contain sufficient funds to cover any increases to the order margin account to be equal to side margin then the order should be stopped (<a name="0019-MCAL-044" href="#0019-MCAL-044">0019-MCAL-044</a>)

- When the party increases the order price and the party's general account does not contain sufficient funds to cover any increases to the order margin account to be equal to side margin then the order should be stopped (<a name="0019-MCAL-045" href="#0019-MCAL-045">0019-MCAL-045</a>)

- When the party increases the order size while decreases the order price and the party's general account does not contain sufficient funds to cover any increases to the order margin account to be equal to side margin then the order should be stopped (<a name="0019-MCAL-046" href="#0019-MCAL-046">0019-MCAL-046</a>)

- When the party increases the order price while decreases the order size and the party's general account does not contain sufficient funds to cover any increases to the order margin account to be equal to side margin then the order should be stopped (<a name="0019-MCAL-047" href="#0019-MCAL-047">0019-MCAL-047</a>)

- When the party's order is partially filled, the order margin and general margin should be updated accordingly (<a name="0019-MCAL-048" href="#0019-MCAL-048">0019-MCAL-048</a>)

- When the party cancels a pegged order, which was their only order, the order margin should be `0`(<a name="0019-MCAL-049" href="#0019-MCAL-049">0019-MCAL-049</a>)

- When the party reduces the pegged order size only, the order margin should be reduced (<a name="0019-MCAL-050" href="#0019-MCAL-050">0019-MCAL-050</a>)

- When the party reduces the pegged buy order offset price, the order margin should be reduced (<a name="0019-MCAL-051" href="#0019-MCAL-051">0019-MCAL-051</a>)

- When the party increases the pegged sell order offset price, the order margin should be reduced (<a name="0019-MCAL-057" href="#0019-MCAL-057">0019-MCAL-057</a>)

- When the party increases the pegged order size and the party's general account does not contain sufficient funds to cover any increases to the order margin account to be equal to side margin then the amendment is rejected and the original order is not effected (<a name="0019-MCAL-052" href="#0019-MCAL-052">0019-MCAL-052</a>)

- When the party increases the pegged order price and the party's general account does not contain sufficient funds to cover any increases to the order margin account to be equal to side margin then the amendment is rejected and the original order is not effected (<a name="0019-MCAL-075" href="#0019-MCAL-075">0019-MCAL-075</a>)

- When the party increases the pegged order size while decreases the order price and the party's general account does not contain sufficient funds to cover any increases to the order margin account to be equal to side margin then the amendment is rejected and the original order is not effected (<a name="0019-MCAL-076" href="#0019-MCAL-076">0019-MCAL-076</a>)

- When the party increases the pegged order price while decreases the order price and the party's general account does not contain sufficient funds to cover any increases to the order margin account to be equal to side margin then the amendment is rejected and the original order is not effected (<a name="0019-MCAL-077" href="#0019-MCAL-077">0019-MCAL-077</a>)

- When the party's pegged order is partially filled, the order margin and general margin should be updated accordingly (<a name="0019-MCAL-078" href="#0019-MCAL-078">0019-MCAL-078</a>)

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

- switch to isolated margin without position and no orders with margin factor such that there is insufficient balance in the general account in auction mode(<a name="0019-MCAL-111" href="#0019-MCAL-111">0019-MCAL-111</a>)

- switch to isolated margin with position and no orders with margin factor such that there is insufficient balance in the general account in continuous mode(<a name="0019-MCAL-112" href="#0019-MCAL-112">0019-MCAL-112</a>)

- switch to isolated margin with position and no orders with margin factor such that there is insufficient balance in the general account in auction mode(<a name="0019-MCAL-113" href="#0019-MCAL-113">0019-MCAL-113</a>)

- switch to isolated margin with position and with orders with margin factor such that there is insufficient balance in the general account in continuous mode(<a name="0019-MCAL-114" href="#0019-MCAL-114">0019-MCAL-114</a>)

- switch to isolated margin with position and with orders with margin factor such that there is insufficient balance in the general account in auction mode(<a name="0019-MCAL-142" href="#0019-MCAL-142">0019-MCAL-142/a>)
- switch to isolate margin with out of range margin factor(<a name="0019-MCAL-115" href="#0019-MCAL-115">0019-MCAL-115</a>)

- submit update margin mode transaction with no state change (already in cross margin, "change" to cross margin, or already in isolated, submit with same margin factor)(<a name="0019-MCAL-116" href="#0019-MCAL-116">0019-MCAL-116</a>)

- update margin factor when already in isolated mode to the same cases as in switch to isolated failures.(<a name="0019-MCAL-117" href="#0019-MCAL-117">0019-MCAL-117</a>)

- switch to isolated margin without position and no orders successful in continuous mode(<a name="0019-MCAL-118" href="#0019-MCAL-118">0019-MCAL-118</a>)

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

- switch to cross margin without position and no orders successful in continuous mode(<a name="0019-MCAL-134" href="#0019-MCAL-134">0019-MCAL-134</a>)

- switch to cross margin without position and no orders successful in auction(<a name="0019-MCAL-135" href="#0019-MCAL-135">0019-MCAL-135</a>)

- switch to cross margin with position and no orders successful in continuous mode(<a name="0019-MCAL-136" href="#0019-MCAL-136">0019-MCAL-136</a>)

- switch to cross margin with position and no orders successful in auction(<a name="0019-MCAL-137" href="#0019-MCAL-137">0019-MCAL-137</a>)

- switch to cross margin without position and with orders successful in continuous mode(<a name="0019-MCAL-138" href="#0019-MCAL-138">0019-MCAL-138</a>)

- switch to cross margin without position and with orders successful in auction(<a name="0019-MCAL-139" href="#0019-MCAL-139">0019-MCAL-139</a>)

- switch to cross margin with position and with orders successful in continuous mode(<a name="0019-MCAL-140" href="#0019-MCAL-140">0019-MCAL-140</a>)

- switch to cross margin with position and with orders successful in auction(<a name="0019-MCAL-141" href="#0019-MCAL-141">0019-MCAL-141</a>)

**Check decimals:**

- A feature test that checks margin in case market PDP > 0 is created and passes. (<a name="0019-MCAL-090" href="#0019-MCAL-090">0019-MCAL-090</a>)

- A feature test that checks margin in case market PDP < 0 is created and passes. (<a name="0019-MCAL-091" href="#0019-MCAL-091">0019-MCAL-091</a>)

**Check API:**

- For each market and each party which has either orders or positions on the market, the API provides the maintenance margin levels.  (<a name="0019-MCAL-092" href="#0019-MCAL-092">0019-MCAL-092</a>)

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

    then the dated future maintenance margin component for the party is `min(1 x (100000-15900), 15900 x 0.25 x 1) + 0.1 x 1 x 15900 = 5565`. The current accrued funding payment for the perpetual component is calculated using

    ```book
    delta_t = funding_period_end - max(funding_period_start, internal_data_points[0].t)
    funding_payment = f_twap - s_twap + min(clamp_upper_bound*s_twap,max(clamp_lower_bound*s_twap, (1 + delta_t * interest_rate)*s_twap-f_twap))
    ```

    Where `f_twap` represents the internal mark price TWAP and `s_twap` represents the TWAP from the external oracle feed. When clamp bounds are large we use:

    ```book
    funding_payment = f_twap - s_twap + (1 + delta_t * interest_rate)*s_twap-f_twap
                    = s_twap * delta_t * interest_rate
    ```

    - If `s_twap = 1600`, `delta_t = 0.002` and `interest_rate = 0.05` then `funding_payment = 1600 * 0.002 * 0.05 = 0.16`.
      - Thus, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * 0.16 * 1 = 5565.08` (<a name="0019-MCAL-053" href="#0019-MCAL-053">0019-MCAL-053</a>)

    - If instead
      - `clamp_upper_bound*s_twap < max(clamp_lower_bound*s_twap, (1 + delta_t * interest_rate)*s_twap-f_twap)`
      - `funding payment = f_twap - s_twap + clamp_upper_bound*s_twap = f_twap + s_twap * (clamp_upper_bound - 1)`.
      - Then with `s_twap = 1600`, `clamp_upper_bound = 0.05` and `f_twap = 1550`, `funding_payment = 1590 + 1600 * (0.05 - 1) = 1590 - 1520 = 70`
      - Thus, with `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * 70 * 1 = 5600` (<a name="0019-MCAL-058" href="#0019-MCAL-058">0019-MCAL-058</a>)
      - However is position is instead `-1`, with the same margin requirement, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * max(0, 70 * -1) = 5565`(<a name="0019-MCAL-054" href="#0019-MCAL-054">0019-MCAL-054</a>)

    - If instead
      - `clamp_upper_bound*s_twap > clamp_lower_bound*s_twap > (1 + delta_t * interest_rate)*s_twap-f_twap)`
      - `funding payment = f_twap - s_twap + clamp_lower_bound*s_twap = f_twap + s_twap * (clamp_lower_bound - 1)`.
      - Then with `s_twap = 1600`, `clamp_lower_bound = -0.05` and `f_twap = 1550`, `funding_payment = 1590 + 1600 * (-0.05 - 1) = 1590 - 1680 = -90`
      - Thus, with `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * max(0, -90 * 1) = 5565` (<a name="0019-MCAL-055" href="#0019-MCAL-055">0019-MCAL-055</a>)
      - However is position is instead `-1`, with the same margin requirement, if `margin funding factor = 0.5`, `total margin requirement = futures margin + funding margin = 5565 + 0.5 * max(0, -90 * -1) = 5610`(<a name="0019-MCAL-056" href="#0019-MCAL-056">0019-MCAL-056</a>)

## Summary

The *margin calculator* returns the set of margin levels for a given *actual position*, along with the amount of additional margin (if any) required to support the party's *potential position* (i.e. active orders including any that are parked/untriggered/undeployed).


### Margining modes

The system can operate in one of two margining modes for each position.
The current mode will be stored alongside of party's position record.

1. **Cross-margin mode (default)**: this is the mode used by all newly created positions.
When in cross-margin mode, margin is dynamically acquired and released as a position is marked to market, allowing profitable positions to offset losing positions for higher capital efficiency (especially with e.g. pairs trades).

1. **Isolated margin mode**: this mode sacrifices capital efficiency for predictability and risk management by segregating positions.
In this mode, the entire margin for any newly opened position volume is transferred to the margin account when the trade is executed.
This includes completely new positions and increases to position size. Other than at time of future trades, the general account will then
*never* be searched for additional funds (a position will be allowed to be closed out instead), nor will profits be moved into the
general account from the margin account.

### Actual position margin levels

1. **Maintenance margin**: the minimum margin a party must have in their margin account to avoid the position being liquidated.

1. **Collateral search level**: when in cross-margin mode, the margin account balance below which the system will seek to recollateralise the margin account back to the initial margin level.

1. **Initial margin**: when in cross-margin mode, the margin account balance initially allocated for the position, and the balance to which the margin account will be returned after collateral search and release, if possible.

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
The margin factor must be greater than 0 and less than or equal to 1, and also greater than `max(risk factor long, risk factor short)`.

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
    = max(min(riskiest_long * slippage_per_unit, product.value(market_observable)  * (riskiest_long * market.linearSlippageFactor)), 0)
    +  max(open_volume, 0) * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ] + buy_orders * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]`,
```

where

`slippage_volume =  max( open_volume, 0 )`,

and

if `open_volume > 0` then

`slippage_per_unit = max(0, Product.value(market_observable) - Product.value(exit_price))`,

else `slippage_per_unit = 0`.

where

`market_observable` = `settlement_mark_price` if in continuous trading, refer to [auction subsection](#margin-calculation-for-auctions) for details of the auction behaviour.

`settlement_mark_price` refers to the mark price most recently utilised in [mark to market settlement](./0003-MTMK-mark_to_market_settlement.md). If no previous mark to market settlement has occurred, the initial mark price, as defined by a market parameter, should be used.

`exit_price` is the price that would be achieved on the order book if the trader's position size on market were exited. Specifically:

- **Long positions** are exited by the system considering what the volume weighted price of **selling** the size of the open long position (not riskiest long position) on the order book (i.e. by selling to the bids on the order book). If there is no open long position, the slippage per unit is zero.

- **Short positions** are exited by the system considering what the volume weighted price of **buying** the size of the open short position (not riskiest short position) on the order book (i.e. by buying from the offers (asks) on the order book). If there is no open short position, the slippage per unit is zero.

If there is zero or insufficient order book volume on the relevant side of the order book to calculate the `exit_price`, then take `slippage_per_unit = +Infinity` which means that `min(slippage_volume * slippage_per_unit, mark_price * (slippage_volume * market.linearSlippageFactor)) = mark_price * (slippage_volume * market.linearSlippageFactor)` above.

### **Step 2**

If `riskiest short == 0` then `maintenance_margin_short = 0`.

Else

```formula
maintenance_margin_short
    = max(min(abs(riskiest short) * slippage_per_unit, mark_price * (abs(riskiest short) *  market.linearSlippageFactor),  0)
    + abs(min( open_volume, 0 )) * [ quantitative_model.risk_factors_short ] . [ Product.value(market_observable) ] + abs(sell_orders) * [ quantitative_model.risk_factors_short ] . [ Product.value(market_observable) ]`
```

where meanings of terms in Step 1 apply except for:

`slippage_per_unit = max(0, Product.value(exit_price)-Product.value(market_observable))`

### **Step 3**

If `open_volume > 0`:

`maintenance_margin = max(min(open_volume * slippage_per_unit, product.value(market_observable)  * (open_volume * market.maxSlippageFraction[1] + open_volume^2 * market.maxSlippageFraction[2])), 0)
    +  open_volume * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]`
where

`slippage_per_unit = max(0, Product.value(market_observable) - Product.value(exit_price))`

If `open_volume < 0`:

```formula
maintenance_margin
    = max(min(abs(open_volume) * slippage_per_unit, mark_price * (abs(open_volume) *  market.maxSlippageFraction[1] + abs(slippage_volume)^2 * market.maxSlippageFraction[2])),  0)
    + abs(open_volume) * [ quantitative_model.risk_factors_short ] . [ Product.value(market_observable) ]`
```

where

`slippage_per_unit = max(0, Product.value(market_observable) - Product.value(exit_price))`

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

- For the orders part of the margin: use `market_observable` =  volume weighted average price of the party's long / short orders.

Note that because the order book is empty during auctions we will always end up with the slippage value implied by the the slippage cap.

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

## exit price considers what selling the open position (10) on the order book would achieve.

slippage_per_unit =  max(0, Product.value(previous_mark_price) - Product.value(exit_price)) = max(0, Product.value($144) - Product.value((1*120 + 4*110 + 5*108)/10)) = max(0, 144 - 110)  = 34


maintenance_margin_long =max(min(riskiest_long * slippage_per_unit, product.value(market_observable)  * (riskiest_long * market.linearSlippageFactor)), 0)
 + max(open_volume, 0 ) * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ] + buy_orders * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]


=  max(min(14 * 34, 144*(14 * 0.25), 0) + 10 * 0.1 * 144 + 4 * 0.1 * 144 = max(min(476, 532.224), 0) + 10 * 0.1 * 144 + 4 * 0.1 * 144 = 677.6

# Step 2

Since riskiest short == 0 then maintenance_margin_short = 0

# Step 3

Since open_volume == 10

maintenance_margin = max(min(open_volume * slippage_per_unit, product.value(market_observable)  * (open_volume * market.maxSlippageFraction[1] + open_volume^2 * market.maxSlippageFraction[2])), 0)
    +  open_volume * [ quantitative_model.risk_factors_long ] . [ Product.value(market_observable) ]
 =  max(min(14 * 34, 144*(14 * 0.25 + 14 * 14 * 0.001), 0) + 10 * 0.1 * 144 = max(min(476, 532.224), 0) + 10 * 0.1 * 144 = 620

# Step 4

maintenance_margin_with_orders = max ( 677.6, 0) = 677.6
order_margin = 677.6 - 620 = 57.6

# Step 5

collateral_release_level = 677.6 * collateral_release_scaling_factor = 677.6 * 1.1
initial_margin = 677.6 * initial_margin_scaling_factor = 677.6 * 1.2
search_level = 677.6 * search_level_scaling_factor = 677.6 * 1.3

```

### EXAMPLE 2 - calculating correct slippage volume

Given the following trader positions:

| Tables        | Open           | Buys  | Sells |
| ------------- |:-------------:| -----:| -----:|
| case-1      | 1 | 1 | -2
| case-2      | -1 | 2| 0
| case-3 | 1 | 0 | -2

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

