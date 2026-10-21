local d = peripheral.find("droneInterface") or error("No Drone Interface found", 0)

local TANKS = { 80, 71, 914,  65, 76, 941, "Filled" }
local DROP = { 68, 71, 910 }

local FLUID = "evilcraft:blood"
local CAPACITY = 16000      -- drone tank size in mB (raise if you add Inventory Upgrades)
local FULL_AT = CAPACITY * 0.9
local WAIT = 60
local MIN_PRESSURE = 3

local sides = { "up", "down", "north", "south", "east", "west" }

local function waitForDrone()
  while not d.isConnectedToDrone() do sleep(1) end
end

local function setup(area)
  d.clearArea()
  d.clearWhitelistLiquidFilter()
  if area then d.addArea(table.unpack(area)) end
  d.addWhitelistLiquidFilter(FLUID)
  for _, s in ipairs(sides) do pcall(d.setSide, s, true) end
end

local function run(action, area)
  setup(area)
  d.setAction(action)
  while not d.isActionDone() do sleep(0.5) end
end

local function isFull()
  setup(nil)
  d.setAction("pneumaticcraft:drone_condition_liquid")
  d.setOperator(">=")
  d.setCount(FULL_AT)
  local ok, res = pcall(d.evaluateCondition)
  if not ok then
    print("Fill check failed: " .. tostring(res))
    return false
  end
  return res
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
  local full = isFull()

  print(full and "Drone full, delivering early..." or "Delivering...")
  run("pneumaticcraft:liquid_export", DROP)

  if full then
    print("More blood likely left, going again")
  else
    print("Tanks drained. Next run in " .. WAIT .. "s")
    sleep(WAIT)
  end
end
