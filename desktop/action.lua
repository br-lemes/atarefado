
function gui.dialog:close_cb()
	if fun.question("Sair do Atarefado?") == "1" then
		self:hide()
		eng.done()
	else
		gui.result.value = nil
		iup.SetFocus(gui.search)
		return iup.IGNORE
	end
end

function gui.search:k_any(k)
--	if (k == iup.K_cV or k == iup.K_cv) then
	if (k == 805306454 or k == 536870998) then
		if fun.paste() then return iup.IGNORE end
	elseif k == iup.K_DOWN then
		iup.SetFocus(gui.result)
		gui.result.value = "1"
		gui.result:valuechanged_cb()
	elseif k == iup.K_CR then
		if gui.zbox.value == gui.new_tag then
			gui.new_ok:action()
		elseif gui.zbox.value == gui.edit_tag then
			gui.edit_ok:action()
		elseif gui.zbox.value == gui.task_box then
			gui.task_ok:action()
		elseif gui.zbox.value == gui.result_box then
			gui.task_new:action()
		end
	end
	return iup.CONTINUE
end

function gui.result:k_any(k)
--	if (k == iup.K_cC or k == iup.K_cc) then
	if (k == 805306435 or k == 536870979) then
		fun.copy()
--	elseif (k == iup.K_cV or k == iup.K_cv) then
	elseif (k == 805306454 or k == 536870998) then
		fun.paste()
--	elseif (k == iup.K_cX or k == iup.K_cx) then
	elseif (k == 805306456 or k == 536871000) then
		fun.cut()
	elseif k == 536936274 then
		fun.priup()
	elseif k == 536936276 then
		fun.pridown()
	elseif k == 1073807186 then
		fun.priup(10)
	elseif k == 1073807188 then
		fun.pridown(10)
	elseif k == iup.K_UP and gui.result.value == "1" then
		iup.SetFocus(gui.search)
		gui.result.value = nil
		gui.result.lastvalue = nil
		gui.result:valuechanged_cb()
		return iup.IGNORE
	elseif k == iup.K_CR and self.value ~= nil and self.value ~= "0" then
		gui.result:dblclick_cb()
	end
	return iup.CONTINUE
end

function gui.task_date:k_any(k)
	if k == iup.K_CR then
		gui.task_ok:action()
	end
	return iup.CONTINUE
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
	elseif k == iup.K_DEL then
		gui.task_delete:action()
	elseif k == 268500991 --[[iup.K_sDEL]] then
		gui.task_delete:action(true)
	elseif k == iup.K_F2 then
		gui.task_today:action(true)
	elseif k == iup.K_F3 then
		gui.task_tomorrow:action(true)
	elseif k == iup.K_F4 then
		gui.task_anytime:action(true)
	elseif k == iup.K_F5 then
		fun.reload()
	elseif k == iup.K_F10 then
		gui.new_button:action()
		return iup.IGNORE
	elseif k == iup.K_F11 then
		gui.edit_button:action()
	elseif k == iup.K_F12 then
		gui.del_button:action()
	end
end

function gui.search:valuechanged_cb()
	if gui.zbox.value ~= gui.result_box then return end
	fun.load_timer.run  = "NO"
	fun.load_timer.run  = "YES"
end

function gui.new_button:action()
	if gui.zbox.value ~= gui.result_box then return end
	gui.optbox.active      = "NO"
	gui.new_button.active  = "NO"
	gui.edit_button.active = "NO"
	gui.del_button.active  = "NO"
	gui.zbox.value = gui.new_tag
	gui.search.value = ""
	iup.SetFocus(gui.search)
end

function gui.new_ok:action()
	gui.taglist.lastvalue = nil
	eng.new_tag(gui.search.value)
	fun.tag_load()
	gui.new_cancel:action()
	gui.taglist.value = fun.tag_table.id[eng.last_row()]
	fun.task_load()
end

function gui.new_cancel:action()
	gui.search.value      = ""
	gui.optbox.active     = "YES"
	gui.new_button.active = "YES"
	if gui.taglist.value ~= nil and
		tonumber(gui.taglist.value) >= 3 then
		gui.edit_button.active = "YES"
		gui.del_button.active  = "YES"
	end
	gui.zbox.value = gui.result_box
	iup.SetFocus(gui.search)
end

function gui.edit_button:action()
	if gui.zbox.value ~= gui.result_box then return end
	local i = tonumber(gui.taglist.value)
	if i >= 3 then
		gui.optbox.active      = "NO"
		gui.new_button.active  = "NO"
		gui.edit_button.active = "NO"
		gui.del_button.active  = "NO"
		gui.zbox.value = gui.edit_tag
		gui.search.value = fun.tag_table[i].name
		iup.SetFocus(gui.search)
	end
end

gui.taglist.dblclick_cb = gui.edit_button.action

function gui.edit_ok:action()
	local i = tonumber(gui.taglist.value)
	gui.taglist.lastvalue = nil
	eng.upd_tag(fun.tag_table[i].id, gui.search.value)
	fun.tag_load()
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
	if gui.zbox.value ~= gui.result_box then return end
	local i = tonumber(gui.taglist.value)
	if i >= 3 and fun.question("Excluir tag?") == "1" then
		gui.taglist.lastvalue = nil
		eng.del_tag(fun.tag_table[i].id)
		fun.tag_load()
		iup.SetFocus(gui.search)
	end
end

function gui.task_ok:action()
	if gui.search.value:match("^%s*$") then return end
	local upd = { }
	if gui.result.value ~= nil and gui.result.value ~= "0" then
		upd.id = fun.task_table[tonumber(gui.result.value)].id
	end
	upd.name = gui.search.value
	upd.date = gui.task_date.value
	upd.comment = gui.task_comment.value
	upd.recurrent = gui.task_recurrent.value
	eng.Begin()
	if upd.id then
		eng.upd_task(upd)
	else
		eng.new_task(upd)
		upd.id = eng.last_row()
	end
	for i = 1, #gui.task_tag.value do
		local n = gui.task_tag.value:byte(i)
		if n == 43 then
			eng.set_tag(upd.id, fun.tag_table[i+2].id)
		elseif n == 45 then
			eng.clear_tag(upd.id, fun.tag_table[i+2].id)
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
	eng.End()
	gui.task_cancel:action()
	fun.task_load()
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
		iup.SetFocus(gui.result)
	end
end

function gui.taglist:valuechanged_cb()
	if self.value == nil or self.lastvalue == self.value then return end
	eng.set_option('tag', self.value)
	self.lastvalue = self.value
	if tonumber(self.value) >= 3 then
		gui.edit_button.active = "YES"
		gui.del_button.active  = "YES"
	else
		gui.edit_button.active = "NO"
		gui.del_button.active  = "NO"
	end
	fun.task_load()
end

function gui.result:dblclick_cb()
	local item
	if gui.result.value == "0" or gui.result.value == nil then
		item = { name = gui.search.value, date = "", comment = "",
		recurrent = "1" }
		local value = ""
		local j = tonumber(gui.taglist.value)
		if j > 2 then
			for i = 3, #fun.tag_table do
				if i == j then
					value = value .. "+"
				else
					value = value .. "-"
				end
			end
		end
		gui.task_tag.value = value
	else
		item = fun.task_table[tonumber(gui.result.value)]
		gui.search.value = item.name
		local tagt = eng.get_tags(item.id)
		local tagv = ""
		for _,v in ipairs(fun.tag_table) do
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
	gui.task_comment.value = loadstring(string.format(
		'return "%s"', item.comment))()
	gui.task_recurrent.value = item.recurrent or "1"
	gui.task_zoption.valuepos = gui.task_recurrent.value - 1
	iup.SetFocus(gui.search)
end

function gui.task_recurrent:valuechanged_cb()
	gui.task_zoption.valuepos = self.value - 1
end

function gui.result:valuechanged_cb()
	if self.value and self.value ~= "0" then
		gui.task_edit.active = "YES"
		gui.task_delete.active = "YES"
		gui.task_today.active = "YES"
		gui.task_tomorrow.active = "YES"
		gui.task_anytime.active = "YES"
		self.lastvalue = self.value
		if fun.task_table[tonumber(self.value)] and fun.task_table[tonumber(self.value)].recurrent == "1" then
			gui.task_delete.image = ico.note_delete
			gui.task_delete.tip = "Excluir Tarefa (DEL)"
		else
			gui.task_delete.image = ico.note_go
			gui.task_delete.tip = "Concluir Tarefa (DEL)"
		end
	else
		gui.task_edit.active = "NO"
		gui.task_delete.active = "NO"
		gui.task_delete.image = ico.note_delete
		gui.task_delete.tip = "Excluir Tarefa (DEL)"
		gui.task_today.active = "NO"
		gui.task_tomorrow.active = "NO"
		gui.task_anytime.active = "NO"
	end
end

function gui.task_new:action()
	gui.result.value = nil
	gui.result:dblclick_cb()
end

gui.task_edit.action = gui.result.dblclick_cb

function gui.task_delete:action(force)
	if iup.GetFocus() == gui.search or
		gui.zbox.value ~= gui.result_box or
		gui.result.value == nil or
		gui.result.value == "0" then return end
	local task = fun.task_table[tonumber(gui.result.value)]
	local question = "Excluir tarefa?"
	if task.recurrent ~= "1" then
		if force then
			question = "Excluir permanentemente tarefa recorrente?"
		else
			question = "Tarefa concluída?"
		end
	end
	if fun.question(question) == "1" then
		eng.del_task(task.id, force)
		fun.task_load()
	end
end

function gui.task_today:action(keyboard)
	if gui.zbox.value == gui.result_box and
		(gui.result.value ~= nil and gui.result.value ~= "0") then
		upd = { }
		upd.id = fun.task_table[tonumber(gui.result.value)].id
		upd.date = os.date('%Y-%m-%d')
		eng.upd_task(upd)
		fun.task_load()
		if not keyboard then iup.SetFocus(gui.result) end
	elseif gui.zbox.value == gui.task_box then
		gui.task_date.value = os.date('%Y-%m-%d')
	end
end

function gui.task_tomorrow:action(keyboard)
	if gui.zbox.value == gui.result_box and
		(gui.result.value ~= nil and gui.result.value ~= "0") then
		upd = { }
		upd.id = fun.task_table[tonumber(gui.result.value)].id
		upd.date = os.date('%Y-%m-%d', os.time()+24*60*60)
		eng.upd_task(upd)
		fun.task_load()
		if not keyboard then iup.SetFocus(gui.result) end
	elseif gui.zbox.value == gui.task_box then
		gui.task_date.value = os.date('%Y-%m-%d', os.time()+24*60*60)
	end
end

function gui.task_anytime:action(keyboard)
	if gui.zbox.value == gui.result_box and
		(gui.result.value ~= nil and gui.result.value ~= "0") then
		upd = { }
		upd.id = fun.task_table[tonumber(gui.result.value)].id
		upd.date = ""
		eng.upd_task(upd)
		fun.task_load()
		if not keyboard then iup.SetFocus(gui.result) end
	elseif gui.zbox.value == gui.task_box then
		gui.task_date.value = ""
	end
end

function gui.dbname:valuechanged_cb()
	if gui.dbname.value ~= nil and
		gui.dbname.value ~= "0" and
		gui.dbname.lastvalue ~= gui.dbname.value then
		gui.dbname.lastvalue = gui.dbname.value
		gui.taglist.lastvalue = nil
		eng.done()
		eng.init(fun.dblist[tonumber(gui.dbname.value)])
		fun.tag_load()
		fun.opt_load()
		fun.task_load()
	end
end

function gui.result:button_cb(button, pressed, x, y)
	if button == iup.BUTTON3 and pressed == 0 then
		local i = iup.ConvertXYToPos(self, x, y)
		if i ~= -1 then self.value = i end
		if self.value and self.value ~= "0" then
			gui.result_menu_edit.active = "YES"
			gui.result_menu_delete.active = "YES"
			gui.result_menu_cut.active = "YES"
			gui.result_menu_copy.active = "YES"
			gui.result_menu_today.active = "YES"
			gui.result_menu_tomorrow.active = "YES"
			gui.result_menu_anytime.active = "YES"
			gui.result_menu_priup.active = "YES"
			gui.result_menu_pridown.active = "YES"
			if fun.task_table[tonumber(self.value)].recurrent == "1" then
				gui.result_menu_delete.title = "Excluir Tarefa\tDEL"
			else
				gui.result_menu_delete.title = "Concluir Tarefa\tDEL"
			end
		else
			gui.result_menu_edit.active = "NO"
			gui.result_menu_delete.active = "NO"
			gui.result_menu_cut.active = "NO"
			gui.result_menu_copy.active = "NO"
			gui.result_menu_today.active = "NO"
			gui.result_menu_tomorrow.active = "NO"
			gui.result_menu_anytime.active = "NO"
			gui.result_menu_priup.active = "NO"
			gui.result_menu_pridown.active = "NO"
		end
		if fun.canpaste() then
			gui.result_menu_paste.active = "YES"
		else
			gui.result_menu_paste.active = "NO"
		end
		gui.result_menu:popup(iup.MOUSEPOS, iup.MOUSEPOS)
	end
end

function gui.taglist:button_cb(button, pressed, x, y)
	if button == iup.BUTTON3 and pressed == 0 then
		local i = iup.ConvertXYToPos(self, x, y)
		if i ~= -1 then self.value = i end
		if self.value and tonumber(self.value) <= 2 then
			gui.taglist_menu_new.active = "YES"
			gui.taglist_menu_edit.active = "NO"
			gui.taglist_menu_delete.active = "NO"
		else
			gui.taglist_menu_new.active = "YES"
			gui.taglist_menu_edit.active = "YES"
			gui.taglist_menu_delete.active = "YES"
		end
		gui.taglist_menu:popup(iup.MOUSEPOS, iup.MOUSEPOS)
	end
end

gui.task_tag.dblclick_cb = gui.task_ok.action
