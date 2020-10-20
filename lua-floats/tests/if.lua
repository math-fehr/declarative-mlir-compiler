if true then
  print("Correct single if")
end

if false then
  print("Incorrect single if")
end

if true then
  print("Correct true")
else
  print("Incorrect true")
end

if false then
  print("Incorrect true")
else
  print("Correct true")
end

if 0 then
  print("Correct 0")
else
  print("Incorrect 0")
end

if 1 then
  print("Correct 1")
else
  print("Incorrect 1")
end

if { false } then
  print("Correct table")
else
  print("Incorrect table")
end

if { } then
  print("Correct empty table")
else
  print("Incorrect empty table")
end

if nil then
  print("Incorrect nil")
else
  print("Correct nil")
end

if true then
  print("Correct elseif")
elseif true then
  print("Incorrect elseif")
else
  print("Incorrect elseif")
end
