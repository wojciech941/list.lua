local list_t = (function()
  local forward_iterator_t = (function()
    local this = {}
    local meta = {}

    meta.__call = coroutine.wrap(function(self)
      while self and self.__data do
        coroutine.yield(self.__data)
        self = self + 1
      end
    end)

    function meta:__index()
      return rawget(self, __data)
    end

    function meta:__add()
      local result = self.__data + 1
      self.__data = result
      return result and self
    end

    function meta:__sub()
      local result = self.__data - 1
      self.__data = result
      return result and self
    end

    function meta:__eq(other)
      return type(other) == "table" and self.__data == other.__data
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

    meta.__call = coroutine.wrap(function(self)
      while self and self.__data do
        coroutine.yield(self.__data)
        self = self + 1
      end
    end)

    function meta:__index()
      return rawget(self, __data)
    end

    function meta:__add()
      local result = self.__data - 1
      self.__data = result
      return result and self
    end

    function meta:__sub()
      local result = self.__data + 1
      self.__data = result
      return result and self
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
      self.__head, self.__tail = node, node
    else
      self.__tail:push_back(node)
      self.__tail = node
    end
    self.__size = self.__size + 1
  end

  function this:push_front(data)
    local node = node_t(data)
    if self.__size == 0 then
      self.__head, self.__tail = node, node
    else
      self.__head:push_front(node)
      self.__head = node
    end
    self.__size = self.__size + 1
  end

  function this:pop_back()
    if self.__size == 1 then
      self:clear()
    elseif self.__size > 1 then
      local new_tail_node = self.__tail.__prev
      self.__tail:pop()
      self.__tail = new_tail_node
      self.__size = self.__size - 1
    end
  end

  function this:pop_front()
    if self.__size == 1 then
      self:clear()
    elseif self.__size > 1 then
      local new_head_node = self.__head.__next
      self.__head:pop()
      self.__head = new_head_node
      self.__size = self.__size - 1
    end
  end

  function this:begin()
    return forward_iterator_t(self.__head)
  end

  function this:rbegin()
    return reverse_iterator_t(self.__tail)
  end

  function this:cend()
    return forward_iterator_t(self.__tail)
  end

  function this:rend()
    return reverse_iterator_t(self.__head)
  end

  function this:front()
    return self.__head or {}
  end

  function this:back()
    return self.__tail or {}
  end

  function this:clear()
    self.__head, self.__tail = nil, nil
    self.__size = 0
  end

  function this:size()
    return self.__size
  end

  function this:empty()
    return self.__size == 0
  end

  function this:remove(data)
    local node = self.__head
    while node do
      if node[0] == data then
        if self.__head == node then
          self.__head = node.__next
        elseif self.__tail == node then
          self.__tail = node.__prev
        end
        node:pop()
        self.__size = self.__size - 1
      end
      node = node.__next
    end
  end

  function this:remove_if(lambda)
    local node = self.__head
    while node do
      if lambda(node[0]) then
        if self.__head == node then
          self.__head = node.__next
        elseif self.__tail == node then
          self.__tail = node.__prev
        end
        node:pop()
        self.__size = self.__size - 1
      end
      node = node.__next
    end
  end

  function this:reverse()
    if self.__size > 1 then
      local node = self.__head
      while node do
        node.__prev, node.__next = node.__next, node.__prev
        node = node.__prev
      end
      self.__head, self.__tail = self.__tail, self.__head
    end
  end

  local function constructor(_, ...)
    local args = { ... }
    local t = {}
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
