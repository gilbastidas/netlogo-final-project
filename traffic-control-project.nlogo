globals [
  right_lanes ; A list of the y coordinates of different lanes right lanes
  up_lanes ; A list of the y coordinates of different lanes up lanes
  down_lanes
  left_lanes ; Left lanes
  num-cars-stopped ;; the number of cars that are stopped during a single pass thru the go procedure
  intersections ;; agentset containing the patches that are intersections
  phase ;; keeps track of the phase
  current-light  ;; the currently selected light
  x-coordinate
  y-coordinate
  succesful_agents
  arrived_agents
  dead_turtles
  random_pos
  random-HCC
  random-EC
]

turtles-own [
  speed ; Current speed of the car
  top-speed ; Maximum speed (different for all)
  orientation
  start-point
  end-point
  up-car?
  down-car?
  right-car?
  left-car?
  destination?
  time?
  wait-time ;; the amount of time since the last time a turtle has moved
  priority
  HCC?
  EC?
]

patches-own
[
  intersection?
  green-light-up? ;; true if the green light is above the intersection.  otherwise, false.
                  ;; false for a non-intersection patches.
  my-row          ;; the row of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-column       ;; the column of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-phase        ;; the phase for the intersection.  -1 for non-intersection patches.
  auto?           ;; whether or not this intersection will switch automatically.
                  ;; false for non-intersection patches.
]

to setup
  clear-all
  setup-globals
  set-default-shape turtles "car"
  draw-road
  create-or-remove-cars
  make-current one-of intersections
  label-current
  reset-ticks
end

to create-or-remove-cars
  ; Make sure don't have too many cars
  let road-patches patches with [ (member? pycor right_lanes) or (member? pxcor up_lanes) or (member? pycor left_lanes) or (member? pxcor down_lanes)]
  if number-of-cars > count road-patches [
    set number-of-cars count road-patches
  ]

  create-turtles (number-of-cars - count turtles) [
    set color 108 + random-float 1.0
    set random-HCC (random-float 1.0)
    set random-EC (random-float (percentage_HCC + percentage_EC))
    if random-HCC < (percentage_HCC + percentage_EC)
    [
      ifelse random-EC < percentage_HCC
      [
        set color yellow
        set HCC? true
      ]
      [
        set color red
        set priority 1;
        set EC? true
      ]
    ]
    ;set wait-time 0
    set speed 0
    move-to one-of free road-patches with [not any? turtles-on self]
    ask turtles with [(member? ycor right_lanes) and (xcor > -12) and destination? = 0]
    [
      move-to patch (random(-20 - -12) + -12) ycor
    ]
    ask turtles with [(member? ycor left_lanes) and (xcor < 12) and destination? = 0]
    [
      move-to patch (random(20 - 12) + 12) ycor
    ]
    ask turtles with [(member? xcor down_lanes) and (ycor < 8) and destination? = 0  ]
    [
      move-to patch xcor (random(12 - 8) + 8)
    ]
    ask turtles with [(member? xcor up_lanes) and (ycor > -8) and destination? = 0 ]
    [
      move-to patch xcor (random(-12 - -8) + -8)
    ]
    ask turtles with [member? ycor right_lanes] [set up-car? false set down-car? false set left-car? true set right-car? false ]
    ask turtles with [member? ycor left_lanes] [set up-car? false set down-car? false set left-car? false set right-car? true  set shape "left_car" ]
    ask turtles with [member? xcor up_lanes] [set up-car? true set down-car? false set left-car? false set right-car? false set shape "up_car" ]
    ask turtles with [member? xcor down_lanes] [set up-car? false set down-car? true set left-car? false set right-car? false set shape "down_car" ]
    set top-speed 0.5 + random-float 0.5
  ]
  if count turtles > number-of-cars [
    let n count turtles - number-of-cars
  ]
  set-destination
  set-time
end

to set-time
  ask turtles with [destination? = true and time? = 0]
  [
    ifelse ((HCC? = true) or (EC? = true))
    [
      ;set color white
      set wait-time (max(list abs(first end-point - first start-point) abs(last end-point - last start-point)) * ticks-per-square / 2)
    ]
    [
      set wait-time (max(list abs(first end-point - first start-point) abs(last end-point - last start-point)) * ticks-per-square)
    ]
    set time? true
  ]
end

to update-time
  ask turtles with [time? = true]
  [
    set wait-time (wait-time - 1)
  ]
end

to set-destination
  ;Set destination for cars who drives from left to right
  ask turtles with [(member? ycor right_lanes) and (xcor <= -12) and destination? = 0]
  [
    ;set color white
    set start-point (list xcor ycor)
    ;ask patch-here [set pcolor red]
    set y-coordinate ycor
    set x-coordinate xcor
    set random_pos random(2);
    ifelse (random_pos = 1)
    [
      set end-point (list (random(6 - -6) + -6)  y-coordinate)
    ]
    [
      set end-point (list (random(20 - 12) + 12)  y-coordinate)
    ]
    ;set end-point (list (random(20 - -6) + -6)  y-coordinate)
    ;ask end-point [set pcolor yellow]
    ;ask patch first end-point last end-point [ set pcolor white ]
    set destination? true
  ]
  ;Set destination for cars who drives from right to left
  ask turtles with [(member? ycor left_lanes) and (xcor >= 12) and destination? = 0]
  [
    ;set color white
    set start-point (list xcor ycor)
    ;ask patch-here [set pcolor red]
    set y-coordinate ycor
    set x-coordinate xcor
    set random_pos random(2);
    ifelse (random_pos = 1)
    [
      set end-point (list (random(-6 - 6) + 6)  y-coordinate)
    ]
    [
      set end-point (list (random(-20 - -12) + -12)  y-coordinate)
    ]
    ;set end-point (list (random(-20 - 6) + 6)  y-coordinate)
    ;ask patch first end-point last end-point [ set pcolor white ]
    set destination? true
  ]
  ;Set destination for cars who drives from up to down
  ask turtles with [(member? xcor down_lanes) and (ycor > 7) and destination? = 0]
  [
    ;set color white
    set start-point (list xcor ycor)
    ;ask patch-here [set pcolor red]
    set y-coordinate ycor
    set x-coordinate xcor
    set random_pos random(2);
    ifelse (random_pos = 1)
    [
      set end-point (list x-coordinate (random(-2 - 2) + 2))
    ]
    [
      set end-point (list x-coordinate (random(-12 - -8) + -8))
    ]
    ;set end-point (list x-coordinate  (random(-12 - 2) + 2))
    ;ask patch first end-point last end-point [ set pcolor white ]
    set destination? true
  ]
  ;Set destination for cars who drives from down to up
  ask turtles with [(member? xcor up_lanes) and (ycor < -7) and destination? = 0]
  [
    ;set color white
    set start-point (list xcor ycor)
    ;ask patch-here [set pcolor red]
    set y-coordinate ycor
    set x-coordinate xcor
    set random_pos random(2);
    ifelse (random_pos = 1)
    [
      set end-point (list x-coordinate (random(2 - -2) + -2))
    ]
    [
      set end-point (list x-coordinate (random(12 - 8) + 8))
    ]
    ;set end-point (list x-coordinate  (random(12 - -2) + -2))
    ;ask patch first end-point last end-point [ set pcolor white ]
    set destination? true
  ]
end

to arrive-destination
  ;ask turtles with start-point != 0
  ;[
  ;  set color violet
  ;]
end

to setup-globals
  set current-light nobody ;; just for now, since there are no lights yet
  set phase 0
  set num-cars-stopped 0
end


to-report free [ road-patches ]
  let this-car self
  report road-patches with [
    not any? turtles-here with [ self != this-car ]
  ]
end

to draw-road
  ; Road surrounded by green grass of varying shades
  ask patches [
    set intersection? false
    set auto? false
    set green-light-up? true
    set my-row -1
    set my-column -1
    set my-phase -1
    ; the road is surrounded by green grass of varying shades
    ;set pcolor green - random-float 0.5
    set pcolor 106 + random-float 1.0
  ]
  ;set lanes n-values number-of-lanes
  set right_lanes [6 4]
  set left_lanes [-6 -4]
  set up_lanes [8 10]
  set down_lanes [-8 -10]

  ; Sky patches
  ask patches with [ (abs pycor <= 8) and (abs pycor >= 8)] [
    ; Different shades of sky for lanes
    set pcolor 92 + random-float 1.0
  ]
  ; Vertical roads
  ask patches with [ (abs pycor <= 7) and (abs pycor >= 3)] [
    ; Different shades of gray for lanes
    set pcolor grey - 2.5 + random-float 0.25
  ]
  ; Horizontal roads
  ask patches with [ (abs pxcor <= 11) and  (abs pxcor >= 7) ] [
    ; Different shades of gray for lanes
    set pcolor grey - 2.5 + random-float 0.25
  ]
  ; Set the intersection patches
  set intersections patches with [ (abs pxcor <= 11) and  (abs pxcor >= 7) and (abs pycor <= 7) and  (abs pycor >= 3)  ]
  ; Add color (cyan) to intersection patches
  ask intersections
  [
    ; Different shades of cyan for intersection
    set pcolor 83 + random-float 0.5
  ]
  setup-intersections
  draw-road-lines
end

;; Give the intersections appropriate values for the intersection?, my-row, and my-column
;; patch variables.  Make all the traffic lights start off so that the lights are red
;; horizontally and green vertically.
to setup-intersections
  ask intersections
  [
    set intersection? true
    set green-light-up? true
    set my-phase 0
    set auto? true
    set-signal-colors
  ]
end

to draw-road-lines
  let y (first right_lanes) + 1.5
  let x (first up_lanes) - 1.5
  while [ y > 0 ] [
    ifelse y = (first right_lanes) - 1
    [
      draw-line y white 0.5
      draw-line (- y) white 0.5
    ]
    [
      draw-line y yellow 0
      draw-line (- y) yellow 0
    ]
    set y y - 2.5
  ]

  while [ x < 12 ] [
    ifelse x = (first up_lanes) + 1
    [
      draw-yline x white 0.5
      draw-yline (- x) white 0.5
    ]
    [
      draw-yline x yellow 0
      draw-yline (- x) yellow 0
    ]
    set x x + 2.5
  ]
end

to draw-line [ y line-color gap ]
  ; We use a temporary turtle to draw the line:
  ; - with a gap of zero, we get a continuous line;
  ; - with a gap greater than zero, we get a dasshed line.
  create-turtles 1 [
    setxy (min-pxcor) y
    hide-turtle
    set color line-color
    set heading 90
    repeat world-width [
      pen-up
      forward gap
      pen-down
      forward (1 - gap)
    ]
    die
  ]
end

to draw-yline [ y line-color gap ]
  ; We use a temporary turtle to draw the line:
  ; - with a gap of zero, we get a continuous line;
  ; - with a gap greater than zero, we get a dasshed line.
  create-turtles 1 [
    setxy y (max-pycor )
    hide-turtle
    set color line-color
    set heading 180
    repeat world-width [
      pen-up
      forward gap
      pen-down
      forward (1 - gap)
    ]
    die
  ]
end

to go
  update-current
  set-signals
  set num-cars-stopped 0
  update-time
  ask turtles [
    set-car-speed
    fd speed ]
  next-phase
  if dead_turtles > 0
  [
    ;create-turtles dead_turtles
    create-or-remove-cars
    set dead_turtles 0
  ]
  if arrived_agents >= 1000
    [stop]
  tick
end


;; cycles phase to the next appropriate value
to next-phase
  ;; The phase cycles from 0 to ticks-per-cycle, then starts over.
  set phase phase + 1
  if phase mod ticks-per-cycle = 0
    [ set phase 0 ]
end

to slow-down-car
  set speed (speed - deceleration)
  if speed < 0 [ set speed deceleration ]
end

to speed-up-car
  set speed (speed + acceleration)
  if speed > top-speed [ set speed top-speed ]
  ;if pcolor = red + 1
  ;[ set speed 0 ]
end

;; Set up the current light and the interface to change it.
to make-current [light]
  set current-light light
  set current-phase [my-phase] of current-light
  set current-auto? [auto?] of current-light
end

;; update the variables for the current light
to update-current
  ask current-light [
    set my-phase current-phase
    set auto? current-auto?
  ]
end

;; label the current light
to label-current
  ask current-light
  [
    ask patch-at -1 1
    [
      set plabel-color black
      set plabel "current"
    ]
  ]
end

;; have the traffic lights change color if phase equals each intersections' my-phase
to set-signals
  ask intersections with [auto? and phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    set green-light-up? (not green-light-up?)
    set-signal-colors
  ]
end

;; This procedure checks the variable green-light-up? at each intersection and sets the
;; traffic lights to have the green light up or the green light to the left.
to set-signal-colors  ;; intersection (patch) procedure
  ifelse power?
  [
    ifelse green-light-up?
    [
      ask patches with [ ( pycor <= -8) and ( pycor >= -8) and ( pxcor <= 11) and ( pxcor >= 7) ] [
        set pcolor red + 1
      ]
      ask patches with [ ( pycor <= 8) and ( pycor >= 8) and ( pxcor <= -7) and ( pxcor >= -11) ] [
        set pcolor red + 1
      ]
      ask patches with [ ( pycor <= -2) and ( pycor >= -2) and ( pxcor <= -7) and ( pxcor >= -11) ] [
        set pcolor red + 1
      ]
      ask patches with [ ( pycor <= 2) and ( pycor >= 2) and ( pxcor <= 11) and ( pxcor >= 7) ] [
        set pcolor red + 1
      ]
      ask patches with [ ( pycor <= 7) and ( pycor >= 3) and (pxcor <= -12) and (pxcor >= -12) ] [
        set pcolor green + 1
      ]
      ask patches with [ ( pycor <= -3) and ( pycor >= -7) and (pxcor <= -6) and (pxcor >= -6) ] [
        set pcolor green + 1
      ]
      ask patches with [ ( pycor <= 7) and ( pycor >= 3) and (pxcor <= 6) and (pxcor >= 6) ] [
        set pcolor green + 1
      ]
      ask patches with [ ( pycor <= -3) and ( pycor >= -7) and (pxcor <= 12) and (pxcor >= 12) ] [
        set pcolor green + 1
      ]
    ]
    [
      ask patches with [ ( pycor <= -8) and ( pycor >= -8) and ( pxcor <= 11) and ( pxcor >= 7) ] [
        set pcolor green + 1
      ]
      ask patches with [ ( pycor <= 8) and ( pycor >= 8) and ( pxcor <= -7) and ( pxcor >= -11) ] [
        set pcolor green + 1
      ]
      ask patches with [ ( pycor <= -2) and ( pycor >= -2) and ( pxcor <= -7) and ( pxcor >= -11) ] [
        set pcolor green + 1
      ]
      ask patches with [ ( pycor <= 2) and ( pycor >= 2) and ( pxcor <= 11) and ( pxcor >= 7) ] [
        set pcolor green + 1
      ]
      ask patches with [ ( pycor <= 7) and ( pycor >= 3) and (pxcor <= -12) and (pxcor >= -12) ] [
        set pcolor red + 1
      ]
      ask patches with [ ( pycor <= -3) and ( pycor >= -7) and (pxcor <= -6) and (pxcor >= -6) ] [
        set pcolor red + 1
      ]
      ask patches with [ ( pycor <= 7) and ( pycor >= 3) and (pxcor <= 6) and (pxcor >= 6) ] [
        set pcolor red + 1
      ]
      ask patches with [ ( pycor <= -3) and ( pycor >= -7) and (pxcor <= 12) and (pxcor >= 12) ] [
        set pcolor red + 1
      ]
    ]
  ]
  [
    ask patches with [ ( pycor <= 8) and ( pycor >= 8) and (abs pxcor <= 11) and (abs pxcor >= 7) ] [
      set pcolor grey - 2.5 + random-float 0.25
    ]
    ask patches with [ ( pycor <= -2) and ( pycor >= -2) and (abs pxcor <= 11) and (abs pxcor >= 7) ] [
      set pcolor grey - 2.5 + random-float 0.25
    ]
    ask patches with [ (abs pycor <= 7) and (abs pycor >= 3) and (pxcor <= -12) and (pxcor >= -12) ] [
      set pcolor grey - 2.5 + random-float 0.25
    ]
    ask patches with [ (abs pycor <= 7) and (abs pycor >= 3) and (pxcor <= 6) and (pxcor >= 6) ] [
      set pcolor grey - 2.5 + random-float 0.25
    ]
    ask patches with [ ( pycor <= 8) and ( pycor >= 8) and (abs pxcor <= 11) and (abs pxcor >= 7) ] [
      set pcolor grey - 2.5 + random-float 0.25
    ]
    ask patches with [ ( pycor <= -2) and ( pycor >= -2) and (abs pxcor <= 11) and (abs pxcor >= 7) ] [
      set pcolor grey - 2.5 + random-float 0.25
    ]
    ask patches with [ (abs pycor <= 7) and (abs pycor >= 3) and (pxcor <= -12) and (pxcor >= -12) ] [
      set pcolor grey - 2.5 + random-float 0.25
    ]
    ask patches with [ (abs pycor <= 7) and (abs pycor >= 3) and (pxcor <= 6) and (pxcor >= 6) ] [
      set pcolor grey - 2.5 + random-float 0.25
    ]
  ]
end

;; set the turtles' speed based on whether they are at a red traffic light or the speed of the
;; turtle (if any) on the patch in front of them
to set-car-speed  ;; turtle procedure
  ifelse pcolor = red + 1
  [ set speed 0 ]
  [
    ifelse up-car? = true
    [ set-speed 0 1
      set heading 360
      if destination? = true
          [
            if patch-here = patch first end-point last end-point
            [
              set destination? false
              set arrived_agents arrived_agents + 1
              if wait-time >= 0
              [
                set succesful_agents succesful_agents + 1
              ]
            ]
          ]
    ]
    [ ifelse down-car? = true
      [ set-speed 0 -1
        set heading 180
        if destination? = true
          [
            if patch-here = patch first end-point last end-point
            [
              set destination? false
              set arrived_agents arrived_agents + 1
              if wait-time >= 0
              [
                set succesful_agents succesful_agents + 1
              ]
            ]
          ]
      ]
      [ ifelse left-car? = true
        [
          set-speed 1 0
          set heading 90
          if destination? = true
          [
            if patch-here = patch first end-point last end-point
            [
              set destination? false
              set arrived_agents arrived_agents + 1
              if wait-time >= 0
              [
                set succesful_agents succesful_agents + 1
              ]
            ]
          ]
        ]
        [
          set-speed -1 0
          set heading -90
          if destination? = true
          [
            if patch-here = patch first end-point last end-point
            [
              set destination? false
              set arrived_agents arrived_agents + 1
              if wait-time >= 0
              [
                set succesful_agents succesful_agents + 1
              ]
            ]
          ]
        ]
      ]
    ]
  ]
  if (patch-here = patch 20 6) or (patch-here = patch 20 4) or (patch-here = patch -20 -6) or (patch-here = patch -20 -4) or (patch-here = patch -10 -12) or (patch-here = patch 10 12) or (patch-here = patch -8 -12) or (patch-here = patch 8 12)
  [
    set dead_turtles dead_turtles + 1
    die
  ]
end

;; set the speed variable of the car to an appropriate value (not exceeding the
;; speed limit) based on whether there are cars on the patch in front of the car
to set-speed [ delta-x delta-y ]  ;; turtle procedure
                                  ;; get the turtles on the patch in front of the turtle
  let turtles-ahead turtles-at delta-x delta-y
  ;; if there are turtles in front of the turtle, slow down
  ;; otherwise, speed up
  ifelse any? turtles-ahead
  [
    ifelse any? (turtles-ahead with [ up-car? = [up-car?] of myself ])
    [
      ifelse any? (turtles-ahead with [ down-car? = [down-car?] of myself ])
      [
        ifelse any? (turtles-ahead with [ left-car? = [left-car?] of myself ])
        [
          ifelse any? (turtles-ahead with [ right-car? = [right-car?] of myself ])
          [
            set speed [speed] of one-of turtles-ahead
            slow-down
          ]
          [
            set speed 0
          ]
        ]
        [
          set speed 0
        ]
      ]
      [
        set speed 0
      ]
    ]
    [
      set speed 0
    ]
  ]
  [ speed-up ]
end


to-report x-distance
  report distancexy [ xcor ] of myself ycor
end

to-report y-distance
  report distancexy xcor [ ycor ] of myself
end

;; decrease the speed of the turtle
to slow-down  ;; turtle procedure
  ifelse speed <= 0  ;;if speed < 0
  [ set speed 0 ]
  [ set speed speed - acceleration ]
end

;; increase the speed of the turtle
to speed-up  ;; turtle procedure
  ifelse speed > top-speed
  [ set speed top-speed ]
  [ set speed speed + acceleration ]
end
;; Methods
;; n-values
; Reports a list of length size containing values computed by repeatedly running the
; reporter.

;; abs
; Reports the absolute value of number.

;; member?
; For a list, reports true if the given value appears in the given list, otherwise reports false.
; http://ccl.northwestern.edu/netlogo/docs/dict/member.html

;; Colors
; https://ccl.northwestern.edu/netlogo/docs/programming.html
@#$#@#$#@
GRAPHICS-WINDOW
286
34
893
408
-1
-1
14.61
1
10
1
1
1
0
0
0
1
-20
20
-12
12
1
1
1
ticks
30.0

BUTTON
20
33
86
66
setup
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

SLIDER
98
34
270
67
number-of-cars
number-of-cars
1
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
20
82
85
115
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

SLIDER
98
86
270
119
deceleration
deceleration
0.01
.1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
98
133
270
166
acceleration
acceleration
.001
.01
0.01
.001
1
NIL
HORIZONTAL

SLIDER
98
180
270
213
ticks-per-cycle
ticks-per-cycle
50
100
90.0
10
1
NIL
HORIZONTAL

SLIDER
98
222
270
255
current-phase
current-phase
0
99
0.0
1
1
%
HORIZONTAL

SWITCH
99
403
242
436
current-auto?
current-auto?
0
1
-1000

SWITCH
100
445
203
478
power?
power?
0
1
-1000

MONITOR
906
146
1009
191
NIL
succesful_agents
0
1
11

MONITOR
906
35
1009
80
NIL
count turtles
17
1
11

SLIDER
98
267
270
300
ticks-per-square
ticks-per-square
0
25
16.0
1
1
NIL
HORIZONTAL

MONITOR
905
91
1009
136
arrived_agents
arrived_agents
17
1
11

SLIDER
98
313
270
346
percentage_HCC
percentage_HCC
0
0.5
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
98
359
270
392
percentage_EC
percentage_EC
0
0.2
0.01
0.01
1
NIL
HORIZONTAL

PLOT
1025
35
1225
185
Avergae car speed
Time
Speed
0.0
300.0
0.0
0.5
true
false
"" ""
PENS
"average" 1.0 0 -14454117 true "" "plot mean [ speed ] of turtles"

PLOT
1028
194
1228
344
Wait time
NIL
NIL
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -11221820 true "" "plot mean [wait-time] of turtles"

PLOT
1029
353
1229
503
Succesful agents
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
"Total agents" 1.0 0 -11033397 true "" "plot mean [arrived_agents] of turtles"
"Succesful" 1.0 0 -8732573 true "" "plot mean [succesful_agents] of turtles"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

down_car
false
0
Polygon -7500403 true true 180 300 164 279 144 261 135 240 132 226 106 213 84 203 63 185 50 159 50 135 60 75 150 0 165 0 225 0 225 300 180 300
Circle -16777216 true false 180 180 90
Circle -16777216 true false 180 30 90
Polygon -16777216 true false 80 162 78 132 135 134 135 209 105 194 96 189 89 180
Circle -7500403 true true 195 47 58
Circle -7500403 true true 195 195 58

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

left_car
false
0
Polygon -7500403 true true 0 180 21 164 39 144 60 135 74 132 87 106 97 84 115 63 141 50 165 50 225 60 300 150 300 165 300 225 0 225 0 180
Circle -16777216 true false 30 180 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 138 80 168 78 166 135 91 135 106 105 111 96 120 89
Circle -7500403 true true 195 195 58
Circle -7500403 true true 47 195 58

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

up_car
false
0
Polygon -7500403 true true 180 0 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 300 165 300 225 300 225 0 180 0
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
