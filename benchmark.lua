local M = {}
local clock = os.clock

local function runbenchmark(cb, count)
  local start = clock()
  for _ = 1, count do
    cb()
  end
  local time = clock() - start
  return time
end

local tests = {}

function M.addbenchmark(name, cb)
  table.insert(tests, { name = name, cb = cb })
end

local function pad_right(maxl, str)
  maxl = maxl + 1
  local pad
  local len = maxl - string.len(str)
  if len > 0 then
    pad = tostring(len)
  else
    pad = ''
  end
  pad = '%' .. pad .. 's'
  pad = string.format(pad, '')
  return str .. pad
end

function M.runbenchmarks(count)
  local max = 0
  local maxl = string.len 'name'
  local results = {}
  for _, b in ipairs(tests) do
    local time = runbenchmark(b.cb, count)
    table.insert(results, { name = b.name, time = time })
    print(b.name, time)
    max = math.max(max, time)
    maxl = math.max(maxl, string.len(max))
  end
  print()
  print('lua version: ', _VERSION)
  print('count: ', count)
  print()
  print(
    pad_right(maxl, 'name'),
    string.format('%8s\t%8s\t%4s', 'sum', 'avg', 'rel')
  )
  print '----------------------------------------------------'
  for _, v in pairs(results) do
    -- local rel = math.ceil(v.time / max * 1000)
    local rel = math.ceil(v.time / max * 1000)
    print(
      pad_right(maxl, v.name),
      string.format('%.3e\t%.3e\t%4d', v.time, v.time / count, rel)
    )
  end
end

return M
