seed = 420
  
-- set player 0 or 1
player_id = 1

-- set piece counter
function set_piece_counter()
  emu.write(0x001A, 2, emu.memType.cpu)
end

function hash(val)
  return ((((val >> 9) & 1) ~ ((val >> 1) & 1)) << 15) | (val >> 1)
end

-- set starting values for rng vars
rng_start_val = 0x8989
rng_val = rng_start_val
sp_rng_val = 0
function update_rng()
   rng_val = hash(rng_val)
end
-- apply seed 
for i=0,0 do
  update_rng()
end

-- gets called every other game
function init_game()
  if rng_val <= sp_rng_val then rng_val = sp_rng_val end
  update_rng()
  set_piece_counter()
  if emu.read(0x33, emu.memType.cpu) == 1 then
    emu.reset()
  end
end
init_game()

-- callbacks for writing rng value to mem
emu.addMemoryCallback(
function(addr, val)
   return rng_val >> 8
end, emu.memCallbackType.cpuWrite, 0x17)

emu.addMemoryCallback(
function(addr, val)
   return rng_val & 0xFF
end, emu.memCallbackType.cpuWrite, 0x18)
-------------------------------------------

-- update rng on write
prev_dc = 0
emu.addMemoryCallback(function(addr, val)
if val ~= prev_dc then update_rng() end
   prev_dc = val
end, emu.memCallbackType.cpuWrite,0x001A)
 
-- rng marker files
function file_exists(path)
  local f = io.open(path, "r")
  if f~= nil then io.close(f) return true else return false end
end

rng_marker = "./marker" 
function update_rng_marker(con)
  if con then
    local f = io.open(rng_marker .. tostring(player_id), "wb")
    f:write(tostring(rng_val))
    io.close(f)
  else
    os.remove(rng_marker .. tostring(player_id))
  end
end

function get_rng_marker()
  local fp = ""
  if player_id == 0 then fp = rng_marker .. "1" else fp = rng_marker .. "0" end
  local f = io.open(fp, "r")
  if f == nil then return false, 0 end
  trng = tonumber(f:read())
  io.close(f)
  return true, trng
end
-------------------------------------------

-- input callback
emu.addEventCallback(function()
  local input = emu.getInput(0)
  
  emu.log("rng_val: " .. rng_val)
  
  update_rng_marker(input.start)
  
  if input.start then
    input.start, sp_rng_val = get_rng_marker()
  end
  emu.setInput(0, input)
end, emu.eventType.inputPolled)


-- memory callback for new game
prev_ng_state = 1
emu.addMemoryCallback(
function(addr, val)
  --emu.log("prev: " .. prev_ng_state .. " curr: " .. val)
  if prev_ng_state == 0x4f and val == 0xef then
    init_game()
  end
  prev_ng_state = val
end, emu.memCallbackType.cpuWrite, 0x400)
