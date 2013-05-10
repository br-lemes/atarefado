
os.setlocale("pt_BR")
os.setlocale("C", "numeric")

gui = { }

require("iuplua")
require("engine")
require("icons")
require("layout")
require("action")

eng.init()
gui.dialog:show()
gui.tag_load()
gui.opt_load()
gui.task_load()

iup.MainLoop()
