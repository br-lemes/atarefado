<form id="main" action=".?action=post&database=<%= html.dbactive %>" method="POST">
	<fieldset>
		<legend>Excluir tag: <%= GET.name %>?</legend>
		<input type="hidden" name="action" value="del_tag">
		<input type="hidden" name="name" value="<%= GET.name %>">
		<input type="hidden" name="id" value="<%= GET.id %>">
		<div class="form-group pull-right">
			<button class="btn" name="cancel">Cancelar</button>
			<button type="submit" class="btn btn-primary">OK</button>
		</div>
	</fieldset>
</form>