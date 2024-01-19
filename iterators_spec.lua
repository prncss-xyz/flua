local f = require 'iterators'

describe('flua', function()
  describe('to_table', function()
    it('should create a table from iterator', function()
      assert.are.same(f.to_table()(ipairs {}), {})
      assert.are.same(f.to_table()(ipairs { 2, 3, 4 }), { 2, 3, 4 })
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

      assert.are.same(f.pipe() 'a', 'a')
      assert.are.same(f.pipe(fd) 'a', 'ad')
      assert.are.same(f.pipe(fd, fc) 'a', 'acd')
      assert.are.same(f.pipe(fd, fc, fb) 'a', 'abcd')
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

    assert.are.same(f.compose() 'a', 'a')
    assert.are.same(f.compose(fd) 'a', 'ad')
    assert.are.same(f.compose(fc, fd) 'a', 'acd')
    assert.are.same(f.compose(fb, fc, fd) 'a', 'abcd')
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

      assert.are.same(f.comp 'a'(), 'a')
      assert.are.same(f.comp 'a'(fd), 'ad')
      assert.are.same(f.comp 'a'(fc, fd), 'acd')
      assert.are.same(f.comp 'a'(fb, fc, fd), 'abcd')
    end)
  end)
  describe('map', function()
    it('should map', function()
      local function idouble(k, v)
        return k, 2 * v
      end
      assert.are.same(f.comp {}(ipairs, f.map(idouble), f.to_table()), {})
      assert.are.same(
        f.compose(ipairs, f.map(idouble), f.to_table()) { 1, 2, 3 }, { 2, 4, 6 }
      )
      assert.are.same(
        f.comp { 1, 2, 3 }(ipairs, f.map(idouble), f.to_table()), { 2, 4, 6 }
      )
    end)
  end)
  describe('list', function()
    it('should clone and transform a list', function()
      assert.are.same(f.list {}, {})
      assert.are.same(f.list { 2, 3 }, { 2, 3 })
      assert.are.same(
        f.list( { 2, 3 }, f.map(function(i, x)
            return i, x * 2
          end)
        ), { 4, 6 }
      )
    end)
  end)
  describe('tbl', function()
    it('should clone and transform a table', function()
      assert.are.same(f.tbl {}, {})
      assert.are.same(f.tbl { 2, 3 }, { 2, 3 })
      assert.are.same(
        f.tbl( { 2, 3 }, f.map(function(k, x)
            return k, x * 2
          end)), { 4, 6 }
      )
    end)
  end)
  describe('filter', function()
    it('should filtered values', function()
      local function odd(i)
        return i % 2 == 1
      end
      assert.are.same(f.to_list()(f.filter(odd)(f.range(5))), { 1, 3, 5 })
    end)
  end)
  describe('indexize', function()
    it('should prepend an index', function()
      assert.are.same(
        f.to_table()(f.indexize(ipairs { 'a', 'b', 'c' })), { 1, 2, 3 }
      )
    end)
  end)
  describe('nth', function()
    it('should return nth value', function()
      assert.are.same(f.nth(3)(f.range(1, 20)), 3)
    end)
    it('should return nil when there is not enough values', function()
      assert.are.same(f.nth(30)(f.range(1, 20)), nil)
    end)
  end)
  describe('range', function()
    it('should iterate the range with index', function()
      assert.are.same(f.to_table()(f.indexize(f.range(1, 3))), { 1, 2, 3 })
      assert.are.same(f.to_table()(f.indexize(f.range(1, 5, 2))), { 1, 3, 5 })
      assert.are.same(f.to_table()(f.indexize(f.range(5, 1, -2))), { 5, 3, 1 })
      assert.are.same(
        f.pipe(f.to_table(), f.indexize)(f.range(5, 1, -2)), { 5, 3, 1 }
      )
      assert.are.same(
        f.compose(f.indexize, f.to_table())(f.range(5, 1, -2)), { 5, 3, 1 }
      )
    end)
  end)
  describe('fold1', function()
    it('should fold', function()
      local function sum(acc, x)
        return acc + x
      end

      assert.are.same(f.fold1(sum, 0)(f.range(2, 4)), 9)
    end)
  end)
  describe('min', function()
    it('should return the min value', function()
      assert.are.same(f.comp { 2, 2, 4, -1, 5 }(ipairs, f.min()), -1)
    end)
  end)
  describe('max', function()
    it('should return the min value', function()
      assert.are.same(f.comp { 2, 4, -1, 5 }(ipairs, f.max()), 5)
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
  describe('concat', function()
    it('concats two iterators', function()
      assert.are.same(
        (f.to_list()(f.concat(f.range(3, 4))(f.range(1, 2)))), { 1, 2, 3, 4 }
      )
      assert.are.same(
        (f.to_list()(f.concat(f.concat(f.range(3))(f.range(2)))(f.range(1)))), { 1, 1, 2, 1, 2, 3 }
      )
    end)
  end)
  describe('flatten', function()
    it('flatten nested iterators', function()
      local n = 0
      local function fu()
        n = n + 1
        if n < 4 then
          return f.range(n)
        end
      end
      assert.are.same(f.to_list()(f.flatten(fu)), { 1, 1, 2, 1, 2, 3 })
    end)
    it('should return empty on empty iterator', function()
      assert.are.same(f.to_list()(f.flatten(f.null())), {})
    end)
  end)
  describe('chain', function()
    it('should chain', function()
      local function t(n)
        return f.range(n)
      end

      assert.are.same(
        f.compose(f.chain(t), f.to_list())(f.range(3)), { 1, 1, 2, 1, 2, 3 }
      )
    end)
    it('should chain', function()
      local t = { 1, 2, 1, 2 }
      assert.are.same(
        f.comp { 1, 2 }(
          ipairs,
          f.chain(function(_, _)
            return ipairs(t)
          end),
          f.to_table()
        ), t
      )
    end)
    it('should respect multiple values', function()
      local function t(i)
        return f.once(i, i, i, i)
      end

      local function pack(...)
        return { ... }
      end

      assert.are.same(
        f.compose(f.chain(t), f.head(), pack)(f.range(3)), { 1, 1, 1, 1 }
      )
    end)
  end)
  describe('zip', function()
    it('should zip two iterators', function()
      assert.are.same(
        f.to_table()(f.zip(f.range(3, 5), nil, 2)(f.range(1, 3), nil, 0)), { 3, 4, 5 }
      )
    end)
    it('should truncate when first is shorter', function()
      assert.are.same(
        f.to_table()(f.zip(f.range(3, 5), nil, 2)(f.range(1, 2), nil, 0)), { 3, 4 }
      )
    end)
    it('should truncate when second is shorter', function()
      assert.are.same(
        f.to_table()(f.zip(f.range(3, 4), nil, 2)(f.range(), nil, 0)), { 3, 4 }
      )
    end)
  end)
  describe('take', function()
    it('should take the nth first values', function()
      assert.are.same((f.to_list()(f.take(3)(f.range(5)))), { 1, 2, 3 })
    end)
    it('should iterate while condition is true', function()
      assert.are.same(
        f.comp { 1, 2, 3, 4 }(
          ipairs,
          f.take(function(_, v)
            return v ~= 3
          end),
          f.to_table()
        ), { 1, 2 }
      )
    end)
  end)
  describe('drop', function()
    it('should return empty list when iterator is empty', function()
      assert.are.same((f.to_list()(f.drop(3)(f.null()))), {})
    end)
    it('should return empty list when iterator is too short', function()
      assert.are.same((f.to_list()(f.drop(10)(f.range(5)))), {})
    end)
    it('should start iterating after n values', function()
      assert.are.same((f.to_list()(f.drop(3)(f.range(5)))), { 4, 5 })
    end)
    it('should start iterating when condition is false', function()
      assert.are.same((f.to_list()(f.drop(function(x)
        return x < 3
      end)(f.range(5)))), { 3, 4, 5 })
    end)
  end)
end)
