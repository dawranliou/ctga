(var *frames* 0)
(var *current-level* nil)
(var *level* nil)
(var *n-row* 0)
(var *n-col* 0)
(var *grid-size* 0)
(var *state* :play)
(local (w h _flags) (love.window.getMode))
(local +margin+ 64)
(local +scale+ 3)
(local +move-frames+ 6)

(local {: assets} (require :assets))

(var *entities* [])
(var *entity-count* 0)

(fn entity [name data ...]
  (set *entity-count* (+ *entity-count* 1))
  (set data.id *entity-count*)
  (set data.name name)
  (set data.components {})
  (each [_ component (ipairs [...])]
    (tset data.components component true))
  (table.insert *entities* data)
  data)

(fn ease-in-out-quad [t]
  (if (< t 0.5)
      (* 2 t t)
      (- (* 2 (- 2 t) t))))

(fn ease-out-quad [t]
  (* (- 2 t) t))

(fn grid [row col]
  (values (+ +margin+ (* *grid-size* (- row 1)))
          (+ +margin+ (* *grid-size* (- col 1)))))

(fn run-grid->loc-system []
  (each [_ e (ipairs *entities*)]
    (when e.components.on-grid
      (let [(target-y target-x) (grid e.row e.col)]
        (if (and e.cooldown (< 0 e.cooldown))
            (let [percentage (ease-out-quad (/ (- +move-frames+ e.cooldown)
                                               +move-frames+))]
              (set e.y (+ e.y-orig (* percentage (- target-y e.y-orig))))
              (set e.x (+ e.x-orig (* percentage (- target-x e.x-orig)))))
            (set (e.y e.x) (values target-y target-x)))))))

(fn run-render-system []
  (love.graphics.setColor 0.8 0.8 0.8 0.8)
  (love.graphics.setLineWidth 3)
  (each [_ e (ipairs *entities*)]
    (when (and e.components.input)
      (love.graphics.polygon "line"
                             (+ e.x 24) (+ e.y 36)
                             (+ e.x 48) (+ e.y 48)
                             (+ e.x 24) (+ e.y 60)
                             e.x        (+ e.y 48))
      ;; (love.graphics.ellipse "line"
      ;;                        (+ e.x 24) (+ e.y 48)
      ;;                        24 12)
      ;; (love.graphics.rectangle "line" e.x e.y 48 48)
      ))
  (love.graphics.setColor 1 1 1)
  (love.graphics.setLineWidth 1)
  (each [_ e (ipairs *entities*)]
    (when (and e.components.render
               e.quad
               (= 0 e.z))
      (love.graphics.draw e.image e.quad e.x e.y 0 +scale+)))
  (each [_ e (ipairs *entities*)]
    (when (and e.components.render
               e.quad
               (= 1 e.z))
      (love.graphics.draw e.image e.quad e.x e.y 0 +scale+)))
  ;; (each [_ e (ipairs *entities*)]
  ;;   (when (and e.components.render (= 2 e.z))
  ;;     (love.graphics.draw e.image e.quad e.x e.y 0 +scale+)))
  )

(fn run-animation-system []
  (each [_ e (ipairs *entities*)]
    (when e.components.animate
      (when (and e.cooldown (< 0 e.cooldown))
        (set e.cooldown (- e.cooldown 1)))
      (set e.quad (. e.animations (+ 1 (% (math.floor (/ *frames* 24)) 2)))))))

(fn entity-at [row col]
  (accumulate [found false
               _ e (ipairs *entities*)
               &until found]
    (when (and (= e.row row)
               (= e.col col))
      e)))

(fn within-bound? [row col]
  (and (<= 1 row *n-row*)
       (<= 1 col *n-col*)))

(fn out-of-bound? [row col]
  (not (within-bound? row col)))

(fn target-ahead [entity offset-row offset-col]
  (var target-row entity.row)
  (var target-col entity.col)
  (var found nil)
  (while (and (not found)
              (within-bound? target-row target-col))
    (set target-row (+ offset-row target-row))
    (set target-col (+ offset-col target-col))
    (set found (entity-at target-row target-col)))
  found)

(fn run-input-system [key]
  (each [_ e (ipairs *entities*)]
    (when e.components.input
      (let [target-entity (match key
                            "up" (target-ahead e -1 0)
                            "down" (target-ahead e 1 0)
                            "left" (target-ahead e 0 -1)
                            "right" (target-ahead e 0 1))]
        (when target-entity
          (set e.cooldown +move-frames+)
          (set e.x-orig e.x)
          (set e.y-orig e.y)
          (set e.row target-entity.row)
          (set e.col target-entity.col)

          (set target-entity.components.rescued true)
          (set target-entity.cooldown +move-frames+)
          (set target-entity.row (- target-entity.row 1))
          ;; (set target-entity.row 1)
          ;; (set target-entity.col 10)
          (set target-entity.x-orig target-entity.x)
          (set target-entity.y-orig target-entity.y))))))

(fn run-rescued-system []
  (for [i (length *entities*) 1 -1]
    (let [e (. *entities* i)]
      (when e.components.rescued
        (set e.cooldown (- e.cooldown 1))
        (when (< e.cooldown 0)
          (table.remove *entities* i))))))

(fn minion [name idx row col ...]
  (let [frames [(love.graphics.newQuad 0 (* idx 16) 16 16
                                       (assets.sprite-sheet:getWidth)
                                       (assets.sprite-sheet:getHeight))
                (love.graphics.newQuad 16 (* idx 16) 16 16
                                       (assets.sprite-sheet:getWidth)
                                       (assets.sprite-sheet:getHeight))]]
    (entity name
            {:col col :row row :x 0 :y 0 :z 1
             :image assets.sprite-sheet
             :animations frames
             :quad (. frames 1)
             :cooldown 0
             :quad nil}
            "animate" "render" "on-grid" "solid" ...)))

(fn load-level [filename]
  (set *state* :play)
  (set *frames* 0)
  (set *current-level* filename)
  (for [i (length *entities*) 1 -1]
    (table.remove *entities* i))
  (set *level* (icollect [line (love.filesystem.lines filename)]
                 (icollect [tile (string.gmatch line "%g")]
                   tile)))
  (set *n-row* (length *level*))
  (set *n-col* (length (. *level* 1)))
  (set *grid-size* (math.min
                    (math.floor (/ (- w +margin+ +margin+) *n-col*))
                    (math.floor (/ (- h +margin+ +margin+) *n-row*))))
  (each [row line (ipairs *level*)]
    (each [col tile (ipairs line)]
      (let [upper-case? (= tile (string.upper tile))]
        (match (string.upper tile)
          "C" (minion "C" 0 row col (when upper-case? "input"))
          "T" (minion "T" 1 row col (when upper-case? "input"))
          "G" (minion "G" 2 row col (when upper-case? "input"))
          "A" (minion "A" 3 row col (when upper-case? "input"))))))
  :loaded)

(fn load-next-level []
  (let [next-level (match *current-level*
                     nil "data/tut-1.txt"
                     "data/tut-1.txt" "data/tut-2.txt"
                     "data/tut-2.txt" "data/level-1.txt"
                     ;; "data/level-1.txt" "data/level-2.txt"
                     ;; "data/level-2.txt" "data/level-3.txt"
                     ;; "data/level-3.txt" "data/level-4.txt"
                     ;; "data/level-4.txt" "data/level-5.txt"
                     ;; "data/level-5.txt" "data/level-6.txt"
                     ;; "data/level-6.txt" "data/level-7.txt"
                     ;; "data/level-7.txt" "data/level-8.txt"
                     ;; "data/level-8.txt" "data/level-9.txt"
                     ;; "data/level-9.txt" "data/level-10.txt"
                     )]
    (if next-level
        (load-level next-level)
        (set *state* :win))))

(fn get-level-title []
  (match *current-level*
    "data/tut-1.txt" "Tutorial 1/2"
    "data/tut-2.txt" "Tutorial 2/2"
    "data/level-1.txt" "1/10"
    "data/level-2.txt" "2/10"
    "data/level-3.txt" "3/10"
    "data/level-4.txt" "4/10"
    "data/level-5.txt" "5/10"
    "data/level-6.txt" "6/10"
    "data/level-7.txt" "7/10"
    "data/level-8.txt" "8/10"
    "data/level-9.txt" "9/10"
    "data/level-10.txt" "10/10"))

(fn get-level-desc []
  (match *current-level*
    "data/tut-1.txt" "→"
    "data/tut-2.txt" "→ →"
    "data/level-1.txt" nil
    "data/level-2.txt" nil
    "data/level-3.txt" nil
    "data/level-4.txt" nil
    "data/level-5.txt" nil
    "data/level-6.txt" nil
    "data/level-7.txt" nil
    "data/level-8.txt" nil
    "data/level-9.txt" nil
    "data/level-10.txt" "Final Puzzle"))

(fn run-win-checker-system []
  (when (accumulate [win true
                     _ e (ipairs *entities*)
                     &until (not win)]
          (or e.components.input
              e.components.rescued))
    (set *state* :level-cleared)
    (set *frames* 0)))

(fn activate []
  (set *current-level* nil)
  (load-next-level))

(fn draw-grid []
  (love.graphics.setColor 0.5 0.5 0.5)
  (for [row 1 *n-row*]
    (for [col 1 *n-col*]
      (let [x (+ +margin+ (* (- col 1) *grid-size*))
            y (+ +margin+ (* (- row 1) *grid-size*))]
        (love.graphics.polygon "line"
                               (+ x 24) (+ y 36)
                               (+ x 48) (+ y 48)
                               (+ x 24) (+ y 60)
                               x        (+ y 48))
        ;; (love.graphics.ellipse "line" (+ x 24) (+ y 48) 24 12)
        ;; (love.graphics.rectangle "line" x y 48 48)
        )))
  (love.graphics.setColor 1 1 1))

(fn update [dt set-mode]
  (set *frames* (+ 1 *frames*))

  (run-animation-system)
  (run-grid->loc-system)
  (run-rescued-system)

  (match *state*
    :play (run-win-checker-system)
    :level-cleared (when (< 60 *frames*)
                     (load-next-level))
    :win (when (< 120 *frames*)
           (set *state* :into-ending))
    :into-ending (when (< 120 *frames*)
                   (set-mode :mode-ending))))

(fn draw [message]
  ;; (love.graphics.print (love.timer.getFPS) 10 10)
  (love.graphics.setBackgroundColor (love.math.colorFromBytes
                                     51 60 87
                                     ;; 41 54 111
                                     ))
  (draw-grid)
  (run-render-system)

  ;; HUD
  (love.graphics.printf (or (get-level-title) "") 0 32 w :center)
  (love.graphics.setFont assets.font-large)
  (love.graphics.printf (or (get-level-desc) "") 0 550 w :center)
  (love.graphics.setFont assets.font)

  (match *state*
    :level-cleared
    (do
      (love.graphics.setColor 0 0 0 0.5)
      (love.graphics.rectangle "fill" 0 0 w h)
      (love.graphics.setColor 1 1 1)
      (love.graphics.printf "AWESOME!" 0 (/ h 2) w :center))
    :win
    (do
      (love.graphics.setColor 0 0 0 0.5)
      (love.graphics.rectangle "fill" 0 0 w h)
      (love.graphics.setColor 1 1 1)
      (love.graphics.printf "YOU WIN!" 0 (/ h 2) w :center))))

(fn keypressed [key set-mode]
  (when (or (= key "up")
            (= key "down")
            (= key "left")
            (= key "right"))
    (match (love.math.random 3)
      1 (assets.sfx1:play)
      2 (assets.sfx2:play)
      3 (assets.sfx3:play)))
  (when (= *state* :play) (run-input-system key)))

{: activate
 : update
 :entities *entities*
 : draw
 : keypressed}
