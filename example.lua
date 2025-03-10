local list_t = require("list")

--// Init //--
local a = list_t() -- initializing an empty list
local b = list_t { "a", "b", "c" } -- initialization by a table
local c = list_t(1, 2, 3, 4, 5) -- initialization with an arbitrary number of arguments

--// Push item //--
a:push_back(2) -- adds an item to the back of the list
a:push_front(1) -- adds an item to the front of the list

--// Pop item //--
a:pop_back() -- deletes an item from the back of the list
a:pop_front() -- deletes an item from the front of the list

--// Iterator //--
for v in b:begin() do -- iterator from the front to the back of the list
	print(v) -- output: a, b, c
end

for v in b:rbegin() do -- iterator from the back to the front of the list
	print(v) -- output: c, b, a
end

--// Remove item //--
c:remove(3) -- deletes an items with the specified value from the list
c:remove_if(function(v) -- deletes an items using the callback function
	return (v % 2) == 0
end)

--// Any //--
local size = c:size() -- returns the size of the list
c:reverse() -- unwrapping the list in reverse order
c:front() -- returns the value of the front element
c:back() -- returns the value of the back element
c:clear() -- clears the list
