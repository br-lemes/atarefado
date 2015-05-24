<!DOCTYPE html>
<html lang="pt-BR">
<head>
	<meta charset="UTF-8">
	<title><%= html.dbactive %> - Atarefado 1.4h</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<script src="webapp/js/jquery.min.js"></script>
	<script src="webapp/js/bootstrap.min.js"></script>
	<script src="webapp/js/bootstrap-datepicker.min.js"></script>
	<script src="webapp/js/bootstrap-datepicker.pt-BR.min.js"></script>
	<link href="webapp/css/bootstrap.min.css" rel="stylesheet">
	<link href="webapp/css/bootstrap-datepicker3.min.css" rel="stylesheet">
	<link href="webapp/css/atarefado.css" rel="stylesheet">
	<link href="favicon.png" rel="shortcut icon">
</head>
<body>
	<nav class="navbar navbar-inverse navbar-fixed-top">
		<div class="navbar-header pull-left">
			<a class="navbar-brand" href=".?database=<%= html.dbactive %>">
				<%= html.img("atarefado", 32) %>
				<span class="hidden-xs"><%= html.dbactive %> - Atarefado 1.4h</span>
			</a>
		</div>
		<div class="navbar-header pull-right">
			<% if not GET.action or (
				GET.action ~= "new_task" and GET.action ~= "new_tag" and
				GET.action ~= "del_task" and GET.action ~= "del_tag" and
				GET.action ~= "upd_task" and GET.action ~= "upd_tag"
			) then %>
			<%in webapp/navbtn.lua %>
			<% else %>
				<button class="btn btn-primary navbar-btn" type="submit" form="main">OK</button>
			<% end %>
		</div>
	</nav>
