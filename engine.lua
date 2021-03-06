
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

local eng = { dateformat = "%Y-%m-%d" }

-- initialize variables and create a database if not exists
-- return: nothing
function eng.init(dbname)
	eng.env = assert(luasql.sqlite3())
	eng.con = assert(eng.env:connect('database/' .. dbname))

	eng.con:execute('BEGIN;')
	if not eng.has_table('tagnames') then
		eng.con:execute([[
			CREATE TABLE tagnames (
				id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
				name TEXT NOT NULL
			);]])
		for _, v in ipairs{
				'Dom', 'Seg', 'Ter', 'Qua',
				'Qui', 'Sex', 'Sáb'
			} do
			eng.con:execute(string.format(
				'INSERT INTO tagnames VALUES(NULL, %q);', v))
		end
		for i = 1, 31 do
			eng.con:execute(string.format(
				'INSERT INTO tagnames VALUES(NULL, "%02d");',
				i))
		end
	end

	if not eng.has_table('tags') then
		eng.con:execute([[
			CREATE TABLE tags (
				task INTEGER NOT NULL,
				tag INTEGER NOT NULL
			);]])
	end

	if not eng.has_table('tasks') then
		eng.con:execute([[
			CREATE TABLE tasks (
				id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
				name TEXT NOT NULL,
				date TEXT,
				comment TEXT,
				recurrent INTEGER NOT NULL
			);]])
	end

	if not eng.has_table('options') then
		eng.con:execute([[
			CREATE TABLE options (
				id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
				name TEXT NOT NULL,
				value TEXT
			);]])
		local optfmt = 'INSERT INTO options VALUES(NULL, %q, %q);'
		for _, v in ipairs{
				'anytime', 'tomorrow', 'future',
				'today', 'yesterday', 'late'
			} do
			eng.con:execute(string.format(optfmt, v, 'ON'))
		end
		eng.con:execute(string.format(optfmt, 'tag', '1'))
		eng.con:execute(string.format(optfmt, 'version', '1'))
	end
	eng.con:execute('END;')

end

-- close everything when done
-- return: nothing
function eng.done()
	eng.con:close()
	eng.env:close()
end

-- check if database has the given table
-- return: true or false
function eng.has_table(table)
	local cur = eng.con:execute(string.format(
		'SELECT * FROM sqlite_master WHERE type="table" AND name=%q;',
		table))
	local row = { }
	cur:fetch(row)
	cur:close()
	return row[1] ~= nil
end

-- check if the given id has in the given table
-- return: true or false
function eng.has_id(id, table)
	local cur = eng.con:execute(string.format(
		'SELECT * FROM %q WHERE id=%d;', table, id))
	if not cur then return false end
	local row = { }
	cur:fetch(row)
	cur:close()
	return row[1] ~= nil
end

-- check if the given task has the given tag
-- return: true or false
function eng.has_tag(task, tag)
	local cur = eng.con:execute(string.format(
		'SELECT * FROM tags WHERE task=%d and tag=%d;', task, tag))
	local row = { }
	cur:fetch(row)
	cur:close()
	return row[1] ~= nil
end

-- check if the given task has no tags
-- return: true or false
function eng.has_notags(task)
	local cur = eng.con:execute(string.format(
		'SELECT * FROM tags WHERE task=%d;', task))
	local row = { }
	while cur:fetch(row, 'a') do
		-- ignore the first 38 special tags
		if tonumber(row.tag) > 38 then
			cur:close()
			return false
		end
	end
	cur:close()
	return true
end

-- create a new task
-- return: 1 or nil and error message
function eng.new_task(task)
	if not task or task.name == nil then
		return nil, 'Engine: task has no name'
	end
	task.date = task.date or ''
	task.comment = task.comment or ''
	task.recurrent = task.recurrent or 1
	local cur, err = eng.con:execute(string.format(
		'INSERT INTO tasks VALUES(NULL, %q, %q, %q, %d);',
		task.name, task.date, task.comment, task.recurrent))
	if cur and task.tags then
		cur = eng.con:execute('SELECT last_insert_rowid();')
		local row = { }
		cur:fetch(row)
		cur:close()
		for _, v in ipairs(task.tags) do
			eng.set_tag(row[1], v)
		end
	end
	return cur, err
end

-- create a new tag
-- return: 1 or nil and error message
function eng.new_tag(name)
	local cur, err = eng.con:execute(string.format(
		'INSERT INTO tagnames VALUES(NULL, %q);', name))
	return cur, err
end

-- remove a task or go to next if it's recurrent
-- return: 1 or nil and error message
function eng.del_task(taskid, force)
	local task = eng.get_task(taskid)
	if task.recurrent == '1' or (task.recurrent ~= '1' and force) then
		local cur, err = eng.con:execute(string.format(
			'DELETE FROM tasks WHERE id=%d;', task.id))
		return cur, err
	else return eng.go_next(task.id) end
end

-- remove the tag from any task and remove the tag
-- return: 1 or nil and error message
function eng.del_tag(tag)
	if tonumber(tag) <= 38 then
		return nil, 'Engine: do not touch the first 38 special tags'
	end
	if not eng.has_id(tag, 'tagnames') then
		return nil, 'Engine: invalid tag'
	end
	local cur = eng.con:execute('SELECT id FROM tasks;')
	local row = { }
	while cur:fetch(row) do
		eng.con:execute(string.format(
			'DELETE FROM tags WHERE task=%d and tag=%d;',
			row[1], tag))
	end
	cur:close()
	local err ; cur, err = eng.con:execute(string.format(
		'DELETE FROM tagnames WHERE id=%d;', tag))
	return cur, err
end

-- add to the given task the given tag
-- return: 1 or nil and error message
function eng.set_tag(task, tag)
	if not eng.has_id(tag, 'tagnames') then
		return nil, 'Engine: invalid tag'
	end
	if not eng.has_tag(task, tag) then
		local cur, err = eng.con:execute(string.format(
			'INSERT INTO tags VALUES(%d, %d);', task, tag))
		return cur, err
	else
		return nil, 'Engine: already tagged'
	end
end

-- remove from the given task the given tag
-- return: 1 or nil and error message
function eng.clear_tag(task, tag)
	if not eng.has_tag(task, tag) then
		return nil, 'Engine: not tagged'
	end
	if not eng.has_id(tag, 'tagnames') then
		return nil, 'Engine: invalid tag'
	end
	local cur, err = eng.con:execute(string.format(
		'DELETE FROM tags WHERE task=%d and tag=%d;', task, tag))
	return cur, err
end

-- return a table with the tasks that match the pattern, flags and tag
function eng.gettasks(pattern, flags, tag)
	if type(flags) ~= 'table' then flags = { } end
	if flags.anytime   == nil then flags.anytime   = true end
	if flags.tomorrow  == nil then flags.tomorrow  = true end
	if flags.future    == nil then flags.future    = true end
	if flags.today     == nil then flags.today     = true end
	if flags.yesterday == nil then flags.yesterday = true end
	if flags.late      == nil then flags.late      = true end
	local cur = eng.con:execute(
		'SELECT * FROM tasks ORDER BY name;')
	local row = { }
	local result = { }
	while cur:fetch(row, 'a') do
		local a, b = pcall(string.match,
			row.name:upper(), pattern:upper())
		if ((eng.isanytime(row.date) and flags.anytime) or
			(eng.istomorrow(row.date) and flags.tomorrow) or
			(eng.isfuture(row.date) and flags.future) or
			(eng.istoday(row.date) and flags.today) or
			(eng.isyesterday(row.date) and flags.yesterday) or
			(eng.islate(row.date) and flags.late)) and
			(not tag or (tag == -1 and eng.has_notags(row.id)) or
			eng.has_tag(row.id, tag)) and (a and b) then
				local copy = { }
				for k,v in pairs(row) do copy[k] = v end
				copy.recurrent = tostring(copy.recurrent) -- it's a string number
				table.insert(result, copy)
		end
	end
	cur:close()
	return result
end

-- return a table with the given task or nil
function eng.get_task(task)
	if not eng.has_id(task, 'tasks') then
		return nil, 'Engine: no task'
	end
	local cur = eng.con:execute(string.format(
		'SELECT * FROM tasks WHERE id=%d;', task))
	local row = { }
	cur:fetch(row, 'a')
	cur:close()
	row.recurrent = tostring(row.recurrent) -- it's a string number
	return row
end

-- return a table with all tags or the task's tags
function eng.get_tags(task)
	local result = { }
	if not task then
		-- ignore the first 38 special tags
		local cur = eng.con:execute(
			'SELECT * FROM tagnames WHERE id > 38 ORDER BY name;')
		local row = { }
		while cur:fetch(row) do
			table.insert(result, {id = row[1], name = row[2]})
		end
		cur:close()
	else
		if not eng.has_id(task, 'tasks') then return nil end
		local cur = eng.con:execute(string.format([[
			SELECT tag, name FROM tags
			JOIN tagnames ON tag=id WHERE task=%d
			ORDER BY name;]], task))
		local row = { }
		while cur:fetch(row) do
			result[tonumber(row[1])] = row[2]
		end
		cur:close()
	end
	return result
end

-- update (rename) the given task
-- return: 1 or nil and error message
function eng.upd_task(task)
	local upd_str = ''
	for k, v in pairs(task) do
		if k ~= 'id' then
			if upd_str ~= '' then
				upd_str = upd_str .. ','
			end
			upd_str = string.format('%s %s=%q', upd_str, k, v)
		end
	end
	local cur, err = eng.con:execute(string.format(
		'UPDATE tasks SET %s WHERE id=%d;', upd_str, task.id))
	return cur, err
end

-- update (rename) the given tag
-- return: 1 or nil and error message
function eng.upd_tag(tag, newname)
	if tonumber(tag) <= 38 then
		return nil, 'Engine: do not touch the first 38 special tags'
	end
	local cur, err = eng.con:execute(string.format(
		'UPDATE tagnames SET name=%q WHERE id=%d;', newname, tag))
	return cur, err
end

-- put off till next date what should be done today
-- return: 1 or nil and error message
function eng.go_next(taskid)
	local task = eng.get_task(taskid)
	local tags = eng.get_tags(task.id)
	if eng.isanytime(task.date) then
		task.date = os.date(eng.dateformat)
	end
	local d = { }
	d.year, d.month, d.day = task.date:match('(%d%d%d%d)-(%d%d)-(%d%d)')
	d = os.date('*t', os.time(d))
	if task.recurrent == '2' then
		-- next date this week
		for i = d.wday + 1, 7 do
			if tags[i] then
				d.day = d.day + (i - d.wday)
				local cur, err = eng.con:execute(string.format(
					'UPDATE tasks SET date=%q WHERE id=%d;',
					os.date(eng.dateformat, os.time(d)),
					task.id))
				return cur, err
			end
		end
		-- next date next week
		for i = 1, 7 do
			if tags[i] then
				d.day = d.day + (7 - d.wday + i)
				local cur, err = eng.con:execute(string.format(
					'UPDATE tasks SET date=%q WHERE id=%d;',
					os.date(eng.dateformat, os.time(d)),
					task.id))
				return cur, err
			end
		end
	elseif task.recurrent == '3' then
		-- next date this month
		for i = d.day + 1, 31 do
			if tags[i + 7] then
				d.day = i
				local cur, err = eng.con:execute(string.format(
					'UPDATE tasks SET date=%q WHERE id=%d;',
					os.date(eng.dateformat, os.time(d)),
					task.id))
				return cur, err
			end
		end
		-- next date next month
		for i = 1, 31 do
			if tags[i + 7] then
				d.day = i
				d.month = d.month + 1
				local cur, err = eng.con:execute(string.format(
					'UPDATE tasks SET date=%q WHERE id=%d;',
					os.date(eng.dateformat, os.time(d)),
					task.id))
				return cur, err
			end
		end
		return nil, 'Engine: no suitable date, check task consistency'
	elseif task.recurrent == '4' then
		local i = eng.daysmonth(d.month, d.year)
		if d.day == i then
			d.month = d.month + 1
			d.day = eng.daysmonth(d.month, d.year)
		else d.day = i end
		local cur, err = eng.con:execute(string.format(
			'UPDATE tasks SET date=%q WHERE id=%d;',
			os.date(eng.dateformat, os.time(d)),
			task.id))
		return cur, err
	elseif task.recurrent == '1' then
		d.day = d.day + 1
		local cur, err = eng.con:execute(string.format(
			'UPDATE tasks SET date=%q WHERE id=%d;',
			os.date(eng.dateformat, os.time(d)),
			task.id))
		return cur, err
	end
	return nil, 'Engine: should never happens'
end

-- return true if d is a valid date else return nil or false
function eng.isdate(d)
	local t = { }
	t.year, t.month, t.day = d:match('(%d%d%d%d)-(%d%d)-(%d%d)')
	return t.year and t.month and t.day and
		os.date(eng.dateformat, os.time(t)) == d
end

-- return true if d is an unespecified time
function eng.isanytime(d)
	return not d or d == '' or d == 'anytime'
end

-- return true if d is tomorrow
function eng.istomorrow(d)
	return d == os.date(eng.dateformat, os.time() + 24*60*60)
end

-- return true if d is in the future but not tomorrow
function eng.isfuture(d)
	return not eng.isanytime(d) and not eng.istomorrow(d) and
		d > os.date(eng.dateformat)
end

-- return true if d is today
function eng.istoday(d)
	return d == os.date(eng.dateformat)
end

-- return true if d is yesterday
function eng.isyesterday(d)
	return d == os.date(eng.dateformat, os.time() - 24*60*60)
end

-- return true if d is in the past but not yesterday
function eng.islate(d)
	return not eng.isanytime(d) and not eng.isyesterday(d) and
		d < os.date(eng.dateformat)
end

-- return the number of days in a month
function eng.daysmonth(month, year)
	while month > 12 do month = month - 12 end
	return month == 2 and (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) and 29
		or ('\31\28\31\30\31\30\31\31\30\31\30\31'):byte(month)
end

function eng.get_options()
	local cur, err = eng.con:execute('SELECT value FROM options;')
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

function eng.set_option(option, value)
	local cur, err = eng.con:execute(string.format(
		'UPDATE options SET value=%q WHERE name=%q;',
		 value, option))
	return cur, err
end

function eng.last_row()
	local cur, err = eng.con:execute('SELECT last_insert_rowid();')
	if not cur then return nil, err end
	local row = { }
	cur:fetch(row)
	cur:close()
	return row[1]
end

function eng.Begin()
	eng.con:execute('BEGIN;')
end

function eng.End()
	eng.con:execute('END;')
end

return eng
