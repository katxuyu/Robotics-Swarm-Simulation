breed [Robots robot]
breed [Humans person]
breed [halos halo]

globals [nearby n_pass_times received fwrds target_fwrds g-get-cost g-paths g-estimated-costs g-path g-visited g-encountered g-destination g-source]




patches-own [
  owned-by
  cost
]

turtles-own [
  my_role
  mlast_handlers
]

robots-own [
  i_met
  the_target_is
  where_the_target_is
  tick_i_met_the_target
  starting_point
  my_path_to_target
  paths_ive_been
  distance_from_source
  target_patch
  source_patch
  smart_count
]

humans-own [
 is_sent
 i_met
 is_received
 the_target_is
 my_random_path
 smart_count
]


to setup
 ca
 set-default-shape halos "thin ring"
 set n_pass_times 0
 create_map
 position_source_target
 set g-destination 0
 set g-source 0
 set received false
 set fwrds 0
  ask patches [
  set cost ""
  ]

  ask n-of rob_num (patches with [pcolor = white])
  [
    sprout-robots 1 [
      set color blue
      set shape "robot"
      set size 5
      set my_role "bridge"
      set i_met []
      set mlast_handlers []
      set the_target_is -1
      set where_the_target_is 0
      set tick_i_met_the_target -1
      set starting_point (list xcor ycor)
      set my_path_to_target []
      set paths_ive_been []
      set distance_from_source []
      set smart_count 0

    ]
  ]
  reset-ticks

end



to go
  if received = true [ stop ]
  move_robots
  if show_trace? = false [reset-patches]
  tick
end


to paint-agents [agents]
  ask agents [ set pcolor [color] of myself - 2 ]
end

to position_source_target

  create-humans 1 [
    set shape "robot"
    set color green
    set size 5
    set my_role "source"
    set mlast_handlers []
    set is_sent false
    set the_target_is 1
    set i_met []
    set my_random_path []
    set smart_count 0
  ]

  create-humans 1 [
    set shape "robot"
    set color red
    set size 5
    set my_role "target"
    set mlast_handlers []
    set is_received false
    set the_target_is -1
    set i_met []
    set my_random_path []
    set smart_count 0
  ]

  let st_distance [distance turtle 1] of turtle 0

  while [st_distance < 45] [

    ask humans [
      set xcor random-xcor
      set ycor random-ycor
      while [pcolor = black]
      [
        set xcor random-xcor
        set ycor random-ycor
      ]
    ]
    set st_distance [distance turtle 1] of turtle 0

  ]
end

to find-path-slowly
  if g-estimated-costs = 0 [
    set g-get-cost 0
    set g-paths (list (list g-source))
    set g-estimated-costs (list [distance g-destination ] of g-source)

    set g-path first g-paths

    set g-visited patch-set g-source
    set g-encountered patch-set g-source
  ]


  ifelse g-source != g-destination [
    let estimated-cost min g-estimated-costs
    let path-index position estimated-cost g-estimated-costs
    set g-path item path-index g-paths
    set g-source last g-path
    let path-cost estimated-cost - [ distance g-destination ] of g-source
    let source-cost [ g-get-cost ] of g-source

    set g-paths remove-item path-index g-paths
    set g-estimated-costs remove-item path-index g-estimated-costs

    set g-visited (patch-set g-source g-visited)
    let turt self
    ask [ neighbors with [ not member? self g-visited and pcolor != black ] ] of g-source [
      set pcolor yellow
      let pat self

      let patch-cost g-get-cost
      let step-cost distance g-source * (patch-cost + source-cost) / 2
      let est-cost path-cost + step-cost + distance g-destination


      let add? true

      if member? self g-encountered [

        let other-path false
        foreach g-paths [
          p ->
          if last p = self [
            set other-path p
          ]
        ]
        if other-path != false [
          let other-path-index position other-path g-paths
          let other-path-cost item other-path-index g-estimated-costs
          ifelse other-path-cost < est-cost [
            set add? false
          ] [
            set g-paths remove-item other-path-index g-paths
            set g-estimated-costs remove-item other-path-index g-estimated-costs
          ]
        ]
      ]

      if add? [
        ask turt [move-to pat]
        set g-estimated-costs fput est-cost g-estimated-costs
        set g-paths fput (lput self g-path) g-paths

        set g-encountered (patch-set self g-encountered)

      ]
    ]
  ]
  [
    set g-destination  0
    set g-source  0
    set g-estimated-costs 0

  ]
end

to move_robots
  ask turtles
  [
    if my_role != "range" [
      if my_role = "bridge" or my_role = "target"
      [
        ifelse how_smart_the_robot_is? = "Randomly Pass the Message" [
          move
        ]
        [
          ifelse not search_slowly? [
            ifelse color = green  and my_role != "target"  [

              if empty? my_path_to_target [
                let source-patch patch-here
                let target-patch []
                ifelse my_role = "bridge" and where_the_target_is != 0
                [ ;set target-patch [patch-here] of turtle 1
                  set target-patch where_the_target_is
                ]
                [ set target-patch one-of patches with [pcolor = white] ]
                 ask target-patch [set pcolor red]
                set my_path_to_target find-path source-patch target-patch
              ]

              if show_trace? = true [
                foreach my_path_to_target [
                  p ->
                  set pcolor yellow
                ]
              ]

              ifelse fwrds < length my_path_to_target - 1 [
                move-to item fwrds my_path_to_target
                set fwrds fwrds + 1
              ]
              [
                set my_path_to_target []
                set fwrds 0
                set smart_count 0
                set where_the_target_is 0
                set tick_i_met_the_target -1
              ]
            ]
            [

              ifelse my_role != "target" [
                move
              ][
                if target_move = true [
                  ;move
                  ifelse target_smart_move? and smart_count = 10 [

                    if empty? my_random_path [
                      let source-patch patch-here
                      let target-patch one-of patches with [pcolor = white]
                      set my_random_path find-path source-patch target-patch
                      set target_fwrds 0
                    ]
                    ifelse target_fwrds < length my_random_path - 1 [
                      move-to item target_fwrds my_random_path
                      set target_fwrds target_fwrds + 1
                    ]
                    [set my_random_path []
                      set target_fwrds 0
                      set smart_count 0
                    ]
                  ][
                    move
                    set smart_count smart_count + 1
                  ]
                ]
              ]
            ]
            if my_role = "bridge" [
              let ive_been_here false
              foreach paths_ive_been [
                pib ->
                if pib = patch-here [
                  set ive_been_here true
                ]
              ]
              if ive_been_here = false [set paths_ive_been fput patch-here paths_ive_been]
              if length paths_ive_been > rob_memory * 5 [
                set paths_ive_been remove-item 0 paths_ive_been
              ]
            ]
          ][
            ;;;;EDIT HERE!!!;;;
            ifelse color = green  and my_role != "target" [

              if g-destination = 0 [
                set g-source patch-here
                set g-destination 0
                ifelse my_role != "source" and where_the_target_is != 0
                [ set g-destination [patch-here] of turtle 1 ]
                [ set g-destination one-of patches with [pcolor = white] ]
                ask g-destination [set pcolor red]

              ]

              find-path-slowly
            ]
            [

              ifelse my_role != "target" [
                move
              ][
                if target_move = true [
                  ;move
                  ifelse target_smart_move? and smart_count = 15 [

                    if empty? my_random_path [

                      let source-patch patch-here
                      let target-patch one-of patches with [pcolor = white]
                      set my_random_path find-path source-patch target-patch
                      set target_fwrds 0
                    ]

                    ifelse target_fwrds < length my_random_path - 1 [
                      move-to item target_fwrds my_random_path
                      set target_fwrds target_fwrds + 1
                    ]
                    [set my_random_path []
                      set target_fwrds 0
                      set smart_count 0
                    ]
                  ][
                    move
                    set smart_count smart_count + 1
                  ]
                ]
              ]
            ]
            if my_role = "bridge" [
              let ive_been_here false
              foreach paths_ive_been [
                pib ->
                if pib = patch-here [
                  set ive_been_here true
                ]
              ]
              if ive_been_here = false [set paths_ive_been fput patch-here paths_ive_been]
              if length paths_ive_been > rob_memory * 5 [
                set paths_ive_been remove-item 0 paths_ive_been
              ]
            ]
          ]
        ]
      ]


      let ext_radius radius + radius
      set nearby moore-offsets ext_radius
      let parent_color color
      let parent_role my_role
      let parent_id who
      let parent_mlh mlast_handlers
      let is_handler_before false
      let can_stop_now false
      let parent_met i_met
      let parent_tti the_target_is
      let parent_wtti 0
      let parent_timtt []



      if color = green [
       ifelse who = 0
        [
          set parent_wtti 0
          set parent_timtt []
        ]
        [
          if where_the_target_is != 0 [
            set parent_wtti distance where_the_target_is]
          set parent_timtt tick_i_met_the_target
        ]

        ask patches at-points nearby with [any? turtles-here]
        [
          let list_neighbors []
          let passed_the_criteria false
          ask turtles-here [
            if my_role = "bridge" or my_role = "target" [
              set list_neighbors lput who list_neighbors
            ]
          ]
          let n_lneighbors length list_neighbors - 1



          while [ n_lneighbors >= 0 and can_stop_now = false]
          [

            ask turtle item n_lneighbors list_neighbors  [


              ifelse my_role = "bridge"
              [
                set the_target_is parent_tti
                foreach parent_mlh [
                  x ->
                  if who = x [
                    set is_handler_before true
                  ]
                ]

                if length parent_mlh >= rob_memory [
                  set parent_mlh remove-item 0 parent_mlh
                ]

                if is_handler_before = false [
                 ifelse how_smart_the_robot_is? = "Randomly Pass the Message" [
                  set can_stop_now true
                 ]
                 [
                   if the_target_is != -1 [
                     foreach i_met [
                       x ->
                       let id item 0 x
                       let xcoor item 1 x
                       let ycoor item 2 x
                       let tick_they_met item 3 x
                       if id = the_target_is [
                         set where_the_target_is patch xcoor ycoor
                         set tick_i_met_the_target tick_they_met
                       ]
                     ]
                   ]
                   ifelse parent_id != 0 [
                      foreach i_met [
                        rob ->
                        if the_target_is = item 0 rob  [
                          let xcoor item 1 rob
                          let ycoor item 2 rob
                          let tick_they_met item 3 rob

                          ifelse where_the_target_is != 0 and parent_timtt != -1 and parent_wtti != -1 [
                            if tick_they_met < parent_timtt [

                              ;print patch_of_wtti
                              if distance where_the_target_is < parent_wtti [
                                print "HEYYYYY"
                                set can_stop_now true
                              ]
                            ]
                          ][set can_stop_now true]
                        ]

                      ]
                   ][set can_stop_now true]
                 ]
                 if can_stop_now = true [

                    set color green
                    ifelse parent_id = 0
                    [ set mlast_handlers lput who [] ]
                    [ set mlast_handlers lput who parent_mlh ]
                    ifelse parent_role = "source"
                    [set parent_color gray]
                    [set parent_color blue]
                    set n_pass_times n_pass_times + 1
                    reset-patches
                    set fwrds 0
                    set g-destination  0
                    set g-estimated-costs 0

                    ;stop
                 ]
                ]
              ]
              [
                if my_role = "target" [

                  set is_received true
                  set received true
                  set can_stop_now true
                  ;stop
                ]

                if my_role = "source" and parent_id = 1 [
                  set is_received true
                  set received true
                  set can_stop_now true
                ]

              ]
            ]
            set n_lneighbors n_lneighbors - 1
          ]

          if can_stop_now = true [stop]
        ]
        set color parent_color
        if color != green [set mlast_handlers []]
        if color = gray [set is_sent true]

      ]

      if color = blue [
        set the_target_is -1
        set where_the_target_is 0
        set tick_i_met_the_target -1
      ]



      ask patches at-points nearby with [any? robots-here]
      [
        let have_met_before false

        ask robots-here [
          let pos_meet (list parent_id pxcor pycor ticks)
          let loop_count 0

          foreach i_met [
            x ->
            let id item 0 x
            let xcoor item 1 x
            let ycoor item 2 x
            let tick_they_met item 3 x
            let pp position x i_met

            ifelse x != pos_meet [
              if id = parent_id [
                if parent_id = 1 and color != green [set color yellow]
                if xcoor != pxcor or ycoor != pycor or tick_they_met != ticks [
                  set i_met replace-item loop_count i_met pos_meet
                  set have_met_before true

                ]
              ]

            ]
            [set have_met_before true]
            set loop_count loop_count + 1

          ]

          if have_met_before = false [set i_met lput pos_meet i_met]
          if length i_met > rob_memory [
            let the_item_to_remove item 0 i_met
            set i_met remove-item 0 i_met
            if item 0 the_item_to_remove = 1 [
              if color = yellow [set color blue]
            ]
          ]

        ]
      ]

    ]
  ]
end

to reset-patches
  ask patches with [pcolor = yellow or pcolor = red] [set pcolor white]
end

to move
  rt one-of [-90 0 90]

  while [[pcolor] of patch-ahead 1 = black ] [
      rt random 360
  ]

  forward 1
end

to move-smartly
  ;rt one-of [-90 0 90]

  let rot [45 -45 90 -90]

  let i 0

  let have_i_been_here? false
  while [have_i_been_here? = true] [
    rt item i rot
    foreach paths_ive_been [
      pib ->
      if patch-ahead 1 = pib [
        set have_i_been_here? true
      ]

    ]
    if [pcolor] of patch-ahead 1 = black [ forward -1 ]

    set i i + 1
  ]



;  while [] [
;      rt 45
;  ]



  forward 1




end





to-report find-path [ source destination ]
  let get-cost 0
  let paths (list (list source))
  let estimated-costs (list [distance destination ] of source)

  let path first paths

  let visited patch-set source
  let encountered patch-set source

  while [ source != destination ] [
    let estimated-cost min estimated-costs
    let path-index position estimated-cost estimated-costs
    set path item path-index paths
    set source last path
    let path-cost estimated-cost - [ distance destination ] of source
    let source-cost [ get-cost ] of source

    set paths remove-item path-index paths
    set estimated-costs remove-item path-index estimated-costs

    set visited (patch-set source visited)

    ask [ neighbors with [ not member? self visited and pcolor != black ] ] of source [
      let patch-cost get-cost
      let step-cost distance source * (patch-cost + source-cost) / 2
      let est-cost path-cost + step-cost + distance destination

      let add? true

      if member? self encountered [
        let other-path false
        foreach paths [
          p ->
          if last p = self [
            set other-path p
          ]
        ]
        if other-path != false [
          let other-path-index position other-path paths
          let other-path-cost item other-path-index estimated-costs
          ifelse other-path-cost < est-cost [
            set add? false
          ] [
            set paths remove-item other-path-index paths
            set estimated-costs remove-item other-path-index estimated-costs
          ]
        ]
      ]

      if add? [
        set estimated-costs fput est-cost estimated-costs
        set paths fput (lput self path) paths

        set encountered (patch-set self encountered)

      ]
    ]
  ]
  report path
end






to make-halo  ;; runner procedure
  ;; when you use HATCH, the new turtle inherits the
  ;; characteristics of the parent.  so the halo will
  ;; be the same color as the turtle it encircles (unless
  ;; you add code to change it
  hatch-halos 1
  [ set size radius + radius + 2
    set color gray
    ;; Use an RGB color to make halo three fourths transparent
    set color lput 64 extract-rgb color
    set my_role "range"
    ;; set thickness of halo to half a patch
    __set-line-thickness 0.5
    ;; We create an invisible directed link from the runner
    ;; to the halo.  Using tie means that whenever the
    ;; runner moves, the halo moves with it.
    create-link-from myself
    [ tie
      hide-link ] ]
end

to-report moore-offsets [n]
  let result [list pxcor pycor] of patches with [abs pxcor <= n and abs pycor <= n]
  report remove [0 0] result
end



to boundries
    ; draw left and right walls
  ask patches with [abs pxcor = max-pxcor]
    [ set pcolor black ]
  ; draw top and bottom walls
  ask patches with [abs pycor = max-pycor]
    [ set pcolor black ]

end



to create_map
  ask patches [ set pcolor white ]
  boundries
  ask patch -10 15  [ set pcolor black ]
  ask patch -9 15  [ set pcolor black ]
  ask patch -7 15  [ set pcolor black ]
  ask patch -6 15  [ set pcolor black ]
  ask patch -10 14  [ set pcolor black ]
  ask patch -9 14  [ set pcolor black ]
  ask patch -7 14  [ set pcolor black ]
  ask patch -6 14  [ set pcolor black ]
  ask patch -10 13  [ set pcolor black ]
  ask patch -9 13  [ set pcolor black ]
  ask patch -8 13  [ set pcolor black ]
  ask patch -10 12  [ set pcolor black ]
  ask patch -9 12  [ set pcolor black ]
  ask patch -7 12  [ set pcolor black ]
  ask patch -6 12  [ set pcolor black ]
  ask patch -10 11  [ set pcolor black ]
  ask patch -9 11  [ set pcolor black ]
  ask patch -7 11  [ set pcolor black ]
  ask patch -6 11  [ set pcolor black ]
  ask patch 3 11  [ set pcolor black ]
  ask patch 4 11  [ set pcolor black ]
  ask patch 3 10  [ set pcolor black ]
  ask patch 4 10  [ set pcolor black ]
  ask patch 8 10  [ set pcolor black ]
  ask patch 9 10  [ set pcolor black ]
  ask patch 10 10  [ set pcolor black ]
  ask patch 11 10  [ set pcolor black ]
  ask patch 12 10  [ set pcolor black ]
  ask patch 13 10  [ set pcolor black ]
  ask patch 14 10  [ set pcolor black ]
  ask patch 15 10  [ set pcolor black ]
  ask patch 16 10  [ set pcolor black ]
  ask patch 3 9  [ set pcolor black ]
  ask patch 4 9  [ set pcolor black ]
  ask patch 8 9  [ set pcolor black ]
  ask patch 9 9  [ set pcolor black ]
  ask patch 10 9  [ set pcolor black ]
  ask patch 11 9  [ set pcolor black ]
  ask patch 12 9  [ set pcolor black ]
  ask patch 13 9  [ set pcolor black ]
  ask patch 14 9  [ set pcolor black ]
  ask patch 15 9  [ set pcolor black ]
  ask patch 16 9  [ set pcolor black ]
  ask patch -5 8  [ set pcolor black ]
  ask patch -4 8  [ set pcolor black ]
  ask patch -3 8  [ set pcolor black ]
  ask patch -2 8  [ set pcolor black ]
  ask patch -1 8  [ set pcolor black ]
  ask patch 8 8  [ set pcolor black ]
  ask patch 9 8  [ set pcolor black ]
  ask patch -5 7  [ set pcolor black ]
  ask patch -4 7  [ set pcolor black ]
  ask patch -3 7  [ set pcolor black ]
  ask patch -2 7  [ set pcolor black ]
  ask patch -1 7  [ set pcolor black ]
  ;ask patch 8 7  [ set pcolor black ]
  ;ask patch 9 7  [ set pcolor black ]
  ;ask patch -3 6  [ set pcolor black ]
  ask patch 8 6  [ set pcolor black ]
  ask patch 9 6  [ set pcolor black ]
  ask patch -3 5  [ set pcolor black ]
  ask patch 8 5  [ set pcolor black ]
  ask patch 9 5  [ set pcolor black ]
  ask patch 10 5  [ set pcolor black ]
  ask patch 11 5  [ set pcolor black ]
  ask patch -16 4  [ set pcolor black ]
  ask patch -15 4  [ set pcolor black ]
  ask patch -14 4  [ set pcolor black ]
  ask patch -13 4  [ set pcolor black ]
  ask patch -12 4  [ set pcolor black ]
  ask patch -11 4  [ set pcolor black ]
  ask patch -10 4  [ set pcolor black ]
  ask patch -9 4  [ set pcolor black ]
  ask patch -3 4  [ set pcolor black ]
  ask patch 8 4  [ set pcolor black ]
  ask patch 9 4  [ set pcolor black ]
  ask patch 10 4  [ set pcolor black ]
  ask patch 11 4  [ set pcolor black ]
  ask patch -16 3  [ set pcolor black ]
  ask patch -15 3  [ set pcolor black ]
  ask patch -14 3  [ set pcolor black ]
  ask patch -13 3  [ set pcolor black ]
  ask patch -12 3  [ set pcolor black ]
  ask patch -11 3  [ set pcolor black ]
  ask patch -10 3  [ set pcolor black ]
  ask patch -9 3  [ set pcolor black ]
  ask patch -10 2  [ set pcolor black ]
  ask patch -9 2  [ set pcolor black ]
;  ask patch 8 2  [ set pcolor black ]
;  ask patch 9 2  [ set pcolor black ]
;  ask patch 10 2  [ set pcolor black ]
;  ask patch 11 2  [ set pcolor black ]
  ask patch -10 1  [ set pcolor black ]
  ask patch -9 1  [ set pcolor black ]
  ask patch 8 1  [ set pcolor black ]
  ask patch 9 1  [ set pcolor black ]
  ask patch 10 1  [ set pcolor black ]
  ask patch 11 1  [ set pcolor black ]
  ask patch -10 0  [ set pcolor black ]
  ask patch -9 0  [ set pcolor black ]
  ask patch 8 0  [ set pcolor black ]
  ask patch 9 0  [ set pcolor black ]
  ask patch 10 0  [ set pcolor black ]
  ask patch 11 0  [ set pcolor black ]
  ask patch -10 -1  [ set pcolor black ]
  ask patch -9 -1  [ set pcolor black ]
  ask patch 8 -1  [ set pcolor black ]
  ask patch 9 -1  [ set pcolor black ]
  ask patch 10 -1  [ set pcolor black ]
  ask patch 11 -1  [ set pcolor black ]
  ask patch 12 -1  [ set pcolor black ]
  ask patch 13 -1  [ set pcolor black ]
  ask patch 14 -1  [ set pcolor black ]
  ask patch 15 -1  [ set pcolor black ]
  ask patch -1 -2  [ set pcolor black ]
  ask patch 0 -2  [ set pcolor black ]
  ask patch 1 -2  [ set pcolor black ]
  ask patch 11 -2  [ set pcolor black ]
  ask patch 12 -2  [ set pcolor black ]
  ask patch 13 -2  [ set pcolor black ]
  ask patch 14 -2  [ set pcolor black ]
  ask patch 15 -2  [ set pcolor black ]
  ask patch -1 -3  [ set pcolor black ]
  ask patch 0 -3  [ set pcolor black ]
  ask patch 1 -3  [ set pcolor black ]
  ask patch 2 -3  [ set pcolor black ]
  ask patch 3 -3  [ set pcolor black ]
  ask patch -1 -4  [ set pcolor black ]
  ask patch 0 -4  [ set pcolor black ]
  ask patch 1 -4  [ set pcolor black ]
  ask patch 2 -4  [ set pcolor black ]
  ask patch 3 -4  [ set pcolor black ]
  ask patch 2 -5  [ set pcolor black ]
  ask patch 3 -5  [ set pcolor black ]
  ask patch 1 -6  [ set pcolor black ]
  ask patch 2 -6  [ set pcolor black ]
  ask patch 3 -6  [ set pcolor black ]
  ask patch -14 -7  [ set pcolor black ]
  ask patch -13 -7  [ set pcolor black ]
  ask patch -12 -7  [ set pcolor black ]
  ask patch -11 -7  [ set pcolor black ]
  ask patch -10 -7  [ set pcolor black ]
  ask patch -9 -7  [ set pcolor black ]
  ask patch -8 -7  [ set pcolor black ]
  ;ask patch -7 -7  [ set pcolor black ]
  ;set pcolor-of patch -6 -7  [ set pcolor black ]
  ask patch -5 -7  [ set pcolor black ]
  ask patch 1 -7  [ set pcolor black ]
  ask patch 2 -7  [ set pcolor black ]
  ask patch 3 -7  [ set pcolor black ]
  ask patch 9 -7  [ set pcolor black ]
  ask patch 10 -7  [ set pcolor black ]
  ask patch 11 -7  [ set pcolor black ]
  ask patch -14 -8  [ set pcolor black ]
  ask patch -10 -8  [ set pcolor black ]
  ask patch -5 -8  [ set pcolor black ]
  ask patch 9 -8  [ set pcolor black ]
  ask patch 10 -8  [ set pcolor black ]
  ask patch 11 -8  [ set pcolor black ]
  ask patch -14 -9  [ set pcolor black ]
  ask patch -10 -9  [ set pcolor black ]
  ask patch -6 -9  [ set pcolor black ]
  ask patch -5 -9  [ set pcolor black ]
  ask patch 9 -9  [ set pcolor black ]
  ask patch 10 -9  [ set pcolor black ]
  ask patch 11 -9  [ set pcolor black ]
  ask patch -14 -10  [ set pcolor black ]
  ask patch -12 -10  [ set pcolor black ]
  ask patch -5 -10  [ set pcolor black ]
  ask patch 9 -10  [ set pcolor black ]
  ask patch 10 -10  [ set pcolor black ]
  ask patch 11 -10  [ set pcolor black ]
  ask patch 12 -10  [ set pcolor black ]
  ask patch 13 -10  [ set pcolor black ]
  ask patch -14 -11  [ set pcolor black ]
  ask patch -13 -11  [ set pcolor black ]
  ask patch -12 -11  [ set pcolor black ]
  ask patch -9 -11  [ set pcolor black ]
  ask patch -8 -11  [ set pcolor black ]
  ask patch -7 -11  [ set pcolor black ]
  ask patch -6 -11  [ set pcolor black ]
  ask patch -5 -11  [ set pcolor black ]
  ask patch 9 -11  [ set pcolor black ]
  ask patch 10 -11  [ set pcolor black ]
  ask patch 11 -11  [ set pcolor black ]
  ask patch 12 -11  [ set pcolor black ]
  ask patch 13 -11  [ set pcolor black ]
  ask patch -9 -12  [ set pcolor black ]
  ask patch -5 -12  [ set pcolor black ]
  ;ask patch -14 -13  [ set pcolor black ]
  ask patch -11 -13  [ set pcolor black ]
  ask patch -7 -13  [ set pcolor black ]
  ask patch -5 -13  [ set pcolor black ]
  ask patch -14 -14  [ set pcolor black ]
  ask patch -13 -14  [ set pcolor black ]
  ask patch -12 -14  [ set pcolor black ]
  ask patch -11 -14  [ set pcolor black ]
  ask patch -10 -14  [ set pcolor black ]
  ask patch -9 -14  [ set pcolor black ]
  ask patch -8 -14  [ set pcolor black ]
  ask patch -7 -14  [ set pcolor black ]
  ;ask patch -6 -14  [ set pcolor black ]
  ask patch -5 -14  [ set pcolor black ]

  ask patch -32 17  [ set pcolor black ]
  ask patch -31 17  [ set pcolor black ]
  ask patch -30 17  [ set pcolor black ]
  ask patch -29 17  [ set pcolor black ]
  ask patch -28 17  [ set pcolor black ]
  ask patch -27 17  [ set pcolor black ]
  ask patch -26 17  [ set pcolor black ]


  ask patch -26 16  [ set pcolor black ]
  ask patch -26 15  [ set pcolor black ]
  ask patch -26 14  [ set pcolor black ]
  ask patch -26 13  [ set pcolor black ]
  ;ask patch -26 12  [ set pcolor black ]
  ;ask patch -26 11  [ set pcolor black ]
  ask patch -26 10  [ set pcolor black ]


  ask patch -26 10  [ set pcolor black ]
  ask patch -25 10  [ set pcolor black ]
  ask patch -24 10  [ set pcolor black ]
  ask patch -23 10  [ set pcolor black ]
  ask patch -22 10  [ set pcolor black ]
  ask patch -21 10  [ set pcolor black ]

  ask patch -26 5  [ set pcolor black ]
  ask patch -25 6  [ set pcolor black ]
  ask patch -24 7  [ set pcolor black ]
  ask patch -23 8  [ set pcolor black ]
  ask patch -22 9  [ set pcolor black ]
  ask patch -21 10  [ set pcolor black ]
  ask patch -21 9  [ set pcolor black ]

  ask patch -26 4  [ set pcolor black ]
  ask patch -25 5  [ set pcolor black ]
  ask patch -24 6  [ set pcolor black ]
  ask patch -23 7  [ set pcolor black ]
  ask patch -22 8  [ set pcolor black ]
  ask patch -21 9  [ set pcolor black ]

   ask patch -26 5  [ set pcolor black ]
  ask patch -26 4  [ set pcolor black ]
  ask patch -26 3  [ set pcolor black ]
  ask patch -26 2  [ set pcolor black ]
  ask patch -26 1  [ set pcolor black ]

  ask patch -31 5  [ set pcolor black ]
  ask patch -31 4  [ set pcolor black ]
  ask patch -31 3  [ set pcolor black ]
  ask patch -31 2  [ set pcolor black ]
  ask patch -31 1  [ set pcolor black ]
  ask patch -31 0  [ set pcolor black ]

  ask patch -27 -5  [ set pcolor black ]
  ask patch -28 -5  [ set pcolor black ]
  ask patch -28 -4  [ set pcolor black ]
  ask patch -29 -4  [ set pcolor black ]
  ask patch -29 -3  [ set pcolor black ]
  ask patch -30 -3  [ set pcolor black ]
  ask patch -30 -2  [ set pcolor black ]
  ask patch -31 -2  [ set pcolor black ]
  ask patch -31 -1  [ set pcolor black ]
  ask patch -27 0  [ set pcolor black ]

  ask patch -21 9  [ set pcolor black ]
  ask patch -20 9  [ set pcolor black ]
  ask patch -19 9  [ set pcolor black ]
  ask patch -18 9  [ set pcolor black ]
  ask patch -17 9  [ set pcolor black ]
  ask patch -16 9  [ set pcolor black ]

  ask patch -21 10  [ set pcolor black ]
  ask patch -20 10  [ set pcolor black ]
  ask patch -19 10  [ set pcolor black ]
  ask patch -18 10  [ set pcolor black ]
  ask patch -17 10  [ set pcolor black ]
  ask patch -16 10  [ set pcolor black ]

  ;ask patch -16 8  [ set pcolor black ]
  ask patch -16 7  [ set pcolor black ]
  ask patch -16 6 [ set pcolor black ]
  ask patch -16 5  [ set pcolor black ]
  ask patch -16 4  [ set pcolor black ]

  ask patch -34 -14  [ set pcolor black ]
  ask patch -33 -14  [ set pcolor black ]
  ask patch -32 -14  [ set pcolor black ]
  ask patch -31 -14  [ set pcolor black ]
  ask patch -30 -14  [ set pcolor black ]
  ask patch -29 -14  [ set pcolor black ]
  ask patch -28 -14  [ set pcolor black ]

  ask patch -28 -13  [ set pcolor black ]
  ask patch -27 -12  [ set pcolor black ]
  ask patch -26 -11  [ set pcolor black ]
  ask patch -25 -10  [ set pcolor black ]
  ask patch -24 -9  [ set pcolor black ]
  ;ask patch -23 -8  [ set pcolor black ]
  ask patch -22 -7  [ set pcolor black ]
  ask patch -21 -6  [ set pcolor black ]
  ask patch -20 -5  [ set pcolor black ]
  ask patch -19 -4  [ set pcolor black ]
  ask patch -18 -3  [ set pcolor black ]
  ask patch -17 -3  [ set pcolor black ]
  ask patch -17 -2  [ set pcolor black ]

  ask patch -27 -13  [ set pcolor black ]
  ask patch -26 -12  [ set pcolor black ]
  ask patch -25 -11  [ set pcolor black ]
  ask patch -24 -10  [ set pcolor black ]
  ask patch -23 -9  [ set pcolor black ]
  ;ask patch -22 -8  [ set pcolor black ]
  ask patch -21 -7  [ set pcolor black ]
  ask patch -20 -6  [ set pcolor black ]
  ask patch -19 -5  [ set pcolor black ]
  ask patch -18 -4  [ set pcolor black ]

  ask patch -17 -1  [ set pcolor black ]
  ask patch -18 -1  [ set pcolor black ]
  ask patch -19 -1  [ set pcolor black ]
  ask patch -20 -1  [ set pcolor black ]
  ask patch -21 -1  [ set pcolor black ]

  ask patch -28 -15  [ set pcolor black ]
  ask patch -28 -16  [ set pcolor black ]
  ask patch -28 -17  [ set pcolor black ]

  ask patch -28 -17  [ set pcolor black ]
  ask patch -27 -17  [ set pcolor black ]
  ask patch -26 -17  [ set pcolor black ]
  ask patch -25 -17  [ set pcolor black ]
  ;fask patch -24 -17  [ set pcolor black ]
  ask patch -23 -17  [ set pcolor black ]
  ask patch -22 -17  [ set pcolor black ]
  ask patch -21 -17  [ set pcolor black ]
  ask patch -20 -17  [ set pcolor black ]

  ask patch -20 -16  [ set pcolor black ]
  ask patch -20 -15  [ set pcolor black ]
  ask patch -20 -14  [ set pcolor black ]
  ask patch -20 -13  [ set pcolor black ]
  ask patch -20 -12  [ set pcolor black ]

  ;ask patch 34 -13  [ set pcolor black ]
  ;ask patch 33 -13  [ set pcolor black ]
  ask patch 32 -13  [ set pcolor black ]
  ask patch 31 -13  [ set pcolor black ]
  ask patch 30 -13  [ set pcolor black ]

  ask patch 29 -13  [ set pcolor black ]
  ask patch 28 -13  [ set pcolor black ]
  ask patch 27 -13  [ set pcolor black ]
  ask patch 26 -13  [ set pcolor black ]
  ask patch 26 -12  [ set pcolor black ]
  ask patch 25 -12  [ set pcolor black ]
  ask patch 25 -11  [ set pcolor black ]
  ask patch 24 -11  [ set pcolor black ]
  ask patch 24 -10  [ set pcolor black ]
  ask patch 23 -10  [ set pcolor black ]
  ask patch 23 -9  [ set pcolor black ]
  ask patch 22 -9  [ set pcolor black ]
  ask patch 22 -8  [ set pcolor black ]
  ask patch 21 -8  [ set pcolor black ]
  ask patch 21 -7  [ set pcolor black ]
  ask patch 20 -7  [ set pcolor black ]
  ask patch 20 -6  [ set pcolor black ]
  ;ask patch 19 -6  [ set pcolor black ]
  ;ask patch 19 -5  [ set pcolor black ]
  ask patch 18 -5  [ set pcolor black ]
  ask patch 18 -4  [ set pcolor black ]
  ask patch 17 -4  [ set pcolor black ]
  ask patch 17 -3  [ set pcolor black ]
  ask patch 16 -3  [ set pcolor black ]
  ask patch 16 -2  [ set pcolor black ]

  ask patch 29 -4  [ set pcolor black ]
  ask patch 28 -4  [ set pcolor black ]
  ask patch 27 -4  [ set pcolor black ]
  ask patch 26 -3  [ set pcolor black ]
  ask patch 25 -2  [ set pcolor black ]
  ask patch 24 -1  [ set pcolor black ]
  ask patch 23 0  [ set pcolor black ]
  ask patch 22 1  [ set pcolor black ]
  ask patch 21 2  [ set pcolor black ]

  ask patch 28 -4  [ set pcolor black ]
  ask patch 27 -4  [ set pcolor black ]
  ask patch 26 -4  [ set pcolor black ]
  ask patch 25 -3  [ set pcolor black ]
  ask patch 24 -2  [ set pcolor black ]
  ask patch 23 -1  [ set pcolor black ]
  ask patch 22 0  [ set pcolor black ]
  ask patch 21 1  [ set pcolor black ]

  ask patch 21 2  [ set pcolor black ]
  ask patch 21 3  [ set pcolor black ]
  ask patch 21 4  [ set pcolor black ]
  ;ask patch 21 5  [ set pcolor black ]
  ask patch 21 6  [ set pcolor black ]
  ask patch 21 7  [ set pcolor black ]
  ask patch 21 8  [ set pcolor black ]

  ask patch 21 8  [ set pcolor black ]
  ask patch 22 9  [ set pcolor black ]
  ask patch 23 10  [ set pcolor black ]
  ask patch 24 11  [ set pcolor black ]
  ask patch 25 12  [ set pcolor black ]
  ask patch 26 13  [ set pcolor black ]
  ask patch 27 14  [ set pcolor black ]
  ask patch 28 15  [ set pcolor black ]



  ask patch 21 9  [ set pcolor black ]
  ask patch 22 10  [ set pcolor black ]
  ask patch 23 11  [ set pcolor black ]
  ask patch 24 12  [ set pcolor black ]
  ask patch 25 13  [ set pcolor black ]
  ask patch 26 14  [ set pcolor black ]
  ask patch 27 15  [ set pcolor black ]

  ask patch 28 14  [ set pcolor black ]
  ask patch 27 15  [ set pcolor black ]
  ask patch 26 15  [ set pcolor black ]
  ask patch 25 15  [ set pcolor black ]
  ask patch 24 15  [ set pcolor black ]
  ask patch 23 15  [ set pcolor black ]
  ask patch 22 15  [ set pcolor black ]

  ask patch 21 16  [ set pcolor black ]
  ask patch 20 17  [ set pcolor black ]
  ask patch 19 18  [ set pcolor black ]
  ;ask patch 18 19  [ set pcolor black ]

  ask patch 21 15  [ set pcolor black ]
  ask patch 20 16  [ set pcolor black ]
  ask patch 19 17  [ set pcolor black ]
  ask patch 18 18  [ set pcolor black ]
  ;ask patch 17 18  [ set pcolor black ]

  ;ask patch 17 19  [ set pcolor black ]
  ask patch 16 18  [ set pcolor black ]
  ask patch 15 17  [ set pcolor black ]
  ask patch 14 16  [ set pcolor black ]
  ask patch 13 15  [ set pcolor black ]
  ask patch 12 14  [ set pcolor black ]

  ;ask patch 16 19  [ set pcolor black ]
  ask patch 15 18  [ set pcolor black ]
  ask patch 14 17  [ set pcolor black ]
  ask patch 13 16  [ set pcolor black ]
  ask patch 12 15  [ set pcolor black ]
  ask patch 11 14  [ set pcolor black ]


  ask patch 12 14  [ set pcolor black ]
  ask patch 11 14  [ set pcolor black ]
  ask patch 10 14  [ set pcolor black ]
  ask patch 9 14  [ set pcolor black ]
  ;ask patch 8 14  [ set pcolor black ]
  ask patch 7 14  [ set pcolor black ]
  ask patch 6 14  [ set pcolor black ]
  ask patch 5 14  [ set pcolor black ]
  ask patch 4 14  [ set pcolor black ]
  ask patch 3 14  [ set pcolor black ]

  ask patch 3 14  [ set pcolor black ]
  ask patch 3 13  [ set pcolor black ]
  ask patch 3 12  [ set pcolor black ]

  ask patch 4 14  [ set pcolor black ]
  ask patch 4 13  [ set pcolor black ]
  ask patch 4 12  [ set pcolor black ]

  ask patch -3 4  [ set pcolor black ]
  ask patch -2 4  [ set pcolor black ]
  ask patch -1 4  [ set pcolor black ]
  ask patch 0 4  [ set pcolor black ]

  ask patch 1 3  [ set pcolor black ]
  ask patch 2 2  [ set pcolor black ]
  ask patch 3 1  [ set pcolor black ]
  ask patch 4 0  [ set pcolor black ]

  ask patch 0 3  [ set pcolor black ]
  ask patch 1 2  [ set pcolor black ]
  ask patch 2 1  [ set pcolor black ]
  ask patch 3 0  [ set pcolor black ]

  ;ask patch -4 3  [ set pcolor black ]
  ;ask patch -5 2  [ set pcolor black ]

  ;ask patch -5 2  [ set pcolor black ]
  ask patch -5 1  [ set pcolor black ]
  ask patch -5 0  [ set pcolor black ]
  ask patch -5 -1  [ set pcolor black ]
  ask patch -5 -2  [ set pcolor black ]
  ask patch -5 -3  [ set pcolor black ]
  ask patch -5 -4  [ set pcolor black ]
  ask patch -5 -5  [ set pcolor black ]
  ;ask patch -5 -6  [ set pcolor black ]

  ask patch -1 -10  [ set pcolor black ]
  ask patch 0 -10  [ set pcolor black ]
  ask patch 1 -10  [ set pcolor black ]
  ask patch 2 -10  [ set pcolor black ]
  ask patch 3 -10  [ set pcolor black ]
  ask patch 4 -10  [ set pcolor black ]

  ask patch 4 -11  [ set pcolor black ]
  ask patch 4 -12  [ set pcolor black ]
  ask patch 4 -13  [ set pcolor black ]
  ask patch 4 -14  [ set pcolor black ]
  ask patch 4 -15  [ set pcolor black ]

  ask patch 4 -15  [ set pcolor black ]
  ask patch 5 -15  [ set pcolor black ]
  ask patch 6 -15  [ set pcolor black ]
  ask patch 7 -15  [ set pcolor black ]
  ;ask patch 8 -15  [ set pcolor black ]
  ask patch 9 -15  [ set pcolor black ]
  ask patch 10 -15  [ set pcolor black ]
  ask patch 11 -15  [ set pcolor black ]
  ask patch 12 -15  [ set pcolor black ]
  ask patch 13 -15  [ set pcolor black ]
  ask patch 14 -15  [ set pcolor black ]

  ask patch 14 -15  [ set pcolor black ]
  ask patch 14 -14  [ set pcolor black ]
  ask patch 14 -13  [ set pcolor black ]
  ask patch 14 -12  [ set pcolor black ]
  ask patch 14 -11  [ set pcolor black ]
  ask patch 14 -10  [ set pcolor black ]

  ask patch -26 0  [ set pcolor black ]
  ask patch -8 14  [ set pcolor black ]
  ask patch -8 12  [ set pcolor black ]

  ;ask patch -1 -9  [ set pcolor black ]
  ask patch -1 -8  [ set pcolor black ]
  ask patch 0 -8  [ set pcolor black ]
  ask patch 1 -8  [ set pcolor black ]

  ask patch 3 -16  [ set pcolor black ]
  ask patch 2 -17  [ set pcolor black ]
  ;ask patch 1 -18  [ set pcolor black ]
  ;ask patch 0 -19  [ set pcolor black ]

  ask patch 3 -15  [ set pcolor black ]
  ask patch 2 -16  [ set pcolor black ]
  ask patch 1 -17  [ set pcolor black ]
  ;ask patch 0 -18  [ set pcolor black ]
  ;ask patch -1 -19  [ set pcolor black ]


  ask patch -19 -12  [ set pcolor black ]
  ask patch -18 -14  [ set pcolor black ]
  ask patch -18 -12  [ set pcolor black ]
  ask patch -18 -13  [ set pcolor black ]
  ask patch -17 -14  [ set pcolor black ]

  ask patch -16 -14  [ set pcolor black ]
  ask patch -15 -14  [ set pcolor black ]
  ask patch -17 -14  [ set pcolor black ]

  ask patch -11 15  [ set pcolor black ]
  ask patch -12 15  [ set pcolor black ]
  ask patch -13 15  [ set pcolor black ]
  ask patch -14 15  [ set pcolor black ]
  ask patch -15 15  [ set pcolor black ]
  ;ask patch -16 15  [ set pcolor black ]
  ask patch -17 15  [ set pcolor black ]
  ask patch -18 15  [ set pcolor black ]
  ask patch -19 15  [ set pcolor black ]

  ask patch -19 15  [ set pcolor black ]
  ask patch -19 16  [ set pcolor black ]
  ask patch -19 17  [ set pcolor black ]
  ;ask patch -19 18  [ set pcolor black ]
  ;ask patch -19 19  [ set pcolor black ]

  ask patch -5 15  [ set pcolor black ]
  ask patch -4 15  [ set pcolor black ]
  ask patch -3 15  [ set pcolor black ]
  ask patch -2 15  [ set pcolor black ]

  ask patch -2 15  [ set pcolor black ]
  ask patch -2 16  [ set pcolor black ]
  ask patch -2 17  [ set pcolor black ]

  ask patch 15 -13  [ set pcolor black ]
  ask patch 16 -13  [ set pcolor black ]
  ask patch 17 -13  [ set pcolor black ]
  ask patch 18 -13  [ set pcolor black ]
  ask patch 19 -13  [ set pcolor black ]
  ask patch 20 -13  [ set pcolor black ]
  ask patch 21 -13  [ set pcolor black ]
  ask patch 22 -13  [ set pcolor black ]

  ask patch 22 -14  [ set pcolor black ]
  ask patch 22 -15  [ set pcolor black ]
  ask patch 22 -16  [ set pcolor black ]

  ask patch 22 -16  [ set pcolor black ]
  ask patch 21 -16  [ set pcolor black ]
  ask patch 20 -16  [ set pcolor black ]

  ask patch 20 -17  [ set pcolor black ]

end
@#$#@#$#@
GRAPHICS-WINDOW
399
19
1152
458
-1
-1
10.5
1
10
1
1
1
0
0
0
1
-35
35
-20
20
1
1
1
ticks
30.0

SLIDER
24
121
196
154
rob_num
rob_num
1
200
91.0
1
1
NIL
HORIZONTAL

BUTTON
17
11
80
44
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
102
11
165
44
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
25
166
305
199
radius
radius
1
5
5.0
1
1
NIL
HORIZONTAL

BUTTON
27
209
154
242
View Network Range
ask halos [ die ]\nask robots [ make-halo ]\nask humans [ make-halo ]
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
162
209
306
242
Hide Network Range
ask halos [ die ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
244
251
363
296
n message is passed 
n_pass_times
17
1
11

SLIDER
208
122
354
155
rob_memory
rob_memory
0
100
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
258
153
408
171
robot can remember
11
0.0
1

CHOOSER
27
250
233
295
how_smart_the_robot_is?
how_smart_the_robot_is?
"Randomly Pass the Message" "Smartly Pass the Message"
1

MONITOR
245
310
323
355
Elapse Time
ticks
17
1
11

TEXTBOX
30
299
245
327
What will the robot do if it has the message?
11
0.0
1

BUTTON
185
12
260
45
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

SWITCH
24
79
140
112
show_trace?
show_trace?
0
1
-1000

SWITCH
147
79
264
112
target_move
target_move
0
1
-1000

SWITCH
269
79
393
112
target_smart_move?
target_smart_move?
0
1
-1000

SWITCH
20
363
159
396
search_slowly?
search_slowly?
1
1
-1000

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

robot
false
0
Rectangle -7500403 false true 135 90 165 120
Rectangle -13791810 true false 150 90 165 105
Rectangle -13840069 true false 135 90 150 105
Rectangle -6459832 true false 120 135 180 150
Rectangle -6459832 true false 120 180 180 195
Rectangle -6459832 true false 120 195 135 210
Rectangle -6459832 true false 165 195 180 210
Rectangle -16777216 true false 135 150 165 180
Rectangle -7500403 false true 135 150 165 180
Rectangle -16777216 true false 105 135 120 165
Rectangle -16777216 true false 180 135 195 165
Rectangle -7500403 false true 105 135 120 165
Rectangle -7500403 false true 180 135 195 165
Rectangle -2674135 true false 135 105 165 120
Rectangle -7500403 false true 120 135 180 150
Rectangle -7500403 false true 120 180 180 195
Rectangle -7500403 false true 165 195 180 210
Rectangle -7500403 false true 120 195 135 210

robot 2
false
0
Rectangle -16777216 true false 120 75 180 105
Rectangle -13840069 true false 165 75 180 90
Rectangle -13840069 true false 120 75 135 90
Rectangle -6459832 true false 120 105 180 135
Rectangle -6459832 true false 90 105 120 135
Rectangle -6459832 true false 180 105 210 135
Rectangle -6459832 true false 120 165 180 195
Rectangle -6459832 true false 120 195 135 210
Rectangle -6459832 true false 165 195 180 210
Rectangle -16777216 true false 120 135 180 165
Rectangle -7500403 false true 120 135 180 165
Rectangle -16777216 true false 90 135 105 165
Rectangle -16777216 true false 195 135 210 165
Rectangle -7500403 false true 90 135 105 165
Rectangle -7500403 false true 195 135 210 165
Rectangle -2674135 true false 135 90 165 105
Rectangle -7500403 false true 120 75 180 105
Rectangle -7500403 false true 90 105 210 135
Rectangle -7500403 false true 120 165 180 195
Rectangle -7500403 false true 165 195 180 210
Rectangle -7500403 false true 120 195 135 210

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

thin ring
true
0
Circle -7500403 false true -1 -1 301

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
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="R Increasing Number of Robots" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>n_pass_times</metric>
    <enumeratedValueSet variable="radius">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rob_num" first="1" step="5" last="200"/>
  </experiment>
  <experiment name="S Increasing Number of Robots" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>n_pass_times</metric>
    <enumeratedValueSet variable="radius">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rob_num" first="1" step="5" last="200"/>
  </experiment>
  <experiment name="R Increasing Memory" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>n_pass_times</metric>
    <enumeratedValueSet variable="radius">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rob_num" first="1" step="10" last="50"/>
    <steppedValueSet variable="rob_memory" first="1" step="3" last="100"/>
  </experiment>
  <experiment name="S Increasing Memory" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>n_pass_times</metric>
    <enumeratedValueSet variable="radius">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="rob_num" first="1" step="10" last="50"/>
    <steppedValueSet variable="rob_memory" first="1" step="3" last="100"/>
  </experiment>
  <experiment name="R Different Radius" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>n_pass_times</metric>
    <steppedValueSet variable="radius" first="1" step="1" last="5"/>
    <steppedValueSet variable="rob_num" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="rob_memory">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S Different Radius" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>n_pass_times</metric>
    <steppedValueSet variable="radius" first="1" step="1" last="5"/>
    <steppedValueSet variable="rob_num" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="rob_memory">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="S Different Radius" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>n_pass_times</metric>
    <steppedValueSet variable="radius" first="1" step="1" last="5"/>
    <steppedValueSet variable="rob_num" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="rob_memory">
      <value value="10"/>
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
