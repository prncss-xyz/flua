local f = require 'iterator'
local b = require 'benchmark'

local vals = { 1, 2, 3, 4, 5, 6, 7 }

local function sum(acc, x)
  return acc + x
end

b.addbenchmark('iterator', function()
  return f.fold(sum, 0)(ipairs(vals))
end)

b.addbenchmark('loop', function()
  local s = 0
  for _, v in ipairs(vals) do
    s = s + v
  end
  return s
end)

b.addbenchmark('forc', function()
  local s = 0
  for i = 1, 7 do
    s = s + i
  end
  return s
end)

b.runbenchmarks(10000)
