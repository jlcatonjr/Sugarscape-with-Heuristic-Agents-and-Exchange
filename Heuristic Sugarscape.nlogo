; Food for thought: Emulate the effects of legal process by creating a delay between turtle death and turtle instantiation in order to emulate the effects of waves of legal proceedings.


; Code in network to the model
;


; Create switch for persistence of present proportions. Whena  turtle is first hatched,
; if it does not inheret from the parent it will be subject to present probabilities.

; MAY NEED TO DIFFERENTIATE BETWEE WATER BID/ASK AND SUGAR BID/ASK

; add arbitrageur
globals [
  gini-index-reserve
  lorenz-points
  number-of-transactions
  deaths
  age-of-death-list
  num-deaths
  deaths-this-tick
  ; sum-age-deaths
  ; mean-age-of-death
  mean-prices-for-last-fifty-ticks
  mean-price-memory-length
  mean-expected-price
  expected-price-variance

  prices-current-tick
  mean-price-current-tick
  mean-price-last-tick
  true-average-price-last-fifty-ticks
  number-of-transactions-last-fifty-ticks
  total-value-exchange-last-fifty-ticks

  sugar-consumed-this-tick
  water-consumed-this-tick
  total-sugar-consumed
  total-water-consumed
  winning-sugar-candidate
  winning-water-candidate

  ;;stats lists
  population
  total-sugar
  total-water
  sugar-minus-water
  ln-equilibrium-price
  mean-price
  mean-price-50-tick-average
  predicted-equilibrium-price
  sugar-demand-list
  sugar-supply-list
  price-variance
  sugar-turtles
  water-turtles
  mean-sugar-reserve-level
  mean-water-reserve-level
  basic
  switcher
  herder
  arbitrageur
  gini-coefficient-list
  final-output
  distance-from-equilibrium-price
  average-mutate-rate
  median-mutate-rate
  csv-name
  filename

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Class Identifiers
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  percent-basic
  percent-arbitrageur
  percent-herder
  percent-switcher

  basic-only
  basic-herder
  basic-arbitrageur
  basic-herder-arbitrageur
  switcher-only
  switcher-herder
  switcher-arbitrageur
  switcher-herder-arbitrageur

  percent-basic-only
  percent-basic-herder
  percent-basic-arbitrageur
  percent-basic-herder-arbitrageur
  percent-switcher-only
  percent-switcher-herder
  percent-switcher-arbitrageur
  percent-switcher-herder-arbitrageur

  ;; Wealth of Class

  wealth-basic
  wealth-switcher
  wealth-herder
  wealth-arbitrageur

  wealth-basic-only
  wealth-basic-herder
  wealth-basic-arbitrageur
  wealth-basic-herder-arbitrageur
  wealth-switcher-only
  wealth-switcher-herder
  wealth-switcher-arbitrageur
  wealth-switcher-herder-arbitrageur

  wealth-per-capita-basic-only
  wealth-per-capita-basic-herder
  wealth-per-capita-basic-arbitrageur
  wealth-per-capita-basic-herder-arbitrageur
  wealth-per-capita-switcher-only
  wealth-per-capita-switcher-herder
  wealth-per-capita-switcher-arbitrageur
  wealth-per-capita-switcher-herder-arbitrageur
]

turtles-own [
  self-mutate-rate
  sugar
  sugar-true?


  water           ;; the amount of sugar this turtle has
  water-true?

  wealth

  ticks-per-switch
  ticks-to-switch

  metabolism      ;; the amount of sugar that each turtles loses each tick
  vision          ;; the distance that this turtle can see in the horizontal and vertical directions
  vision-points
  trade-points    ;; the points that this turtle can see in relative to it's current position (based on vision)
  age             ;; the current age of this turtle (in ticks)
  max-age         ;; the age at which this turtle will die of natural causes

  reproductive?
  num-offspring
                  ;; used to clean up code
  price ;; sugar-bid-price = to bid-price, sugar-price = price
  water-price   ;; water-price = 1 / price
  pricing-strategy
  expected-sugar-price
  sugar-reserve-level
  water-reserve-level
  endogenous-rate-of-price-change


  past-sugar-price   ;; records price of last x trades
  price-difference
  price-memory
  max-wealth-trading-partner
  traded?           ;; did agent trade this period

  ;; agent strategies
  basic?
  herder?
  switcher?
  arbitrageur?

  transaction-price ;; price agreed upon for trade

 ;  Herders use these lists to record stats of known agents, and to copy

  who-list
  wealth-list
  basic?-list
  herder?-list
  switcher?-list
  arbitrageur?-list
  price-list
  water-price-list
  ; transaction-price-list
  ticks-per-switch-list
  max-desired-stock-list
  sugar-reserve-level-list
  water-reserve-level-list

  sugar-true?-list
  water-true?-list

]

patches-own [
  psugar           ;; the amount of sugar on this patch
  pwater           ;; water on patch
  max-psugar       ;; the maximum amount of sugar that can be on this patch
  max-pwater       ;; max water on patch
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup

  if maximum-sugar-endowment <= minimum-sugar-endowment [
    user-message "Oops: the maximum-sugar-endowment must be larger than the minimum-sugar-endowment"
    stop
  ]
  if maximum-water-endowment <= minimum-water-endowment [
    user-message "Oops: the maximum-water-endowment must be larger than the minimum-sugar-endowment"
    stop
  ]
  clear-all
  create-turtles initial-population [ turtle-setup ]
  setup-patches
  update-lorenz-and-gini
  setup-lists
  prep-csv-name
  reset-ticks
end

to turtle-setup ;; turtle procedure
  set traded? false
  set num-offspring 0
  set-strategy
  ;; all agents start with a price-ratio of 1 sugar : 1 water
  set price 1
  set water-price 1 / price
  if herder? [set max-wealth-trading-partner 0]
  set self-mutate-rate random-float mutate-rate

  move-to one-of patches with [not any? other turtles-here]
  set shape "circle"

  ; arbitrageur agents track past sugar prices
  set past-sugar-price 1
  ; arbitrageur must choose a length of time for considering past prices
  if arbitrageur?[ set price-memory 1 + random (max-price-memory - 1)]

  ; choose initial sugar and water holdings
  set sugar random-in-range minimum-sugar-endowment maximum-sugar-endowment
  set water random-in-range minimum-water-endowment maximum-water-endowment

  set metabolism 1 ; random-in-range 1 4
  set max-age random-in-range 600 1000
  set age 0
  set vision random-in-range 1 max-turtle-vision
  set-vision-and-trade-points
                                             ;; turtles can look horizontally and vertically up to vision patches
                                             ;; but cannot look diagonally at all

;  run visualization
end

to set-vision-and-trade-points
  set vision-points []
  set trade-points []
  foreach n-values vision [? + 1]
    [
      set vision-points sentence vision-points (list (list 0 ?) (list ? 0) (list 0 (- ?)) (list (- ?) 0))
    ]
    foreach n-values 1 [? + 1]
    [
      set trade-points sentence trade-points (list (list 0 ?) (list ? 0) (list 0 (- ?)) (list (- ?) 0))
    ]
end

to turtle-hatch  ;; turtle procedure
  set num-offspring 0
  set traded? false

  if mutate?
    [mutate]

  if reproductive? [
    ask myself[set num-offspring num-offspring + 1]
  ]

  ifelse age != max-age[
    set sugar maximum-sugar-endowment
    set water maximum-water-endowment
  ]
  [
    set sugar sugar
    set water water]
  set ticks-to-switch 0

  if herder? [set max-wealth-trading-partner 0 ]

  move-to one-of patches with [not any? other turtles-here]
  set shape "circle"

  set past-sugar-price 1


  set sugar random-in-range minimum-sugar-endowment maximum-sugar-endowment
  set water random-in-range minimum-water-endowment maximum-water-endowment


  set metabolism 1;random-in-range 1 4
  set max-age random-in-range 600 1000
  set age 0
  set vision max-turtle-vision; random-in-range 1 max-turtle-vision; random-in-range 1 6
                                                ;; turtles can look horizontally and vertically up to vision patches
                                                ;; but cannot look diagonally at all
  set vision-points []
  foreach n-values vision [? + 1]
  [
    set vision-points sentence vision-points (list (list 0 ?) (list ? 0) (list 0 (- ?)) (list (- ?) 0))
  ]
;  run visualization
end


to setup-patches
  file-open "sugar-map.txt"
  foreach sort patches
  [
    ask ?
    [
      ; these
      set max-psugar file-read
      set max-pwater max-psugar
      set psugar max-psugar
      set pwater max-pwater
    ]
  ]
  file-close
  ask patches[
    ifelse pycor <= pxcor[
      set max-psugar 0
    ]
    [
      set max-pwater 0
    ]
    patch-recolor

  ]
end

to check-reproduction
  ifelse sugar-reserve-level > maximum-sugar-endowment * 2 and water-reserve-level > maximum-water-endowment * 2
  [set reproductive? true]
  [set reproductive? false]
end

to set-strategy

  ; choose agent strategies
  ifelse random-float 1 < initial-percent-basic [
    set basic? true
    set switcher? false
  ]
  [
    set basic? false
    set switcher? true
  ]

  ; switchers choose to mine water or sugar at a given time
  ifelse switcher? [
    ifelse  pycor < pxcor
      [set sugar-true? true
        set water-true? false]
      [set sugar-true? false
        set water-true? true]
  ]
  [
    ;set color red
    set sugar-true? false
    set water-true? false
  ]

  ; agent is switcher if not basic
  ifelse random-float 1 < initial-percent-herders
  [set herder? true]
  [set herder? false]


  ifelse random-float 1 < initial-percent-arbitrageurs
  [set arbitrageur? true]
  [set arbitrageur? false]
  ;; price that arbitrageur will switch commodities
  if endogenous-arbitrageur-choice? [
      set-expected-sugar-price

  ]

  set ticks-per-switch random max-ticks-per-switch

  ; the probablity of selecting a value falls as the value rises

  set sugar-reserve-level 1 + (random (sqrt max-reserve-level  - 1)) ^ 2
  set water-reserve-level 1 + (random (sqrt max-reserve-level  - 1)) ^ 2



;  ifelse random-float 1 < probability-dynamic-pricing
  set pricing-strategy 0
;  [set pricing-strategy 1]

  set endogenous-rate-of-price-change random-float max-rate-of-endogenous-price-change

end


to mutate
if random-float 1 < self-mutate-rate [
  set self-mutate-rate random-float mutate-rate
]
mutate-classes
;; scalar required due to limit of random-float size
;if random-float 1 < mutate-rate [set sugar-reserve-level ln (1 + round random-float (e ^ (max-reserve-level - 1))) * reserve-level-scalar]; (random (sqrt max-reserve-level  - 1)) ^ 2]
;if random-float 1 < mutate-rate [set water-reserve-level ln (1 + round random-float (e ^ (max-reserve-level - 1))) * reserve-level-scalar];(random (sqrt max-reserve-level  - 1)) ^ 2]

   if random-float 1 < self-mutate-rate [set sugar-reserve-level 1 + ( random (sqrt max-reserve-level  - 1))^ 2]
   if random-float 1 < self-mutate-rate [set water-reserve-level 1 + (random (sqrt max-reserve-level  - 1))^ 2]


;; Not in use for experiments in Dissertation
if mutate-pricing-strategy? [
if random-float 1 < self-mutate-rate [
ifelse pricing-strategy = 0
  [set pricing-strategy 1]
  [set pricing-strategy 0]
]
]


if mutate-price-rate? [
  if random-float 1 < self-mutate-rate [
    ; endogenous-rate-of-price-change governs the magnitude of change in bid-ask prices
    set endogenous-rate-of-price-change random-float max-rate-of-endogenous-price-change
  ]
]

if arbitrageur?[
  if random-float 1 < self-mutate-rate [
    set price-memory 1 + random (max-price-memory - 1)]
]

if endogenous-arbitrageur-choice?[
  if random-float 1 < self-mutate-rate [
    set-expected-sugar-price

  ]
]

end

to set-expected-sugar-price
  set expected-sugar-price e ^ (ln (1 / max-expected-sugar-price) + random-float (ln max-expected-sugar-price - ln (1 / max-expected-sugar-price)))  ;exp (random-normal 1 1)]
;  set expected-sugar-price 1 / max-expected-sugar-price + random-float (max-expected-sugar-price - 1 / max-expected-sugar-price)  ;exp (random-normal 1 1)]
end

to mutate-classes
  if mutate-basic?[
  if random-float 1 < self-mutate-rate [
 ifelse basic? = false
    [
      set basic? true
      set switcher? false]
    [
      set basic? false
      set switcher? true
      set ticks-per-switch random 100]
  ]
]
if mutate-herder?[
  if random-float 1 < self-mutate-rate [
    ifelse herder? = false
    [set herder? true]
    [set herder? false]
  ]
]

if mutate-arbitrageur? [
    if random-float 1 < self-mutate-rate [
      ifelse arbitrageur? = false
      [set arbitrageur? true]
      [set arbitrageur? false]
    ]
]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  reset-global-stats
  set prices-current-tick []
  set age-of-death-list []
  if not any? turtles [
    stop
  ]
  ask patches [
    patch-growback
    patch-recolor
  ]
  ask turtles[
    set traded? false
    ; color represents class
    ; size represents wealth
    set-color-size

    ;Wealth is calculated as: good / (metabolism rate for good)
    update-wealth

    if Trade? [
     ; agents set bid-ask price
     set-prices
      ]

    turtle-move

    ;consume sugar, add good from patch to personal stock
    turtle-eat


    if Trade?[
      ; find neighbor, bargain, trade
      trade
    ]
    set age (age + 1)

    ; die if agent runs out of sugar or water
    if sugar <= 0 or water <= 0 [
      set age-of-death-list lput age age-of-death-list
      die
    ]
    if age > max-age [

      hatch 1
      [
        turtle-hatch
      ]
      set age-of-death-list lput age age-of-death-list
      die

    ]
    check-reproduction
    if reproductive? [
      if num-offspring < max-offspring [
        if sugar > sugar-reserve-level and water > water-reserve-level [
          if  sugar > maximum-sugar-endowment * 2 and water > maximum-water-endowment * 2 [

            hatch 1
            [
              turtle-hatch
            ]
            set sugar sugar - maximum-sugar-endowment
            set water water - maximum-water-endowment
          ]
        ]
      ]
    ]
;    run visualization

  ]
  reset-global-lists
  update-lorenz-and-gini
  prepare-behavior-space-output
  calculate-statistics
  write-csv csv-name final-output
  tick
end
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Turtle Procedures
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set-prices
  if sugar > 0 and water > 0[

; dynamic pricing
  if price - endogenous-rate-of-price-change * (ln(sugar / sugar-reserve-level) - ln(water / water-reserve-level))  > 0 and pricing-strategy = 0 [
    set price price - endogenous-rate-of-price-change * (ln(sugar / sugar-reserve-level) - ln(water / water-reserve-level))
  ];set water-price 1 / price]
  ]


; static pricing
  if pricing-strategy = 1[
    if water > water-reserve-level[
      if price < (1 /  rate-of-price-change)[
        raise-price
      ]]
    if water < water-reserve-level  [
      if price > rate-of-price-change [
        lower-price]] ; must have enough sugar to enact bid
    if sugar > sugar-reserve-level[
      if price > rate-of-price-change [
        lower-price]] ; must have enough water to enact bid
    if sugar < sugar-reserve-level [
      if price < ( 1 / rate-of-price-change)[
        raise-price]]
  ]
  set water-price 1 / price
  adjust-target-reserve-levels
end

to adjust-target-reserve-levels
  ; reserve levels rise if there is excess of both goods relative to target
  if sugar - sugar-reserve-level > 0 and water - water-reserve-level > 0 [

    set sugar-reserve-level sugar-reserve-level * 1.01
    set water-reserve-level water-reserve-level * 1.01
  ]
  if sugar - sugar-reserve-level < 0 and water - water-reserve-level < 0 [
  ; reserve levels falls if there is shortage of both goods relative to target


    set sugar-reserve-level sugar-reserve-level / 1.01
    set water-reserve-level water-reserve-level / 1.01      ]
end

to lower-price
  set price price / (1 + random-float endogenous-rate-of-price-change)
end

to raise-price
  set price price * (1 + random-float endogenous-rate-of-price-change)
end

to set-color-size
if basic? [
  if herder? = false and arbitrageur? = false[ set color black]
  if herder? and arbitrageur? = false[set color grey]
  if herder? = false and arbitrageur? [ set color red]
  if herder? and arbitrageur?[set color orange]
]
if switcher?[
  if herder? = false and arbitrageur? = false[ set color brown]
  if herder? and arbitrageur? = false[set color yellow]
  if herder? = false and arbitrageur? [set color green]
  if herder? and arbitrageur?[set color lime]
]

set size .25 * ln(sugar + water)
end

to update-wealth
  set wealth sugar / sugar-metabolism-scalar + water / water-metabolism-scalar
end

to turtle-move ;; turtle procedure

  let move-candidates (patch-set patch-here (patches at-points vision-points) with [not any? turtles-here])

  ; movement for unaugmented Basic
  if sugar-true? = false and water-true? = false [
    let winning-candidate move-candidates with-max [psugar + pwater] ; choose the patch with the most resources
    if any? winning-candidate [
      move-to min-one-of winning-candidate [distance myself]
    ]
  ]

  ;; switcher and arbitrageur moves
    if sugar-true? [
      let possible-winners-sugar move-candidates with-max [psugar]
      ifelse any? possible-winners-sugar and max [psugar] of possible-winners-sugar > 0; and pcolor <= yellow + 4.9
      [
        move-to min-one-of possible-winners-sugar [distance myself]
      ]
      [
        facexy [pxcor] of self - 1  [pycor] of self + 1
        fd vision
      ]
    ]

    if water-true? [
      let possible-winners-water move-candidates with-max [pwater]
      ifelse any? possible-winners-water and max [pwater] of possible-winners-water > 0; and pcolor >= blue + .9
      [
        move-to min-one-of possible-winners-water [distance myself]
      ]
      [
        facexy [pxcor] of self + 1  [pycor] of self - 1
        fd vision ;sqrt 2 * vision / 2
      ]
    ]
  update-switcher-arbitrageur-preferences
end


to trade

  ;; When trading, agents must  be sure to have enough resources to trade. This is defined in the while loop conditions
  ;; Also, not that the water price is the inverse of the (sugar) price. These are reestablished at the end of the run
  let trade-candidates (turtles at-points trade-points)

  ifelse global-trade? = false
  [ifelse trade-vision-distance? = false
    [set winning-sugar-candidate one-of trade-candidates with [(sugar - sugar-reserve-level) > 0]]
  [let vision-trade-candidates (turtles at-points vision-points)
    set winning-sugar-candidate one-of vision-trade-candidates with [(sugar - sugar-reserve-level) > 0]]]
   [ set winning-sugar-candidate one-of turtles with [sugar - sugar-reserve-level > 0]]

  if sugar < sugar-reserve-level and water > water-reserve-level [
    if winning-sugar-candidate != nobody [ ; running low on sugar, enough water to trade

      let candidate-price [price] of winning-sugar-candidate
      set-exchange-price price candidate-price


      ask winning-sugar-candidate [set transaction-price [transaction-price] of myself]
      execute-trades winning-sugar-candidate transaction-price true

    ]
  ]
;  ]
  ; the bid-price for water is the inverse of an agent's price for sugar (your willingness to accept for water is equal to willingnes to pay for sugar)
  ; the price for water is the inverse of an agent's bid-price for sugar


    ifelse global-trade? = false
  [ifelse trade-vision-distance? = false
    [set winning-water-candidate one-of trade-candidates with [(water - water-reserve-level) > 0]]
  [let vision-trade-candidates (turtles at-points vision-points)
    set winning-water-candidate one-of vision-trade-candidates with [(water - water-reserve-level) > 0]]]
   [ set winning-water-candidate one-of turtles with [water - water-reserve-level > 0]]

  if sugar > sugar-reserve-level and water < water-reserve-level [

    if winning-water-candidate != nobody [


      let candidate-price [water-price] of winning-water-candidate
      set-exchange-price water-price candidate-price




        ask winning-water-candidate [set transaction-price [transaction-price] of myself]

          execute-trades winning-water-candidate transaction-price false

      ]
    ]
  ;]
  ifelse show-price?
  [set label int transaction-price]
  [set label ""]
end

to execute-trades [ candidate p sugar? ]
    if p != 0 [

      trade-loop candidate p sugar?
      ask candidate [
        if herder? [
          if [wealth] of myself > max-wealth-trading-partner[
            if [wealth] of myself > wealth[

              set max-wealth-trading-partner [wealth] of myself
              set basic? [basic?] of myself
              set switcher? [switcher?] of myself
              set arbitrageur? [arbitrageur?] of myself
              if arbitrageur? [set expected-sugar-price [expected-sugar-price] of myself]
              set ticks-per-switch [ticks-per-switch] of myself
;              set sugar-reserve-level [sugar-reserve-level] of myself
;              set water-reserve-level [water-reserve-level] of myself

            ]
          ]
        ]
      ]


        if herder? [
          if [wealth] of candidate  > wealth[
            if [wealth] of candidate  > max-wealth-trading-partner[
              set max-wealth-trading-partner [wealth] of candidate
              set basic? [basic?] of candidate
              set switcher? [switcher?] of candidate
              set arbitrageur? [arbitrageur?] of candidate
              if arbitrageur? [set expected-sugar-price [expected-sugar-price] of candidate]
              set ticks-per-switch [ticks-per-switch] of candidate
;              set sugar-reserve-level [sugar-reserve-level] of candidate
;              set water-reserve-level [water-reserve-level] of candidate
            ]
          ]
        ]
          ;        record-prices
          set traded? true     ;; use traded? to identify transaction prices of period
          ask candidate[
            ;          record-prices
            set traded? true
          ]
      ]
end


to set-exchange-price[my-price candidate-price]
    if my-price > candidate-price [
      set transaction-price ln candidate-price + (random-float (ln (my-price) - ln candidate-price)) ; price in units of sugar per unit of water
      set transaction-price e ^ transaction-price]
end

to trade-loop[candidate p sugar?]
  ; agents trade one good at a time until the conditions for trading is no longer satifisfied
ifelse sugar?[
      while [[sugar] of candidate > [sugar-reserve-level] of candidate and water > water-reserve-level and water > p] ; winning candidate will trade if sugar above reserve level
     [
        set sugar sugar + 1
        set water water - p
        if arbitrageur?[record-prices price true]
        ask candidate [
          set sugar sugar - 1
          set water water + p
          if arbitrageur?[record-prices price true]

        ]
        set prices-current-tick lput ln p prices-current-tick
      ]
]

        [while[[water] of candidate > [water-reserve-level] of candidate and sugar > sugar-reserve-level and sugar > (p) ]
        [

          set water water + 1
          set sugar sugar - p
          if arbitrageur?[record-prices p false]
          ask winning-water-candidate [
            set water water - 1
            set sugar sugar + p
            if arbitrageur?[record-prices p false]
          ]
          set prices-current-tick lput ln (1 / p) prices-current-tick
        ]
        ]

end
to record-prices [p sugar?]
  ifelse sugar?[
set past-sugar-price (p + past-sugar-price * price-memory) / (price-memory + 1)
set price-difference (expected-sugar-price - past-sugar-price ) / expected-sugar-price
  ]
  [
    set past-sugar-price (1 / p + past-sugar-price * price-memory) / (price-memory + 1)
    set price-difference (expected-sugar-price - past-sugar-price ) / expected-sugar-price
  ]
end

to update-switcher-arbitrageur-preferences
if switcher?[ set ticks-to-switch ticks-to-switch + 1
  if sugar-true? [
    if ticks-to-switch = ticks-per-switch[ ; or water < water-reserve-level [
      set sugar-true? false
      set water-true? true

      ;;switcher rate adjusts according to ratio of consumption-rates
      if economic-switching?[set ticks-per-switch ticks-per-switch  * (water-metabolism-scalar / sugar-metabolism-scalar)]
      set ticks-to-switch 0]
  ]
  if water-true? [
    if ticks-to-switch = ticks-per-switch
    [; or sugar < sugar-reserve-level [


      set sugar-true? true
      set water-true? false

      if economic-switching?[ set ticks-per-switch ticks-per-switch * (sugar-metabolism-scalar / water-metabolism-scalar)]

      set ticks-to-switch 0]
  ]
  ]
  if arbitrageur? [; and water > water-reserve-level and sugar > sugar-reserve-level[

    if endogenous-arbitrageur-choice? [
      ifelse price-difference < 0 [
        set sugar-true? true
        set water-true? false
      ]
      [ if price-difference > 0 [
        set sugar-true? false
        set water-true? true]
      ]
    ]
    if endogenous-arbitrageur-choice? = false[
      ifelse price-difference > 0[
        set sugar-true? true
        set water-true? false
      ]
      [
        set sugar-true? false
        set water-true? true
      ]
    ]
  ]
end




to-report max-item [ #wealth-list]
  let $max-value first #wealth-list
  let $max-item 0
  let $item 1
  foreach but-first #wealth-list
  [ if ? > $max-value [ set $max-value ? set $max-item $item]
    set $item $item + 1
  ]
  report $max-item
end

to turtle-eat ;; turtle procedure
              ;; metabolize some sugar, and eat all the sugar on the current patch
;
;  ifelse random 1 < .5 [
;  set sugar (sugar - metabolism * sugar-metabolism-scalar + psugar)
;  set psugar 0
;  set water (water - metabolism * water-metabolism-scalar + pwater)
;  set pwater 0]


  set water (water - metabolism * water-metabolism-scalar + pwater)
  set pwater 0
  set sugar (sugar - metabolism * sugar-metabolism-scalar + psugar)
  set psugar 0

  if sugar > 0 [set sugar-consumed-this-tick sugar-consumed-this-tick + sugar-metabolism-scalar * metabolism]
  if water > 0[set water-consumed-this-tick water-consumed-this-tick + water-metabolism-scalar * metabolism]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; patch recovery
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to patch-recolor ;; patch procedure
                 ;; color patches based on the amount of sugar they have
  ifelse max-psugar > 0 [
    set pcolor (yellow + 4.9 - psugar)
  ]
  [
    ifelse max-pwater > 0 [
      set pcolor (blue + 4.9 - pwater)
    ]
    [
      set pcolor (yellow + 4.9)
    ]
  ]
end

to patch-growback ;; patch procedure
                  ;; gradually grow back all of the sugar for the patch
  set psugar min (list max-psugar (psugar + 1))
  set pwater min (list max-pwater (pwater + 1))
end

to setup-lists
  set mean-prices-for-last-fifty-ticks []
  set prices-current-tick []
  set number-of-transactions-last-fifty-ticks []
  set total-value-exchange-last-fifty-ticks []
;  set sugar-demand-list [][]
;  set sugar-supply-list [][]
  set ln-equilibrium-price ln (sugar-metabolism-scalar / water-metabolism-scalar)
end

to reset-global-stats
  set total-sugar-consumed total-sugar-consumed + sugar-consumed-this-tick
  set total-water-consumed total-water-consumed + water-consumed-this-tick
  set sugar-consumed-this-tick 0
  set water-consumed-this-tick 0
end

to reset-global-lists
;  set sugar-supply-list
;  set sugar-demand-list
  set num-deaths num-deaths + length age-of-death-list
  set deaths-this-tick length age-of-death-list
;  set sum-age-deaths sum-age-deaths + sum age-of-death-list
;  if num-deaths > 0 [set mean-age-of-death sum-age-deaths / num-deaths]
  set age-of-death-list []
  end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Gini-coefficient, Lorenz Curve
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-lorenz-and-gini
  let num-people count turtles
  let sorted-wealths sort [sugar + water] of turtles
  let total-wealth sum sorted-wealths
  let wealth-sum-so-far 0
  let index 0
  set gini-index-reserve 0
  set lorenz-points []
  repeat num-people [
    set wealth-sum-so-far (wealth-sum-so-far + item index sorted-wealths)
    set lorenz-points lput ((wealth-sum-so-far / total-wealth) * 100) lorenz-points
    set index (index + 1)
    set gini-index-reserve
    gini-index-reserve +
    (index / num-people) -
    (wealth-sum-so-far / total-wealth)
  ]
end

;;
;; Utilities
;;

to-report random-in-range [low high]
  report low + random (high - low + 1)
end

;;
;; Visualization Procedures
;;

to no-visualization ;; turtle procedure
                    ;  set color red
end

to color-agents-by-vision ;; turtle procedure
  set color red - (vision - 3.5)
end

to color-agents-by-metabolism ;; turtle procedure
  set color red + (metabolism - 2.5)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Stats and Lists
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to calculate-statistics
  ;; set median and variance of price and
  if length prices-current-tick > 0
  [
    set mean-price-current-tick mean prices-current-tick
    if length prices-current-tick > 1 [set price-variance variance prices-current-tick]
  ]

  ;
  if length prices-current-tick > 0
  [set mean-prices-for-last-fifty-ticks lput (mean-price-current-tick) mean-prices-for-last-fifty-ticks ]
  if length mean-prices-for-last-fifty-ticks > 0
  [set mean-price-50-tick-average mean mean-prices-for-last-fifty-ticks]

  if length mean-prices-for-last-fifty-ticks  > 50 [set mean-prices-for-last-fifty-ticks remove-item 0 mean-prices-for-last-fifty-ticks ]
  set number-of-transactions-last-fifty-ticks lput number-of-transactions number-of-transactions-last-fifty-ticks
  if length number-of-transactions-last-fifty-ticks > 50 [set number-of-transactions-last-fifty-ticks  remove-item 0 number-of-transactions-last-fifty-ticks ]

  set average-mutate-rate mean [self-mutate-rate] of turtles
  set median-mutate-rate median [self-mutate-rate] of turtles
  set number-of-transactions 0

  set basic-only count turtles with [basic? and herder? = false and arbitrageur? = false]
  set basic-herder count turtles with [basic? and herder? and arbitrageur? = false]
  set basic-arbitrageur count turtles with [basic? and herder? = false and arbitrageur?]
  set basic-herder-arbitrageur count turtles with [basic? and herder? and arbitrageur?]
  set switcher-only count turtles with [switcher? and herder? = false and arbitrageur? = false]
  set switcher-herder count turtles with [switcher? and herder? and arbitrageur? = false]
  set switcher-arbitrageur count turtles with [switcher? and herder? = false and arbitrageur?]
  set switcher-herder-arbitrageur count turtles with [switcher? and herder? and arbitrageur?]

;  set percent-basic-only basic-only / count turtles
;  set percent-basic-herder basic-herder / count turtles
;  set percent-basic-arbitrageur basic-arbitrageur / count turtles
;  set percent-basic-herder-arbitrageur basic-herder-arbitrageur / count turtles
;  set percent-switcher-only switcher-only / count turtles
;  set percent-switcher-herder switcher-herder / count turtles
;  set percent-switcher-arbitrageur switcher-arbitrageur / count turtles
;  set percent-switcher-herder-arbitrageur switcher-herder-arbitrageur / count turtles
;
  set basic count turtles with [basic? = true]
  set switcher count turtles with [basic? = false]
  set herder count turtles with [herder? = true]
  set arbitrageur count turtles with [arbitrageur? = true]

  set percent-basic basic / count turtles
  set percent-switcher 1 - percent-basic
  set percent-herder herder / count turtles
  set percent-arbitrageur arbitrageur /  count turtles

;  set excess-sugar-demand sum [sugar-reserve-level - sugar] of turtles with [sugar-reserve-level - sugar > 0 and (water - water-reserve-level) / price > sugar-reserve-level - sugar]
;  set excess-sugar-demand excess-sugar-demand +  sum [(water - water-reserve-level) / price] of turtles with [sugar-reserve-level - sugar > 0 and (water - water-reserve-level) / price < sugar-reserve-level - sugar]
;
;  set excess-sugar-supply sum [sugar - sugar-reserve-level] of turtles with [sugar - sugar-reserve-level > 0 ]
;
;
;  set excess-water-demand sum [water-reserve-level - water] of turtles with [water-reserve-level - water > 0 and (sugar - sugar-reserve-level) * price > water-reserve-level - water]
;  set excess-water-demand excess-water-demand +  sum [(sugar - sugar-reserve-level) * price] of turtles with [water-reserve-level - water > 0 and (sugar - sugar-reserve-level) * price < water-reserve-level - water]
;
;  set excess-water-supply sum [water - water-reserve-level] of turtles with [water - water-reserve-level > 0 ]

  set total-sugar sum [sugar] of turtles
  set total-water sum [water] of turtles
  set sugar-minus-water sum[sugar - water] of turtles
  set population count turtles
  set predicted-equilibrium-price sugar-metabolism-scalar / water-metabolism-scalar
  set sugar-turtles  count turtles with [sugar-true? = true]
  set water-turtles count turtles with [water-true? = true]
  ifelse count turtles with [arbitrageur?] > 1 [
    set mean-price-memory-length  mean [price-memory] of turtles with [arbitrageur?]
    set mean-expected-price mean [expected-sugar-price] of turtles with [arbitrageur?]
    set expected-price-variance variance [expected-sugar-price] of turtles with [arbitrageur?]
  ]
  [ifelse count turtles with [arbitrageur?] > 0[
    set mean-price-memory-length  [price-memory] of one-of turtles with [arbitrageur?]
    set mean-expected-price [expected-sugar-price] of one-of turtles with [arbitrageur?]
    set expected-price-variance 0
  ]
  [ set mean-price-memory-length  0
    set mean-expected-price 0
    set expected-price-variance 0
  ]
  ]






    if Trade?
    [
      set mean-sugar-reserve-level mean [sugar-reserve-level] of turtles
      set mean-water-reserve-level mean [water-reserve-level] of turtles
    ]

  if length prices-current-tick > 0
  [set distance-from-equilibrium-price (mean-price-current-tick) - ln (predicted-equilibrium-price)] ;; mean price is already logged


 ;; Wealth meaasured according to long-run equilibrium prices
  set wealth-basic-only sum [sugar] of turtles with [basic? and herder? = false and arbitrageur? = false] / sugar-metabolism-scalar
  + sum [water] of turtles with [basic? and herder? = false and arbitrageur? = false] / water-metabolism-scalar
  set wealth-basic-herder sum [sugar] of turtles with [basic? and herder? and arbitrageur? = false] / sugar-metabolism-scalar
  + sum [water] of turtles with [basic? and herder? and arbitrageur? = false] / water-metabolism-scalar
  set wealth-basic-arbitrageur sum [sugar] of turtles with [basic? and herder? = false and arbitrageur? ] / sugar-metabolism-scalar
  + sum [water] of turtles with [basic? and herder? = false and arbitrageur? ] / water-metabolism-scalar
  set wealth-basic-herder-arbitrageur sum [sugar] of turtles with [basic? and herder? and arbitrageur? ] / sugar-metabolism-scalar
  + sum [water] of turtles with [basic? and herder? and arbitrageur?] / water-metabolism-scalar

  set wealth-switcher-only sum [sugar] of turtles with [basic? = false and herder? = false and arbitrageur? = false] / sugar-metabolism-scalar
  + sum [water] of turtles with [basic? = false and herder? = false and arbitrageur? = false] / water-metabolism-scalar
  set wealth-switcher-herder sum [sugar] of turtles with [basic? = false and herder? and arbitrageur? = false] / sugar-metabolism-scalar
  + sum [water] of turtles with [basic? = false and herder? and arbitrageur? = false] / water-metabolism-scalar
  set wealth-switcher-arbitrageur sum [sugar] of turtles with [basic? = false and herder? = false and arbitrageur? ] / sugar-metabolism-scalar
  + sum [water] of turtles with [basic? = false and herder? = false and arbitrageur? ] / water-metabolism-scalar
  set wealth-switcher-herder-arbitrageur sum [sugar] of turtles with [basic? = false and herder?  and arbitrageur? ] / sugar-metabolism-scalar
  + sum [water] of turtles with [basic? = false and herder? and arbitrageur? ] / water-metabolism-scalar

  set wealth-basic sum [sugar] of turtles with [basic? ] / sugar-metabolism-scalar
  + sum [water] of turtles with [basic?] / water-metabolism-scalar

  set wealth-switcher sum [sugar] of turtles with [basic? = false ] / sugar-metabolism-scalar
  + sum [water] of turtles with [basic? = false] / water-metabolism-scalar

  set wealth-herder sum [sugar] of turtles with [herder? ] / sugar-metabolism-scalar
  + sum [water] of turtles with [herder?] / water-metabolism-scalar

  set wealth-arbitrageur sum [sugar] of turtles with [arbitrageur? ] / sugar-metabolism-scalar
  + sum [water] of turtles with [arbitrageur?] / water-metabolism-scalar
end

to prepare-behavior-space-output


  set final-output (list
    sugar-metabolism-scalar
    water-metabolism-scalar
    mutate-rate
    total-sugar
    total-water
    mean-price-current-tick
    price-variance
    population
    average-mutate-rate
    median-mutate-rate


    sugar-consumed-this-tick
    water-consumed-this-tick
    distance-from-equilibrium-price
    mean-price-50-tick-average
    mean-sugar-reserve-level
    mean-water-reserve-level
    mean [endogenous-rate-of-price-change] of turtles
    mean-price-memory-length
    mean-expected-price
    expected-price-variance

    basic-only
    basic-herder
    basic-arbitrageur
    basic-herder-arbitrageur
    switcher-only
    switcher-herder
    switcher-arbitrageur
    switcher-herder-arbitrageur

;    percent-basic
;    percent-arbitrageur
;    percent-herder
;    percent-switcher

    basic
    switcher
    herder
    arbitrageur
    wealth-basic
    wealth-switcher
    wealth-herder
    wealth-arbitrageur

;    percent-basic-only
;    percent-basic-herder
;    percent-basic-arbitrageur
;    percent-basic-herder-arbitrageur
;    percent-switcher-only
;    percent-switcher-herder
;    percent-switcher-arbitrageur
;    percent-switcher-herder-arbitrageur
;

    wealth-basic-only
    wealth-basic-herder
    wealth-basic-arbitrageur
    wealth-basic-herder-arbitrageur
    wealth-switcher-only
    wealth-switcher-herder
    wealth-switcher-arbitrageur
    wealth-switcher-herder-arbitrageur

;    wealth-per-capita-basic-only
;    wealth-per-capita-basic-herder
;    wealth-per-capita-basic-arbitrageur
;    wealth-per-capita-basic-herder-arbitrageur
;    wealth-per-capita-switcher-only
;    wealth-per-capita-switcher-herder
;    wealth-per-capita-switcher-arbitrageur
;    wealth-per-capita-switcher-herder-arbitrageur

    )
end

to write-csv [ #filename #items ]
  ;; #items is a list of the data (or headers!) to write.
  if is-list? #items and not empty? #items
  [ file-open #filename
    ;; quote non-numeric items
    set #items map quote #items
    ;; print the items
    ;; if only one item, print it.
    ifelse length #items = 1 [ file-print first #items ]
    [file-print reduce [ (word ?1 "," ?2) ] #items]
    ;; close-up
    file-close
  ]
end

to prep-csv-name
  set csv-name "0sugarscapemutate25shock10000movingreservelevels10final.csv"
  set csv-name replace-item 0 csv-name (word behaviorspace-run-number)

end

to-report quote [ #thing ]
  ifelse is-number? #thing
  [ report #thing ]
  [ report (word "\"" #thing "\"") ]
end

; Copyright 2009 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
970
8
1380
439
-1
-1
8.0
1
10
1
1
1
0
0
0
1
0
49
0
49
1
1
1
ticks
30.0

BUTTON
0
308
80
348
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
90
308
180
348
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
190
308
280
348
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
-1
5
279
38
initial-population
initial-population
10
3000
500
10
1
NIL
HORIZONTAL

SLIDER
-1
38
279
71
minimum-sugar-endowment
minimum-sugar-endowment
0
200
5
1
1
NIL
HORIZONTAL

SLIDER
-1
71
279
104
maximum-sugar-endowment
maximum-sugar-endowment
0
200
25
1
1
NIL
HORIZONTAL

SLIDER
-1
104
279
137
minimum-water-endowment
minimum-water-endowment
0
200
5
1
1
NIL
HORIZONTAL

SLIDER
-1
137
279
170
maximum-water-endowment
maximum-water-endowment
0
200
25
1
1
NIL
HORIZONTAL

SLIDER
1
170
178
203
sugar-metabolism-scalar
sugar-metabolism-scalar
0
2
1
.05
1
NIL
HORIZONTAL

SLIDER
430
100
608
133
initial-percent-herders
initial-percent-herders
0
1
0
.01
1
NIL
HORIZONTAL

SLIDER
533
318
705
351
max-reserve-level
max-reserve-level
0
10000
2500
50
1
NIL
HORIZONTAL

SWITCH
788
113
893
146
Trade?
Trade?
0
1
-1000

SWITCH
298
10
412
43
show-price?
show-price?
1
1
-1000

SWITCH
600
100
747
133
mutate-herder?
mutate-herder?
0
1
-1000

SLIDER
430
67
602
100
initial-percent-basic
initial-percent-basic
0
1
1
.01
1
NIL
HORIZONTAL

SLIDER
730
65
902
98
max-ticks-per-switch
max-ticks-per-switch
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
3
240
181
273
max-turtle-vision
max-turtle-vision
0
6
1
1
1
NIL
HORIZONTAL

SLIDER
430
133
607
166
initial-percent-arbitrageurs
initial-percent-arbitrageurs
0
1
0
.01
1
NIL
HORIZONTAL

SLIDER
1
206
180
239
water-metabolism-scalar
water-metabolism-scalar
0
2
0.5
.05
1
NIL
HORIZONTAL

SLIDER
533
285
705
318
rate-of-price-change
rate-of-price-change
0
.4
0.1
.005
1
NIL
HORIZONTAL

SWITCH
450
10
554
43
mutate?
mutate?
0
1
-1000

SLIDER
552
10
725
43
mutate-rate
mutate-rate
0
.5
0.25
.001
1
NIL
HORIZONTAL

SLIDER
430
182
602
215
probability-dynamic-pricing
probability-dynamic-pricing
0
1
1
.01
1
NIL
HORIZONTAL

SLIDER
3
275
181
308
max-offspring
max-offspring
0
100
20
1
1
NIL
HORIZONTAL

SWITCH
600
65
729
98
mutate-basic?
mutate-basic?
0
1
-1000

SWITCH
600
132
766
165
mutate-arbitrageur?
mutate-arbitrageur?
0
1
-1000

SWITCH
600
182
784
215
mutate-pricing-strategy?
mutate-pricing-strategy?
1
1
-1000

SWITCH
660
250
813
283
mutate-price-rate?
mutate-price-rate?
0
1
-1000

SLIDER
430
250
663
283
max-rate-of-endogenous-price-change
max-rate-of-endogenous-price-change
0
2
1.5
.1
1
NIL
HORIZONTAL

SWITCH
610
216
867
249
endogenous-arbitrageur-choice?
endogenous-arbitrageur-choice?
0
1
-1000

SLIDER
430
215
619
248
max-expected-sugar-price
max-expected-sugar-price
0
20
5
1
1
NIL
HORIZONTAL

TEXTBOX
570
42
645
60
Agent Class\n
11
0.0
1

TEXTBOX
531
167
710
194
Pricing Objects and Mechanisms
11
0.0
1

TEXTBOX
323
295
535
323
If Exogenous Rate of Price Change -->
11
0.0
1

TEXTBOX
308
65
426
94
Primary Classes: \nBasic and Switcher -->
11
0.0
1

TEXTBOX
280
117
448
147
Secondary Classes:\nHerder and Entrepreneur -->
11
0.0
1

TEXTBOX
202
228
441
256
Max Entrepreneurs Expected Sugar Price -->
11
0.0
1

TEXTBOX
257
194
441
223
Initial Pricing Strategy Setting -->
11
0.0
1

TEXTBOX
193
258
442
288
Endogenous Rate of Price Change Settings -->
11
0.0
1

TEXTBOX
305
330
529
357
Defines Scope of Reserve Preference -->
11
0.0
1

TEXTBOX
280
50
530
80
Initial Class Proportions on LHS
11
0.0
1

SWITCH
788
147
913
180
global-trade?
global-trade?
1
1
-1000

SWITCH
787
182
962
215
trade-vision-distance?
trade-vision-distance?
1
1
-1000

SWITCH
730
33
903
66
economic-switching?
economic-switching?
1
1
-1000

PLOT
23
720
755
951
Mutate Rate
NIL
NIL
0.0
10.0
0.0
0.05
true
true
"" ""
PENS
"Average" 1.0 0 -16777216 true "" "plot average-mutate-rate"
"Median" 1.0 0 -7500403 true "" "plot median-mutate-rate"

PLOT
25
370
789
720
Prices
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Log Mean Price" 1.0 2 -6565750 true "" "ifelse ticks > 200 [plot mean-price-current-tick]\n[plot 0]"
"50-Period RAP" 1.0 2 -16777216 true "" "ifelse ticks > 200 [plot mean mean-prices-for-last-fifty-ticks]\n[plot 0]"
"E(Price)" 1.0 0 -2674135 true "" "plot ln (sugar-metabolism-scalar / water-metabolism-scalar)"

PLOT
1472
706
2154
926
Population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

PLOT
1475
456
2236
706
Class Composition
NIL
NIL
0.0
10.0
0.0
0.4
true
true
"" ""
PENS
"Basic" 1.0 0 -16777216 true "" "plot percent-basic"
"Herder" 1.0 0 -7500403 true "" "plot percent-herder"
"Arbitrageur" 1.0 0 -2674135 true "" "plot percent-arbitrageur"
"Switcher" 1.0 0 -6459832 true "" "plot percent-switcher"

SLIDER
707
287
881
320
max-price-memory
max-price-memory
0
100
100
1
1
NIL
HORIZONTAL

PLOT
795
733
1450
964
Mean Reserve Levels
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Sugar" 1.0 0 -16777216 true "" "plot mean-sugar-reserve-level"
"Water" 1.0 0 -7500403 true "" "plot mean-water-reserve-level"

PLOT
789
441
1467
733
Wealth Per Capita
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Basic" 1.0 0 -16777216 true "" "ifelse basic > 0 [plot wealth-basic / basic]\n[plot 0]"
"Herder" 1.0 0 -7500403 true "" "ifelse herder > 0 [plot wealth-herder / herder]\n[plot 0]"
"Arbitrageur" 1.0 0 -2674135 true "" "ifelse arbitrageur > 0 [plot wealth-arbitrageur / arbitrageur]\n[plot 0]"
"Switcher" 1.0 0 -6459832 true "" "ifelse switcher > 0 [plot wealth-switcher / switcher]\n[plot 0]"
"Overall" 1.0 0 -5825686 true "" "plot (wealth-basic + wealth-switcher) / population"

@#$#@#$#@


## WHAT IS IT?

This model extends Wilensky's third model of Sugarscape to include economic exchange by ecologically rational agents.

## HOW IT WORKS

Each patch contains some sugar or water, the maximum amount of which is predetermined. At each tick, each patch regains one unit of sugar or water, until it reaches the maximum amount.

The amount of sugar or water a patch currently contains is indicated by its color; the darker the yellow, the more sugar or water.

At setup, agents are placed at random within the world. Each agent can only see a certain distance horizontally and vertically. At each tick, each agent will move to the nearest unoccupied location within their vision range with the most sugar or water, and collect all the sugar or water there.  If its current location has as much or more sugar or water than any unoccupied location it can see, it will stay put.

Agents also use (and thus lose) a certain amount of sugar or water each tick, based on their metabolism rates. If an agent runs out of sugar or water, it dies.

Each agent also has a maximum age, which is assigned randomly from the range 60 to 100 ticks.  When the agent reaches an age beyond its maximum age, it dies.

Whenever an agent dies (either from starvation or old age), a new randomly initialized agent is created somewhere in the world; hence, in this model the global population count stays constant.

## HOW TO USE IT

The INITIAL-POPULATION slider sets how many agents are in the world.

The MINIMUM-SUGAR-ENDOWMENT and MAXIMUM-SUGAR-ENDOWMENT sliders set the initial amount of sugar ("wealth") each agent has when it hatches. The actual value is randomly chosen from the given range.

Press SETUP to populate the world with agents and import the sugar map data. GO will run the simulation continuously, while GO ONCE will run one tick.

The VISUALIZATION chooser gives different visualization options and may be changed while the GO button is pressed. When NO-VISUALIZATION is selected all the agents will be red. When COLOR-AGENTS-BY-VISION is selected the agents with the longest vision will be darkest and, similarly, when COLOR-AGENTS-BY-METABOLISM is selected the agents with the lowest metabolism will be darkest.


Choose the composition of agent rules by sliding the percent-basic slider. This choose
the number of agents that will be Basic, meaning that they search for the highest valued patch of sugar or water simultaneously. The remaining portion of the population will be Switchers. They look for one resource at a timea nd switch back and forth every time period.

Basics and Switchers may also be Herders and/or Entrepreneurs. These rule sets are not mutually exclusive. Set them using the percent-herders and percent-entrepreneurs sliders.


## THINGS TO TRY

The behavior space for this model is very large. Varying the parameters used will yield different types of patterns for prices, output, rule composition, etc...


How does the initial population affect the wealth distribution? How long does it take for the skewed distribution to emerge?

How is the wealth distribution affected when you change the initial endowments of wealth?

## NETLOGO FEATURES

All of the Sugarscape models create the world by using `file-read` to import data from an external file, `sugar-map.txt`. This file defines both the initial and the maximum sugar value for each patch in the world.

Since agents cannot see diagonally we cannot use `in-radius` to find the patches in the agents' vision.  Instead, we use `at-points`.

# DATA OUTPUT
Data is recorded in a csv. Code for this is at the end of the file under functions "prepare-behavior-space-output", "write-csv", and "quote [ #thing ]"

## RELATED MODELS

Other models in the NetLogo Sugarscape suite include:

* Sugarscape 1 Immediate Growback
* Sugarscape 2 Constant Growback
* Sugarscape 3 Wealth Inequality

For more explanation of the Lorenz curve and the Gini index, see the Info tab of the Wealth Distribution model.  (That model is also based on Epstein and Axtell's Sugarscape model, but more loosely.)

## CREDITS AND REFERENCES

Epstein, J. and Axtell, R. (1996). Growing Artificial Societies: Social Science from the Bottom Up.  Washington, D.C.: Brookings Institution Press.
 Li, J. and Wilensky, U. (2009).  NetLogo Sugarscape 3 Wealth Distribution model.  http://ccl.northwestern.edu/netlogo/models/Sugarscape3WealthDistribution.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2009 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>output-results</final>
    <timeLimit steps="100000"/>
    <metric>total-sugar-list</metric>
    <metric>total-water-list</metric>
    <metric>sugar-minus-water-list</metric>
    <metric>median-price-list</metric>
    <metric>price-variance-list</metric>
    <metric>mean-age-of-death-list</metric>
    <metric>sugar-turtles-list</metric>
    <metric>water-turtles-list</metric>
    <metric>median-sugar-reserve-level-list</metric>
    <metric>median-water-reserve-level-list</metric>
    <metric>percent-switcher-list</metric>
    <metric>percent-basic-list</metric>
    <metric>percent-herder-list</metric>
    <metric>percent-arbitrageur-list</metric>
    <metric>median-arb-wealth-list</metric>
    <metric>median-non-arb-wealth-list</metric>
    <metric>gini-coefficient-list</metric>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="herding?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turtle-vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-max-desired-stock">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Basic Only" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>output-results</final>
    <timeLimit steps="50000"/>
    <metric>total-sugar-list</metric>
    <metric>total-water-list</metric>
    <metric>sugar-minus-water-list</metric>
    <metric>median-price-list</metric>
    <metric>price-variance-list</metric>
    <metric>sugar-turtles-list</metric>
    <metric>water-turtles-list</metric>
    <metric>median-sugar-reserve-level-list</metric>
    <metric>median-water-reserve-level-list</metric>
    <metric>percent-switcher-list</metric>
    <metric>percent-basic-list</metric>
    <metric>percent-herder-list</metric>
    <metric>percent-arbitrageur-list</metric>
    <metric>median-arb-wealth-list</metric>
    <metric>median-non-arb-wealth-list</metric>
    <metric>gini-coefficient-list</metric>
    <metric>basic-only</metric>
    <metric>basic-herder</metric>
    <metric>basic-entrepreneur</metric>
    <metric>basic-herder-entrepreneur</metric>
    <metric>switcher-only</metric>
    <metric>switcher-herder</metric>
    <metric>switcher-entrepreneur</metric>
    <metric>switcher-herder-entrepreneur</metric>
    <metric>wealth-basic-only</metric>
    <metric>wealth-basic-herder</metric>
    <metric>wealth-basic-entrepreneur</metric>
    <metric>wealth-basic-herder-entrepreneur</metric>
    <metric>wealth-switcher-only</metric>
    <metric>wealth-switcher-herder</metric>
    <metric>wealth-switcher-entrepreneur</metric>
    <metric>wealth-switcher-herder-entrepreneur</metric>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="herding?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-entrepreneur?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Basic Entrepreneur" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>output-results</final>
    <timeLimit steps="25000"/>
    <metric>total-sugar-list</metric>
    <metric>total-water-list</metric>
    <metric>sugar-minus-water-list</metric>
    <metric>median-price-list</metric>
    <metric>price-variance-list</metric>
    <metric>sugar-turtles-list</metric>
    <metric>water-turtles-list</metric>
    <metric>median-sugar-reserve-level-list</metric>
    <metric>median-water-reserve-level-list</metric>
    <metric>percent-switcher-list</metric>
    <metric>percent-basic-list</metric>
    <metric>percent-herder-list</metric>
    <metric>percent-arbitrageur-list</metric>
    <metric>median-arb-wealth-list</metric>
    <metric>median-non-arb-wealth-list</metric>
    <metric>gini-coefficient-list</metric>
    <metric>basic-only</metric>
    <metric>basic-herder</metric>
    <metric>basic-entrepreneur</metric>
    <metric>basic-herder-entrepreneur</metric>
    <metric>switcher-only</metric>
    <metric>switcher-herder</metric>
    <metric>switcher-entrepreneur</metric>
    <metric>switcher-herder-entrepreneur</metric>
    <metric>wealth-basic-only</metric>
    <metric>wealth-basic-herder</metric>
    <metric>wealth-basic-entrepreneur</metric>
    <metric>wealth-basic-herder-entrepreneur</metric>
    <metric>wealth-switcher-only</metric>
    <metric>wealth-switcher-herder</metric>
    <metric>wealth-switcher-entrepreneur</metric>
    <metric>wealth-switcher-herder-entrepreneur</metric>
    <enumeratedValueSet variable="mutate-entrepreneur?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="herding?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Basic Herder" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>output-results</final>
    <timeLimit steps="30000"/>
    <metric>total-sugar-list</metric>
    <metric>total-water-list</metric>
    <metric>sugar-minus-water-list</metric>
    <metric>median-price-list</metric>
    <metric>price-variance-list</metric>
    <metric>sugar-turtles-list</metric>
    <metric>water-turtles-list</metric>
    <metric>median-sugar-reserve-level-list</metric>
    <metric>median-water-reserve-level-list</metric>
    <metric>percent-switcher-list</metric>
    <metric>percent-basic-list</metric>
    <metric>percent-herder-list</metric>
    <metric>percent-arbitrageur-list</metric>
    <metric>median-arb-wealth-list</metric>
    <metric>median-non-arb-wealth-list</metric>
    <metric>gini-coefficient-list</metric>
    <metric>basic-only</metric>
    <metric>basic-herder</metric>
    <metric>basic-entrepreneur</metric>
    <metric>basic-herder-entrepreneur</metric>
    <metric>switcher-only</metric>
    <metric>switcher-herder</metric>
    <metric>switcher-entrepreneur</metric>
    <metric>switcher-herder-entrepreneur</metric>
    <metric>wealth-basic-only</metric>
    <metric>wealth-basic-herder</metric>
    <metric>wealth-basic-entrepreneur</metric>
    <metric>wealth-basic-herder-entrepreneur</metric>
    <metric>wealth-switcher-only</metric>
    <metric>wealth-switcher-herder</metric>
    <metric>wealth-switcher-entrepreneur</metric>
    <metric>wealth-switcher-herder-entrepreneur</metric>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="herding?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-entrepreneur?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Endogenous Entrepreneurial Choice" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>output-results</final>
    <timeLimit steps="100000"/>
    <metric>total-sugar-list</metric>
    <metric>total-water-list</metric>
    <metric>sugar-minus-water-list</metric>
    <metric>median-price-list</metric>
    <metric>price-variance-list</metric>
    <metric>sugar-turtles-list</metric>
    <metric>water-turtles-list</metric>
    <metric>median-sugar-reserve-level-list</metric>
    <metric>median-water-reserve-level-list</metric>
    <metric>percent-switcher-list</metric>
    <metric>percent-basic-list</metric>
    <metric>percent-herder-list</metric>
    <metric>percent-arbitrageur-list</metric>
    <metric>median-arb-wealth-list</metric>
    <metric>median-non-arb-wealth-list</metric>
    <metric>gini-coefficient-list</metric>
    <metric>basic-only</metric>
    <metric>basic-herder</metric>
    <metric>basic-entrepreneur</metric>
    <metric>basic-herder-entrepreneur</metric>
    <metric>switcher-only</metric>
    <metric>switcher-herder</metric>
    <metric>switcher-entrepreneur</metric>
    <metric>switcher-herder-entrepreneur</metric>
    <metric>wealth-basic-only</metric>
    <metric>wealth-basic-herder</metric>
    <metric>wealth-basic-entrepreneur</metric>
    <metric>wealth-basic-herder-entrepreneur</metric>
    <metric>wealth-switcher-only</metric>
    <metric>wealth-switcher-herder</metric>
    <metric>wealth-switcher-entrepreneur</metric>
    <metric>wealth-switcher-herder-entrepreneur</metric>
    <enumeratedValueSet variable="max-entrepreneur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="herding?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-entrepreneur?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-entrepreneurial-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="25000"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="max-entrepreneur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="herding?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-entrepreneur?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inheritance?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-entrepreneurial-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Global and Von-Neumann Trade" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>output-results</final>
    <timeLimit steps="30000"/>
    <exitCondition>count turtles = 0</exitCondition>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-entrepreneurial-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-entrepreneur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-entrepreneur?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vision Trade" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>output-results</final>
    <timeLimit steps="10000"/>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-entrepreneurial-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-entrepreneur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-entrepreneur?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>output-results</final>
    <timeLimit steps="20000"/>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-entrepreneurial-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-entrepreneur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-entrepreneur?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="C2to1 Global and Von-Neumann Trade" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>output-results</final>
    <timeLimit steps="10000"/>
    <exitCondition>count turtles = 0</exitCondition>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-entrepreneurial-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-entrepreneur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-entrepreneur?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="HerderEntrepreneurLocal" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>output-results</final>
    <timeLimit steps="10000"/>
    <exitCondition>count turtles = 0</exitCondition>
    <metric>sum [sugar] of turtles</metric>
    <metric>sum [water] of turtles</metric>
    <metric>mean prices-current-tick</metric>
    <metric>mean mean-prices-for-last-fifty-ticks</metric>
    <enumeratedValueSet variable="global-trade?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-entrepreneurial-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-entrepreneurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-entrepreneur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-entrepreneur?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vision 3 Von Neuman Trade" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="15000"/>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.45"/>
      <value value="0.5"/>
      <value value="0.55"/>
      <value value="0.6"/>
      <value value="0.65"/>
      <value value="0.7"/>
      <value value="0.75"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.45"/>
      <value value="0.5"/>
      <value value="0.55"/>
      <value value="0.6"/>
      <value value="0.65"/>
      <value value="0.7"/>
      <value value="0.75"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-arbitrageur-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-arbitrageurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-arbitrageur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-arbitrageur?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vision 3 Global Trade" repetitions="15" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go

if ticks = 12000 [
set sugar-metabolism-scalar sugar-metabolism-scalar * 2
]</go>
    <timeLimit steps="20000"/>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.5"/>
      <value value="0.525"/>
      <value value="0.55"/>
      <value value="0.575"/>
      <value value="0.6"/>
      <value value="0.625"/>
      <value value="0.65"/>
      <value value="0.675"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
      <value value="0.525"/>
      <value value="0.55"/>
      <value value="0.575"/>
      <value value="0.6"/>
      <value value="0.625"/>
      <value value="0.65"/>
      <value value="0.675"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-arbitrageur-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-arbitrageurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-arbitrageur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-arbitrageur?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vision 3 Global Trade" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="15000"/>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.45"/>
      <value value="0.5"/>
      <value value="0.55"/>
      <value value="0.6"/>
      <value value="0.65"/>
      <value value="0.7"/>
      <value value="0.75"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.45"/>
      <value value="0.5"/>
      <value value="0.55"/>
      <value value="0.6"/>
      <value value="0.65"/>
      <value value="0.7"/>
      <value value="0.75"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-arbitrageur-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-arbitrageurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-arbitrageur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-arbitrageur?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vision 3 Global Trade .5 .65 redo" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="15000"/>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-arbitrageur-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-arbitrageurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-arbitrageur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-arbitrageur?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vision 3 Von Neuman Trade Basic Herder Arbitrageur" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.5"/>
      <value value="0.525"/>
      <value value="0.55"/>
      <value value="0.575"/>
      <value value="0.6"/>
      <value value="0.625"/>
      <value value="0.65"/>
      <value value="0.675"/>
      <value value="0.7"/>
      <value value="0.725"/>
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-arbitrageur-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-arbitrageurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
      <value value="0.075"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-arbitrageur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-arbitrageur?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vision 3 Global Trade .65 .8" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="15000"/>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-arbitrageur-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-arbitrageurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="2240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-arbitrageur-switching-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;no-visualization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-arbitrageur?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="15" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go
if ticks = 10000[
set sugar-metabolism-scalar sugar-metabolism-scalar * 2
; set water-metabolism-scalar water-metabolism-scalar / 2
]</go>
    <timeLimit steps="20000"/>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.3"/>
      <value value="0.35"/>
      <value value="0.4"/>
      <value value="0.45"/>
      <value value="0.5"/>
      <value value="0.55"/>
      <value value="0.6"/>
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.3"/>
      <value value="0.35"/>
      <value value="0.4"/>
      <value value="0.45"/>
      <value value="0.5"/>
      <value value="0.55"/>
      <value value="0.6"/>
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="economic-switching?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-expected-sugar-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-price-memory">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-arbitrageur?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-arbitrageur-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-percent-arbitrageurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go
if ticks = 20000[
set sugar-metabolism-scalar sugar-metabolism-scalar * 1.5
set water-metabolism-scalar water-metabolism-scalar / 2
]</go>
    <timeLimit steps="100000"/>
    <enumeratedValueSet variable="sugar-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="water-metabolism-scalar">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-water-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-rate-of-endogenous-price-change">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-offspring">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-basic?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-rate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-pricing-strategy?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-dynamic-pricing">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="economic-switching?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-expected-sugar-price">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-sugar-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-reserve-level">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Trade?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-price-memory">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-price?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-turtle-vision">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-percent-basic">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="global-trade?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-arbitrageur?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-vision-distance?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-water-endowment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks-per-switch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-herder?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutate-price-rate?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="endogenous-arbitrageur-choice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-percent-arbitrageurs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-sugar-endowment">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-percent-herders">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rate-of-price-change">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
