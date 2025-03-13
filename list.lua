local list_t = (function()
  local EMPTY = {}

  local forward_iterator_t = (function()
    local this = {}
    local meta = {}

    function meta:__index()
      return rawget(self, "__data")
    end

    function meta:__add()
      if self.__data then
        self.__data = self.__data + 1
      end
      return self.__data and self
    end

    function meta:__sub()
      if self.__data then
        self.__data = self.__data - 1
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
        return setmetatable(forward_iterator, {
          __index = meta.__index,
          __add = meta.__add,
          __sub = meta.__sub,
          __eq = meta.__eq,
          __call = coroutine.wrap(function(self)
            while self and self.__data[0] ~= EMPTY do
              coroutine.yield(self.__data)
              self = self + 1
            end
          end)
        })
      end
    end

    return setmetatable(this, { __call = constructor })
  end)()

  local reverse_iterator_t = (function()
    local this = {}
    local meta = {}

    function meta:__index()
      return rawget(self, "__data")
    end

    function meta:__add()
      if self.__data then
        self.__data = self.__data - 1
      end
      return self.__data and self
    end

    function meta:__sub()
      if self.__data then
        self.__data = self.__data + 1
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
        return setmetatable(reverse_iterator, {
          __index = meta.__index,
          __add = meta.__add,
          __sub = meta.__sub,
          __eq = meta.__eq,
          __call = coroutine.wrap(function(self)
            while self and self.__data[0] ~= EMPTY do
              coroutine.yield(self.__data)
              self = self + 1
            end
          end)
        })
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
      self.__next, node.__next, node.__prev = node, self.__next, self
    end

    function this:push_front(node)
      self.__prev, node.__next, node.__prev = node, self, self.__prev
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

  function this:push_back(data)
    local node = node_t(data)
    if self.__size == 0 then
      self.__impl.__next, self.__impl.__prev = node, node
      self.__impl.__next.__prev, self.__impl.__prev.__next = self.__impl, self.__impl
    else
      self.__impl.__prev:push_back(node)
      self.__impl.__prev = node
    end
    self.__size = self.__size + 1
  end

  function this:push_front(data)
    local node = node_t(data)
    if self.__size == 0 then
      self.__impl.__next, self.__impl.__prev = node, node
      self.__impl.__next.__prev, self.__impl.__prev.__next = self.__impl, self.__impl
    else
      self.__impl.__next:push_front(node)
      self.__impl.__next = node
    end
    self.__size = self.__size + 1
  end

  function this:pop_back()
    if self.__size == 1 then
      self:clear()
    elseif self.__size > 1 then
      local new_tail_node = self.__impl.__prev.__prev
      self.__impl.__prev:pop()
      self.__impl.__prev = new_tail_node
      self.__size = self.__size - 1
    end
  end

  function this:pop_front()
    if self.__size == 1 then
      self:clear()
    elseif self.__size > 1 then
      local new_head_node = self.__impl.__next.__next
      self.__impl.__next:pop()
      self.__impl.__next = new_head_node
      self.__size = self.__size - 1
    end
  end

  function this:begin()
    return forward_iterator_t(self.__impl.__next)
  end

  function this:rbegin()
    return reverse_iterator_t(self.__impl.__prev)
  end

  function this:cend()
    return forward_iterator_t(self.__impl)
  end

  function this:rend()
    return reverse_iterator_t(self.__impl)
  end

  function this:front()
    return self.__impl.__next or {}
  end

  function this:back()
    return self.__impl.__prev or {}
  end

  function this:clear()
    self.__impl.__next, self.__impl.__prev = nil, nil
    self.__size = 0
  end

  function this:size()
    return self.__size
  end

  function this:empty()
    return self.__size == 0
  end

  function this:remove(data)
    local node = self.__impl.__next
    while node ~= self.__impl do
      if node[0] == data then
        if self.__impl.__next == node then
          self.__impl.__next = node.__next
        elseif self.__impl.__prev == node then
          self.__impl.__prev = node.__prev
        end
        node:pop()
        self.__size = self.__size - 1
      end
      node = node.__next
    end
  end

  function this:remove_if(lambda)
    local node = self.__impl.__next
    while node ~= self.__impl do
      if lambda(node[0]) then
        if self.__impl.__next == node then
          self.__impl.__next = node.__next
        elseif self.__impl.__prev == node then
          self.__impl.__prev = node.__prev
        end
        node:pop()
        self.__size = self.__size - 1
      end
      node = node.__next
    end
  end

  function this:reverse()
    if self.__size > 1 then
      local node = self.__impl.__next
      while node do
        node.__prev, node.__next = node.__next, node.__prev
        node = node.__prev
      end
      self.__impl.__next, self.__impl.__prev = self.__impl.__prev, self.__impl.__next
    end
  end

  function this:swap(other)
    self.__impl, other.__impl = other.__impl, self.__impl
  end

  local function constructor(_, ...)
    local args = { ... }
    local t = {}
    t.__impl = node_t(EMPTY)
    t.__size = 0
    setmetatable(t, { __index = this })

    if #args == 1 and type(args[1]) == "table" then
      for _, v in ipairs(args[1]) do
        t:push_back(v)
      end
    elseif #args > 0 then
      for _, v in ipairs(args) do
        t:push_back(v)
      end
    end

    return t
  end

  return setmetatable(this, { __call = constructor })
end)()
