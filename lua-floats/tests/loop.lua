local res = 0;
for var=1,10 do
  res = res + var
end
print(res)

local res2 = 0;
for var=1,10,3 do
  res2 = res2 + var
end
print(res2)

local res3 = 0;
while res3 < 10 do
  res3 = res3 + 1
end
print(res3)

local res4 = 0;
for var=1,10 do
  for var=1,10 do
    res4 = res4 + 1
  end
end
print(res4)
