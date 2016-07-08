#!/usr/bin/haserl --shell=lua
Content-type: text/html

<%
lfs  = require("lfs")
eng  = require("engine")
html = require("webapp.html")
%>

<%in webapp/header.lua %>
	<div class="container">
		<div class="row">
			<div class="col-md-7">
				<%= html.alertString %>
				<% if GET.action == "new_task" then %>
					<%in webapp/post/newtask.lua %>
				<% elseif GET.action == "new_tag" then %>
					<%in webapp/post/newtag.lua %>
				<% elseif GET.action == "del_task" then %>
					<%in webapp/post/deltask.lua %>
				<% elseif GET.action == "del_tag" then %>
					<%in webapp/post/deltag.lua %>
				<% elseif GET.action == "upd_task" then %>
					<%in webapp/post/updtask.lua %>
				<% elseif GET.action == "upd_tag" then %>
					<%in webapp/post/updtag.lua %>
				<% else %>
					<%in webapp/tasklist.lua %>
				<% end %>
			</div>
			<div class="col-md-5">
				<%in webapp/taglist.lua %>
				<% html.debugInfo() %>
			</div>
		</div>
		<p>Ícones por <a href="http://www.fatcow.com/free-icons/">FatCow</a>.</p>
	</div>
<%in webapp/footer.lua %>
