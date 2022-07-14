if _VERSION ~= 'Lua 5.1' then
  print(
    'this is meant to run with lua 5.1, your are currently running ' .. _VERSION
  )
  return
end

local f = require 'iterator'
describe('flua', function()
  describe('to_table', function()
    it('should create a table from iterator', function()
      assert.are.same({}, f.to_table()(ipairs {}))
      assert.are.same({ 2, 3, 4 }, f.to_table()(ipairs { 2, 3, 4 }))
    end)
  end)
  describe('pipe', function()
    it('should pipe functions', function()
      local function fb(t)
        return t .. 'b'
      end
      local function fc(t)
        return t .. 'c'
      end
      local function fd(t)
        return t .. 'd'
      end
      assert.are.same('a', f.pipe() 'a')
      assert.are.same('ad', f.pipe(fd) 'a')
      assert.are.same('acd', f.pipe(fd, fc) 'a')
      assert.are.same('abcd', f.pipe(fd, fc, fb) 'a')
    end)
  end)
  describe('compose', function()
    local function fb(t)
      return t .. 'b'
    end
    local function fc(t)
      return t .. 'c'
    end
    local function fd(t)
      return t .. 'd'
    end
    assert.are.same('a', f.compose() 'a')
    assert.are.same('ad', f.compose(fd) 'a')
    assert.are.same('acd', f.compose(fc, fd) 'a')
    assert.are.same('abcd', f.compose(fb, fc, fd) 'a')
  end)
  describe('comp', function()
    it('should compose functions', function()
      local function fb(t)
        return t .. 'b'
      end
      local function fc(t)
        return t .. 'c'
      end
      local function fd(t)
        return t .. 'd'
      end
      assert.are.same('a', f.comp 'a'())
      assert.are.same('ad', f.comp 'a'(fd))
      assert.are.same('acd', f.comp 'a'(fc, fd))
      assert.are.same('abcd', f.comp 'a'(fb, fc, fd))
    end)
  end)
  describe('map', function()
    it('should map', function()
      assert.are.same(
        {},
        f.comp {}(
          ipairs,
          f.map(function(k, v)
            return k, 2 * v
          end),
          f.to_table()
        )
      )
      assert.are.same(
        { 2, 4, 6 },
        f.compose(
          ipairs,
          f.map(function(k, v)
            return k, 2 * v
          end),
          f.to_table()
        ) { 1, 2, 3 }
      )
      assert.are.same(
        { 2, 4, 6 },
        f.comp { 1, 2, 3 }(
          ipairs,
          f.map(function(k, v)
            return k, 2 * v
          end),
          f.to_table()
        )
      )
    end)
  end)
  describe('list', function()
    it('should clone and transform a list', function()
      assert.are.same({}, f.list {})
      assert.are.same({ 2, 3 }, f.list { 2, 3 })
      assert.are.same(
        { 4, 6 },
        f.list(
          { 2, 3 },
          f.map(function(i, x)
            return i, x * 2
          end)
        )
      )
    end)
  end)
  describe('tbl', function()
    it('should clone and transform a table', function()
      assert.are.same({}, f.tbl {})
      assert.are.same({ 2, 3 }, f.tbl { 2, 3 })
      assert.are.same(
        { 4, 6 },
        f.tbl(
          { 2, 3 },
          f.map(function(k, x)
            return k, x * 2
          end)
        )
      )
    end)
  end)
  describe('map_opt', function()
    it('should map or skip', function()
      local i
      local function cb(k, x)
        if x % 2 == 0 then
          i = i + 1
          return i, x * 2
        end
      end
      i = 0
      assert.are.same({}, f.tbl({}, f.map_opt(cb)))
      i = 0
      assert.are.same({}, f.tbl({ 3 }, f.map_opt(cb)))
      i = 0
      assert.are.same({ 4, 8, 12 }, f.tbl({ 2, 3, 4, 5, 6 }, f.map_opt(cb)))
    end)
  end)
  describe('filter', function()
    it('should fileter values', function()
      local function odd(i)
        return i % 2 == 1
      end
      assert.are.same({ 1, 3, 5 }, f.to_list()(f.filter(odd)(f.range(5))))
    end)
  end)
  describe('indexize', function()
    it('should prepend an index', function()
      assert.are.same(
        { 1, 2, 3 },
        f.to_table()(f.indexize(ipairs { 'a', 'b', 'c' }))
      )
    end)
  end)
  describe('nth', function()
    it('should return nth value', function()
      assert.are.same(3, f.nth(3)(f.range(1, 20)))
    end)
  end)
  describe('range', function()
    it('should iterate the range with index', function()
      assert.are.same({ 1, 2, 3 }, f.to_table()(f.indexize(f.range(1, 3))))
      assert.are.same({ 1, 3, 5 }, f.to_table()(f.indexize(f.range(1, 5, 2))))
      assert.are.same({ 5, 3, 1 }, f.to_table()(f.indexize(f.range(5, 1, -2))))
      assert.are.same(
        { 5, 3, 1 },
        f.pipe(f.to_table(), f.indexize)(f.range(5, 1, -2))
      )
      assert.are.same(
        { 5, 3, 1 },
        f.compose(f.indexize, f.to_table())(f.range(5, 1, -2))
      )
    end)
  end)
  describe('fold', function()
    it('should fold', function()
      local function sum(acc, x)
        return acc + x
      end
      assert.are.same(9, f.fold1(sum, 0)(f.range(2, 4)))
      -- assert.are.same(9, f.fold(sum)(f.range(2, 4)))
    end)
  end)
  describe('each', function()
    it('should be called on each iteration', function()
      local acc = 'a'
      local function inc(_, v)
        acc = acc .. v
      end
      f.comp { 'b', 'c', 'd', 'e' }(ipairs, f.each(inc))
      assert.are.same(acc, 'abcde')
    end)
  end)
  describe('tap', function()
    it('should be called on each iteration', function()
      local acc = 'a'
      local function inc(_, v)
        acc = acc .. v
      end
      f.comp { 'b', 'c', 'd', 'e' }(ipairs, f.tap(inc), f.last)
      assert.are.same(acc, 'abcde')
    end)
  end)
  describe('concat', function()
    it('concats two iterators', function()
      assert.are.same(
        { 1, 2, 3, 4 },
        (f.to_list()(f.concat(f.range(3, 4))(f.range(1, 2))))
      )
      assert.are.same(
        { 1, 1, 2, 1, 2, 3 },
        (f.to_list()(f.concat(f.concat(f.range(3))(f.range(2)))(f.range(1))))
      )
    end)
  end)
  describe('flatten', function()
    it('description', function()
      local n = 0
      local function fu()
        n = n + 1
        if n < 4 then
          local g, p, s = f.range(n)
          return f.range(n)
        end
      end
      assert.are.same({ 1, 1, 2, 1, 2, 3 }, f.to_list()(f.flatten(fu)))
    end)
    it('should respect multiple values', function()
      local function t(i)
        return f.once(i, i, i, i)
      end
      local function pack(...)
        return { ... }
      end
      local function u(i)
        return i, i, i, i
      end
      local function v()
        return 1, 1, 1, 1
      end
      assert.are.same(
        { 1, 1, 1, 1 },
        f.compose(f.chain(t), f.head, pack)(f.range(3))
      )
    end)
  end)
  describe('chain', function()
    it('should chain', function()
      local function t(n)
        return f.range(n)
      end
      assert.are.same(
        { 1, 1, 2, 1, 2, 3 },
        f.compose(f.chain(t), f.to_list())(f.range(3))
      )
    end)
  end)
  describe('chain', function()
    it('should chain', function()
      local t = { 1, 2, 1, 2 }
      assert.are.same(
        t,
        f.comp { 1, 2 }(
          ipairs,
          f.chain(function(_, _)
            return ipairs(t)
          end),
          f.to_table()
        )
      )
    end)
  end)
  describe('zip', function()
    local function iter(_, k)
      if k < 5 then
        return k + 1
      end
    end
    it('should zip two iterators', function()
      assert.are.same(
        { 3, 4, 5 },
        f.to_table()(f.zip(iter, nil, 2)(iter, nil, 0))
      )
    end)
  end)
  describe('take', function()
    it('should take the nth first values', function()
      assert.are.same({ 1, 2, 3 }, (f.to_list()(f.take(3)(f.range(5)))))
    end)
    it('should iterate while condition is true', function()
      assert.are.same(
        { 1, 2 },
        f.comp { 1, 2, 3, 4 }(
          ipairs,
          f.take(function(_, v)
            return v ~= 3
          end),
          f.to_table()
        )
      )
    end)
  end)
  describe('drop', function()
    it('should start iterating after n values', function()
      assert.are.same({ 4, 5 }, (f.to_list()(f.drop(3)(f.range(5)))))
    end)
    it('should start iterating when condition is false', function()
      assert.are.same(
        { 3, 4, 5 },
        (
            f.to_list()(f.drop(function(x)
              return x < 3
            end)(f.range(5)))
          )
      )
    end)
  end)
end)
