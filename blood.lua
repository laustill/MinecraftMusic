local d = peripheral.wrap("right") or error("No Drone Interface on the right side", 0)

local TANKS   = { 80, 71, 914,  65, 76, 941, "Filled" }
local DROP    = { 68, 72, 910 }
local CHARGER = { 66, 75, 940 }   -- <-- your Charging Station's coordinates

local FLUID = "evilcraft:blood"
local WAIT = 3          -- pause after each delivery
local COLLECT_TIME = 20  -- max seconds to spend collecting

local LOW_PRESSURE  = 0.5   -- go charge below this (bar)
local FULL_PRESSURE = 4.0   -- leave the charger at/above this
local CHARGE_TIMEOUT = 120  -- give up waiting after this many seconds

local sides = { "up", "down", "north", "south", "east", "west" }

local function pressure()
  local ok, p = pcall(d.getDronePressure)
  return ok and p or 0
end

local function waitForDrone()
  if d.isConnectedToDrone() then return end
  print("Waiting for drone...")
  while not d.isConnectedToDrone() do sleep(1) end
  print("Drone connected")
end

local function setup(area, filter)
  d.clearArea()
  d.clearWhitelistLiquidFilter()
  d.addArea(table.unpack(area))
  if filter then d.addWhitelistLiquidFilter(FLUID) end
  for _, s in ipairs(sides) do pcall(d.setSide, s, true) end
end

-- Returns "done", "timeout", or "low"
local function run(action, area, filter, timeout)
  setup(area, filter)
  d.setAction(action)
  sleep(1)
  local start = os.clock()
  while not d.isActionDone() do
    if pressure() < LOW_PRESSURE then
      pcall(d.abortAction)
      print("  pressure low, aborting")
      return "low"
    end
    if timeout and os.clock() - start > timeout then
      pcall(d.abortAction)
      print("  time limit reached")
      return "timeout"
    end
    sleep(0.5)
  end
  return "done"
end

local function charge()
  print("Heading to charger (" .. string.format("%.1f", pressure()) .. " bar)")
  setup(CHARGER, false)
  d.setAction("pneumaticcraft:goto")
  sleep(1)
  while not d.isActionDone() do sleep(0.5) end

  local start = os.clock()
  while pressure() < FULL_PRESSURE do
    if os.clock() - start > CHARGE_TIMEOUT then
      print("  charge timeout - is the station pressurized?")
      break
    end
    waitForDrone()
    sleep(2)
  end
  print("Charged: " .. string.format("%.1f", pressure()) .. " bar")
end

local function ensureCharged()
  if pressure() < LOW_PRESSURE then charge() end
end

waitForDrone()

while true do
  waitForDrone()
  print("Pressure: " .. string.format("%.1f", pressure()))
  ensureCharged()

  print("Collecting blood...")
  if run("pneumaticcraft:liquid_import", TANKS, true, COLLECT_TIME) == "low" then
    charge()   -- keep whatever it collected, deliver after charging
  end

  print("Delivering...")
  while run("pneumaticcraft:liquid_export", DROP, false) == "low" do
    charge()   -- retry the delivery after charging
  end

  print("Done. Next run in " .. WAIT .. "s")
  sleep(WAIT)
end
