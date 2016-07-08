<form action="." class="form-horizontal hidden-print" id="main" method="GET">
<div class="form-group">
	<input type="hidden" name="database" value="<%= html.dbactive %>">
	<input type="hidden" name="action" value="new_task">
	<input type="hidden" name="tagid" value="<%= html.taglist[html.options.tag].id %>">
	<div class="col-xs-10">
		<input id="search" class="form-control" name="name" type="text" autocomplete="off" autofocus>
	</div>
	<div class="col-xs-2">
		<button class="btn btn-default pull-right" type="submit"><%= html.img("note_add", 16) %></button>
	</div>
</div>
</form>
<ul id="tasklist" class="list-group">
<li class="list-group-item active"><%= #html.tasklist %> Tarefas</li>
<% for i, v in pairs(html.tasklist) do %>
	<li class="list-group-item">
		<a href="#" class="dropdown-toggle" data-toggle="dropdown">
			<%= html.img(html.dueicon(v), 16) %>
			<span class="caret"></span>
			<%= v.name %>
		</a>
		<ul class="dropdown-menu">
			<li><a href="?action=new_task&tagid=<%= html.taglist[html.options.tag].id %>&database=<%= html.dbactive %>"><%= html.img("note_add", 16) %> Nova tarefa</a></li>
			<li><a href="?action=upd_task&id=<%= v.id %>&database=<%= html.dbactive %>"><%= html.img("note_edit", 16) %> Editar tarefa</a></li>
			<% if v.recurrent == "1" then %>
				<li><a href="?action=del_task&id=<%= v.id %>&name=<%= v.name %>&database=<%= html.dbactive %>"><%= html.img("note_delete", 16) %> Excluir tarefa</a></li>
			<% else %>
				<li><a href="?action=del_task&id=<%= v.id %>&name=<%= v.name %>&recurrent=<%= v.recurrent %>&database=<%= html.dbactive %>"><%= html.img("note_go", 16) %> Concluir tarefa</a></li>
			<% end %>
			<li class="divider"></li>
			<li><a href="?action=set_date&date=today&id=<%= v.id %>&database=<%= html.dbactive %>"><%= html.img("today", 16) %> Marcar para hoje</a></li>
			<li><a href="?action=set_date&date=tomorrow&id=<%= v.id %>&database=<%= html.dbactive %>"><%= html.img("tomorrow", 16) %> Marcar para amanhã</a></li>
			<li><a href="?action=set_date&date=anytime&id=<%= v.id %>&database=<%= html.dbactive %>"><%= html.img("anytime", 16) %> Deixar para qualquer dia</a></li>
		</ul>
	</li>
<% end %>
</ul>

<script>
$("#search").on("input", function(){
	var r = new RegExp(this.value, "i");
	$("#tasklist > li > a").each(function(i, e) {
		if ($(e).text().match(r))
			e.parentNode.style.display = "block"
		else
			e.parentNode.style.display = "none";
	});
	$("#tasklist > li.active").text($("#tasklist > li > a:visible").length + " Tarefas");
});
</script>
