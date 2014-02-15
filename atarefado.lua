
os.setlocale("pt_BR")
os.setlocale("C", "numeric")

gui = { }

require("lfs")
require("iuplua")
require("engine")
require("icons")
require("layout")
require("action")

iup.SetGlobal("UTF8MODE", "NO")

gui.dialog:show()
gui.db_load()
eng.init(gui.dblist[1])
gui.tag_load()
gui.opt_load()
gui.task_load()

iup.MainLoop()
