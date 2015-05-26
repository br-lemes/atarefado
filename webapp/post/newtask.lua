<form action="." class="form-horizontal" id="main" method="POST">
	<fieldset>
		<legend>Nova tarefa</legend>
		<input type="hidden" name="database" value="<%= html.dbactive %>">
		<input type="hidden" name="action" value="new_task">
		<div class="form-group">
			<label for="name" class="col-lg-2 control-label">Tarefa</label>
			<div class="col-lg-10">
				<input class="form-control" name="name" type="text" value="<%= GET.name or '' %>" autofocus>
			</div>
		</div>
		<div class="form-group">
			<label for="date" class="col-lg-2 control-label">Data</label>
			<div class="col-lg-10">
				<input id="date-picker" class="form-control" type="text" name="date" onfocus="blur();">
			</div>
		</div>
		<div class="form-group">
			<label for="comment" class="col-lg-2 control-label">Comentários</label>
			<div class="col-lg-10">
				<textarea class="form-control" rows="7" name="comment"></textarea>
			</div>
		</div>
		<div class="form-group">
			<label for="tags" class="col-lg-2 control-label">Tags</label>
			<div class="col-lg-10">
				<select class="form-control" name="tags[]" size="7" multiple>
				<% for i, v in ipairs(html.taglist) do  if i > 2 then %>
					<option value="<%= v.id%>" <% if tonumber(GET.tagid) == v.id then %>selected<% end %>><%= v.name %></option>
				<% end end %>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label for="recurrent" class="col-lg-2 control-label">Recorrente</label>
			<div class="col-lg-10">
				<select class="form-control" name="recurrent">
					<option value="1">Não</option>
					<option value="2">Semanal</option>
					<option value="3">Mensal</option>
					<option value="4">Último dia</option>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label for="rweek" class="col-lg-2 control-label">Semanal</label>
			<div class="col-lg-10">
				<select class="form-control" name="rweek[]" size="7" multiple>
					<option value="1">Domingo</option>
					<option value="2">Segunda-feira</option>
					<option value="3">Terça-feira</option>
					<option value="4">Quarta-feira</option>
					<option value="5">Quinta-feira</option>
					<option value="6">Sexta-feira</option>
					<option value="7">Sábado</option>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label for="rmonth" class="col-lg-2 control-label">Mensal</label>
			<div class="col-lg-10">
				<select class="form-control" name="rmonth[]" size="7" multiple>
				<% for i = 1, 31 do %>
					<option value="<%= i + 7 %>"><%= i %></option>
				<% end %>
				</select>
			</div>
		</div>
		<div class="form-group">
			<div class="col-lg-12">
				<div class="pull-right">
					<button class="btn" name="cancel">Cancelar</button>
					<button class="btn btn-primary" type="submit">OK</button>
				</div>
			</div>
		</div>
	</fieldset>
</form>
<script>
	$('#date-picker').datepicker({
		format: "yyyy-mm-dd",
		language: "pt-BR",
		todayHighlight: true
	});
</script>
