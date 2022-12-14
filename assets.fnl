(local assets {})

(fn init []
  (set assets.music (love.audio.newSource "assets/galacticknight.mp3" "stream"))
  (assets.music:setLooping true)
  (assets.music:setVolume 0.3)
  (set assets.sfx1 (love.audio.newSource "assets/sfx-1.wav" "static"))
  (set assets.sfx2 (love.audio.newSource "assets/sfx-2.wav" "static"))
  (set assets.sfx3 (love.audio.newSource "assets/sfx-3.wav" "static"))
  (assets.sfx3:setVolume 1.5)
  (set assets.font (love.graphics.newFont "assets/FSEX300.ttf" 24))
  (set assets.font-large (love.graphics.newFont "assets/FSEX300.ttf" 32))
  (set assets.title-sheet (love.graphics.newImage "assets/title-Sheet.png"))
  (assets.title-sheet:setFilter "nearest" "nearest")
  (set assets.sprite-sheet (love.graphics.newImage "assets/monsters.png"))
  (assets.sprite-sheet:setFilter "nearest" "nearest"))

{:assets assets
 :init init}
