local d = peripheral.find("droneInterface")

local TANKS = { 80, 71, 914,  65, 76, 941 }
local DROP = { 68, 71, 910 }

local FLUID = "evilcraft:blood"
local WAIT = 60
local MIN_PRESSURE = 3

local sides = { "up", "down", "north", "south", "east", "west" }

local function waitForDrone()
  while not d.isConnectedToDrone() do sleep(1) end
end

local function run(action, area)
  d.clearArea()
  d.clearWhitelistLiquidFilter()
  d.addArea(table.unpack(area))
  d.addWhitelistLiquidFilter(FLUID)
  for _, s in ipairs(sides) do pcall(d.setSide, s, true) end
  d.setAction(action)
  while not d.isActionDone() do sleep(0.5) end
end

print("Waiting for drone...")
waitForDrone()
print("Drone connected")

while true do
  local p = d.getDronePressure()
  print("Pressure: " .. string.format("%.1f", p))

  if p < MIN_PRESSURE then
    print("Low pressure, releasing drone to charge...")
    d.exitPiece()
    sleep(30)
    waitForDrone()
    print("Drone back")
  end

  print("Collecting blood...")
  run("pneumaticcraft:liquid_import", TANKS)
  print("Delivering...")
  run("pneumaticcraft:liquid_export", DROP)
  print("Done. Next run in " .. WAIT .. "s")
  sleep(WAIT)
end
