<%
	task = eng.get_task(GET.id)
	tags = eng.get_tags(GET.id)
%>
<form action="." class="form-horizontal" id="main" method="POST">
	<fieldset>
		<legend>Nova tarefa</legend>
		<input type="hidden" name="database" value="<%= html.dbactive %>">
		<input type="hidden" name="action" value="upd_task">
		<input type="hidden" name="id" value="<%= task.id %>">
		<div class="form-group">
			<label for="name" class="col-lg-2 control-label">Tarefa</label>
			<div class="col-lg-10">
				<input class="form-control" name="name" type="text" value="<%= task.name %>" autofocus>
			</div>
		</div>
		<div class="form-group">
			<label for="date" class="col-lg-2 control-label">Data</label>
			<div class="col-lg-10">
				<input id="date-picker" class="form-control" type="text" name="date" value="<%= task.date %>" onfocus="blur();">
			</div>
		</div>
		<div class="form-group">
			<label for="comment" class="col-lg-2 control-label">Comentários</label>
			<div class="col-lg-10">
				<textarea class="form-control" rows="7" name="comment"><%= task.comment %></textarea>
			</div>
		</div>
		<div class="form-group">
			<label for="tags" class="col-lg-2 control-label">Tags</label>
			<div class="col-lg-10">
				<select class="form-control" name="tags[]" size="7" multiple>
				<% for i, v in ipairs(html.taglist) do  if i > 2 then %>
					<option value="<%= v.id%>" <% if tags[v.id] then %>selected<% end %>><%= v.name %></option>
				<% end end %>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label for="recurrent" class="col-lg-2 control-label">Recorrente</label>
			<div class="col-lg-10">
				<select class="form-control" name="recurrent">
					<option value="1" <% if task.recurrent == "1" then %>selected<% end %>>Não</option>
					<option value="2" <% if task.recurrent == "2" then %>selected<% end %>>Semanal</option>
					<option value="3" <% if task.recurrent == "3" then %>selected<% end %>>Mensal</option>
					<option value="4" <% if task.recurrent == "4" then %>selected<% end %>>Último dia</option>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label for="rweek" class="col-lg-2 control-label">Semanal</label>
			<div class="col-lg-10">
				<select class="form-control" name="rweek[]" size="7" multiple>
					<option value="1" <% if tags[1] then %>selected<% end %>>Domingo</option>
					<option value="2" <% if tags[2] then %>selected<% end %>>Segunda-feira</option>
					<option value="3" <% if tags[3] then %>selected<% end %>>Terça-feira</option>
					<option value="4" <% if tags[4] then %>selected<% end %>>Quarta-feira</option>
					<option value="5" <% if tags[5] then %>selected<% end %>>Quinta-feira</option>
					<option value="6" <% if tags[6] then %>selected<% end %>>Sexta-feira</option>
					<option value="7" <% if tags[7] then %>selected<% end %>>Sábado</option>
				</select>
			</div>
		</div>
		<div class="form-group">
			<label for="rmonth" class="col-lg-2 control-label">Mensal</label>
			<div class="col-lg-10">
				<select class="form-control" name="rmonth[]" size="7" multiple>
				<% for i = 1, 31 do %>
					<option value="<%= i + 7 %>" <% if tags[i + 7] then %>selected<% end %>><%= i %></option>
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
