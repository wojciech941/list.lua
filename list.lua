local list_t = (function()
  local CONST_EMPTY_NODE_DATA = {}

  local forward_iterator_t = (function()
    local this = {}
    local meta = {}

    function meta:__call()
      if self and self.__data and self.__data[0] ~= CONST_EMPTY_NODE_DATA then
        local temp = self.__data
        self = self + 1
        return temp
      end
    end

    function meta:__index(k)
      if k == "__basetype" then
        return "iterator_t"
      elseif k == "__type" then
        return "forward_iterator_t"
      else
        return rawget(self, "__data")
      end
    end

    function meta:__add()
      if self.__data then
        self.__data = self.__data + 1
      end
      return self.__data and self
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

    function meta:__call()
      if self and self.__data[0] ~= CONST_EMPTY_NODE_DATA then
        local temp = self.__data
        self = self + 1
        return temp
      end
    end

    function meta:__index()
      if k == "__basetype" then
        return "iterator_t"
      elseif k == "__type" then
        return "reverse_iterator_t"
      else
        return rawget(self, "__data")
      end
    end

    function meta:__add()
      if self.__data then
        self.__data = self.__data - 1
      end
      return self.__data and self
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

  function this:assign()
  end

  ---@return [node_t] back element
  function this:back()
    return self.__impl.__prev
  end

  ---@return [forward_iterator_t]
  function this:begin()
    return forward_iterator_t(self.__impl.__next)
  end

  function this:cbegin()
  end

  function this:cend()
  end

  function this:clear()
    self.__impl.__next = nil
    self.__impl.__prev = nil
    self.__size = 0
  end

  function this:crbegin()
  end

  function this:crend()
  end

  function this:emplace()
  end

  function this:emplace_back()
  end

  function this:emplace_front()
  end

  ---@return [boolean] size ~= 0
  function this:empty()
    return self.__size == 0
  end

  ---@return [forward_iterator_t]
  function this:end_()
    return forward_iterator_t(self.__impl)
  end

  function this:erase()
  end

  ---@return [node_t] front element
  function this:front()
    return self.__impl.__next
  end

  -- does NOT WORK with uninitialized list
  ---@any_iterator_t where
  ---@table initializer_list
  ---
  ---@any_iterator_t where
  ---@any value
  ---
  ---@any_iterator_t where
  ---@number count 
  ---@any value
  ---
  ---@return [any_iterator_t]
  function this:insert(where, ...)
    local args = { ... }
    if #args == 1 then
      if type(args[1]) == "table" then
        for _, v in ipairs(args[1]) do
          where.__data:push_back( node_t(v) )
          where = where + 1
        end
      else
        where.__data:push_back( node_t(args[1]) )
        where = where + 1
      end
    elseif #args == 2 then
      for i = 1, args[1] do
        where.__data:push_back( node_t(args[2]) )
        where = where + 1
      end
    end
    return where
  end

  function this:merge(lambda)
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
    if self.__impl.__prev then
      self.__impl:push_front(node)
    else
      self.__impl.__prev = self.__impl:push_back(node)
    end
    self.__size = self.__size + 1
  end

  ---@any data
  function this:push_front(data)
    local node = node_t(data)
    if self.__impl.__next then
      self.__impl:push_back(node)
    else
      self.__impl.__next = node
    end
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

  ---@return [number] size
  function this:size()
    return self.__size
  end

  function this:sort()
  end

  function this:splice()
  end

  function this:swap(other)
    self.__impl, other.__impl = other.__impl, self.__impl
  end

  function this:unique(lambda)
  end

  ---@nil empty initializer
  ---
  ---@table initializer_list
  ---
  ---@any_iterator_t first
  ---@any_iterator_t last
  ---
  ---@(...) arguments initializer
  ---
  ---@return [list_t]
  local function constructor(_, ...)
    local args = { ... }
    local list = {}
    list.__impl = node_t(CONST_EMPTY_NODE_DATA)
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
