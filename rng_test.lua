function hash(val)
  return ((((val >> 9) & 1) ~ ((val >> 1) & 1)) << 15) | (val >> 1)
end


frng = io.open("./rng_vals.txt", "wb")
if frng == nil then emu.log("error opening rng file") end

-- 0x8989
rng_val =26688
function set_piece_counter()
  emu.write(0x001A, 2, emu.memType.cpu)
end


function update_rng()
   rng_val = hash(rng_val)
end
 
 
for i=0, 136485 do 
  update_rng()
end
 
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
 
last_time = os.time()
-- input callback
emu.addEventCallback(function()
  local input = emu.getInput(0)

  --emu.log("time: " .. tostring(os.time()))
  if (os.time() - last_time) >= 1 then
    last_time = os.time()
    if input.select then
      emu.log("rng: " .. tostring(rng_val))
      frng:write(tostring(rng_val) .. "\n")
      update_rng()
    end
  end
end, emu.eventType.inputPolled)