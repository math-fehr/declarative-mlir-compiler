function Fun1(n)
  n = 0
end

local a = 2
Fun1(a)
print(a)

function Fun2(n)
  n[1] = 1
  return n[1]
end

local c = { 2 }
local d = Fun2(c)
print(c[1],d)

function Fib(n)
  if n == 0 then return 0 end
  if n == 1 then return 1 end
  return Fib(n-1) + Fib(n-2)
end

print(Fib(4))
