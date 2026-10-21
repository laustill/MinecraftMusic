local d = peripheral.wrap("right") or error("No Drone Interface on the right side", 0)

local TANKS = { 80, 71, 914,  65, 76, 941, "Filled" }
local DROP = { 68, 72, 910 }

local FLUID = "evilcraft:blood"
local WAIT = 30

local sides = { "up", "down", "north", "south", "east", "west" }

local function setup(area)
  d.clearArea()
  d.clearWhitelistLiquidFilter()
  d.addArea(table.unpack(area))
  d.addWhitelistLiquidFilter(FLUID)
  for _, s in ipairs(sides) do pcall(d.setSide, s, true) end
end

local function run(action, area)
  setup(area)
  d.setAction(action)
  while not d.isActionDone() do sleep(0.5) end
end

print("Waiting for drone...")
while not d.isConnectedToDrone() do sleep(1) end
print("Drone connected")

while true do
  print("Pressure: " .. string.format("%.1f", d.getDronePressure()))
  print("Collecting blood...")
  run("pneumaticcraft:liquid_import", TANKS)
  print("Delivering...")
  run("pneumaticcraft:liquid_export", DROP)
  print("Done. Next run in " .. WAIT .. "s")
  sleep(WAIT)
end
