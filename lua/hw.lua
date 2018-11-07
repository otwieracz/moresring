local M = {}

M.btn_pin = null
M.led_pin = null

-- Callback functions
M.short_fn = null
M.long_fn  = null
M.pause_fn = null
M.stop_fn  = null

-- Button
EVENT_LONG    = 250 -- event longer than this ms is considered long
EVENT_STOP    = 1500 -- event longer than this ms is considered stop (end of word)
EVENT_CONNECT = 5000 -- event longer than this ms is considered connectivity request
EVENT_PAUSE_TIMEOUT = 1500 -- inactivity period after which pause (end of letter) is triggered
M.pause_timer = tmr.create()

DEBOUNCE_UP = 20 -- release debounce time, in miliseconds
DEBOUNCE_DN = 10 -- push debounce time, in miliseconds
M.debounce_timer = tmr.create()

-- when button has been pressed
M.event_start_time = null 

-- Watchdog timer, preventing button to be pressed indefinitely
MAX_EVENT_TIME = 10000 -- maximum time of, in milliseconds
M.watchdog_timer = tmr.create()

-- LED blinking
BLINK_LENGTH = 20
BLINK_PAUSE  = 80
M.blink1_timer = tmr.create()
M.blink2_timer = tmr.create()

-- Interrupts
function INT_down(level, timestamp, count)
    -- disable interrupts
    gpio.trig(M.btn_pin, "none")
    -- wait DEBOUNCE_DN to settle and start handler
    M.debounce_timer:register(DEBOUNCE_DN, tmr.ALARM_SINGLE, function()
        btn_pressed(timestamp)
        gpio.trig(M.btn_pin, "up", INT_up)
    end)
    M.debounce_timer:start() 
end

function INT_up(level, timestamp, count)
    -- disable interrupts
    gpio.trig(M.btn_pin, "none")
    M.debounce_timer:register(DEBOUNCE_UP, tmr.ALARM_SINGLE, function()
        btn_released(timestamp)
        gpio.trig(M.btn_pin, "down", INT_down)
    end)
    M.debounce_timer:start() 
end

-- LED handling
function M.blink(times)
    gpio.write(M.led_pin, gpio.LOW)
    M.blink1_timer:register(BLINK_LENGTH, tmr.ALARM_SINGLE, function()
        gpio.write(M.led_pin, gpio.HIGH)
        M.blink2_timer:register(BLINK_PAUSE, tmr.ALARM_SINGLE, function()
            if times > 1 then
                M.blink(times-1)
            else
                gpio.write(M.led_pin, gpio.HIGH)
            end
        end)
        M.blink2_timer:start()
    end)
    M.blink1_timer:start()
end

-- Button handling
function btn_pressed(timestamp)
    M.event_start_time = timestamp
    -- Start event watchdog timer
    M.watchdog_timer:start() 
end

function btn_released(timestamp)
    -- stop event watchdog timer, as event finished
    M.watchdog_timer:stop()
    M.pause_timer:stop()

    -- calculate how long button were pressed
    -- FIXME: timer can loop!
    local event_duration = (timestamp - M.event_start_time)/1000
    print(string.format("Button pressed for %dms (%d - %d)\n", event_duration, timestamp/1000, M.event_start_time/1000))
    -- FIXME: attach morse handler here
    if (event_duration < EVENT_LONG) then
        -- SHORT
        M.blink(1)
        M.short_fn()
        M.pause_timer:start()
    elseif (EVENT_LONG <= event_duration and event_duration < EVENT_STOP) then
        -- LONG
        M.blink(2)
        M.long_fn()
        M.pause_timer:start()
    elseif (EVENT_STOP <= event_duration and event_duration < EVENT_CONNECT) then
        -- STOP (end of word)
        M.blink(4)
        M.stop_fn()
    else
        -- CONNECT
        M.blink(10)
        M.connect_fn()
    end
end


-- Setup hardware from already collected config 
function setup()
    -- configure GPIO modes
    gpio.mode(M.btn_pin, gpio.INT, gpio.PULLUP)
    gpio.mode(M.led_pin, gpio.OUTPUT)
    gpio.write(M.led_pin, gpio.HIGH)
    -- set `M.btn_pin` interrupt on falling edge (button pressed)
    gpio.trig(M.btn_pin, "down", INT_down)
    -- Create watchdog timer for staled events detection (button pressed indefinitely)
    M.watchdog_timer:stop()
    M.watchdog_timer:unregister()
    M.watchdog_timer:register(MAX_EVENT_TIME, tmr.ALARM_SEMI, function() print("Staled press detected!\n"); setup() end)
    -- Create pause timer 
    M.watchdog_timer:stop()
    M.watchdog_timer:unregister()
    M.pause_timer:register(EVENT_PAUSE_TIMEOUT, tmr.ALARM_SEMI, function() M.pause_fn() end)
end

-- init GPIO, set interrupt
function M.init(btn, led, short_fn, long_fn, pause_fn, stop_fn, connect_fn)
    -- save configuration
    M.btn_pin    = btn
    M.led_pin    = led
    M.short_fn   = short_fn
    M.long_fn    = long_fn
    M.pause_fn   = pause_fn
    M.stop_fn    = stop_fn
    M.connect_fn = connect_fn
    -- Setup
    setup()
end
    
return M
