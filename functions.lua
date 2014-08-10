
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
	local cur = eng.con:execute('SELECT value FROM options;')
	local row = { }
	cur:fetch(row) gui.anytime.value   = row[1]
	cur:fetch(row) gui.tomorrow.value  = row[1]
	cur:fetch(row) gui.future.value    = row[1]
	cur:fetch(row) gui.today.value     = row[1]
	cur:fetch(row) gui.yesterday.value = row[1]
	cur:fetch(row) gui.late.value      = row[1]
	cur:fetch(row) gui.taglist.value   = row[1]
	cur:close()
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
	for file in lfs.dir(".") do
		if file:sub(-7, -1) == ".sqlite" then
			table.insert(fun.dblist, file)
			gui.dbname.appenditem = file:sub(1, -8)
		end
	end
	if #fun.dblist == 0 then
		eng.init('atarefado.sqlite')
		eng.done()
		fun.db_load()
	else
		gui.dbname.lastvalue = value
		gui.dbname.value = value
	end
end

fun.load_timer.action_cb = fun.task_load
