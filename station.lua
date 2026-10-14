{\rtf1\ansi\ansicpg1252\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 local name = ... or "Radio 1"\
peripheral.find("modem", rednet.open)\
local CHUNK = 6 * 1024\
local DUR = CHUNK * 8 / 48000\
local skip = false\
\
local playlist = \{\}\
for line in io.lines("playlist.txt") do\
  local title, src = line:match("^(.-)|(.+)$")\
  if title then table.insert(playlist, \{ title = title, src = src \}) end\
end\
\
local function shuffle(t)\
  for i = #t, 2, -1 do\
    local j = math.random(i)\
    t[i], t[j] = t[j], t[i]\
  end\
end\
\
local function open(src)\
  if src:match("^https?://") then\
    return http.get\{ url = src, binary = true \}\
  end\
  return fs.open(src, "rb")\
end\
\
local function broadcast()\
  while true do\
    shuffle(playlist)\
    for _, song in ipairs(playlist) do\
      print("Now playing: " .. song.title)\
      local h = open(song.src)\
      if h then\
        skip = false\
        local t = os.clock()\
        while not skip do\
          local chunk = h.read(CHUNK)\
          if not chunk then break end\
          rednet.broadcast(\{ station = name, title = song.title, data = chunk \}, "radio")\
          t = t + DUR\
          sleep(math.max(0, t - os.clock() - 0.1))\
        end\
        h.close()\
      else\
        print("Can't open " .. song.title)\
      end\
    end\
  end\
end\
\
local function control()\
  while true do\
    local ev, a, b, c = os.pullEvent()\
    if ev == "key" and a == keys.s then\
      skip = true\
    elseif ev == "rednet_message" and c == "radio_ctrl" and type(b) == "table" and b.skip == name then\
      skip = true\
    end\
  end\
end\
\
print("Broadcasting as " .. name .. "  (S = skip)")\
parallel.waitForAny(broadcast, control)}