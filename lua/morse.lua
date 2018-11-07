local M = {}

-- morse code
SHORT = "."
LONG  = "-"
MORSE = {
    [".-"]   = "a",
    ["-..."] = "b",
    ["-.-."] = "c",
    ["-.."]  = "d",
    ["."]    = "e",
    ["..-."] = "f",
    ["--."]  = "g",
    ["...."] = "h",
    [".."]   = "i",
    [".---"] = "j",
    ["-.-"]  = "k",
    [".-.."] = "l",
    ["--"]   = "m",
    ["-."]   = "n",
    ["---"]  = "o",
    [".--."] = "p",
    ["--.-"] = "q"
    -- TODO finish
}

M.letter_fn         = null -- function to call with letter argument after letter is completed
M.unknown_letter_fn = null -- function to call with letter argument when unknown letter is typed
M.word_fn           = null -- function to call with word argument after word is completed

M.letter = ""
M.word = ""

function M.short()
    M.letter = (M.letter .. SHORT)
end

function M.long()
    M.letter = (M.letter .. LONG)
end

-- end of letter
function M.pause()
    -- parse letter into word
    local letter = MORSE[M.letter]
    if letter then
        M.letter_fn(letter)
        M.word = (M.word .. letter)
    else
        M.unknown_letter_fn(M.letter)
    end
    M.letter = ""
end

-- end of word
function M.stop()
    M.word_fn(M.word)
    M.word = ""
end

-- init
function M.init(letter_fn, word_fn, unknown_letter_fn)
    M.letter_fn         = letter_fn
    M.word_fn           = word_fn
    M.unknown_letter_fn = unknown_letter_fn
end

return M
