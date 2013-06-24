
function gui.option(self)
	eng.con:execute(string.format(
		'UPDATE options SET value=%q WHERE name=%q;', self.value, self.elemname))
	gui.task_load()
end

function gui.iupnames(elem, dest)
	if type(elem) == "userdata" then
		if elem.elename ~= "" and elem.elemname ~= nil then
			dest[elem.elemname] = elem
		end
	end
	local i = 1
	while elem[i] do
		gui.iupnames(elem[i], dest)
		i = i + 1
	end
end

gui.dialog = iup.dialog{
	elemname   = nil,
	font       = "HELVETICA_BOLD_12",
	title      = "Atarefado 1.0",
	rastersize = "600x440",
	iup.split{
		elemname = "",
		iup.vbox{
			elemname = "",
			margin   = "10x10",
			gap      = "10",
			iup.text{
				elemname = "search",
				expand   = "HORIZONTAL",
			},
			iup.zbox{
				elemname = "zbox",
				iup.vbox{
					elemname = "result_box",
					margin   = "0",
					iup.list{
						elemname       = "result",
						visiblelines   = "1",
						visiblecolumns = "1",
						expand         = "YES",
						showimage      = "YES",
					},
					iup.hbox{
						elemname = "",
						iup.button{
							elemname = "task_new",
							tip      = "Nova Tarefa (ENTER)",
							image    = load_image_note_add(),
							active   = "YES",
						},
						iup.button{
							elemname = "task_edit",
							tip      = "Editar Tarefa (ENTER)",
							image    = load_image_note_edit(),
							active   = "NO",
						},
						iup.button{
							elemname = "task_delete",
							tip      = "Excluir Tarefa (DEL)",
							image    = load_image_note_delete(),
							active   = "NO",
						},
						iup.fill{
							elemname = "",
						},
						iup.label{
							elemname = "task_recurrency",
							image    = load_image_refresh(),
							active   = "NO",
							padding  = "5x5",
							tip      = "Tarefa recorrente",
						},
						iup.fill{
							elemname = "",
						},
						iup.button{
							elemname = "task_today",
							tip      = "Marcar para hoje (F2)",
							image    = load_image_flag_orange(),
							active   = "NO",
						},
						iup.button{
							elemname = "task_tomorrow",
							tip      = "Deixar para amanhã (F3)",
							image    = load_image_flag_blue(),
							active   = "NO",
						},
						iup.button{
							elemname = "task_anytime",
							tip      = "Deixar para qualquer dia (F4)",
							image    = load_image_flag_green(),
							active   = "NO",
						},
					},
				},
				iup.hbox{
					elemname = "new_tag",
					iup.fill{
						elemname   = "",
						rastersize = "200",
					},
					iup.button{
						elemname = "new_cancel",
						tip      = "ESC",
						title    = "Cancelar",
						expand   = "HORIZONTAL",
					},
					iup.button{
						elemname = "new_ok",
						tip      = "ENTER",
						title    = "OK",
						expand   = "HORIZONTAL",
					},
				},
				iup.hbox{
					elemname = "edit_tag",
					iup.fill{
						elemname   = "",
						rastersize = "200",
					},
					iup.button{
						elemname = "edit_cancel",
						tip      = "ESC",
						title    = "Cancelar",
						expand   = "HORIZONTAL",
					},
					iup.button{
						elemname = "edit_ok",
						tip      = "ENTER",
						title    = "OK",
						expand   = "HORIZONTAL",
					},
				},
				iup.vbox{
					elemname = "task_box",
					margin   = "0",
					iup.tabs{
						elemname = "",
						margin   = "10x10",
						iup.vbox{
							elemname = "",
							tabtitle = "&Comentários",
							iup.text{
								elemname  = "task_comment",
								expand    = "YES",
								multiline = "YES",
							},
						},
						iup.vbox{
							elemname = "",
							tabtitle = "&Tags",
							iup.list{
								elemname     = "task_tag",
								expand       = "YES",
								multiple     = "YES",
								visiblelines = "1",
							},
						},
						iup.vbox{
							elemname = "",
							tabtitle = "&Recorrente",
							iup.list{
								elemname = "task_recurrent",
								dropdown = "YES",
								expand   = "HORIZONTAL",
								value    = "1",
								"Não",
								"Semanal",
								"Mensal",
								"Último dia",
							},
							iup.zbox{
								elemname = "task_zoption",
								iup.vbox{
									elemname = "",
								},
								iup.list{
									elemname     = "task_tagw",
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
									elemname     = "task_tagm",
									expand       = "YES",
									multiple     = "YES",
									visiblelines = "1",
									 "1",  "2",  "3",  "4",  "5",  "6",  "7",
									 "8",  "9", "10", "11", "12", "13", "14",
									"15", "16", "17", "18", "19", "20", "21",
									"22", "23", "24", "25", "26", "27", "28",
									"29", "30", "31",
								},
								iup.vbox{
									elemname = "",
								},
							},
						},
					},
					iup.hbox{
						elemname = "",
						iup.text{
							elemname = "task_date",
							expand   = "HORIZONTAL",
							mask     = "20/d/d-/d/d-/d/d",
						},
						iup.fill{
							elemname   = "",
							rastersize = "100",
						},
						iup.button{
							elemname = "task_cancel",
							tip      = "ESC",
							title    = "Cancelar",
							expand   = "HORIZONTAL",
						},
						iup.button{
							elemname = "task_ok",
							tip      = "ENTER",
							title    = "OK",
							expand   = "HORIZONTAL",
						},
					},
				},
			},
		},
		iup.vbox{
			elemname = "optbox",
			margin   = "10x10",
			gap      = "10",
			expand   = "YES",
			iup.list{
				elemname = "dbname",
				dropdown = "YES",
				expand   = "HORIZONTAL",
			},
			iup.hbox{
				elemname = "",
				margin   = "0",
				iup.toggle{
					elemname = "anytime",
					image    = gui.green,
					tip      = "Qualquer dia",
					value    = "ON",
					action   = gui.option,
				},
				iup.fill{
					elemname = "",
				},
				iup.toggle{
					elemname = "tomorrow",
					image    = gui.blue,
					tip      = "Amanhã",
					value    = "ON",
					action   = gui.option,
				},
				iup.fill{
					elemname = "",
				},
				iup.toggle{
					elemname = "future",
					image    = gui.black,
					tip      = "Futuras",
					value    = "ON",
					action   = gui.option,
				},
			},
			iup.hbox{
				elemname = "",
				margin   = "0",
				iup.toggle{
					elemname = "today",
					image    = gui.orange,
					tip      = "Hoje",
					value    = "ON",
					action   = gui.option,
				},
				iup.fill{
					elemname = "",
				},
				iup.toggle{
					elemname = "yesterday",
					image    = gui.purple,
					tip      = "Ontem",
					value    = "ON",
					action   = gui.option,
				},
				iup.fill{
					elemname = "",
				},
				iup.toggle{
					elemname = "late",
					image    = gui.red,
					tip      = "Vencidas",
					value    = "ON",
					action   = gui.option,
				},
			},
			iup.list{
				elemname     = "taglist",
				rastersize   = "150",
				visiblelines = "1",
				expand       = "YES",
				value        = "1",
				lastvalue    = "1",
				"Todas",
				"Nenhuma",
			},
			iup.hbox{
				elemname = "",
				margin   = "0",
				iup.button{
					elemname = "new_button",
					tip      = "Nova Tag (F10)",
					image    = load_image_tag_blue_add(),
					active   = "YES",
				},
				iup.fill{
					elemname = "",
				},
				iup.button{
					elemname = "edit_button",
					tip      = "Editar Tag (F11)",
					image    = load_image_tag_blue_edit(),
					active   = "NO",
				},
				iup.fill{
					elemname = "",
				},
				iup.button{
					elemname = "del_button",
					tip      = "Excluir Tag (F12)",
					image    = load_image_tag_blue_delete(),
					active   = "NO",
				},
			},
		},
	},
}

gui.iupnames(gui.dialog, gui)
