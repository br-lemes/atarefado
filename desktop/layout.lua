
gui = { }

function gui.option(self)
	eng.set_option(self.name, self.value)
	fun.task_load()
end

gui.taglist_menu = iup.menu{
	iup.item{
		name   = "taglist_menu_new",
		title  = "Nova Tag\tF10",
		action = function() gui.new_button:action() end
	},
	iup.item{
		name   = "taglist_menu_edit",
		title  = "Editar Tag\tF11",
		action = function() gui.edit_button:action() end
	},
	iup.item{
		name   = "taglist_menu_delete",
		title  = "Excluir Tag\tF12",
		action = function() gui.del_button:action() end
	},
}

gui.result_menu = iup.menu{
	iup.item{
		name   = "result_menu_new",
		title  = "Nova Tarefa\tENTER",
		action = function() gui.task_new:action() end
	},
	iup.item{
		name   = "result_menu_edit",
		title  = "Editar Tarefa\tENTER",
		action = function() gui.result:dblclick_cb() end
	},
	iup.item{
		name   = "result_menu_delete",
		title  = "Excluir Tarefa\tDEL",
		action = function() gui.task_delete:action() end
	},
	iup.separator{},
	iup.item{
		name   = "result_menu_cut",
		title  = "Recortar\tCtrl+X",
		action = function() fun.cut() end
	},
	iup.item{
		name   = "result_menu_copy",
		title  = "Copiar\tCtrl+C",
		action = function() fun.copy() end
	},
	iup.item{
		name   = "result_menu_paste",
		title  = "Colar\tCtrl+V",
		action = function() fun.paste() end
	},
	iup.separator{},
	iup.item{
		name   = "result_menu_today",
		title  = "Marcar para hoje\tF2",
		action = function() gui.task_today:action() end
	},
	iup.item{
		name   = "result_menu_tomorrow",
		title  = "Deixar para amanhã\tF3",
		action = function() gui.task_tomorrow:action() end
	},
	iup.item{
		name   = "result_menu_anytime",
		title  = "Deixar para qualquer dia\tF4",
		action = function() gui.task_anytime:action() end
	},
	iup.separator{},
	iup.item{
		name   = "result_menu_priup",
		title  = "Aumentar prioridade",
		action = function() fun.priup() end
	},
	iup.item{
		name   = "result_menu_pridown",
		title  = "Diminuir prioridade",
		action = function() fun.pridown() end
	},
}

gui.dialog = iup.dialog{
	font       = "Helvetica, Bold 12",
	title      = "Atarefado 1.4+",
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
						iup.label{
							name      = "count",
							font      = "Helvetica, Bold 10",
							expand    = "HORIZONTAL",
							alignment = "ACENTER",
							title     = "\n0",
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
				visiblecolumns = "1",
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
