
fun = { }

fun.clipboard = iup.clipboard{}
fun.task_table = { }
fun.tag_table = { }
fun.dblist = { }

fun.load_timer = iup.timer{
	time      = 500,
	run       = "NO",
}

function fun.question(message)
	local dlg = iup.messagedlg{
		title      = "Confirmar",
		value      = message,
		buttons    = "YESNO",
		dialogtype = "QUESTION"
	}
	dlg:popup()
	return dlg.buttonresponse
end

function fun.opt_load()
	local options = eng.get_options()
	gui.anytime.value     = options.anytime
	gui.tomorrow.value    = options.tomorrow
	gui.future.value      = options.future
	gui.today.value       = options.today
	gui.yesterday.value   = options.yesterday
	gui.late.value        = options.late
	gui.taglist.value     = options.tag
	gui.taglist.lastvalue = options.tag
	if gui.taglist.value == nil or gui.taglist.value == "0" then
		gui.taglist.value = "1"
	end
	if tonumber(gui.taglist.value) >= 3 then
		gui.edit_button.active = "YES"
		gui.del_button.active = "YES"
	end
end

function fun.tag_load()
	local id    = 0
	local value = tonumber(gui.taglist.value)
	if fun.tag_table and fun.tag_table[value] then
		id = fun.tag_table[value].id
	end
	fun.tag_table = { }
	fun.tag_table.id = { }
	gui.taglist.removeitem = "ALL"
	gui.task_tag.removeitem = "ALL"
	table.insert(fun.tag_table, false)
	table.insert(fun.tag_table, false)
	gui.taglist.appenditem = "Todas"
	gui.taglist.appenditem = "Nenhuma"
	for i,v in ipairs(eng.get_tags()) do
		table.insert(fun.tag_table, v)
		fun.tag_table.id[v.id] = #fun.tag_table
		gui.taglist.appenditem = v.name
		gui.task_tag.appenditem = v.name
	end
	gui.taglist.value = fun.tag_table.id[id]
end

function fun.task_load()
	local value = tonumber(gui.result.value)
	local flags = { }
	local tag   = false
	local i     = tonumber(gui.taglist.value) or 1
	if fun.task_table and fun.task_table[value] then
		gui.result.lastid = fun.task_table[value].id
	else
		gui.result.lastid = 0
	end
	gui.result.itemcount = 0
	fun.task_table = { }
	fun.task_table.id = { }
	gui.result.removeitem = "ALL"
	flags.anytime = gui.anytime.value == "ON"
	flags.tomorrow = gui.tomorrow.value == "ON"
	flags.future = gui.future.value == "ON"
	flags.today = gui.today.value == "ON"
	flags.yesterday = gui.yesterday.value == "ON"
	flags.late = gui.late.value == "ON"
	if i == 2 then tag = -1 elseif i > 2 then tag = fun.tag_table[i].id end
	gui.result.removeitem = "ALL"
	for _,v in ipairs(eng.gettasks(gui.search.value, flags, tag)) do
		table.insert(fun.task_table, v)
		fun.task_table.id[v.id] = #fun.task_table
	end
	gui.count.title = "\n" .. #fun.task_table
	fun.load_timer.run = "NO"
	iup.SetIdle(fun.item_load)
end

function fun.item_load()
	local n = gui.result.itemcount + 1
	local v = fun.task_table[n]
	if v then
		gui.result.appenditem = v.name
		if eng.isanytime(v.date) then
			gui.result["image" .. n] = ico.green
		elseif eng.istomorrow(v.date) then
			gui.result["image" .. n] = ico.blue
		elseif eng.isfuture(v.date) then
			gui.result["image" .. n] = ico.black
		elseif eng.istoday(v.date) then
			gui.result["image" .. n] = ico.orange
		elseif eng.isyesterday(v.date) then
			gui.result["image" .. n] = ico.purple
		elseif eng.islate(v.date) then
			gui.result["image" .. n] = ico.red
		end
		gui.result.itemcount = n
	else
		local value = fun.task_table.id[gui.result.lastid]
		if value == nil then value = gui.result.lastvalue end
		if value and tonumber(value) > tonumber(gui.result.count) then
			value = gui.result.count
		end
		gui.result.itemcount = 0
		gui.result.value = value
		iup.SetIdle(nil)
		gui.result:valuechanged_cb()
	end
end

function fun.db_load()
	local value = gui.dbname.value
	if value == "0" then value = "1" end
	fun.dblist = { }
	gui.dbname.removeitem = "ALL"
	for file in lfs.dir("database") do
		if file:sub(-7, -1) == ".sqlite" then
			table.insert(fun.dblist, file)
		end
	end
	if #fun.dblist == 0 then
		eng.init('atarefado.sqlite')
		eng.done()
		fun.db_load()
	else
		table.sort(fun.dblist)
		for i, v in ipairs(fun.dblist) do
			gui.dbname.appenditem = v:sub(1, -8)
		end
		gui.dbname.lastvalue = value
		gui.dbname.value = value
	end
end

function fun.cut()
	if not fun.copy() then return false end
	eng.del_task(fun.task_table[tonumber(gui.result.value)].id, true)
	fun.task_load()
	return true
end

function fun.copy()
	if gui.result.value == nil or gui.result.value == "0" then
		return false
	end
	local fmt = [[
eng.new_task{
	name = %q,
	date = %q,
	comment = %q,
	recurrent = %q,
	tags = {%s %%s }
}
]]
	local item = fun.task_table[tonumber(gui.result.value)]
	local tags = eng.get_tags(item.id)
	local buff = ""
	for i = 1,38 do
		if tags[i] then
			buff = string.format("%s %d,", buff, i)
		end
	end
	fun.clipboard.text = nil
	fun.clipboard.text = string.format(fmt, item.name, item.date,
		item.comment, item.recurrent, buff)
	return true
end

function fun.canpaste()
	local fmt = [[
eng%.new_task{
	name = .*,
	date = .*,
	comment = .*,
	recurrent =.*,
	tags = {.* %%s }
}
]]
	return fun.clipboard.text and fun.clipboard.text:match(fmt)
end

function fun.paste()
	if not fun.canpaste() then return false end
	local s = ""
	local n = tonumber(gui.taglist.value)
	if n > 2 then s = tostring(fun.tag_table[n].id) end
	loadstring(string.format(fun.clipboard.text, s))()
	fun.task_load()
	return true
end

function fun.reload()
	if gui.zbox.value ~= gui.result_box then return end
	fun.db_load()
	if gui.taglist.value == "0" or gui.taglist.value == nil then
		gui.taglist.value = "1"
	end
	fun.tag_load()
	fun.opt_load()
	fun.task_load()
end

function fun.iupnames(elem, dest)
	if type(elem) == "userdata" then
		if elem.name ~= "" and elem.name ~= nil then
			dest[elem.name] = elem
		end
	end
	local i = 1
	while elem[i] do
		fun.iupnames(elem[i], dest)
		i = i + 1
	end
end

function fun.priup(inc)
	inc = inc or 1
	if not gui.result.value or gui.result.value == "0" then return end
	local item = fun.task_table[tonumber(gui.result.value)]
	local num = tonumber(item.name:match("^(%d%d) ?%- ?"))
	if num and num <= inc then return end
	if num == nil then
		item.name = string.format("%02d - %s", inc, item.name)
	else
		if num > 1 then num = num - inc end
		item.name = item.name:gsub("^%d%d ?%- ?",
			string.format("%02d - ", num))
	end
	eng.upd_task{id=item.id, name=item.name}
	fun.task_load()
end

function fun.pridown(inc)
	inc = inc or 1
	if not gui.result.value or gui.result.value == "0" then return end
	local item = fun.task_table[tonumber(gui.result.value)]
	local num = tonumber(item.name:match("^(%d%d) ?%- ?"))
	if num and num >= 100 - inc then return end
	if num == nil then
		item.name = string.format("%02d - %s", 100 - inc, item.name)
	else
		if num < 99 then num = num + inc end
		item.name = item.name:gsub("^%d%d ?%- ?",
			string.format("%02d - ", num))
	end
	eng.upd_task{id=item.id, name=item.name}
	fun.task_load()
end

fun.iupnames(gui.dialog, gui)
fun.iupnames(gui.result_menu, gui)
fun.iupnames(gui.taglist_menu, gui)

fun.load_timer.action_cb = fun.task_load
