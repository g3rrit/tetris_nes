
function print_piece() 
   local piece = memory.readbyteunsigned(0x62)
   if(piece <= 3) then
      emu.print("T")
   elseif(piece <= 7) then
      emu.print("J")
   elseif(piece <= 9) then
      emu.print("Z")
   elseif(piece <= 0xa) then
      emu.print("O")
   elseif(piece <= 0xc) then
      emu.print("S")
   elseif(piece <= 0x10) then
      emu.print("L")
   elseif(piece <= 0x12) then
      emu.print("I")
   else
      print("input error")
   end
end

-- wait for player to press start
while(true) do
   emu.frameadvance()
   jp = joypad.get(1)
   if(jp.start) then break end
end
emu.frameadvance()

print_state = true
while(true) do
   emu.frameadvance()
   if(print_state and memory.readbyteunsigned(0x61) == 0) then
      print_piece()
      print_state = false
   end
   if(memory.readbyteunsigned(0x61) ~= 0) then
      print_state = true
   end
end
