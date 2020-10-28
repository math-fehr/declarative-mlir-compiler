function partition(array, p, r)
  local x = array[r]
  local i = p - 1
  for j = p, r - 1 do
    if array[j] <= x then
      i = i + 1
      local temp = array[i]
      array[i] = array[j]
      array[j] = temp
    end
  end
  local temp = array[i + 1]
  array[i + 1] = array[r]
  array[r] = temp
  return i + 1
end

function quickSort(array, p, r)
  if p < r then
    q = partition(array, p, r)
    quickSort(array, p, q - 1)
    quickSort(array, q + 1, r)
  end
end

local len = 10000
array = {}
for i = 1,len do
  array[i] = len - i
end

quickSort(array, 1, len)
print(array[43])
