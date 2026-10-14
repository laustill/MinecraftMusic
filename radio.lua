{\rtf1\ansi\ansicpg1252\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 peripheral.find("modem", rednet.open)\
local speaker = peripheral.find("speaker")\
local dec = require("cc.audio.dfpwm").make_decoder()\
local station, current\
\
local function listen()\
  while true do\
    local id, msg = rednet.receive("radio")\
    if type(msg) == "table" and msg.data then\
      station = msg.station\
      if msg.title ~= current then\
        current = msg.title\
        print("Playing: " .. current)\
      end\
      local buf = dec(msg.data)\
      while not speaker.playAudio(buf, 3) do\
        os.pullEvent("speaker_audio_empty")\
      end\
    end\
  end\
end\
\
local function controls()\
  while true do\
    local _, key = os.pullEvent("key")\
    if key == keys.s and station then\
      rednet.broadcast(\{ skip = station \}, "radio_ctrl")\
      speaker.stop()\
      print("Skipping...")\
    end\
  end\
end\
\
print("Listening...  (S = skip)")\
parallel.waitForAny(listen, controls)}