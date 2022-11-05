(var *frame* 0)
(local {: assets} (require :assets))
(var *count-down* 1)
(local (w h) (love.window.getMode))

(fn activate []
  (assets.music:seek 0)
  (set *frame* 0)
  (set *count-down* 1))

(fn draw [message]
  (love.graphics.setBackgroundColor (love.math.colorFromBytes
                                     51 60 87
                                     ;; 41 54 111
                                     ))
  (love.graphics.setFont assets.font-large)
  (love.graphics.print "Credits" 150 100)
  (love.graphics.print "Code: Daw-Ran Liou" 150 150)
  (love.graphics.print "Art: Daw-Ran Liou" 150 200)
  (love.graphics.print "Music: MAOU" 150 250)
  (love.graphics.print "SFX: Daw-Ran Liou" 150 300)
  (when (and (<= *count-down* 0)
             (= 0 (% (math.floor (/ *frame* 30)) 2)))
    (love.graphics.setFont assets.font)
    (love.graphics.printf "press <x> to restart" 0 500 w :center)))

(fn update [dt set-mode]
  (when (< 0 *count-down*)
    (set *count-down* (- *count-down* dt)))
  (set *frame* (+ *frame* 1)))

(fn keypressed [key set-mode]
  (match key
    "x" (when (<= *count-down* 0) (set-mode :mode-title))))

{: activate
 : draw
 : update
 : keypressed}
