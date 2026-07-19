local this = {}

-- enqueue function to insert an element to the end of queue
function this.enqueue(queue, value)
    queue.tail = queue.tail + 1;
	queue.length = queue.length + 1;
	queue.data[queue.tail] = value;
end

-- get the first element in the front of the queue without removing it
function this.first(queue)
    local value = queue.data[queue.front];

    return value;
end

-- dequeue function to remove an element from the front of queue
function this.dequeue(queue)
    if queue.length <= 0 then
        return;
    end
	
	local value = queue.data[queue.front];

	queue.data[queue.front] = nil;
    queue.front = queue.front + 1;
	queue.length = queue.length - 1;
	
	return value;
end

function this.contains(queue, value)
    for i = queue.front, queue.tail do
        if queue.data[i] == value then
            return true;
        end
    end

    return false;
end

function this.new()
    local queue = {
        data = {},
        front = 1, -- front index
        tail = 0,  -- tail index
		length = 0,
    };

    queue.enqueue = function(value)
        this.enqueue(queue, value);
    end

    queue.first = function()
        return this.first(queue);
    end

    queue.dequeue = function()
        return this.dequeue(queue);
    end

    queue.contains = function(value)
        return this.contains(queue, value);
    end

    return queue;
end

function this.init_module()
end

return this;