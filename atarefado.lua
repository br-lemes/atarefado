
os.setlocale("pt_BR")
os.setlocale("C", "numeric")

require("lfs")
require("iuplua")
require("engine")
require("icons")
require("layout")
require("action")
require("functions")

iup.SetGlobal("UTF8MODE", "NO")

gui.dialog:show()
fun.db_load()
eng.init(fun.dblist[1])
fun.tag_load()
fun.opt_load()
fun.task_load()

iup.MainLoop()
