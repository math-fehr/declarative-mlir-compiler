local width = 2000
local height, wscale = width, 2/width
local m, limit2 = 50, 4.0

print("P4\n", width, " ", height, "\n")

for y=0,height-1 do
  local Ci = 2*y / height - 1
  for xb=0,width-1,8 do
    local bits = 0
    local xbb = xb+7
    local xbb_limit = 0
    if xbb < width then
      xbb_limit = xbb
    else
      xbb_limit = width - 1
    end
    for x=xb,xbb_limit do
      bits = bits + bits
      local Zr, Zi, Zrq, Ziq = 0.0, 0.0, 0.0, 0.0
      local Cr = x * wscale - 1.5
      local i = 1
      local continue = true
      while continue and i <= m do
        local Zri = Zr*Zi
        Zr = Zrq - Ziq + Cr
        Zi = Zri + Zri + Ci
        Zrq = Zr*Zr
        Ziq = Zi*Zi
        if Zrq + Ziq > limit2 then
          bits = bits + 1
          continue = false
        end
        i = i + 1
      end
    end
    if xbb >= width then
      for x=width,xbb do bits = bits + bits + 1 end
    end
    print(255-bits)
  end
end
