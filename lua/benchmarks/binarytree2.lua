-- The Computer Language Benchmarks Game
-- http://benchmarksgame.alioth.debian.org/
-- contributed by Mike Pall

function BottomUpTree(item, depth)
  if depth > 0 then
    local i = item + item
    depth = depth - 1
    local left, right = BottomUpTree(i-1, depth), BottomUpTree(i, depth)
    return { item, left, right }
  else
    return { item }
  end
end

function ItemCheck(tree)
  if tree[2] then
    return tree[1] + ItemCheck(tree[2]) - ItemCheck(tree[3])
  else
    return tree[1]
  end
end

function CheckTree(item, depth)
  if depth > 0 then
    local i = item + item
    depth = depth - 1
    local left, right = CheckTree(i-1, depth), CheckTree(i, depth)
    return item + left + right
  else
    return item
  end
end

local mindepth = 4
local maxdepth = 18

local stretchdepth = maxdepth + 1
local stretchtree = BottomUpTree(0, stretchdepth)
print("stretch tree of depth", stretchdepth, "check:", ItemCheck(stretchtree))

local longlivedtree = BottomUpTree(0, maxdepth)

for depth=mindepth,maxdepth,2 do
  local iterations = 2 ^ (maxdepth - depth + mindepth)
  local check = 0
  for i=1,iterations do
    check = check + CheckTree(1, depth) +
            CheckTree(-1, depth)
  end
  print(iterations*2, "trees of depth", depth, "check:", check)
end

print("long lived tree of depth", maxdepth, "check:", ItemCheck(longlivedtree))
