
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

local function test_hasid()
	local expected = "expected id number '%d' not found in table '%s'"
	local unexpected = "unexpected id number '%d' found in table '%s'"
	local list = { tagnames = 38, tags = 0, tasks = 0, options = 8 }
	for k,v in pairs(list) do
		if v == 0 then
			assert(not eng.has_id(1, k), string.format(unexpected, 1, k))
		else
			for i = 1, v do
				assert(eng.has_id(i, k), string.format(expected, i, k))
			end
			assert(not eng.has_id(v + 1, k), string.format(unexpected, v + 1, k))
		end
	end
end

local function test_isdate()
	assert(not eng.isdate('2020-00-01'), "accepting invalid date")
	assert(eng.isdate('2020-01-01'), "not accepting valid date")
	assert(not eng.isdate('01-01-2020'), "accepting invalid format")
end

local function test_isanytime()
	assert(eng.isanytime(), "not accepting nil")
	assert(eng.isanytime(""), "not accepting empty string")
	assert(eng.isanytime("anytime"), "not accepting 'anytime'")
	assert(not eng.isanytime(true), "accepting 'true'")
end

local accept = {
	late = "accepting late (before yesterday)",
	yesterday = "accepting yesterday",
	today = "accepting today",
	tomorrow = "accepting tomorrow",
	future = "accepting future (after tomorrow)"
}

local reject = {
	late = "not " .. accept.late,
	yesterday = "not " .. accept.yesterday,
	today = "not " .. accept.today,
	tomorrow = "not " .. accept.tomorrow,
	future = "not " .. accept.future
}

local today     = os.time() -- WARNING: the test may fail if it's 23:59:59
local late      = today - (24 * 60 * 60) * 2
local yesterday = today -  24 * 60 * 60
local tomorrow  = today +  24 * 60 * 60
local future    = today + (24 * 60 * 60) * 2

local function test_istomorrow()
	local test = eng.istomorrow
	assert(not test(os.date(eng.dateformat,      late)), accept.late)
	assert(not test(os.date(eng.dateformat, yesterday)), accept.yesterday)
	assert(not test(os.date(eng.dateformat,     today)), accept.today)
	assert(test(os.date(eng.dateformat,      tomorrow)), reject.tomorrow)
	assert(not test(os.date(eng.dateformat,    future)), accept.future)
end

local function test_isfuture()
	local test = eng.isfuture
	assert(not test(os.date(eng.dateformat,      late)), accept.late)
	assert(not test(os.date(eng.dateformat, yesterday)), accept.yesterday)
	assert(not test(os.date(eng.dateformat,     today)), accept.today)
	assert(not test(os.date(eng.dateformat,  tomorrow)), accept.tomorrow)
	assert(test(os.date(eng.dateformat,        future)), reject.future)
end

local function test_istoday()
	local test = eng.istoday
	assert(not test(os.date(eng.dateformat,      late)), accept.late)
	assert(not test(os.date(eng.dateformat, yesterday)), accept.yesterday)
	assert(test(os.date(eng.dateformat,         today)), reject.today)
	assert(not test(os.date(eng.dateformat,  tomorrow)), accept.tomorrow)
	assert(not test(os.date(eng.dateformat,    future)), accept.future)
end

local function test_isyesterday()
	local test = eng.isyesterday
	assert(not test(os.date(eng.dateformat,      late)), accept.late)
	assert(test(os.date(eng.dateformat,     yesterday)), reject.yesterday)
	assert(not test(os.date(eng.dateformat,     today)), accept.today)
	assert(not test(os.date(eng.dateformat,  tomorrow)), accept.tomorrow)
	assert(not test(os.date(eng.dateformat,    future)), accept.future)
end

local function test_islate()
	local test = eng.islate
	assert(test(os.date(eng.dateformat,          late)), reject.late)
	assert(not test(os.date(eng.dateformat, yesterday)), accept.yesterday)
	assert(not test(os.date(eng.dateformat,     today)), accept.today)
	assert(not test(os.date(eng.dateformat,  tomorrow)), accept.tomorrow)
	assert(not test(os.date(eng.dateformat,    future)), accept.future)
end

local function test_daysmonth()
	for i, v in pairs{ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 } do
		assert(eng.daysmonth(i, 2020) == v, string.format("wrong result for 2020-%02d", i))
	end
	assert(eng.daysmonth(2, 2019) == 28, "wrong result for 2019-02")
end

local function test_getoptions()
	local o = eng.get_options()
	for i, v in pairs{ "anytime", "tomorrow", "future", "today", "yesterday", "late" } do
		assert(o[v] == "ON", v .. " ~= 'ON'")
	end
	assert(o.tag == "1", "tag ~= '1'")
end

local function test_setoption()
	local o = eng.get_options()
	assert(o.tomorrow == "ON", "tomorrow ~= 'ON'")
	assert(eng.set_option("tomorrow", "NO"))
	o = eng.get_options()
	assert(o.tomorrow == "NO", "tomorrow ~= 'NO'")
end

local function test_lastrow()
	assert(eng.last_row() == 8, "eng.last_row() ~= 8")
end

local function test_task()
	local r, e = eng.get_task(1)
	assert(not r, e)
	r, e = eng.new_task()
	assert(not r, e)
	r, e = eng.new_task{ name = "test" }
	assert(r == 1, e)
	r, e = eng.get_task(1)
	assert(r, e)
	assert(r.name == "test", "unexpected task")
end

local function test_tag()
	assert(not eng.has_tag(1, 1), "has_tag: unexpected tag")
	assert(eng.has_notags(1), "has_notags: unexpected tag")
	assert(not eng.set_tag(1, 101), "set_tag: accepting invalid tag")
	assert(eng.set_tag(1, 1))
	assert(not eng.set_tag(1, 1), "set_tag: accepting already tagged")
	assert(eng.has_tag(1, 1), "has_tag: tag not set")
	assert(not eng.clear_tag(1, 101), "clear_tag: accepting invalid tag")
	assert(eng.clear_tag(1, 1))
	assert(not eng.has_tag(1, 1), "has_tag: tag not cleared")
end

local function count_tag(task)
	local tags = eng.get_tags(task)
	local count = 0
	for _ in pairs(tags) do count = count + 1 end
	return count
end

local function test_moretag()
	assert(eng.new_tag("test"))
	local tags = eng.get_tags()
	assert(type(tags) == "table", "tags is not a table")
	assert(#tags == 1, "unexpected number of tags")
	assert(tags[1].name == "test", "unexpected tag")
	local r, e = eng.upd_tag(39, "#test")
	assert(r == 1, e) -- FIX Engine: error when tag not found
	tags = eng.get_tags(1)
	assert(#tags == 0, "unexpected tag for task 1")
	assert(eng.set_tag(1, 39))
	assert(eng.get_tags(1)[39] == "#test", "unexpected tag")
	assert(count_tag(1) == 1, "unexpected number of tags")
	r, e = eng.del_tag(39)
	assert(r == 1, e)
	assert(count_tag(1) == 0, "unexpected number of tags")
end

local function test_moretask()
	assert(eng.get_task(1).recurrent == "1", "unexpected value")
	local r, e = eng.upd_task{id = 1, recurrent = 2, date = "2020-01-01"}
	assert(r, e)
	assert(eng.get_task(1).recurrent == "2", "unexpected value")
	assert(eng.set_tag(1, 1))
	r, e = eng.go_next(1)
	assert(r, e)
	assert(eng.get_task(1).date == "2020-01-05", "unexpected date")
	r, e = eng.go_next(1)
	assert(r, e)
	assert(eng.get_task(1).date == "2020-01-12", "unexpected date")
	assert(eng.clear_tag(1, 1))
	assert(eng.set_tag(1, 1 + 7))
	r, e = eng.upd_task{id = 1, recurrent = 3}
	assert(r, e)
	r, e = eng.go_next(1)
	assert(r, e)
	assert(eng.get_task(1).date == "2020-02-01", "unexpected date")
	assert(eng.clear_tag(1, 1 + 7))
	r, e = eng.upd_task{id = 1, recurrent = 4}
	assert(r, e)
	r, e = eng.go_next(1)
	assert(r, e)
	assert(eng.get_task(1).date == "2020-02-29", "unexpected date")
	r, e = eng.del_task(1, true)
	assert(r, e)
	assert(not eng.get_task(1), "unexpected task")
end

-- TODO gettasks
