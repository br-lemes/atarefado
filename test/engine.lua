
package.path = "../?.lua;" .. package.path

local lfs = require("lfs")
local eng = require("engine")

local dirname  = "database"
local filename = "test.sqlite"
local fullname = "database/test.sqlite"

local function test_directory()
	local mode = lfs.attributes(dirname, "mode")
	assert(mode == "directory", dirname .. " is not a directory")
	if not mode then
		assert(lfs.mkdir(dirname))
	end
end

local function test_database()
	local msg = fullname .. " is not a file"
	local mode = lfs.attributes(fullname, "mode")
	if mode ~= nil then
		assert(mode == "file", msg)
		assert(os.remove(fullname) ~= nil)
	end
	eng.init(filename)
	mode = lfs.attributes(fullname, "mode")
	assert(mode == "file", msg)
end

local function test_hastable()
	local truelist = { "tagnames", "tags", "tasks", "options" }
	local falselist = { "pay", "dress", "sauna", "hook" }
	for _,v in ipairs(truelist) do
		assert(eng.has_table(v), string.format("expected '%s' table not found", v))
	end
	for _,v in ipairs(falselist) do
		assert(not eng.has_table(v), string.format("unexpected '%s' table found", v))
	end
end