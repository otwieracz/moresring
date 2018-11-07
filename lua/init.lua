hw    = require "hw"
morse = require "morse"

-- init morse parser
morse.init(
function(l) print(l) end, -- letter finished fn
function(w) print(w) end, -- word finished fn
function(u) print(u) end  -- unknown letter fn
)

-- init hardware
hw.init(4, 3,
morse.short, -- short press callback
morse.long,  -- long press callback
morse.pause, -- pause (timeout) callback
morse.stop,  -- longer press callback
function() print("CONNECTING... Not yet implemented!") end -- super-long press callback
)
