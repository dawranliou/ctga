(var *frame* 0)
(var *font* nil)
(var *font-large* nil)
(var *count-down* 1)
(local (w h) (love.window.getMode))

(fn activate []
  (set *frame* 0)
  (set *count-down* 1)
  (set *font-large* (love.graphics.newFont "assets/FSEX300.ttf" 32))
  (set *font* (love.graphics.newFont "assets/FSEX300.ttf" 24))
  (love.graphics.setDefaultFilter "nearest" "nearest"))

(fn draw [message]
  (love.graphics.setBackgroundColor (love.math.colorFromBytes
                                     51 60 87
                                     ;; 41 54 111
                                     ))
  (love.graphics.setFont *font-large*)
  (love.graphics.print "Credits" 150 100)
  (love.graphics.print "Code: Daw-Ran Liou" 150 150)
  (love.graphics.print "Art: Daw-Ran Liou" 150 200)
  (love.graphics.print "Music:" 150 250)
  (love.graphics.print "SFX: Daw-Ran Liou" 150 300)
  (when (and (<= *count-down* 0)
             (= 0 (% (math.floor (/ *frame* 30)) 2)))
    (love.graphics.setFont *font*)
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
