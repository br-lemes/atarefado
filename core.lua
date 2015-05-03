
local luasql = require('luasql.sqlite3')

-- assert time calculations (os dependent)

assert(
	os.time{day = -1, month = 1, year = 2013}
	==
	os.time{day = 30, month = 12, year = 2012}
)

assert(
	os.time{day = 32, month = 12, year = 2012}
	==
	os.time{day = 1, month = 1, year = 2013}
)

local env, con

local function hasTable(table)
	if not con then return nil, 'There is no open database' end
	local cur, err = con:execute(string.format(
		'SELECT * FROM sqlite_master WHERE type="table" AND name=%q;',
		table))
	if not cur then return nil, err end
	local row = { }
	cur:fetch(row)
	cur:close()
	return row[1] ~= nil
end

local function open(dbname)
	local err
	env, err = luasql.sqlite3()
	if not env then return nil, err end
	con, err = env:connect(dbname)
	if not con then return nil, err end
	con:execute('BEGIN;')
	if not hasTable('tagnames') then
		con:execute([[
			CREATE TABLE tagnames (
				id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
				name TEXT NOT NULL
			);]])
		for i, v in ipairs{
				'Dom', 'Seg', 'Ter', 'Qua',
				'Qui', 'Sex', 'Sáb'
			} do
			con:execute(string.format(
				'INSERT INTO tagnames VALUES(NULL, %q);', v))
		end
		for i = 1, 31 do
			con:execute(string.format(
				'INSERT INTO tagnames VALUES(NULL, "%02d");',
				i))
		end
	end

	if not hasTable('tags') then
		con:execute([[
			CREATE TABLE tags (
				task INTEGER NOT NULL,
				tag INTEGER NOT NULL
			);]])
	end

	if not hasTable('tasks') then
		con:execute([[
			CREATE TABLE tasks (
				id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
				name TEXT NOT NULL,
				date TEXT,
				comment TEXT,
				recurrent INTEGER NOT NULL
			);]])
	end

	if not hasTable('options') then
		con:execute([[
			CREATE TABLE options (
				id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
				name TEXT NOT NULL,
				value TEXT
			);]])
		local optfmt = 'INSERT INTO options VALUES(NULL, %q, %q);'
		for i, v in ipairs{
				'anytime', 'tomorrow', 'future',
				'today', 'yesterday', 'late'
			} do
			con:execute(string.format(optfmt, v, 'ON'))
		end
		con:execute(string.format(optfmt, 'tag', '1'))
		con:execute(string.format(optfmt, 'version', '1'))
	end
	con:execute('END;')
	return true
end

local function close()
	if con then con:close() end
	if env then env:close() end
end

local function hasId(id, table)
	if not con then return nil, 'There is no open database' end
	local cur, err = con:execute(string.format(
		'SELECT * FROM %q WHERE id=%d;', table, id))
	if not cur then return nil, err end
	local row = { }
	cur:fetch(row)
	cur:close()
	return row[1] ~= nil
end

local function hasTag(task, tag)
	if not con then return nil, 'There is no open database' end
	local cur, err = con:execute(string.format(
		'SELECT * FROM tags WHERE task=%d and tag=%d;', task, tag))
	if not cur then return nil, err end
	local row = { }
	cur:fetch(row)
	cur:close()
	return row[1] ~= nil
end

local function hasNoTags(task)
	if not con then return nil, 'There is no open database' end
	local cur, err = con:execute(string.format(
		'SELECT * FROM tags WHERE task=%d;', task))
	if not cur then return nil, err end
	local row = { }
	while cur:fetch(row, "a") do
		-- ignore the first 38 special tags
		if tonumber(row.tag) > 38 then 
			cur:close()
			return false
		end
	end
	cur:close()
	return true
end

local function newTask(task)
	if not con then return nil, 'There is no open database' end
	if not task or task.name == nil then
		return nil, 'Task has no name'
	end
	task.date = task.date or ''
	task.comment = task.comment or ''
	task.recurrent = task.recurrent or 1
	local cur, err = con:execute(string.format(
		'INSERT INTO tasks VALUES(NULL, %q, %q, %q, %d);',
		task.name, task.date, task.comment, task.recurrent))
	if cur and task.tags then
		local cur, err = con:execute('SELECT last_insert_rowid();')
		if not cur then return nil, err end
		local row = { }
		cur:fetch(row)
		cur:close()
		for i,v in ipairs(task.tags) do
			setTag(row[1], v)
		end
	end
	return cur, err
end

local function newTag(name)
	if not con then return nil, 'There is no open database' end
	local cur, err = con:execute(string.format(
		'INSERT INTO tagnames VALUES(NULL, %q);', name))
	return cur, err
end

local function delTask(task, force)
	if not con then return nil, 'There is no open database' end
	local task = getTask(task)
	if task.recurrent == '1' or (task.recurrent ~= '1' and force) then
		local cur, err = con:execute(string.format(
			'DELETE FROM tasks WHERE id=%d;', task.id))
		return cur, err
	else return goNext(task.id) end
end

local function delTag(tag)
	if not con then return nil, 'There is no open database' end
	if tonumber(tag) <= 38 then
		return nil, 'Do not touch the first 38 special tags'
	end
	if not hasId(tag, 'tagnames') then
		return nil, 'Invalid tag'
	end
	local cur, err = con:execute('SELECT id FROM tasks;')
	if not cur then return nil, err end
	local row = { }
	while cur:fetch(row) do
		local cur, err = con:execute(string.format(
			'DELETE FROM tags WHERE task=%d and tag=%d;',
			row[1], tag))
		if not cur then return nil, err end
	end
	cur:close()
	local cur, err = con:execute(string.format(
		'DELETE FROM tagnames WHERE id=%d;', tag))
	return cur, err
end

local function setOption(option, value)
	if not con then return nil, 'There is no open database' end
	local cur, err = con:execute(string.format(
		'UPDATE options SET value=%q WHERE name=%q;',
		 value, option))
	return cur, err
end

local function setTag(task, tag)
	if not con then return nil, 'There is no open database' end
	if not hasId(tag, 'tagnames') then
		return nil, 'Invalid tag'
	end
	if not hasTag(task, tag) then
		local cur, err = con:execute(string.format(
			'INSERT INTO tags VALUES(%d, %d);', task, tag))
		return cur, err
	else
		return nil, 'Already tagged'
	end
end

local function clearTag(task, tag)
	if not con then return nil, 'There is no open database' end
	if not hasTag(task, tag) then
		return nil, 'Not tagged'
	end
	if not hasId(tag, 'tagnames') then
		return nil, 'Invalid tag'
	end
	local cur, err = con:execute(string.format(
		'DELETE FROM tags WHERE task=%d and tag=%d;', task, tag))
	return cur, err
end

local function getTask(task)
	if not con then return nil, 'There is no open database' end
	if not hasId(task, 'tasks') then
		return nil, 'No task'
	end
	local cur,err = con:execute(string.format(
		'SELECT * FROM tasks WHERE id=%d;', task))
	if not cur then return nil, err end
	local row = { }
	cur:fetch(row, 'a')
	cur:close()
	return row
end

local function getTags(task)
	if not con then return nil, 'There is no open database' end
	local result = { }
	if not task then
		-- ignore the first 38 special tags
		local cur, err = con:execute(
			'SELECT * FROM tagnames WHERE id > 38 ORDER BY name;')
		if not cur then return nil, err end
		local row = { }
		while cur:fetch(row) do
			table.insert(result, {id = row[1], name = row[2]})
		end
		cur:close()
	else
		if not hasId(task, 'tasks') then return nil end
		local cur, err = con:execute(string.format([[
			SELECT tag, name FROM tags
			JOIN tagnames ON tag=id WHERE task=%d
			ORDER BY name;]], task))
		if not cur then return nil, err end
		local row = { }
		while cur:fetch(row) do
			result[tonumber(row[1])] = row[2]
		end
		cur:close()
	end
	return result
end

local function getOptions()
	if not con then return nil, 'There is no open database' end
	local cur, err = con:execute('SELECT value FROM options;')
	if not cur then return nil, err end
	local result = { }
	local row = { }
	cur:fetch(row) result.anytime   = row[1]
	cur:fetch(row) result.tomorrow  = row[1]
	cur:fetch(row) result.future    = row[1]
	cur:fetch(row) result.today     = row[1]
	cur:fetch(row) result.yesterday = row[1]
	cur:fetch(row) result.late      = row[1]
	cur:fetch(row) result.tag       = row[1]
	cur:close()
	return result
end

local function updTask(task)
	if not con then return nil, 'There is no open database' end
	local upd_str = ''
	for k, v in pairs(task) do
		if k ~= 'id' then
			if upd_str ~= '' then
				upd_str = upd_str .. ','
			end
			upd_str = string.format('%s %s=%q', upd_str, k, v)
		end
	end
	local cur, err = con:execute(string.format(
		'UPDATE tasks SET %s WHERE id=%d;', upd_str, task.id))
	return cur, err
end

local function updTag(tag, newname)
	if not con then return nil, 'There is no open database' end
	if tonumber(tag) <= 38 then
		return nil, 'Do not touch the first 38 special tags'
	end
	local cur, err = con:execute(string.format(
		'UPDATE tagnames SET name=%q WHERE id=%d;', newname, tag))
	return cur, err
end

local function goNext(task)
	if not con then return nil, 'There is no open database' end
	local task = getTask(task)
	local tags = getTags(task.id)
	if isAnytime(task.date) then
		task.date = os.date('%Y-%m-%d')
	end
	local d = { }
	d.year, d.month, d.day = task.date:match('(%d%d%d%d)-(%d%d)-(%d%d)')
	d = os.date('*t', os.time(d))
	if task.recurrent == '2' then
		-- next date this week
		for i = d.wday + 1, 7 do
			if tags[i] then
				d.day = d.day + (i - d.wday)
				local cur, err = con:execute(string.format(
					'UPDATE tasks SET date=%q WHERE id=%d;',
					os.date('%Y-%m-%d', os.time(d)),
					task.id))
				return cur, err
			end
		end
		-- next date next week
		for i = 1, 7 do
			if tags[i] then
				d.day = d.day + (7 - d.wday + i)
				local cur, err = con:execute(string.format(
					'UPDATE tasks SET date=%q WHERE id=%d;',
					os.date('%Y-%m-%d', os.time(d)),
					task.id))
				return cur, err
			end
		end
	elseif task.recurrent == '3' then
		-- next date this month
		for i = d.day + 1, 31 do
			if tags[i + 7] then
				d.day = i
				local cur, err = con:execute(string.format(
					'UPDATE tasks SET date=%q WHERE id=%d;',
					os.date('%Y-%m-%d', os.time(d)),
					task.id))
				return cur, err
			end
		end
		-- next date next month
		for i = 1, 31 do
			if tags[i + 7] then
				d.day = i
				d.month = d.month + 1
				local cur, err = con:execute(string.format(
					'UPDATE tasks SET date=%q WHERE id=%d;',
					os.date('%Y-%m-%d', os.time(d)),
					task.id))
				return cur, err
			end
		end
	elseif task.recurrent == '4' then
		local i = daysMonth(d.month, d.year)
		if d.day == i then
			d.month = d.month + 1
			d.day = daysMonth(d.month, d.year)
		else d.day = i end
		local cur, err = con:execute(string.format(
			'UPDATE tasks SET date=%q WHERE id=%d;',
			os.date('%Y-%m-%d', os.time(d)),
			task.id))
		return cur, err
	elseif task.recurrent == '1' then
		d.day = d.day + 1
		local cur, err = con:execute(string.format(
			'UPDATE tasks SET date=%q WHERE id=%d;',
			os.date('%Y-%m-%d', os.time(d)),
			task.id))
		return cur, err
	end
end

local function lastRow()
	if not con then return nil, 'There is no open database' end
	local cur, err = con:execute('SELECT last_insert_rowid();')
	if not cur then return nil, err end
	local row = { }
	cur:fetch(row)
	cur:close()
	return row[1]
end

local function Begin()
	if not con then return nil, 'There is no open database' end
	con:execute('BEGIN;')	
end

local function End()
	if not con then return nil, 'There is no open database' end
	con:execute('END;')
end

local function isDate(d)
	t = { }
	t.year, t.month, t.day = d:match('(%d%d%d%d)-(%d%d)-(%d%d)')
	return t.year and t.month and t.day and
		os.date('%Y-%m-%d', os.time(t)) == d
end

local function isAnytime(d)
	return not d or d == '' or d == 'anytime'
end

local function isTomorrow(d)
	return d == os.date('%Y-%m-%d', os.time() + 24*60*60)
end

local function isFuture(d)
	return not isAnytime(d) and not isTomorrow(d) and
		d > os.date('%Y-%m-%d')
end

local function isToday(d)
	return d == os.date('%Y-%m-%d')
end

local function isYesterday(d)
	return d == os.date('%Y-%m-%d', os.time() - 24*60*60)
end

local function isLate(d)
	return not isAnytime(d) and not isYesterday(d) and
		d < os.date('%Y-%m-%d')
end

local function daysMonth(month, year)
	while month > 12 do month = month - 12 end
	local function is_leap_year(year)
		return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
	end
	return month == 2 and is_leap_year(year) and 29
		or ('\31\28\31\30\31\30\31\31\30\31\30\31'):byte(month)
end

function getTasks(pattern, flags, tag)
	if not con then return nil, 'There is no open database' end
	local flags = flags or { }
	if flags.anytime   == nil then flags.anytime   = true end
	if flags.tomorrow  == nil then flags.tomorrow  = true end
	if flags.future    == nil then flags.future    = true end
	if flags.today     == nil then flags.today     = true end
	if flags.yesterday == nil then flags.yesterday = true end
	if flags.late      == nil then flags.late      = true end
	local cur, err = con:execute(
		'SELECT * FROM tasks ORDER BY name;')
	if not cur then return nil, err end
	local row = { }
	local result = { }
	while cur:fetch(row, 'a') do
		local a, b = pcall(string.match,
			row.name:upper(), pattern:upper())
		if ((isAnytime(row.date) and flags.anytime) or
			(isTomorrow(row.date) and flags.tomorrow) or
			(isFuture(row.date) and flags.future) or
			(isToday(row.date) and flags.today) or
			(isYesterday(row.date) and flags.yesterday) or
			(isLate(row.date) and flags.late)) and
			(not tag or (tag == -1 and hasNoTags(row.id)) or
			hasTag(row.id, tag)) and (a and b) then
				local copy = { }
				for k,v in pairs(row) do copy[k] = v end
				table.insert(result, copy)
		end
	end
	cur:close()
	return result
end

return {
	-- function open(dbname)
	-- open or create a database if not exists
	-- return: true or nil and an error message
	open = open,
	-- function close()
	-- close the database
	-- return: nothing
	close = close,
	-- function hasTable(table)
	-- check if database has the given table
	-- return: true or false (or nil and an error message)
	hasTable = hasTable,
	-- function hasId(id, table)
	-- check if the given id has in the given table
	-- return: true or false (or nil and an error message)
	hasId = hasId,
	-- function hasTag(task, tag)
	-- check if the given task has the given tag
	-- return: true or false (or nil and an error message)
	hasTag = hasTag,
	-- function hasNoTags(task)
	-- check if the given task has no tags
	-- return: true or false (or nil and an error message)
	hasNoTags = hasNoTags,
	-- function newTask(task)
	-- create a new task - task: table - must have task.name ~= nil
	-- return: 1 or nil and error message
	newTask = newTask,
	-- function newTag(name)
	-- create a new tag - name: string
	-- return: 1 or nil and error message
	newTag = newTag,
	-- function delTask(task, force)
	-- remove a task or go to next if it's recurrent
	-- (or force to remove a reccurrent task)
	-- return: 1 or nil and error message
	delTask = delTask,
	-- function delTag(tag)
	-- remove the tag from any task and remove the tag
	-- return: 1 or nil and error message
	delTag = delTag,
	-- function setOption(option, value)
	-- set the given database option
	-- return: 1 or nil and error message
	setOption = setOption,
	-- function setTag(task, tag)
	-- add to the given task the given tag
	-- return: 1 or nil and error message
	setTag = setTag,
	-- function clearTag(task, tag)
	-- remove from the given task the given tag
	-- return: 1 or nil and error message
	clearTag = clearTag,
	-- function getTask(task)
	-- return a table with the given task or nil
	getTask = getTask,
	-- function getTasks(pattern, flags, tag)
	-- return a table with the tasks that match the pattern, flags and tag
	getTasks = getTasks,
	-- function getTags()
	-- return a table with all tags
	-- function getTags(task)
	-- return a table with all the task's tags
	getTags = getTags,
	-- function getOptions()
	-- return a table with the database options
	getOptions = getOptions,
	-- function updTask(task)
	-- update (rename) the given task
	-- return: 1 or nil and error message
	updTask = updTask,
	-- function updTag(tag, newname)
	-- update (rename) the given tag
	-- return: 1 or nil and error message
	updTag = updTag,
	-- function goNext(task)
	-- put off a task till next date
	-- return: 1 or nil and error message
	goNext = goNext,
	-- function lastRow - return last_insert_rowid()
	lastRow = lastRow,
	-- function isDate(d) - return true if d is a valid
	isDate = isDate,
	-- function isAnytime(d) - return true if d is an unespecified time
	isAnytime = isAnytime,
	-- function isTomorrow(d) - return true if d is tomorrow
	isTomorrow = isTomorrow,
	-- function isFuture(d) - return true if d is in the future but not tomorrow
	isFuture = isFuture,
	-- function isToday(d) - return true if d is today
	isToday = isToday,
	-- function isYesterday(d) - return true if d is yesterday
	isYesterday = isYesterday,
	-- function isLate(d) - return true if d is in the past but not yesterday
	isLate = isLate,
	-- function daysMonth(month, year) - return the number of days in a month
	daysMonth = daysMonth,
}
