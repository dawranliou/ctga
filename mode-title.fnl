(local {: assets} (require :assets))
(var *frame-counter* 0)
(var *frames* [])
(var *count-down* 1)
(local (w h) (love.window.getMode))

(fn activate []
  (assets.music:play)
  (set *frame-counter* 0)
  (set *count-down* 1)
  (love.graphics.setFont assets.font)
  (let [image-w (assets.title-sheet:getWidth)
        image-h (assets.title-sheet:getHeight)]
    (set *frames* [(love.graphics.newQuad 0 0 64 64 image-w image-h)
                   (love.graphics.newQuad 64 0 64 64 image-w image-h)
                   (love.graphics.newQuad 128 0 64 64 image-w image-h)])))

(fn draw [message]
  ;; (love.graphics.print (love.timer.getFPS) 10 10)
  (love.graphics.setBackgroundColor (love.math.colorFromBytes
                                     51 60 87
                                     ;; 41 54 111
                                     ))
  (let [current-frame (+ 1 (% (math.floor (/ *frame-counter* 6)) 3))
        current-quad (. *frames* current-frame)]
    (when (and (< *count-down* 0)
               (= 0 (% (math.floor (/ *frame-counter* 30)) 2)))
      (love.graphics.printf "press <x> to start" 0 500 w :center))
    (when current-quad
      (love.graphics.draw assets.title-sheet current-quad
                          (- (/ w 2) (/ (* 64 5) 2))
                          (- (/ h 2) (/ (* 64 5) 2))
                          0 5))))

(fn update [dt set-mode]
  (when (< 0 *count-down*)
    (set *count-down* (- *count-down* dt)))
  (if (< *frame-counter* 65535)
      (set *frame-counter* (+ *frame-counter* 1))
      (set *frame-counter* 0)))

(fn keypressed [key set-mode]
  (assets.sfx1:play)
  (match key
    "x" (when (< *count-down* 0) (set-mode :mode-play))))

{: activate
 : draw
 : update
 : keypressed}
