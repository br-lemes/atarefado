<form id="main" action=".?action=post&database=<%= html.dbactive %>" method="POST">
	<fieldset>
		<legend>Nova tag</legend>
		<input type="hidden" name="action" value="new_tag">
		<div class="form-group">
			<input class="form-control" type="text" name="name" autofocus>
		</div>
		<div class="form-group pull-right">
			<button class="btn" name="cancel">Cancelar</button>
			<button type="submit" class="btn btn-primary">OK</button>
		</div>
	</fieldset>
</form>
