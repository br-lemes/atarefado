
local html = { }

html.alert   = ""
html.dblist  = { }
html.taglist = { }
html.duename = { "Qualquer dia", "Amanhã", "Futuras", "Hoje", "Ontem", "Vencidas" }
html.duelist = { "anytime", "tomorrow", "future", "today", "yesterday", "late" }
-- due [date] list :)
html.onoff = { ON = "OFF", OFF = "ON" }

html.alertString = ""
html.debugString = ""

function html.alert(msg, class)
	html.alertString = string.format([[
		<div class="alert alert-dismissible %s">
			<button type="button" class="close" data-dismiss="alert">×</button>
				%s
		</div>]], class, msg)
end

function html.debug(msg)
	html.debugString = string.format("%s<br>%s<br>",
		html.debugString, msg)
end

function html.debugInfo()
	if html.debugString ~= "" then
		print("<pre>", html.debugString, "</pre>")
	end
end

function html.dueicon(task)
	if eng.isanytime(task.date) then
		return "anytime"
	elseif eng.istomorrow(task.date) then
		return "tomorrow"
	elseif eng.isfuture(task.date) then
		return "future"
	elseif eng.istoday(task.date) then
		return "today"
	elseif eng.isyesterday(task.date) then
		return "yesterday"
	elseif eng.islate(task.date) then
		return "late"
	end
end

function html.img(image, size)
	return string.format(
		'<img src="webapp/images/%s.png" width="%d" height="%d">',
		image, size, size)
end

--
-- Get database list and set the active database
--

for file in lfs.dir("database") do
	if file:sub(-7, -1) == ".sqlite" then
		local name = file:sub(1, -8)
		table.insert(html.dblist, name)
		html.dblist[name] = #html.dblist
	end
end
if #html.dblist == 0 then
	table.insert(html.dblist, "atarefado")
	html.dblist["atarefado"] = #html.dblist
end
table.sort(html.dblist)
if _G[ENV.REQUEST_METHOD].database and html.dblist[_G[ENV.REQUEST_METHOD].database] then
	html.dbactive = _G[ENV.REQUEST_METHOD].database
else
	html.dbactive = html.dblist[1]
end

eng.init(html.dbactive .. ".sqlite")
if ENV.REQUEST_METHOD == "POST" and not POST.cancel then
	if POST.action == "new_task" then
		if POST.name then POST.name = POST.name:match("^%s*(.-)%s*$") end
		if POST.name ~= "" then
			local upd = { }
			upd.name = POST.name
			upd.date = POST.date
			upd.comment = POST.comment
			upd.recurrent = POST.recurrent
			eng.Begin()
			local cur, err = eng.new_task(upd)
			if cur then
				upd.id = eng.last_row()
				local taglist = eng.get_tags()
				for i, v in ipairs(taglist) do
					if POST.tags and POST.tags:match("%f[%d]" .. v.id .. "%f[%D]") then
						eng.set_tag(upd.id, v.id)
					else
						eng.clear_tag(upd.id, v.id)
					end
				end
				for i = 1, 7 do
					if POST.rweek and POST.rweek:match("%f[%d]" .. i .. "%f[%D]") then
						eng.set_tag(upd.id, i)
					else
						eng.clear_tag(upd.id, i)
					end
				end
				for i = 1, 31 do
					if POST.rmonth and POST.rmonth:match("%f[%d]" .. i .. "%f[%D]") then
						eng.set_tag(upd.id, i+7)
					else
						eng.clear_tag(upd.id, i+7)
					end
				end
				html.alert(string.format("Nova tarefa criada: %s.", POST.name), "alert-success")
			else
				html.alert(err, "alert-danger")
			end
			eng.End()
		else
			html.alert("Tarefa sem nome.", "alert-danger")
		end
	elseif POST.action == "new_tag" then
		if POST.name ~= "" then
			local cur, err = eng.new_tag(POST.name)
			if cur then
				html.alert(string.format("Nova tag criada: %s.", POST.name), "alert-success")
			else
				html.alert(err, "alert-danger")
			end
		else
			html.alert("Tag sem nome.", "alert-danger")
		end
	elseif POST.action == "del_task" then
		local s = "excluída"
		if POST.recurrent and not POST.force then s = "concluída" end
		local cur, err = eng.del_task(POST.id, POST.force)
		if cur then
			html.alert(string.format("Tarefa %s: %s.", s, POST.name), "alert-success")
		else
			html.alert(err, "alert-danger")
		end
	elseif POST.action == "del_tag" then
		local cur, err = eng.del_tag(POST.id)
		if cur then
			html.alert(string.format("Tag excluída: %s.", POST.name), "alert-success")
		else
			html.alert(err, "alert-danger")
		end
	elseif POST.action == "upd_task" then
			local upd = { }
			upd.id = POST.id
			upd.name = POST.name
			upd.date = POST.date
			upd.comment = POST.comment
			upd.recurrent = POST.recurrent
			eng.Begin()
			local cur, err = eng.upd_task(upd)
			if cur then
				local taglist = eng.get_tags()
				for i, v in ipairs(taglist) do
					if POST.tags and POST.tags:match("%f[%d]" .. v.id .. "%f[%D]") then
						eng.set_tag(upd.id, v.id)
					else
						eng.clear_tag(upd.id, v.id)
					end
				end
				for i = 1, 7 do
					if POST.rweek and POST.rweek:match("%f[%d]" .. i .. "%f[%D]") then
						eng.set_tag(upd.id, i)
					else
						eng.clear_tag(upd.id, i)
					end
				end
				for i = 1, 31 do
					if POST.rmonth and POST.rmonth:match("%f[%d]" .. i .. "%f[%D]") then
						eng.set_tag(upd.id, i+7)
					else
						eng.clear_tag(upd.id, i+7)
					end
				end
				html.alert(string.format("Tarefa atualizada: %s.", POST.name), "alert-success")
			else
				html.alert(err, "alert-danger")
			end
			eng.End()
		else
			html.alert("Tarefa sem nome.", "alert-danger")
		end
	elseif POST.action == "upd_tag" then
		if POST.name ~= "" then
			local cur, err = eng.upd_tag(POST.id, POST.name)
			if cur then
				html.alert(string.format("Tag atualizada: %s.", POST.name), "alert-success")
			else
				html.alert(err, "alert-danger")
			end
		else
			html.alert("Tag sem nome.", "alert-danger")
		end
	elseif GET.action == "set_date" then
		local upd = { }
		if GET.date == "today" then
			upd.id = GET.id
			upd.date = os.date("%Y-%m-%d")
			local cur, err = eng.upd_task(upd)
			if not cur then html.alert(err, "alert-danger") end
		elseif GET.date == "tomorrow" then
			upd.id = GET.id
			upd.date = os.date("%Y-%m-%d", os.time()+24*60*60)
			local cur, err = eng.upd_task(upd)
			if not cur then html.alert(err, "alert-danger") end
		elseif GET.date == "anytime" then
			upd.id = GET.id
			upd.date = ""
			local cur, err = eng.upd_task(upd)
			if not cur then html.alert(err, "alert-danger") end
		end
end
for i, v in ipairs(html.duelist) do
	if GET[v] then
		local cur, err = eng.set_option(v, GET[v])
		if not cur then html.alert(err, "alert-danger") end
	end
end
if GET.tag then
	local cur, err = eng.set_option("tag", GET.tag)
	if not cur then html.alert(err, "alert-danger") end
end
html.options = eng.get_options()
html.options.tag = tonumber(html.options.tag) or 1
html.taglist = eng.get_tags()
table.insert(html.taglist, 1, { name = "Todas"})
table.insert(html.taglist, 2, { name = "Nenhuma"})
html.flags = {
	anytime   = html.options.anytime   == "ON",
	tomorrow  = html.options.tomorrow  == "ON",
	future    = html.options.future    == "ON",
	today     = html.options.today     == "ON",
	yesterday = html.options.yesterday == "ON",
	late      = html.options.late      == "ON",
}
if html.options.tag == 1 then
	html.tag = nil
elseif html.options.tag == 2 then
	html.tag = -1
elseif html.options.tag > 2 then
	html.tag = html.taglist[html.options.tag].id
end
html.tasklist = eng.gettasks("", html.flags, html.tag)

return html
