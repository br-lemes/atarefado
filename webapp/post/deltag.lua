<form action="." class="form-horizontal" id="main" method="POST">
	<fieldset>
		<legend>Excluir tag: <%= GET.name %>?</legend>
		<input type="hidden" name="database" value="<%= html.dbactive %>">
		<input type="hidden" name="action" value="del_tag">
		<input type="hidden" name="name" value="<%= GET.name %>">
		<input type="hidden" name="id" value="<%= GET.id %>">
		<div class=" form-group">
			<div class="col-xs-12">
				<div class="pull-right">
					<button class="btn" name="cancel">Cancelar</button>
					<button type="submit" class="btn btn-primary">OK</button>
				</div>
			</div>
		</div>
	</fieldset>
</form>
