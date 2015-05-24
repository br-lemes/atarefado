<div class="btn-group">
	<a href="#" class="btn btn-primary navbar-btn dropdown-toggle" data-toggle="dropdown">
		<%= html.img("date", 16) %> <span class="caret"></span>
	</a>
	<ul class="dropdown-menu">
		<li> <div id="date-picker"></div></li>
	</ul>
</div>
<div class="btn-group">
	<a href="#" class="btn btn-primary navbar-btn dropdown-toggle" data-toggle="dropdown">
		<%= html.img("database", 16) %> <span class="caret"></span>
	</a>
	<ul class="dropdown-menu scrollable-menu">
		<% for i, v in ipairs(html.dblist) do %>
		<% local a = "" if html.dblist[i] == html.dbactive then a = "active" end %>
		<li class ="<%= a %>"><a href="?database=<%= v %>"><%= v %></a></li>
		<% end %>
	</ul>
</div>
<div class="btn-group">
	<a href="#" class="btn btn-primary navbar-btn dropdown-toggle" data-toggle="dropdown">
		<%= html.img("anytime", 16) %> <span class="caret"></span>
	</a>
	<ul class="dropdown-menu scrollable-menu pull-right">
		<% for i, v in ipairs(html.duelist) do %>
		<% local a = "" if html.options[v] == "ON" then a = "active" end %>
		<li class="<%= a %>"><a href="?<%= v %>=<%= html.onoff[html.options[v]] %>&database=<%= html.dbactive %>">
			<%= html.img(v, 16) %>&nbsp;<%= html.duename[i] %>
		</a></li>
		<% end %>
	</ul>
</div>
<div class="btn-group">
	<a href="#" class="btn btn-primary navbar-btn dropdown-toggle" data-toggle="dropdown">
		<%= html.img("tags", 16) %> <span class="caret"></span>
	</a>
	<ul class="dropdown-menu scrollable-menu pull-right">
		<% for i, v in ipairs(html.taglist) do %>
		<% local a = "" if i == html.options.tag then a = "active" end %>
		<li class="<%= a %>"><a href="?tag=<%= i %>&database=<%= html.dbactive %>"><%= v.name %></a></li>
		<% end %>
	</ul>
</div>
<script>
	$('#date-picker').datepicker({
		format: "yyyy-mm-dd",
		language: "pt-BR",
		todayHighlight: true
	});
</script>
