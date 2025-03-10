local list_t = (function()
  local CONST_NODE = {} 

  local node_t = (function()
    local this = {}

    local function constructor(_, data)
      local t = {}
      t.data = data
      return setmetatable(t, { __index = this })
    end

    function this:push_front(t)
      self.prev, t.next, t.prev = t, self, self.prev
      return t
    end

    function this:push_back(t)
      self.next, t.next, t.prev = t, self.next, self
      return t
    end

    function this:pop()
      if self.prev then
        self.prev.next = self.next
      end
      if self.next then
        self.next.prev = self.prev
      end
    end

    function this:begin()
      local iterator = self
      return coroutine.wrap(function()
        while iterator do
          local temp = iterator
          iterator = iterator.next
          coroutine.yield(temp)
        end
      end)
    end

    function this:rbegin()
      local iterator = self
      return coroutine.wrap(function()
        while iterator do
          local temp = iterator
          iterator = iterator.prev
          coroutine.yield(temp)
        end
      end)
    end

    return setmetatable(this, { __call = constructor })
  end)()

  local this = {}

  function this:push_front(data)
    self.__size = self.__size + 1
    self.__head = self.__head:push_front( node_t(data) )
  end

  function this:push_back(data)
    self.__size = self.__size + 1
    self.__tail = self.__tail:push_back( node_t(data) )
  end

  function this:pop_front()
    if self.__size > 0 then
      self.__size = self.__size - 1
      return self.__head:pop()
    end
  end

  function this:pop_back()
    if self.__size > 0 then
      self.__size = self.__size - 1
      return self.__tail:pop()
    end
  end

  function this:begin()
    local iterator = self.__head:begin()
    return function()
      :: continue ::
      local node = iterator()
      if node and node.data then
        if node.data == CONST_NODE then
          goto continue
        end
        return node.data
      end
    end
  end

  function this:rbegin()
    local iterator = self.__tail:rbegin()
    return function()
      :: continue ::
      local node = iterator()
      if node and node.data then
        if node.data == CONST_NODE then
          goto continue
        end
        return node.data
      end
    end
  end

  function this:remove(data)
    local iterator = self.__head:begin()
    repeat
      local node = iterator()
      if node and node.data == data then
        if self.__head == node then
          self.__head = node.next
        elseif self.__tail == node then
          self.__tail = node.prev
        end
        node:pop()
        self.__size = self.__size - 1
      end
    until not node
  end

  function this:remove_if(lambda)
    local iterator = self.__head:begin()
    repeat
      local node = iterator()
      if node and node.data ~= CONST_NODE and lambda(node.data) then
        if self.__head == node then
          self.__head = node.next
        elseif self.__tail == node then
          self.__tail = node.prev
        end
        node:pop()
        self.__size = self.__size - 1
      end
    until not node
  end

  function this:clear()
    local node = node_t(CONST_NODE)
    self.__head, self.__tail = node, node
    self.__size = 0
  end

  function this:reverse()
    local front_iterator = self.__head:begin()
    local back_iterator = self.__tail:rbegin()
    repeat
      local a, b = front_iterator(), back_iterator()
      a.data, b.data = b.data, a.data
    until (a == b) or (a.next == b) or (b.prev == a)
  end

  function this:front()
    return self.__head.data
  end

  function this:back()
    return self.__tail.data
  end

  function this:size()
    return self.__size
  end

  local function constructor(data)
    local t = {}
    local node = node_t(data or CONST_NODE)
    t.__head = node
    t.__tail = node
    t.__size = 0
    return setmetatable(t, { __index = this })
  end

  local function determinant(_, ...)
    local args = {...}
    if #args == 0 then
      return constructor()
    elseif #args == 1 then
      if type(args[1]) == "table" then
        local t = constructor(args[1][1])
        for i = 2, #args[1] do
          t:push_back(args[1][i])
        end
        t.__size = #args[1]
        return t
      end
    else
      local t = constructor(args[1])
      for i = 2, #args do
        t:push_back(args[i])
      end
      t.__size = #args
      return t
    end
  end

  return setmetatable(this, { __call = determinant })
end)()
