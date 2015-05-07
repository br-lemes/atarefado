
os.setlocale("pt_BR")
os.setlocale("C", "numeric")

eng = require("engine")

require("lfs")
require("iuplua")
require("desktop.icons")
require("desktop.layout")
require("desktop.functions")
require("desktop.action")

iup.SetGlobal("UTF8MODE", "NO")

gui.dialog:show()
fun.db_load()
eng.init(fun.dblist[1])
fun.tag_load()
fun.opt_load()
fun.task_load()

iup.MainLoop()
