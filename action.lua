
gui.clipboard = iup.clipboard{}

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
	elseif (k == 805306435 --[[iup.K_cC]] or k == 536870979 --[[iup.K_cc]]) and iup.GetFocus() == gui.result then
		if gui.result.value ~= nil and gui.result.value ~= "0" then
			local item = gui.task_table[tonumber(gui.result.value)]
			local tags = eng.get_tags(item.id)
			local buff = ""
			for i = 1,38 do
				if tags[i] then
					buff = string.format("%s %d,", buff, i)
				end
			end
			gui.clipboard.text = nil
			gui.clipboard.text = string.format([[
eng.new_task{
	name = %q,
	date = %q,
	comment = %q,
	recurrent = %q,
	tags = {%s }
}
]], item.name, item.date, item.comment, item.recurrent, buff)
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
		elseif gui.zbox.value == gui.result_box and gui.result.value ~= nil and gui.result.value ~= "0" then
			gui.result:dblclick_cb()
		end
	elseif k == iup.K_DEL and iup.GetFocus() ~= gui.search and gui.zbox.value == gui.result_box then
		gui.task_delete:action()
	elseif k == 268500991 --[[iup.K_sDEL]] and iup.GetFocus() ~= gui.search and gui.zbox.value == gui.result_box then
		gui.task_delete:action(true)
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
		gui.task_delete.image = gui.note_delete
		gui.task_delete.tip = "Excluir Tarefa (DEL)"
		gui.task_today.active = "NO"
		gui.task_tomorrow.active = "NO"
		gui.task_anytime.active = "NO"
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
			gui.task_delete.image = gui.note_delete
			gui.task_delete.tip = "Excluir Tarefa (DEL)"
		else
			gui.task_delete.image = gui.note_go
			gui.task_delete.tip = "Concluir Tarefa (DEL)"
		end
	end
	
end

function gui.task_new:action()
	gui.result.value = nil
	gui.result:dblclick_cb()
end

gui.task_edit.action = gui.result.dblclick_cb

function gui.task_delete:action(force)
	if gui.result.value ~= nil and gui.result.value ~= "0" then
		local task = gui.task_table[tonumber(gui.result.value)]
		local question = "Excluir tarefa?"
		if task.recurrent ~= "1" then
			if force then
				question = "Excluir permanentemente tarefa recorrente?"
			else
				question = "Tarefa concluída?"
			end
		end
		if gui.question(question) == 1 then
			eng.del_task(task.id, force)
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

function gui.savedlg:file_cb(file_name, status)
	if status == "OK" and not file_name:match("%.[^\\/]+$") then
		gui.savedlg.file = file_name:match("[\\/]([^\\/.]+)%.?$") .. ".html"
		return iup.CONTINUE
	end
end

function gui.savehtml:action()
	gui.savedlg:popup()
	if gui.savedlg.status ~= "-1" then
		local htmlfile = io.open(gui.savedlg.value, "w")
		if htmlfile then
			local filter = ""
			if gui.anytime.value == "ON" then
				filter = "<li class='green' style='float: left; padding-right:32px;'>Qualquer dia</li>"
			end
			if gui.tomorrow.value == "ON" then
				filter = filter .. "<li class='blue' style='float: left; padding-right:32px;'>Amanhã</li>"
			end
			if gui.future.value == "ON" then
				filter = filter .. "<li class='black' style='float: left; padding-right:32px;'>Futuras</li>"
			end
			if gui.today.value == "ON" then
				filter = filter .. "<li class='orange' style='float: left; padding-right:32px;'>Hoje</li>"
			end
			if gui.yesterday.value == "ON" then
				filter = filter .. "<li class='purple' style='float: left; padding-right:32px;'>Ontem</li>"
			end
			if gui.late.value == "ON" then
				filter = filter .. "<li class='red' style='float: left; padding-right:32px;'>Vencidas</li>"
			end
			htmlfile:write(string.format([[
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<title>Atarefado - %s</title>
		<style>
			li.black {list-style-image:url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB94HGgIMG0ww7poAAAJiSURBVDjLpZOxT1NRGMV/97373n0vfSDB1kVSEaMyKFgSwoAmTjiAJqyS0MVE/wXjrKyMmOgACW5dVAbTkDiYgAxUHChJFShJ0wq1BdrSQnnvOUgJGnDxS+7w3XO/8yXn3CN83+d/Svzdj4w87JPSGBNC3D0J+L7/8fCw/nR6+s1nwD+NQI9GRyccp/lRJHKLcPgSplIAHOzvs7GRJpH4Qrm8+2pycuoJ4J4kkNHoaKz1fPDB/cEhUt9XWVpaIp/PAxAMBunu7ubqlQ7ezbyn8DP/enJy6jHg6oAYHh6+EwqFxgYHh/gQnyWZTOK6LkopTNOkXq+TTqfJ5ja5NzBAOr3e09bWNptMJjc0wHAc53lvbx9z8wsUiwVs28ayLJRSKKWwLAvbtikWC8zNL9Db24fjOC8AQwK2lLK/qamZXC6LZVlomnaq4p7nkctl6bp5A13X+wFbAqYQgkw2i1IKXddOMefYC1zXI5PNIoQAMCUghBDsVSooZTWAM0tKn71KpfFOSAAhoFQqY5rqpMVnfp1SqUxjjwT8Wm1/sX5Y7wkEHDzP++e4pmlUKmVqtf1FwJfAQSqVGnecwFRLSwsgziT5La7PdmGLVCo1DhzogJ/JZIrt7Zc73MP69VDoAtIw0HX9+EgpMQwDXdNYX/vG1tbW23g8/hIo6oAHeMvLy4vhcDhcq1avKaUIBJowlcIwDITQ2N3ZZn1tlc3NHzOxWOwZkAOqDcl14BxwMRKJ3O7s7Hxi23YXjaQKQbVa/bqysjKRSCQ+ARlgB3D/CBMQAFqBIOAc3XEUnDKQBwpApRGmX7hz407psoIvAAAAAElFTkSuQmCC');}
			li.blue  {list-style-image:url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB94HGQIZJ0Zf2+cAAAJuSURBVDjLpZNBSFRRFIa/e+97b2Z8jo6DaaaUtDApKBmCDDMKaRFBtXARrSOFtm6khRSUmxYSBAYFLSLatFCU2gy2iEgwscQgSRjLUQemmebNjKOj790WOmCmtOjAWdzDf7/Ff84vtNb8T4md77rel6e0r7zfE+qcRm+JBFK7b8Varnep/9o4oHcDqLq+ocGKYPDGxaOHOFFfTZmlAFgpunyKJ3n9ZR4nm32ydOdKN+BuBxh1fUOvasNVl3s6WphMrBKN5Yk7GwDUVxh0NNpEav08iE6R+Jl6unT3ahfgKkDU3HrUXlXb0N9zIcKz6Qzv4yu4WlNmSQKmoOh6zCTXiGU26GptZGIhFZHNp6P58ZHvEjBF+MC9zpZGRuZyJPLrVPoU5ZbCNiW2KSm3FJU+RSK/zshcjs6WRkSo7j5gGkAA099WEwrx5odD0FJIsbvjnoZYep2zDSEwrDYgYACWQBPLetiWQIq/V1MqXYJkPcTmIiwDEAJwih5lltzz83aIU/RKOmEACCHIFFxsU/KvwypphdhEGIDWK85kNvcrsj8cxvVc9mIIAUoqllMp9IozCWgJFAtT0YHZxUV8UmCbBgFD4t/RAUNimwY+KZhdXKQwFR0AigrQq98+pn3H2g8nit6R5vpafJbCVBJTCUwlsQyFz1IYUhCdniG7MDecfN73GEgrwAO83IfhSdnUejCW32iq9JvsC9oE/SYBUyGBheRPxmZmycx/HU08vHkbWAYKJdMVUAnUV5y/fiZw8lI3warjJS+EALLpz4WJ0UFn7MU7IA5kAPePMAE2EAaqgfKtGVvByQFJIAXkS2H6DXwg5oA/CW51AAAAAElFTkSuQmCC');}
			li.green {list-style-image:url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB94HGQIWB/qp5+AAAAIpSURBVDjLpZPdS9NRGMc/52W/bTm3sFmiuIuioqIIvBhkbzcmRngX/gNB0k11WQYilF1EYDdhUPYHRDdSgXmjlNFIpwTropDVhmxz7sUxtzVxvy72mw4TDDrwXJxzvs+H8zzf8wjTNPmfJbbvuwbxSwcPTcnFGlsIEBWmKiXuTA4RAMydAKp7mFGPe8+1S6evcsLnx2k0AFAsrxGKBHi/8IrVXOH5xF36gY16gO4e5nWL19t74/J9oquf+JZ4Q7aYBmCvs4njB67Q7jnD03f3iCdXXkwMcB3YEIA4d5vzrYdcUzd7h5iJjLCcjyLFFt0EKibsd7XT6bvFk/FB4uH8henHfJCAzbmPBz0dfczHxsgUotg1GApsVhgK7BoyhSjzsTF6OvqwNzEM2CTgFDY6W5sbieVDaAVKgtwWSoJWEMuHaG1uRGg6AacGDAEkSrMoBfIfbEuUZmvlGdpyifzvCFrs7ru0tJZU6JrP2VIEpcGs7PICWdUKsQU01wsEU+lqjUr9Xf9mH1RVk0rDeoEgYEqgvDTHyGIYlACtd4YoZd0JWAzD0hwjQFkBZvI7mZaTHMwWOeprqwqlqIpVXbIAPs9CKsL4l5c8AzIKqACVnzMEvcfwJXMccTjA7QLDXk3EhMQyBBcg+Yu3048YAOJAsdZ3BXiAtsNdnPX56TfcnNocGQHlHF8jAUZ/TPIRWAJWa1+ZOkgD0AR4AZd1hjU4eWAFSANrtWH6A3N1tYLSqOERAAAAAElFTkSuQmCC');}
			li.orange{list-style-image:url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB94HGQIUE9JFUR8AAAI7SURBVDjLpZNfSNNRFMc/98/v17Zsg1VrEKZlFILmW4JG9RKUYE8F4XOk4FP0FD1XT5EvhkU9JRFUCEbgo5AEKxCW0jALJ7aYQ3/b1P2c4vbr4W64RHvpwpd77zn3fO8933OP8DyP/xli5z52q7k9ZHsPFd5FquRCUEKM5zfF3fZniRjg7Uagpvqbh+qCoZuRs5cJHG8Dn994iuu4c3Eyn8dYW8k/bx1M9AGlWgI91d/8LnQwerX++m1IT8PPT7CWNt66KDR1QLSFhTePyS+lX7Q+SfQCJQGI9z0nz7c0HB5vvHEH4m/BmQepQUhD4JWhvAXhBmi7RvL1IxILSxe6hmc/SsBqCOn7kY5umBmDlRTYPrBs0NrAso1tJQUzY0Q6uqkPqgeAJQG/X4vOQCQMy7PbgUr+jSrR8iyBSBifEp2AXwM2CMj9ANuuPFvsUTQJnjRnzRlbm5WEomNu2TO4hqTomBmErtaZQga0qqnwP35OIWNiKjRedqM06eaKYFmV/NXu0BosCzdXJLtRmsQkxOZIIjeQSTpGLFsZbfUOWBWfkmSSDiOJ3ACwqQBvYn4129UUPGEX3NOh+rAJkAKkNFDSpCcEC1/mmPldGO0dTT4FsgooA+Xh+PLkpcYDx6yce8r2WVhBP+yzwTIyuYurpOK/+JZa/XDl5fd7QBpYr0qugBBwtL/9yLmelnBfJKDPbCsqyLhbX19NO0ODscUJIAXkq1+ZGpL9QBg4BNRVbFQaZw1YAhygUG2mPzVHvDddhkcLAAAAAElFTkSuQmCC');}
			li.purple{list-style-image:url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB94HGQISA5mo5v0AAAJlSURBVDjLpZNNSJRRGIWf+/eNg5q/aaIYaCghWlgRYUmEQUi0qK1LIaFAcBdBrUpqEQYJBrZz6yYKpKxkKrAgsSREk2JEnXT+HJ1xZnTm+1qMA2YSQS+cxX25nAvnuUc4jsP/jNh9fnBu8KRb5fZKW57NmgshsKU9Fk/HbvS87vwAOHsZqP62oYH8wrzO+gsHqWgswbg1AFvxFL6pIDMjXtZXo4PXRju6gPROA93fNjRcVFFwqbX7KJH5NZanV0isJgHIKXRRfriMgup9eB5OEvJFnlwf7bgKpBUgbrXcP1NRXtHb2t3M/PsFQt+CkHJQWqG0wtmyWV9cZyOYoPFyHb7JYPORohOvxuZfzEvA7M85cKehvZaVST/JUBJjWWhjobXJyFgYyyIZSrIy6aehvZZSV9ldwEjAbUlXS3FVPhu+OFoZlDIoqX+XMmhl2PDFKa7Kx0irBXBrwAJIBJJoY/7ksnNUJv9EIJndWBoQCEhHbZTS/8Q+HbWzDwmd5bwZTmG0wbb//rGkzNwVIuMgASeaWpuI+GMYYzBaodXeMlphjCHijxFNrU0AjgQ2x5c8fd5ZH1IojLYyQe4KUSuD0RZSKLyzPsaXPH3ApgKcr4HP4WNlp2oSQbu+sqYcrTRSKKSUSKkyBlqDFEx4pvEGfjx99OneYyCsABuw33hHJppKjlfHlrfqctw55Bfm4XK5MMbgAP6lMFMfZ/jun3t++23PTeAnEBc7ABUAlRcPXTndWnW+q8BV2JQtqhAQSa5+8Sy8HHg2N/wOWAQiQFrsopwLFAOlQN72ju3iRIEAEAJi2TL9AreD3KRrTpxGAAAAAElFTkSuQmCC');}
			li.red   {list-style-image:url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB94HGQIOC3EEM5IAAAJkSURBVDjLpZPPS1RRHMU/98d7b56/ddIURSMimbCilYiREqELwdZtqkWUFP0B0rraClFY5KZNq4gEN0PEREFJKJSWmiCa1tSoM6/x1zDOm9tiZsBKadGFs7g/zuHyPecIYwz/s8Sf+2etodYSyW1lTGdBXAiBL0RkPUv/2dGpUcDsJqDCbaHB0rKySw2nz1AVakEVuQD4m1vEpyZZevGctWTyYdebqT7A3ymgw22hJxU1Nb0tl6+xPTNBavQlmeVo7rK6jkBrB1bzUSYf3MX7ERvqejt1BfAFIIZOHDp1ZH915PjV66SGH7O9NA9Kg5Q5+WwW/AxWwwECved4f+8OM7GVjovjs68kYNXb+mZTdw/pyAj+chRZVIx0XaTj5OC6yKJi/OUo6cgITd091NnqFmBJwA0o2V4ZrMBfmEM6LtJ2kNr6HbaDdFz8hTkqgxU4UrYDrgZsA8jFObQdwEgJQuzumTEIpZGLcwUbbA0IhMR4CaTtYPYiF2wzBuMlQEgAofNGk/USKCdA9h/Bkvm3hV9KwCQz/ri3mULbDlpbqD2gtYW2HbzNFMmMPw4YCaTDMW9gIRpDKo22HZRl/TVEZeXIUmkWojHCMW8ASCvAvEusJTqDZQe3N9ab62trcySlEFIhlUJpjdIWQkjGPk0z660P93+cvw8kFJAFsk+/rY63l5c0ppLeYTfgUFxamsuAZSGEYDUeZ2JmlunV5MiFsc83gO/AVmHkCigH6s831pzsravqC2p1zOwozGrG/zAcjQ8++hJ7DXwFfhaizA6RYqAK2AeU5M/IF2cdWAHiwEahTL8A2T7ZYtz52FMAAAAASUVORK5CYII=');}
		</style>
	</head>
<body>
	<h1>Atarefado - %s</h1>
	<h2>Tag: %s</h2>
	<h2>Filtros: %s</h2>
	<ul>%s</ul>
	<br>
	<ul>
]], gui.dbname[gui.dbname.value], gui.dbname[gui.dbname.value],
			gui.taglist[gui.taglist.value], gui.search.value, filter))
			for i = 1, gui.result.count do
				local v = gui.task_table[i]
				if eng.isanytime(v.date) then
					v.color = "green"
				elseif eng.istomorrow(v.date) then
					v.color = "blue"
				elseif eng.isfuture(v.date) then
					v.color = "black"
				elseif eng.istoday(v.date) then
					v.color = "orange"
				elseif eng.isyesterday(v.date) then
					v.color = "purple"
				elseif eng.islate(v.date) then
					v.color = "red"
				end
				htmlfile:write(string.format('\t\t<li class="%s">%s</li>\n',
					v.color, v.name))
			end
			htmlfile:write("\t</ul>\n</body>\n</html>\n")
			htmlfile:close()
		end
	end
end
