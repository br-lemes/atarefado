
gui = { }

function gui.option(self)
	eng.con:execute(string.format(
		'UPDATE options SET value=%q WHERE name=%q;',
		 self.value, self.name))
	fun.task_load()
end

function gui.iupnames(elem, dest)
	if type(elem) == "userdata" then
		if elem.name ~= "" and elem.name ~= nil then
			dest[elem.name] = elem
		end
	end
	local i = 1
	while elem[i] do
		gui.iupnames(elem[i], dest)
		i = i + 1
	end
end

gui.savedlg = iup.filedlg{
	name       = "savedlg",
	dialogtype = "SAVE",
	extfilter  = "Página HTML (*.html)|*.html;*.htm",
	title      = "Salvar como HTML",
}

gui.dialog = iup.dialog{
	font       = "HELVETICA_BOLD_12",
	title      = "Atarefado 1.1.1",
	rastersize = "600x440",
	iup.split{
		iup.vbox{
			margin = "10x10",
			gap    = "10",
			iup.text{
				name   = "search",
				expand = "HORIZONTAL",
			},
			iup.zbox{
				name = "zbox",
				iup.vbox{
					name   = "result_box",
					margin = "0",
					iup.list{
						name           = "result",
						visiblelines   = "1",
						visiblecolumns = "1",
						expand         = "YES",
						showimage      = "YES",
					},
					iup.hbox{
						iup.button{
							name   = "task_new",
							tip    = "Nova Tarefa (ENTER)",
							image  = ico.note_add,
							active = "YES",
						},
						iup.button{
							name   = "task_edit",
							tip    = "Editar Tarefa (ENTER)",
							image  = ico.note_edit,
							active = "NO",
						},
						iup.button{
							name   = "task_delete",
							tip    = "Excluir Tarefa (DEL)",
							image  = ico.note_delete,
							active = "NO",
						},
						iup.fill{},
						iup.button{
							name    = "savehtml",
							tip     = "Salvar como HTML",
							image   = ico.html,
						},
						iup.fill{},
						iup.button{
							name   = "task_today",
							tip    = "Marcar para hoje (F2)",
							image  = ico.flag_orange,
							active = "NO",
						},
						iup.button{
							name   = "task_tomorrow",
							tip    = "Deixar para amanhã (F3)",
							image  = ico.flag_blue,
							active = "NO",
						},
						iup.button{
							name   = "task_anytime",
							tip    = "Deixar para qualquer dia (F4)",
							image  = ico.flag_green,
							active = "NO",
						},
					},
				},
				iup.hbox{
					name = "new_tag",
					iup.fill{rastersize = "200"},
					iup.button{
						name   = "new_cancel",
						tip    = "ESC",
						title  = "Cancelar",
						expand = "HORIZONTAL",
					},
					iup.button{
						name   = "new_ok",
						tip    = "ENTER",
						title  = "OK",
						expand = "HORIZONTAL",
					},
				},
				iup.hbox{
					name = "edit_tag",
					iup.fill{rastersize = "200"},
					iup.button{
						name   = "edit_cancel",
						tip    = "ESC",
						title  = "Cancelar",
						expand = "HORIZONTAL",
					},
					iup.button{
						name   = "edit_ok",
						tip    = "ENTER",
						title  = "OK",
						expand = "HORIZONTAL",
					},
				},
				iup.vbox{
					name   = "task_box",
					margin = "0",
					iup.tabs{
						margin   = "10x10",
						iup.vbox{
							tabtitle = "&Comentários",
							iup.text{
								name      = "task_comment",
								expand    = "YES",
								multiline = "YES",
							},
						},
						iup.vbox{
							tabtitle = "&Tags",
							iup.list{
								name         = "task_tag",
								expand       = "YES",
								multiple     = "YES",
								visiblelines = "1",
							},
						},
						iup.vbox{
							tabtitle = "&Recorrente",
							iup.list{
								name     = "task_recurrent",
								dropdown = "YES",
								expand   = "HORIZONTAL",
								value    = "1",
								"Não",
								"Semanal",
								"Mensal",
								"Último dia",
							},
							iup.zbox{
								name = "task_zoption",
								iup.vbox{},
								iup.list{
									name         = "task_tagw",
									expand       = "YES",
									multiple     = "YES",
									visiblelines = "1",
									"Domingo",
									"Segunda-Feira",
									"Terça-Feira",
									"Quarta-Feira",
									"Quinta-Feira",
									"Sexta-Feira",
									"Sábado",
								},
								iup.list{
									name         = "task_tagm",
									expand       = "YES",
									multiple     = "YES",
									visiblelines = "1",
									 "1",  "2",  "3",  "4",  "5",  "6",  "7",
									 "8",  "9", "10", "11", "12", "13", "14",
									"15", "16", "17", "18", "19", "20", "21",
									"22", "23", "24", "25", "26", "27", "28",
									"29", "30", "31",
								},
								iup.vbox{},
							},
						},
					},
					iup.hbox{
						iup.text{
							name   = "task_date",
							expand = "HORIZONTAL",
							mask   = "20/d/d-/d/d-/d/d",
						},
						iup.fill{rastersize = "80"},
						iup.button{
							name   = "task_cancel",
							tip    = "ESC",
							title  = "Cancelar",
							expand = "HORIZONTAL",
						},
						iup.button{
							name   = "task_ok",
							tip    = "ENTER",
							title  = "OK",
							expand = "HORIZONTAL",
						},
					},
				},
			},
		},
		iup.vbox{
			name   = "optbox",
			margin = "10x10",
			gap    = "10",
			expand = "YES",
			iup.list{
				name     = "dbname",
				dropdown = "YES",
				expand   = "HORIZONTAL",
			},
			iup.hbox{
				margin = "0",
				iup.toggle{
					name   = "anytime",
					image  = ico.green,
					tip    = "Qualquer dia",
					value  = "ON",
					action = gui.option,
				},
				iup.fill{},
				iup.toggle{
					name   = "tomorrow",
					image  = ico.blue,
					tip    = "Amanhã",
					value  = "ON",
					action = gui.option,
				},
				iup.fill{},
				iup.toggle{
					name   = "future",
					image  = ico.black,
					tip    = "Futuras",
					value  = "ON",
					action = gui.option,
				},
			},
			iup.hbox{
				name   = "",
				margin = "0",
				iup.toggle{
					name   = "today",
					image  = ico.orange,
					tip    = "Hoje",
					value  = "ON",
					action = gui.option,
				},
				iup.fill{},
				iup.toggle{
					name   = "yesterday",
					image  = ico.purple,
					tip    = "Ontem",
					value  = "ON",
					action = gui.option,
				},
				iup.fill{},
				iup.toggle{
					name   = "late",
					image  = ico.red,
					tip    = "Vencidas",
					value  = "ON",
					action = gui.option,
				},
			},
			iup.list{
				name         = "taglist",
				rastersize   = "150",
				visiblelines = "1",
				expand       = "YES",
				value        = "1",
				lastvalue    = "1",
				"Todas",
				"Nenhuma",
			},
			iup.hbox{
				margin = "0",
				iup.button{
					name   = "new_button",
					tip    = "Nova Tag (F10)",
					image  = ico.tag_blue_add,
					active = "YES",
				},
				iup.fill{},
				iup.button{
					name   = "edit_button",
					tip    = "Editar Tag (F11)",
					image  = ico.tag_blue_edit,
					active = "NO",
				},
				iup.fill{},
				iup.button{
					name   = "del_button",
					tip    = "Excluir Tag (F12)",
					image  = ico.tag_blue_delete,
					active = "NO",
				},
			},
		},
	},
}

gui.iupnames(gui.dialog, gui)
