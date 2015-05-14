
local html = { }

html.alert   = ""
html.dblist  = { }
html.taglist = { }
html.duename = { "Qualquer dia", "Amanhã", "Futuras", "Hoje", "Ontem", "Vencidas" }
html.duelist = { "anytime", "tomorrow", "future", "today", "yesterday", "late" }
-- due [date] list :)
html.onoff = { ON = "OFF", OFF = "ON" }

html.debugString = ""

function html.debug(msg)
	html.debugString = string.format("%s<br>%s<br>",
		html.debugString, msg)
end

function html.debugInfo()
	print("<pre>", html.debugString, "</pre>")
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
if GET.database and html.dblist[GET.database] then
	html.dbactive = GET.database
else
	html.dbactive = html.dblist[1]
end
eng.init(html.dbactive .. ".sqlite")
if GET.action == "post" and not POST.cancel then
	if POST.action == "new_tag" then
		if POST.name ~= "" then
			eng.new_tag(POST.name)
			html.alert = string.format([[
			<div class="alert alert-dismissible alert-success">
				<button type="button" class="close" data-dismiss="alert">×</button>
				Nova tag criada: %s.
			</div>]], POST.name)
		else
			html.alert = [[
			<div class="alert alert-dismissible alert-danger">
				<button type="button" class="close" data-dismiss="alert">×</button>
				Tag sem nome.
			</div>]]
		end
	elseif POST.action == "del_tag" then
		eng.del_tag(POST.id)
		html.alert = string.format([[
			<div class="alert alert-dismissible alert-success">
				<button type="button" class="close" data-dismiss="alert">×</button>
				Tag excluída: %s.
			</div>]], POST.name)
	elseif POST.action == "upd_tag" then
		if POST.name ~= "" then
			eng.upd_tag(POST.id, POST.name)
			html.alert = string.format([[
				<div class="alert alert-dismissible alert-success">
					<button type="button" class="close" data-dismiss="alert">×</button>
					Tag atualizada: %s.
				</div>]], POST.name)
		else
			html.alert = [[
			<div class="alert alert-dismissible alert-danger">
				<button type="button" class="close" data-dismiss="alert">×</button>
				Tag sem nome.
			</div>]]
		end
	end
	elseif GET.action == "set_date" then
		local upd = { }
		if GET.date == "today" then
			upd.id = GET.id
			upd.date = os.date("%Y-%m-%d")
			eng.upd_task(upd)
		elseif GET.date == "tomorrow" then
			upd.id = GET.id
			upd.date = os.date("%Y-%m-%d", os.time()+24*60*60)
			eng.upd_task(upd)
		elseif GET.date == "anytime" then
			upd.id = GET.id
			upd.date = ""
			eng.upd_task(upd)
		end
end
for i, v in ipairs(html.duelist) do
	if GET[v] then eng.set_option(v, GET[v]) end
end
if GET.tag then eng.set_option("tag", GET.tag) end
html.options = eng.get_options()
html.options.tag = tonumber(html.options.tag)
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
