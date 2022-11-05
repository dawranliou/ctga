(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))
(local assets (require :assets))
(local canvas (let [(w h) (love.window.getMode)]
                (love.graphics.newCanvas w h)))
(var scale 1)

;; set the first mode
(var (mode mode-name) nil)

(fn set-mode [new-mode-name ...]
  (set (mode mode-name) (values (require new-mode-name) new-mode-name))
  (when mode.activate
    (match (pcall mode.activate ...)
      (false msg) (print mode-name "activate error" msg))))

(fn love.load [args]
  (assets.init)
  (set-mode :mode-title)
  (canvas:setFilter "nearest" "nearest")
  (when (~= :web (. args 1)) (repl.start)))

(fn safely [f]
  (xpcall f #(set-mode :mode-error mode-name $ (fennel.traceback))))

(fn love.draw []
  ;; the canvas allows you to get sharp pixel-art style scaling; if you
  ;; don't want that, just skip that and call mode.draw directly.
  (love.graphics.setCanvas canvas)
  (love.graphics.clear)
  (love.graphics.setColor 1 1 1)
  (safely mode.draw)
  (love.graphics.setCanvas)
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw canvas 0 0 0 scale scale))

(fn love.update [dt]
  (when mode.update
    (safely #(mode.update dt set-mode))))

(fn love.keypressed [key]
  (if (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") (= key "q"))
      (love.event.quit)
      (= key "f1")
      (safely #(set-mode mode-name))
      (= key "f2")
      (safely #(set-mode :mode-title))
      (= key "f3")
      (safely #(set-mode :mode-play))
      (= key "f4")
      (safely #(set-mode :mode-ending))
      ;; add what each keypress should do in each mode
      (safely #(mode.keypressed key set-mode))))
