seed = 1000

c_r_f = 0
c_r_s = 0
math.randomseed(seed)
function new_rands() 
   c_r_f = math.floor(math.random() * 256)
   c_r_s = math.floor(math.random() * 256)
end
new_rands()

memory.register(0x17, 1, 
function(add, size, val)
   if(val == c_r_f) then return end
   memory.writebyte(add, c_r_f)
end)

memory.register(0x18, 1, 
function(add, size, val)
   if(val == c_r_s) then return end
   memory.writebyte(add, c_r_s)
end)

memory.registerexec(0x988e, 1, new_rands)

emu.poweron()











