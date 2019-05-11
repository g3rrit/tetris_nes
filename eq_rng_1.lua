seed = 0
math.randomseed(seed)

-- set player 0 or 1
player_id = 1

-- set piece counter
function set_piece_counter()
  emu.write(0x001A, 2, emu.memType.cpu)
end

rng_vec = {
35209,
17604,
8802,
4401,
2200,
1100,
550,
275,
32905,
16452,
8226,
36881,
18440,
9220,
4610,
2305,
1152,
576,
33056,
16528,
8264,
4132,
2066,
33801,
16900,
41218,
53377,
26688,
18052,
41794,
20897,
10448,
32831,
49183,
57359,
61447,
32889,
16444,
8222,
36879,
51207,
58371,
61953,
34576,
50056,
57796,
28898,
49669,
57602,
61569,
1849,
33692,
49614,
57575,
61555,
43203,
50755,
25377,
17395,
8697,
4348,
2174,
33855,
49695,
26630,
21251,
10625
}
rng_vec_len = 0
for _ in pairs(rng_vec) do rng_vec_len = rng_vec_len + 1 end

-- original rng hashing function
function hash(val)
  return ((((val >> 9) & 1) ~ ((val >> 1) & 1)) << 15) | (val >> 1)
end

-- 0x8989
-- set starting values for rng vars
rng_start_val = 0x8989
rng_val = rng_start_val
sp_rng_val = 0
function update_rng()
   rng_val = hash(rng_val)
end

function get_rng_from_vec()
  pos = math.random(1, rng_vec_len - 1) 
  rng_val = rng_vec[pos] 
end

-- gets called every other game
function init_game()
  --if rng_val <= sp_rng_val then rng_val = sp_rng_val end
  set_piece_counter()
  get_rng_from_vec()
  --if emu.read(0x33, emu.memType.cpu) == 1 then
  --  get_rng_from_vec()
  --  emu.reset()
  --end
end
init_game()
--get_rng_from_vec()

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
function update_marker(con)
  if con then
    local f = io.open(rng_marker .. tostring(player_id), "wb")
    if emu.read(0x4c7, emu.memType.cpu) == 0x4f then 
      f:write("1")
    else 
      f:write("0")
    end
    io.close(f)
  else
    os.remove(rng_marker .. tostring(player_id))
  end
end

function get_marker()
  local fp = ""
  if player_id == 0 then fp = rng_marker .. "1" else fp = rng_marker .. "0" end
  local f = io.open(fp, "r")
  if f == nil then return false, false end
  eg = tonumber(f:read())
  io.close(f)
  if eg == 0 then
    return true, false
  else 
    return true, true
  end
end
-------------------------------------------

-- input callback
emu.addEventCallback(function()
  local input = emu.getInput(0)
  
  emu.log("rng_val: " .. rng_val)
  
  update_marker(input.start)
  
  if input.start then
    is, eg = get_marker()
    --emu.log("is: " .. tostring(is) .. " rng: " .. sp_rng_val)
    input.start = is
    if (not eg) and emu.read(0x4c7, emu.memType.cpu) == 0x4f then
      input.start = false
    end
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
end, emu.memCallbackType.cpuWrite, 0x4c7)
