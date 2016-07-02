<ul class="list-group">
<% for i,v in pairs(html.taglist) do %>
<% local a = "" if i == html.options.tag then a = "active" end %>
	<li class="list-group-item <%= a %>">
		<a style="width: 75%" href="?tag=<%= i%>&database=<%= html.dbactive %>">
		<%= v.name %>
		</a>
		<span class="pull-right">
			<% if i > 2 then %>
			<a href="?action=upd_tag&name=<%= v.name %>&id=<%= v.id %>&database=<%= html.dbactive %>" class="btn btn-xs">
				<%= html.img("tag_edit", 16) %>
			</a>
			<a href="?action=del_tag&name=<%= v.name %>&id=<%= v.id %>&database=<%= html.dbactive %>" class="btn btn-xs">
				<%= html.img("tag_delete", 16) %>
			</a>
			<% else %>
			<a href="?action=new_tag&database=<%= html.dbactive %>" class="btn btn-xs">
				<%= html.img("tag_add", 16) %>
			</a>
			<% end %>
		</span>
	</li>
<% end %>
</ul>
