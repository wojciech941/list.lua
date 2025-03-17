local function create_meta_iterator(this)
  local meta = {}

  function meta:__call()
    if self.__temp then
      self.__data, self.__temp = self.__temp, false
    end
    if self.__data and not self.__data:is_empty() then
      self.__temp = self.__data + self.__step
      return self
    end
  end

  function meta:__index(k)
    if k == 0 then
      return rawget(self, "__data")[0]
    else
      return this[k]
    end
  end

  function meta:__newindex(k, v)
    if k == 0 then
      self.__data[k] = v
    end
  end

  function meta:__add()
    if self.__data then
      self.__data = self.__data + self.__step
    end
    return self
  end

  function meta:__sub()
    if self.__data then
      self.__data = self.__data - self.__step
    end
    return self
  end

  function meta:__eq(other)
    return (type(other) == "table") and (self.__data == other.__data)
  end

  return meta
end

local iterator_t = (function()
  local this = {}
  local meta = create_meta_iterator(this)

  this.__basetype = "iterator_t"
  this.__type     = "iterator_t"
  this.__step     = 1

  local function constructor(_, data)
    if data then
      local iterator = {}
      iterator.__data = data
      iterator.__temp = false
      return setmetatable(iterator, meta)
    end
  end

  return setmetatable(this, { __call = constructor })
end)()

local reverse_iterator_t = (function()
  local this = {}
  local meta = create_meta_iterator(this)

  this.__basetype = "iterator_t"
  this.__type     = "reverse_iterator_t"
  this.__step     = -1

  local function constructor(_, data)
    if data then
      local reverse_iterator = {}
      reverse_iterator.__data = data
      reverse_iterator.__temp = false
      return setmetatable(reverse_iterator, meta)
    end
  end

  return setmetatable(this, { __call = constructor })
end)()

local const_iterator_t = (function()
  local this = {}
  local meta = create_meta_iterator(this)

  this.__basetype = "iterator_t"
  this.__type     = "const_iterator_t"
  this.__step     = 1
  meta.__newindex = function()
    error("attempt to change the value under a constant iterator")
  end

  local function constructor(_, data)
    if data then
      local const_iterator = {}
      const_iterator.__data = data
      const_iterator.__temp = false
      return setmetatable(const_iterator, meta)
    end
  end

  return setmetatable(this, { __call = constructor })
end)()

local const_reverse_iterator_t = (function()
  local this = {}
  local meta = create_meta_iterator(this)

  this.__basetype = "iterator_t"
  this.__type     = "const_reverse_iterator_t"
  this.__step     = -1
  meta.__newindex = function()
    error("attempt to change the value under a constant iterator")
  end

  local function constructor(_, data)
    if data then
      local const_reverse_iterator = {}
      const_reverse_iterator.__data = data
      const_reverse_iterator.__temp = false
      return setmetatable(const_reverse_iterator, meta)
    end
  end

  return setmetatable(this, { __call = constructor })
end)()

local node_t = (function()
  local this = {}
  local meta = {}
  local CONST_EMPTY_NODE_DATA = {}

  meta.__index = this

  function meta:__add(a)
    return (a > 0) and self.__next or self.__prev
  end

  function meta:__sub(a)
    return (a > 0) and self.__prev or self.__next
  end

  function this:push_back(node)
    if self.__next then
      self.__next.__prev = node
    end
    node.__next = self.__next
    self.__next = node
    node.__prev = self
    return node
  end

  function this:push_front(node)
    if self.__prev then
      self.__prev.__next = node
    end
    node.__prev = self.__prev
    self.__prev = node
    node.__next = self
    return node
  end

  function this:pop()
    if self.__prev then self.__prev.__next = self.__next end
    if self.__next then self.__next.__prev = self.__prev end
  end

  function this:is_empty()
    return self[0] == CONST_EMPTY_NODE_DATA
  end

  function this:make_this_node_empty()
    self[0] = CONST_EMPTY_NODE_DATA
  end

  local function constructor(_, data)
    local node = {}
    node[0] = data
    return setmetatable(node, meta)
  end

  return setmetatable(this, { __call = constructor })
end)()

local list_t = (function()
  local this = {}
  this.__basetype = "list_t"
  this.__type     = "list_t"

  ---// Erases elements from a list and places a new set of elements to a target list.
  ---@table initializer_list
  ---@return [nil]
  ---
  ---@any_iterator_t first
  ---@any_iterator_t last
  ---@return [nil]
  ---
  ---@number count
  ---@any data
  ---@return [nil]
  function this:assign(...)
    local args = { ... }
    if #args == 1 then
      assert(type(args[1]) == "table", "bad argument #1 to 'assign' (table expected)")
      self:clear()
      for _, v in ipairs(args[1]) do
        self:push_back(v)
      end
      return
    elseif #args == 2 then
      if type(args[1]) == "table" and type(args[2]) == "table" then
        assert(args[1].__basetype == "iterator_t", "bad argument #1 to 'assign' (any_iterator_t expected)")
        assert(args[2].__basetype == "iterator_t", "bad argument #2 to 'assign' (any_iterator_t expected)")
        self:clear()
        while args[1] ~= args[2] do
          local node = args[1].__data
          self:push_back(node[0])
          args[1] = args[1] + 1
        end
        return
      else
        assert(type(args[1]) == "number", "bad argument #1 to 'assign' (number expected)")
        self:clear()
        for i = 1, args[1] do
          self:push_back(args[2])
        end
        return
      end
    end
    error("cannot find an overload for 'assign' for passed arguments")
  end

  ---// Returns a pointer to the last element of a list.
  ---@return [node_t]
  function this:back()
    return self.__impl.__prev
  end

  ---// Returns an iterator addressing the first element in a list.
  ---@return [iterator_t]
  function this:begin()
    return iterator_t(self.__impl.__next, 0)
  end

  ---// Returns an const iterator addressing the first element in a list.
  ---@return [const_iterator_t]
  function this:cbegin()
    return const_iterator_t(self.__impl.__next)
  end

  ---// Returns a const iterator that addresses the location just beyond the last element in a range.
  ---@return [const_iterator_t]
  function this:cend()
    return const_iterator_t(self.__impl)
  end

  ---// Erases all the elements of a list.
  ---@return [nil]
  function this:clear()
    self.__impl.__next = self.__impl
    self.__impl.__prev = self.__impl
    self.__size = 0
  end

  ---// Returns a const iterator addressing the first element in a reversed list.
  ---@return [const_reverse_iterator_t]
  function this:crbegin()
    return const_reverse_iterator_t(self.__impl.__prev)
  end

  ---// Returns a const iterator that addresses the location succeeding the last element in a reversed list.
  ---@return [const_reverse_iterator_t]
  function this:crend()
    return const_reverse_iterator_t(self.__impl)
  end

  ---// Inserts an element into a list at a specified position.
  ---@any_iterator_t where
  ---@any data
  ---@return [nil]
  function this:emplace(where, data)
    assert(type(where) == "table" and where.__basetype == "iterator_t", "bad argument #1 to 'emplace' (any_iterator_t expected)")
    where.__data:push_front( node_t(data) )
    self.__size = self.__size + 1
  end

  ---// Adds an element to the end of a list.
  ---@any data
  ---@return [nil]
  function this:emplace_back(data)
    self.__impl:push_front( node_t(data) )
    self.__size = self.__size + 1
  end

  ---// Adds an element to the beginning of a list.
  ---@any data
  ---@return [nil]
  function this:emplace_front(data)
    self.__impl:push_back( node_t(data) )
    self.__size = self.__size + 1
  end

  ---// Tests if a list is empty.
  ---@return [boolean]
  function this:empty()
    return self.__size == 0
  end

  ---// Returns an iterator that addresses the location succeeding the last element in a list.
  ---@return [iterator_t]
  function this:end_()
    return iterator_t(self.__impl)
  end

  ---// Removes an element or a range of elements in a list from specified positions.
  ---@any_iterator_t where
  ---@return [any_iterator_t]
  ---
  ---@any_iterator_t first
  ---@any_iterator_t last
  ---@return [any_iterator_t]
  function this:erase(first, last)
    assert(type(first) == "table" and first.__basetype == "iterator_t", "bad argument #1 to 'erase' (any_iterator_t expected)")
    assert(type(last) == "nil" or (type(last) == "table" and last.__basetype == "iterator_t"), "bad argument #2 to 'erase' (any_iterator_t expected)")
    if last then
      while first ~= last do
        local temp = first.__data
        first = first + 1
        temp:pop()
        self.__size = self.__size - 1
      end
      return first
    else
      first.__data:pop()
      self.__size = self.__size - 1
      return first
    end
  end

  ---// Returns a pointer to the first element in a list.
  ---@return [node_t]
  function this:front()
    return self.__impl.__next
  end

  ---// Inserts an element or a number of elements or a range of elements into a list at a specified position.
  ---@any_iterator_t where
  ---@table initializer_list
  ---@return [any_iterator_t]
  ---
  ---@any_iterator_t where
  ---@any value
  ---@return [any_iterator_t]
  ---
  ---@any_iterator_t where
  ---@number count
  ---@any value
  ---@return [any_iterator_t]
  ---
  ---@any_iterator_t where
  ---@any_iterator_t first
  ---@any_iterator_t last
  ---@return [any_iterator_t]
  function this:insert(where, ...)
    assert(type(where) == "table" and where.__basetype == "iterator_t", "bad argument #1 to 'insert' (any_iterator_t expected)")
    local args = { ... }
    if #args == 1 then
      if type(args[1]) == "table" then
        for _, v in ipairs(args[1]) do
          where.__data:push_front( node_t(v) )
          where = where + 1
          self.__size = self.__size + 1
        end
        return where
      else
        where.__data:push_front( node_t(args[1]) )
        where = where + 1
        self.__size = self.__size + 1
        return where
      end
    elseif #args == 2 then
      if type(args[1]) == "number" then
        for i = 1, args[1] do
          where.__data:push_front( node_t(args[2]) )
          where = where + 1
          self.__size = self.__size + 1
        end
        return where
      else
        assert(type(args[1]) == "table" and args[1].__basetype == "iterator_t", "bad argument #1 to 'insert' (any_iterator_t expected)")
        assert(type(args[2]) == "table" and args[2].__basetype == "iterator_t", "bad argument #2 to 'insert' (any_iterator_t expected)")
        while args[1] ~= args[2] do
          local node = args[1].__data
          where.__data:push_front( node_t(node[0]) )
          args[1] = args[1] + 1
          self.__size = self.__size + 1
        end
        return where
      end
    end
    error("cannot find an overload for 'insert' for passed arguments")
  end

  function this:merge()
  end

  ---// Deletes the element at the end of a list.
  ---@return [nil]
  function this:pop_back()
    if not self.__impl.__prev:is_empty() then
      self.__impl.__prev:pop()
      self.__size = self.__size - 1
    end
  end

  ---// Deletes the element at the beginning of a list.
  ---@return [nil]
  function this:pop_front()
    if not self.__impl.__next:is_empty() then
      self.__impl.__next:pop()
      self.__size = self.__size - 1
    end
  end

  ---// Adds an element to the end of a list.
  ---@any data
  ---@return [nil]
  function this:push_back(data)
    local node = node_t(data)
    self.__impl:push_front(node)
    self.__size = self.__size + 1
  end

  ---// Adds an element to the beginning of a list.
  ---@any data
  ---@return [nil]
  function this:push_front(data)
    local node = node_t(data)
    self.__impl:push_back(node)
    self.__size = self.__size + 1
  end

  ---// Returns an iterator that addresses the first element in a reversed list.
  ---@return [reverse_iterator_t]
  function this:rbegin()
    return reverse_iterator_t(self.__impl.__prev)
  end

  ---// Erases elements in a list that match a specified value.
  ---@any data
  ---@return [nil]
  function this:remove(data)
    local node = self.__impl.__next
    while node ~= self.__impl do
      if node[0] == data then
        node:pop()
        self.__size = self.__size - 1
      end
      node = node.__next
    end
  end

  ---// Erases elements from a list for which a specified predicate is satisfied.
  ---@function predicate
  ---@return [nil]
  function this:remove_if(predicate)
    assert(type(predicate) == "function", "bad argument #1 to 'remove_if' (function expected)")
    local node = self.__impl.__next
    while node ~= self.__impl do
      if predicate(node[0]) then
        node:pop()
        self.__size = self.__size - 1
      end
      node = node.__next
    end
  end

  ---// Returns an iterator that addresses the location that follows the last element in a reversed list.
  ---@return [reverse_iterator_t]
  function this:rend()
    return reverse_iterator_t(self.__impl)
  end

  ---// Reverses the order in which the elements occur in a list.
  ---@return [nil]
  function this:reverse()
    local node = self.__impl.__next
    while node ~= self.__impl do
      node.__prev, node.__next = node.__next, node.__prev
      node = node.__prev
    end
    self.__impl.__next, self.__impl.__prev = self.__impl.__prev, self.__impl.__next
  end

  ---// Returns the number of elements in a list.
  ---@return [number]
  function this:size()
    return self.__size
  end

  function this:sort()
  end

  ---// Removes elements from a source list and inserts them into a destination list.
  ---@any_iterator_t where
  ---@list_t source
  ---@return [nil]
  ---
  ---@any_iterator_t where
  ---@list_t source
  ---@any_iterator_t iter
  ---@return [nil]
  ---
  ---@any_iterator_t where
  ---@list_t source
  ---@any_iterator_t first
  ---@any_iterator_t last
  ---@return [nil]
  function this:splice(where, source, ...)
    assert(type(where) == "table" and where.__basetype == "iterator_t", "bad argument #1 to 'splice' (any_iterator_t expected)")
    assert(type(source) == "table" and source.__basetype == "list_t", "bad argument #2 to 'splice' (list_t expected)")
    local args = { ... }
    if #args == 0 then
      local node = source.__impl.__next
      while node and not node:is_empty() do
        where.__data:push_front( node_t(node[0]) )
        local temp = node.__next
        node:pop()
        node = temp
        source.__size = source.__size - 1
        self.__size = self.__size + 1
      end
      return
    elseif #args == 1 then
      assert(type(args[1]) == "table" and args[1].__basetype == "iterator_t", "bad argument #3 to 'splice' (any_iterator_t expected)")
      local node = args[1].__data
      if node and not node:is_empty()then
        where.__data:push_front( node_t(node[0]) )
        node:pop()
        source.__size = source.__size - 1
        self.__size = self.__size + 1
      end
      return
    elseif #args == 2 then
      assert(type(args[1]) == "table" and args[1].__basetype == "iterator_t", "bad argument #3 to 'splice' (any_iterator_t expected)")
      assert(type(args[2]) == "table" and args[2].__basetype == "iterator_t", "bad argument #4 to 'splice' (any_iterator_t expected)")
      while args[1] ~= args[2] do
        local node = args[1].__data
        where.__data:push_front( node_t(node[0]) )
        args[1] = args[1] + 1
        node:pop()
        source.__size = source.__size - 1
        self.__size = self.__size + 1
      end
      return
    end
    error("cannot find an overload for 'splice' for passed arguments")
  end

  ---// Exchanges the elements of two lists.
  ---@list_t other
  ---@return [nil]
  function this:swap(other)
    assert(type(other) == "table" and other.__basetype == "list_t", "bad argument #1 to 'swap' (list_t expected)")
    self.__impl, other.__impl = other.__impl, self.__impl
    self.__size, other.__size = other.__size, self.__size
  end

  ---// Removes adjacent duplicate elements or adjacent elements that satisfy some other binary predicate from a list.
  ---@return [nil]
  ---
  ---@function predicate
  ---@return [nil]
  function this:unique(predicate)
    assert(predicate == nil or type(predicate) == "function", "bad argument #1 to 'unique' (function expected)")
    local a = self.__impl.__next
    local b = a.__next
    while not a:is_empty() do
      if predicate and predicate(a[0], b[0]) or (a[0] == b[0]) then
        a:pop()
        self.__size = self.__size - 1
      end
      a, b = b, b.__next
    end
  end

  ---// Creates a list with elements of a specific value, or as a copy of all or part of some other list.
  ---@nil
  ---@return [list_t]
  ---
  ---@table initializer_list
  ---@return [list_t]
  ---
  ---@list_t right
  ---@return [list_t]
  ---
  ---@number count
  ---@any data
  ---@return [list_t]
  ---
  ---@any_iterator_t first
  ---@any_iterator_t last
  ---@return [list_t]
  local function constructor(_, ...)
    local args = { ... }
    local list = {}
    list.__impl = node_t()
    list.__impl:make_this_node_empty()
    list.__impl.__next = list.__impl
    list.__impl.__prev = list.__impl
    list.__size = 0
    setmetatable(list, { __index = this })

    if #args == 0 then
      return list
    elseif #args == 1 and type(args[1]) == "table" then
      if args[1].__basetype == "list_t" then
        for i in args[1]:begin() do
          list:push_back(i[0])
        end
        return list
      else
        for _, v in ipairs(args[1]) do
          list:push_back(v)
        end
        return list
      end
    elseif #args == 2 then
      if
        (type(args[1]) == "table" and args[1].__basetype == "iterator_t") and
        (type(args[2]) == "table" and args[2].__basetype == "iterator_t")
      then
        local iterator = args[1]
        while iterator ~= args[2] do
          list:push_back(iterator[0][0])
          iterator = iterator + 1
        end
        return list
      else
        assert(type(args[1]) == "number", "bad argument #1 to 'list_t()' (number expected)")
        for i = 1, args[1] do
          list:push_back(args[2])
        end
        return list
      end
    end
    error("cannot find an overload for 'list_t()' for passed arguments")
  end

  return setmetatable(this, { __call = constructor })
end)()

return list_t
