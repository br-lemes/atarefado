<form action="." class="form-horizontal" id="main" method="POST">
	<fieldset>
		<% if not GET.recurrent then %>
			<legend>Excluir tarefa: <%= GET.name %>?</legend>
		<% else %>
			<legend>Concluir tarefa: <%= GET.name %>?</legend>
		<% end %>
		<input type="hidden" name="database" value="<%= html.dbactive %>">
		<input type="hidden" name="action" value="del_task">
		<input type="hidden" name="name" value="<%= GET.name %>">
		<input type="hidden" name="id" value="<%= GET.id %>">
		<div class="form-group pull-right">
			<button class="btn" name="cancel">Cancelar</button>
			<% if GET.recurrent then %>
				<input type="hidden" name="recurrent" value="<%= GET.recurrent %>">
				<button class="btn btn-danger" name="force">Excluir</button>
			<% end %>
			<button type="submit" class="btn btn-primary">OK</button>
		</div>
	</fieldset>
</form>
