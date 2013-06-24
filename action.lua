
function gui.question(message)
	local dlg = iup.messagedlg{
		title      = "Confirmar",
		value      = message,
		buttons    = "YESNO",
		dialogtype = "QUESTION"
	}
	dlg:popup()
	return tonumber(dlg.buttonresponse)
end

function gui.dialog:close_cb()
	if gui.question("Sair do Atarefado?") == 1 then
		self:hide()
		eng.done()
	else
		gui.result.value = nil
		iup.SetFocus(gui.search)
		return iup.IGNORE
	end
end

function gui.dialog:k_any(k)
	if k == iup.K_ESC then
		if gui.zbox.value == gui.new_tag then
			gui.new_cancel:action()
		elseif gui.zbox.value == gui.edit_tag then
			gui.edit_cancel:action()
		elseif gui.zbox.value == gui.task_box then
			gui.task_cancel:action()
		else
			self:close_cb()
		end
	elseif (k == iup.K_cC or iup.K_cc) and iup.GetFocus() == gui.result then
		if gui.result.value ~= nil and gui.result.value ~= "0" then
			for k,v in pairs(gui.task_table[tonumber(gui.result.value)]) do
				print(k, v)
			end
			io.stdout:flush()
		end
	elseif k == iup.K_CR then
		if iup.GetFocus() == gui.search then
			if gui.zbox.value == gui.new_tag then
				gui.new_ok:action()
			elseif gui.zbox.value == gui.edit_tag then
				gui.edit_ok:action()
			elseif gui.zbox.value == gui.task_box then
				gui.task_ok:action()
			elseif gui.zbox.value == gui.result_box then
				gui.task_new:action()
			end
		elseif iup.GetFocus() == gui.task_date then
			gui.task_ok:action()
		elseif gui.result.value ~= nil and gui.result.value ~= "0" then
			gui.result:dblclick_cb()
		end
	elseif k == iup.K_DEL then
		gui.task_delete:action()
	elseif k == iup.K_DOWN and iup.GetFocus() == gui.search then
		iup.SetFocus(gui.result)
		gui.result.value = "1"
		gui.result:valuechanged_cb()
	elseif k == iup.K_UP and iup.GetFocus() == gui.result and gui.result.value == "1" then
		iup.SetFocus(gui.search)
		gui.result.value = nil
		gui.result.lastvalue = nil
		gui.result:valuechanged_cb()
		return iup.IGNORE
	elseif k == iup.K_F2 then
		gui.task_today:action()
	elseif k == iup.K_F3 then
		gui.task_tomorrow:action()
	elseif k == iup.K_F4 then
		gui.task_anytime:action()
	elseif k == iup.K_F5 then
		gui.db_load()
		if gui.taglist.value == "0" or gui.taglist.value == nil then gui.taglist.value = "1" end
		gui.tag_load()
		gui.opt_load()
		gui.task_load()
	elseif k == iup.K_F10 and gui.zbox.value == gui.result_box then
		gui.new_button:action()
		return iup.IGNORE
	elseif k == iup.K_F11 then
		gui.edit_button:action()
	elseif k == iup.K_F12 then
		gui.del_button:action()
	end
end

function gui.opt_load()
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

gui.task_table = { }
gui.tag_table = { }

function gui.tag_load()
	local id    = 0
	local value = tonumber(gui.taglist.value)
	if gui.tag_table and gui.tag_table[value] then
		id = gui.tag_table[tonumber(gui.taglist.value)].id
	end
	gui.tag_table = { }
	gui.tag_table.id = { }
	gui.taglist.removeitem = "ALL"
	gui.task_tag.removeitem = "ALL"
	table.insert(gui.tag_table, false)
	table.insert(gui.tag_table, false)
	gui.taglist.appenditem = "Todas"
	gui.taglist.appenditem = "Nenhuma"
	for i,v in ipairs(eng.get_tags()) do
		table.insert(gui.tag_table, v)
		gui.tag_table.id[v.id] = #gui.tag_table
		gui.taglist.appenditem = v.name
		gui.task_tag.appenditem = v.name
	end
	gui.taglist.value = gui.tag_table.id[id]
end

function gui.task_load()
	local value = tonumber(gui.result.value)
	local flags = { }
	local tag   = false
	local i     = tonumber(gui.taglist.value) or 1
	if gui.task_table and gui.task_table[value] then
		gui.result.lastid = gui.task_table[value].id
	else
		gui.result.lastid = 0
	end
	gui.result.itemcount = 0
	gui.task_table = { }
	gui.task_table.id = { }
	gui.result.removeitem = "ALL"
	flags.anytime = gui.anytime.value == "ON"
	flags.tomorrow = gui.tomorrow.value == "ON"
	flags.future = gui.future.value == "ON"
	flags.today = gui.today.value == "ON"
	flags.yesterday = gui.yesterday.value == "ON"
	flags.late = gui.late.value == "ON"
	if i == 2 then tag = -1 elseif i > 2 then tag = gui.tag_table[i].id end
	gui.result.removeitem = "ALL"
	for _,v in ipairs(eng.gettasks(gui.search.value, flags, tag)) do
		table.insert(gui.task_table, v)
		gui.task_table.id[v.id] = #gui.task_table
	end
	gui.load_timer.run = "NO"
	iup.SetIdle(gui.item_load)
end

function gui.item_load()
	local n = gui.result.itemcount + 1
	local v = gui.task_table[n]
	if v then
		gui.result.appenditem = v.name
		if eng.isanytime(v.date) then
			gui.result["image" .. n] = gui.green
		elseif eng.istomorrow(v.date) then
			gui.result["image" .. n] = gui.blue
		elseif eng.isfuture(v.date) then
			gui.result["image" .. n] = gui.black
		elseif eng.istoday(v.date) then
			gui.result["image" .. n] = gui.orange
		elseif eng.isyesterday(v.date) then
			gui.result["image" .. n] = gui.purple
		elseif eng.islate(v.date) then
			gui.result["image" .. n] = gui.red
		end
		gui.result.itemcount = n
	else
		local value = gui.task_table.id[gui.result.lastid]
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

gui.load_timer = iup.timer{
	time      = 500,
	run       = "NO",
	action_cb = gui.task_load
}

function gui.search:valuechanged_cb()
	if gui.zbox.value == gui.result_box then
		gui.load_timer.run  = "NO"
		gui.load_timer.run  = "YES"
	end
end

function gui.new_button:action()
	gui.optbox.active      = "NO"
	gui.new_button.active  = "NO"
	gui.edit_button.active = "NO"
	gui.del_button.active  = "NO"
	gui.zbox.value = gui.new_tag
	gui.search.value = ""
	iup.SetFocus(gui.search)
end

function gui.new_ok:action()
	eng.new_tag(gui.search.value)
	local cur = eng.con:execute('SELECT last_insert_rowid();')
	local row = { }
	cur:fetch(row)
	cur:close()
	gui.tag_load()
	gui.new_cancel:action()
	gui.taglist.value = gui.tag_table.id[row[1]]
	gui.task_load()
end

function gui.new_cancel:action()
	gui.search.value      = ""
	gui.optbox.active     = "YES"
	gui.new_button.active = "YES"
	if gui.taglist.value ~= nil and tonumber(gui.taglist.value) >= 3 then
		gui.edit_button.active = "YES"
		gui.del_button.active  = "YES"
	end
	gui.zbox.value = gui.result_box
	iup.SetFocus(gui.search)
end

function gui.edit_button:action()
	gui.optbox.active      = "NO"
	gui.new_button.active  = "NO"
	gui.edit_button.active = "NO"
	gui.del_button.active  = "NO"
	gui.zbox.value = gui.edit_tag
	gui.search.value = gui.tag_table[tonumber(gui.taglist.value)].name
	iup.SetFocus(gui.search)
end

gui.taglist.dblclick_cb = gui.edit_button.action

function gui.edit_ok:action()
	eng.upd_tag(gui.tag_table[tonumber(gui.taglist.value)].id, gui.search.value)
	gui.tag_load()
	gui.edit_cancel:action()
end

function gui.edit_cancel:action()
	gui.search.value      = ""
	gui.optbox.active     = "YES"
	gui.new_button.active = "YES"
	if tonumber(gui.taglist.value) >= 3 then
		gui.edit_button.active = "YES"
		gui.del_button.active  = "YES"
	end
	gui.zbox.value = gui.result_box
	iup.SetFocus(gui.taglist)
end

function gui.del_button:action()
	local i = tonumber(gui.taglist.value)
	if i >= 3 and gui.question("Excluir tag?") == 1 then
		eng.del_tag(gui.tag_table[i].id)
		gui.tag_load()
		iup.SetFocus(gui.search)
	end
end

function gui.task_ok:action()
	if gui.search.value:match("^%s*$") then return end
	local upd = { }
	if gui.result.value ~= nil and gui.result.value ~= "0" then
		upd.id = gui.task_table[tonumber(gui.result.value)].id
	end
	upd.name = gui.search.value
	upd.date = gui.task_date.value
	upd.comment = gui.task_comment.value
	upd.recurrent = gui.task_recurrent.value
	eng.con:execute('BEGIN;')
	if upd.id then
		eng.upd_task(upd)
	else
		eng.new_task(upd)
		local cur = eng.con:execute('SELECT last_insert_rowid();')
		local row = { }
		cur:fetch(row)
		cur:close()
		upd.id = row[1]
	end
	for i = 1, #gui.task_tag.value do
		local n = gui.task_tag.value:byte(i)
		if n == 43 then
			eng.set_tag(upd.id, gui.tag_table[i+2].id)
		elseif n == 45 then
			eng.clear_tag(upd.id, gui.tag_table[i+2].id)
		end
	end
	for i = 1, 7 do
		local n = gui.task_tagw.value:byte(i)
		if n == 43 then
			eng.set_tag(upd.id, i)
		elseif n == 45 then
			eng.clear_tag(upd.id, i)
		end
	end
	for i = 1, 31 do
		local n = gui.task_tagm.value:byte(i)
		if n == 43 then
			eng.set_tag(upd.id, i+7)
		elseif n == 45 then
			eng.clear_tag(upd.id, i+7)
		end
	end
	eng.con:execute('END;')
	gui.task_cancel:action()
	gui.task_load()
end

function gui.task_cancel:action()
	gui.search.value      = ""
	gui.optbox.active     = "YES"
	gui.new_button.active = "YES"
	if tonumber(gui.taglist.value) >= 3 then
		gui.edit_button.active = "YES"
		gui.del_button.active  = "YES"
	end
	gui.zbox.value = gui.result_box
	if gui.result.value == "0" or gui.result.value == nil then
		iup.SetFocus(gui.search)
	else
		-- corrigir result.value
		iup.SetFocus(gui.result)
	end
end

function gui.taglist:valuechanged_cb()
	if self.value ~= nil and self.lastvalue ~= self.value then
		eng.con:execute(string.format(
			'UPDATE options SET value=%q WHERE name="tag";', self.value, self.name))
		self.lastvalue = self.value
		local i = tonumber(self.value)
		if i >= 3 then
			gui.edit_button.active = "YES"
			gui.del_button.active  = "YES"
		else
			gui.edit_button.active = "NO"
			gui.del_button.active  = "NO"
		end
		gui.task_load()
	end
end

function gui.result:dblclick_cb()
	local item
	if gui.result.value == "0" or gui.result.value == nil then
		item = { name = gui.search.value, date = "", comment = "", recurrent = "1" }
		local value = ""
		if tonumber(gui.taglist.value) > 2 then
			for i = 3, #gui.tag_table do
				if i == tonumber(gui.taglist.value) then
					value = value .. "+"
				else
					value = value .. "-"
				end
			end
		end
		gui.task_tag.value = value
	else
		item = gui.task_table[tonumber(gui.result.value)]
		gui.search.value = item.name
		local tagt = eng.get_tags(item.id)
		local tagv = ""
		for i,v in ipairs(gui.tag_table) do
			if v then
				if tagt[tonumber(v.id)] then
					tagv = tagv .. "+"
				else
					tagv = tagv .. "-"
				end
			end
		end
		gui.task_tag.value = tagv
		tagv = ""
		for i = 1, 7 do
			if tagt[i] then
				tagv = tagv .. "+"
			else
				tagv = tagv .. "-"
			end
		end
		gui.task_tagw.value = tagv
		tagv = ""
		for i = 1, 31 do
			if tagt[i+7] then
				tagv = tagv .. "+"
			else
				tagv = tagv .. "-"
			end
		end
		gui.task_tagm.value = tagv
	end
	gui.optbox.active      = "NO"
	gui.new_button.active  = "NO"
	gui.edit_button.active = "NO"
	gui.del_button.active  = "NO"
	gui.zbox.value = gui.task_box
	gui.task_date.value = item.date
	gui.task_comment.value = loadstring(string.format('return "%s"', item.comment))()
	gui.task_recurrent.value = item.recurrent or "1"
	gui.task_zoption.valuepos = gui.task_recurrent.value - 1
	iup.SetFocus(gui.search)
end

function gui.task_recurrent:valuechanged_cb()
	gui.task_zoption.valuepos = self.value - 1
end

function gui.result:valuechanged_cb()
	if self.value == "0" or self.value == nil then
		gui.task_edit.active = "NO"
		gui.task_delete.active = "NO"
		gui.task_today.active = "NO"
		gui.task_tomorrow.active = "NO"
		gui.task_anytime.active = "NO"
		gui.task_recurrency.active = "NO"
	else
		gui.task_edit.active = "YES"
		gui.task_delete.active = "YES"
		gui.task_today.active = "YES"
		gui.task_tomorrow.active = "YES"
		gui.task_anytime.active = "YES"
	end
	if self.value and self.value ~= "0" then
		self.lastvalue = self.value
		if gui.task_table[tonumber(self.value)].recurrent == "1" then
			gui.task_recurrency.active = "NO"
		else
			gui.task_recurrency.active = "YES"
		end
	end
	
end

function gui.task_new:action()
	gui.result.value = nil
	gui.result:dblclick_cb()
end

gui.task_edit.action = gui.result.dblclick_cb

function gui.task_delete:action()
	if gui.result.value ~= nil and gui.result.value ~= "0" then
		local task = gui.task_table[tonumber(gui.result.value)]
		if gui.question("Excluir tarefa?") == 1 then
			eng.del_task(task.id)
			gui.task_load()
		end
	end
end

function gui.task_today:action()
	if gui.zbox.value == gui.result_box and (gui.result.value ~= nil and gui.result.value ~= "0") then
		upd = { }
		upd.id = gui.task_table[tonumber(gui.result.value)].id
		upd.date = os.date('%Y-%m-%d')
		eng.upd_task(upd)
		gui.task_load()
		iup.SetFocus(gui.result)
	elseif gui.zbox.value == gui.task_box then
		gui.task_date.value = os.date('%Y-%m-%d')
	end
end

function gui.task_tomorrow:action()
	if gui.zbox.value == gui.result_box and (gui.result.value ~= nil and gui.result.value ~= "0") then
		upd = { }
		upd.id = gui.task_table[tonumber(gui.result.value)].id
		upd.date = os.date('%Y-%m-%d', os.time()+24*60*60)
		eng.upd_task(upd)
		gui.task_load()
		iup.SetFocus(gui.result)
	elseif gui.zbox.value == gui.task_box then
		gui.task_date.value = os.date('%Y-%m-%d', os.time()+24*60*60)
	end
end

function gui.task_anytime:action()
	if gui.zbox.value == gui.result_box and (gui.result.value ~= nil and gui.result.value ~= "0") then
		upd = { }
		upd.id = gui.task_table[tonumber(gui.result.value)].id
		upd.date = ""
		eng.upd_task(upd)
		gui.task_load()
		iup.SetFocus(gui.result)
	elseif gui.zbox.value == gui.task_box then
		gui.task_date.value = ""
	end
end

gui.dblist = { }

function gui.db_load()
	local value = gui.dbname.value
	if value == "0" then value = "1" end
	gui.dblist = { }
	gui.dbname.removeitem = "ALL"
	for file in lfs.dir(".") do
		if file:sub(-7, -1) == ".sqlite" then
			table.insert(gui.dblist, file)
			gui.dbname.appenditem = file:sub(1, -8)
		end
	end
	if #gui.dblist == 0 then
		eng.init('atarefado.sqlite')
		eng.done()
		gui.db_load()
	else
		gui.dbname.lastvalue = value
		gui.dbname.value = value
	end
end

function gui.dbname:valuechanged_cb()
	if gui.dbname.value ~= nil and gui.dbname.value ~= "0" and gui.dbname.lastvalue ~= gui.dbname.value then
		gui.dbname.lastvalue = gui.dbname.value
		eng.done()
		eng.init(gui.dblist[tonumber(gui.dbname.value)])
		gui.tag_load()
		gui.opt_load()
		gui.task_load()
	end
end
