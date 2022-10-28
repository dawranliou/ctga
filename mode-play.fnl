(fn draw [message]
  (love.graphics.print (love.timer.getFPS) 10 10)
  (love.graphics.setBackgroundColor (love.math.colorFromBytes
                                     51 60 87
                                     ;; 41 54 111
                                     ))
  (love.graphics.print "play" 10 100))

(fn keypressed [key set-mode]
  )

{: draw
 : keypressed}
