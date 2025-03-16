local list_t = (function()
  local CONST_EMPTY_NODE_DATA = {}

  local iterator_t = (function()
    local this = {}
    local meta = {}

    local function recreate_call_iterator()
      return coroutine.wrap(function(self)
        while self and self.__data and self.__data[0] ~= CONST_EMPTY_NODE_DATA do
          coroutine.yield(self)
          self = self + 1
        end
        getmetatable(self).__call = recreate_call_iterator()
      end)
    end

    meta.__call = recreate_call_iterator()

    function meta:__index(k)
      if k == 0 then
        return rawget(self, "__data")[0]
      elseif k == "__basetype" then
        return "iterator_t"
      elseif k == "__type" then
        return "iterator_t"
      end
    end

    function meta:__newindex(k, v)
      if k == 0 then
        rawget(self, "__data")[k] = v
      end
    end

    function meta:__add()
      if self.__data then
        self.__data = self.__data + 1
      end
      return self
    end

    function meta:__sub()
      if self.__data then
        self.__data = self.__data - 1
      end
      return self
    end

    function meta:__eq(other)
      return type(other) == "table" and (self.__data == other.__data)
    end

    local function constructor(_, data)
      if data then
        local forward_iterator = {}
        forward_iterator.__data = data
        return setmetatable(forward_iterator, meta)
      end
    end

    return setmetatable(this, { __call = constructor })
  end)()

  local reverse_iterator_t = (function()
    local this = {}
    local meta = {}

    local function recreate_call_iterator()
      return coroutine.wrap(function(self)
        while self and self.__data and self.__data[0] ~= CONST_EMPTY_NODE_DATA do
          coroutine.yield(self)
          self = self + 1
        end
        getmetatable(self).__call = recreate_call_iterator()
      end)
    end

    meta.__call = recreate_call_iterator()

    function meta:__index(k)
      if k == 0 then
        return rawget(self, "__data")[0]
      elseif k == "__basetype" then
        return "iterator_t"
      elseif k == "__type" then
        return "reverse_iterator_t"
      end
    end

    function meta:__newindex(k, v)
      if k == 0 then
        rawget(self, "__data")[k] = v
      end
    end

    function meta:__add()
      if self.__data then
        self.__data = self.__data - 1
      end
      return self
    end

    function meta:__sub()
      if self.__data then
        self.__data = self.__data + 1
      end
      return self
    end

    function meta:__eq(other)
      return type(other) == "table" and self.__data == other.__data
    end

    local function constructor(_, data)
      if data then
        local reverse_iterator = {}
        reverse_iterator.__data = data
        return setmetatable(reverse_iterator, meta)
      end
    end

    return setmetatable(this, { __call = constructor })
  end)()

  local const_iterator_t = (function()
    local this = {}
    local meta = {}

    local function recreate_call_iterator()
      return coroutine.wrap(function(self)
        while self and self.__data and self.__data[0] ~= CONST_EMPTY_NODE_DATA do
          coroutine.yield(self)
          self = self + 1
        end
        getmetatable(self).__call = recreate_call_iterator()
      end)
    end

    meta.__call = recreate_call_iterator()

    function meta:__index(k)
      if k == 0 then
        return rawget(self, "__data")[0]
      elseif k == "__basetype" then
        return "iterator_t"
      elseif k == "__type" then
        return "const_iterator_t"
      end
    end

    function meta:__newindex()
      return
    end

    function meta:__add()
      if self.__data then
        self.__data = self.__data + 1
      end
      return self
    end

    function meta:__sub()
      if self.__data then
        self.__data = self.__data - 1
      end
      return self
    end

    function meta:__eq(other)
      return type(other) == "table" and (self.__data == other.__data)
    end

    local function constructor(_, data)
      if data then
        local forward_iterator = {}
        forward_iterator.__data = data
        return setmetatable(forward_iterator, meta)
      end
    end

    return setmetatable(this, { __call = constructor })
  end)()

  local const_reverse_iterator_t = (function()
    local this = {}
    local meta = {}

    local function recreate_call_iterator()
      return coroutine.wrap(function(self)
        while self and self.__data and self.__data[0] ~= CONST_EMPTY_NODE_DATA do
          coroutine.yield(self)
          self = self + 1
        end
        getmetatable(self).__call = recreate_call_iterator()
      end)
    end

    meta.__call = recreate_call_iterator()

    function meta:__index(k)
      if k == 0 then
        return rawget(self, "__data")[0]
      elseif k == "__basetype" then
        return "iterator_t"
      elseif k == "__type" then
        return "const_reverse_iterator_t"
      end
    end

    function meta:__newindex()
      return
    end

    function meta:__add()
      if self.__data then
        self.__data = self.__data - 1
      end
      return self
    end

    function meta:__sub()
      if self.__data then
        self.__data = self.__data + 1
      end
      return self
    end

    function meta:__eq(other)
      return type(other) == "table" and self.__data == other.__data
    end

    local function constructor(_, data)
      if data then
        local reverse_iterator = {}
        reverse_iterator.__data = data
        return setmetatable(reverse_iterator, meta)
      end
    end

    return setmetatable(this, { __call = constructor })
  end)()

  local node_t = (function()
    local this = {}
    local meta = {}

    meta.__index = this

    function meta:__add()
      return self.__next
    end

    function meta:__sub()
      return self.__prev
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

    local function constructor(_, data)
      local node = {}
      node[0] = data
      return setmetatable(node, meta)
    end

    return setmetatable(this, { __call = constructor })
  end)()

  local this = {}
  this.CONST_EMPTY_NODE_DATA = CONST_EMPTY_NODE_DATA

  ---@table initializer_list
  ---
  ---@any_iterator_t first
  ---@any_iterator_t last
  ---
  ---@number count
  ---@any data
  function this:assign(...)
    local args = { ... }
    if #args == 1 and type(args[1]) == "table" then
      self:clear()
      for _, v in ipairs(args[1]) do
        self:push_back(v)
      end
    elseif #args == 2 then
      if
        type(args[1]) == "table" and
        args[1].__basetype == "iterator_t" and
        type(args[2]) == "table" and
        args[2].__basetype == "iterator_t"
      then
        self:clear()
        while args[1] ~= args[2] do
          local node = args[1].__data
          self:push_back(node[0])
          args[1] = args[1] + 1
        end
      else
        self:clear()
        for i = 1, args[1] do
          self:push_back(args[2])
        end
      end
    end
  end

  ---@return [node_t]
  function this:back()
    return self.__impl.__prev
  end

  ---@return [iterator_t]
  function this:begin()
    return iterator_t(self.__impl.__next)
  end

  ---@return [const_iterator_t]
  function this:cbegin()
    return const_iterator_t(self.__impl.__next)
  end

  ---@return [const_iterator_t]
  function this:cend()
    return const_iterator_t(self.__impl)
  end

  function this:clear()
    self.__impl.__next = self.__impl
    self.__impl.__prev = self.__impl
    self.__size = 0
  end

  ---@return [const_reverse_iterator_t]
  function this:crbegin()
    return const_reverse_iterator_t(self.__impl.__prev)
  end

  ---@return [const_reverse_iterator_t]
  function this:crend()
    return const_reverse_iterator_t(self.__impl)
  end

  ---@any_iterator_t where
  ---@any data
  function this:emplace(where, data)
    where.__data:push_front( node_t(data) )
    self.__size = self.__size + 1
  end

  ---@any data
  function this:emplace_back(data)
    self.__impl:push_front( node_t(data) )
    self.__size = self.__size + 1
  end

  ---@any data
  function this:emplace_front(data)
    self.__impl:push_back( node_t(data) )
    self.__size = self.__size + 1
  end

  ---@return [boolean]
  function this:empty()
    return self.__size == 0
  end

  ---@return [iterator_t]
  function this:end_()
    return iterator_t(self.__impl)
  end

  ---@any_iterator_t where
  ---
  ---@any_iterator_t first
  ---@any_iterator_t last
  function this:erase(first, last)
    if last then
      while first ~= last do
        local temp = first.__data
        first = first + 1
        temp:pop()
        self.__size = self.__size - 1
      end
    else
      first.__data:pop()
      self.__size = self.__size - 1
    end
  end

  ---@return [node_t]
  function this:front()
    return self.__impl.__next
  end

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
    local args = { ... }
    if #args == 1 then
      if type(args[1]) == "table" then
        for _, v in ipairs(args[1]) do
          where.__data:push_front( node_t(v) )
          where = where + 1
          self.__size = self.__size + 1
        end
      else
        where.__data:push_front( node_t(args[1]) )
        where = where + 1
        self.__size = self.__size + 1
      end
    elseif #args == 2 then
      if type(args[1]) == "number" then
        for i = 1, args[1] do
          where.__data:push_front( node_t(args[2]) )
          where = where + 1
          self.__size = self.__size + 1
        end
      else
        while args[1] ~= args[2] do
          local node = args[1].__data
          where.__data:push_front( node_t(node[0]) )
          args[1] = args[1] + 1
          self.__size = self.__size + 1
        end
      end
    end
    return where
  end

  function this:merge()
  end

  function this:pop_back()
    if self.__impl.__prev then
      self.__impl.__prev:pop()
      self.__size = self.__size - 1
    end
  end

  function this:pop_front()
    if self.__impl.__next then
      self.__impl.__next:pop()
      self.__size = self.__size - 1
    end
  end

  ---@any data
  function this:push_back(data)
    local node = node_t(data)
    self.__impl:push_front(node)
    self.__size = self.__size + 1
  end

  ---@any data
  function this:push_front(data)
    local node = node_t(data)
    self.__impl:push_back(node)
    self.__size = self.__size + 1
  end

  ---@return [reverse_iterator_t]
  function this:rbegin()
    return reverse_iterator_t(self.__impl.__prev)
  end

  ---@any data
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

  ---@function lambda
  function this:remove_if(lambda)
    local node = self.__impl.__next
    while node ~= self.__impl do
      if lambda(node[0]) then
        node:pop()
        self.__size = self.__size - 1
      end
      node = node.__next
    end
  end

  ---@return [reverse_iterator_t]
  function this:rend()
    return reverse_iterator_t(self.__impl)
  end

  function this:reverse()
    local node = self.__impl.__next
    while node ~= self.__impl do
      node.__prev, node.__next = node.__next, node.__prev
      node = node.__prev
    end
    self.__impl.__next, self.__impl.__prev = self.__impl.__prev, self.__impl.__next
  end

  ---@return [number]
  function this:size()
    return self.__size
  end

  function this:sort()
  end

  ---@any_iterator_t where
  ---@list_t source
  ---
  ---@any_iterator_t where
  ---@list_t source
  ---@any_iterator_t iter 
  ---
  ---@any_iterator_t where
  ---@list_t source
  ---@any_iterator_t first
  ---@any_iterator_t last 
  function this:splice(where, source, ...)
    local args = { ... }
    if #args == 0 then
      local node = source.__impl.__next
      while node and node[0] ~= CONST_EMPTY_NODE_DATA do
        where.__data:push_front( node_t(node[0]) )
        local temp = node.__next
        node:pop()
        node = temp
        source.__size = source.__size - 1
        self.__size = self.__size + 1
      end
    elseif #args == 1 then
      local node = args[1].__data
      if node and node[0] ~= CONST_EMPTY_NODE_DATA then
        where.__data:push_front( node_t(node[0]) )
        node:pop()
        source.__size = source.__size - 1
        self.__size = self.__size + 1
      end
    elseif #args == 2 then
      while args[1] ~= args[2] do
        local node = args[1].__data
        where.__data:push_front( node_t(node[0]) )
        args[1] = args[1] + 1
        node:pop()
        source.__size = source.__size - 1
        self.__size = self.__size + 1
      end
    end
  end

  ---@list_t other
  function this:swap(other)
    self.__impl, other.__impl = other.__impl, self.__impl
    self.__size, other.__size = other.__size, self.__size
  end

  ---@nil
  ---
  ---@function lambda
  function this:unique(lambda)
    if not self.__impl.__next then
      return
    end
    local a = self.__impl.__next
    local b = a.__next
    while (a and b) and a ~= self.__impl and b ~= self.__impl do
      if lambda and lambda(a[0], b[0]) or (a[0] == b[0]) then
        a:pop()
        self.__size = self.__size - 1
      end
      a, b = b, b.__next
    end
  end

  ---@nil
  ---@return [list_t]
  ---
  ---@table initializer_list
  ---@return [list_t]
  ---
  ---@any_iterator_t first
  ---@any_iterator_t last
  ---@return [list_t]
  ---
  ---@(...)
  ---@return [list_t]
  local function constructor(_, ...)
    local args = { ... }
    local list = {}
    list.__impl = node_t(CONST_EMPTY_NODE_DATA)
    list.__impl.__next = list.__impl
    list.__impl.__prev = list.__impl
    list.__size = 0
    setmetatable(list, { __index = this })

    if #args == 1 and type(args[1]) == "table" then
      for _, v in ipairs(args[1]) do
        list:push_back(v)
      end
    elseif
      #args == 2 and
      (type(args[1]) == "table" and args[1].__basetype == "iterator_t") and
      (type(args[2]) == "table" and args[2].__basetype == "iterator_t")
    then
      local iterator = args[1]
      while iterator ~= args[2] do
        list:push_back(iterator[0][0])
        iterator = iterator + 1
      end
    elseif #args > 0 then
      for _, v in ipairs(args) do
        list:push_back(v)
      end
    end

    return list
  end

  return setmetatable(this, { __call = constructor })
end)()

return list_t
