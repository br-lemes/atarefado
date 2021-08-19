<?php
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Factory\AppFactory;

require __DIR__ . '/../vendor/autoload.php';

$app = AppFactory::create();

class Engine {
	private $db;
	public $dateformat = 'Y-m-d';
	private $valid_tables = ['options', 'tagnames', 'tags', 'tasks'];

	// create a database if not exists with default values
	public function __construct($dbname) {
		$this->db = new PDO("sqlite:../database/{$dbname}.sqlite");
		$this->db->beginTransaction();

		if (!$this->has_table('tagnames')) {
			$this->db->query('
				CREATE TABLE tagnames (
					id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
					name TEXT NOT NULL
				);');
			foreach (['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'] as $v) {
				$query = $this->db->prepare('INSERT INTO tagnames VALUES(NULL, ?);');
				$query->execute([$v]);
			}
			for ($i = 1; $i <= 31; $i++) {
				$query = $this->db->prepare('INSERT INTO tagnames VALUES(NULL, ?);');
				$query->execute([str_pad($i, 2, "0", STR_PAD_LEFT)]);
			}
		}

		if (!$this->has_table('tags'))
			$this->db->query('
				CREATE TABLE tags (
					task INTEGER NOT NULL,
					tag INTEGER NOT NULL
				);');

		if (!$this->has_table('tasks'))
			$this->db->query('
				CREATE TABLE tasks (
					id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
					name TEXT NOT NULL,
					date TEXT,
					comment TEXT,
					recurrent INTEGER NOT NULL
				);');

		if (!$this->has_table('options')) {
			$this->db->query('
				CREATE TABLE options (
					id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
					name TEXT NOT NULL,
					value TEXT
				);');
			foreach (['anytime', 'tomorrow', 'future', 'today', 'yesterday', 'late'] as $v) {
				$query = $this->db->prepare('INSERT INTO options VALUES(NULL, ?, ?);');
				$query->execute([$v, 'ON']);
			}
			$this->db->query('INSERT INTO options VALUES(NULL, "tag", "1");');
			$this->db->query('INSERT INTO options VALUES(NULL, "version", "1");');
		}

		$this->db->commit();
	}

	// check if database has the given table
	// return: true or false
	public function has_table($table) {
		$query = $this->db->prepare('SELECT * FROM sqlite_master WHERE type="table" AND name=?');
		$query->execute([$table]);
		return $query->fetch(PDO::FETCH_ASSOC) and true or false;
	}

	// check if the given id has in the given table
	// return: true or false
	public function has_id($id, $table) {
		if (!in_array($table, $this->valid_tables)) return false;
		$query = $this->db->prepare("SELECT * FROM {$table} WHERE id=?");
		$query->execute([$id]);
		return $query->fetch(PDO::FETCH_ASSOC) and true or false;
	}

	// check if the given task has the given tag
	// return: true or false
	public function has_tag($task, $tag) {
		$query = $this->db->prepare('SELECT * FROM tags WHERE task=? and tag=?');
		$query->execute([$task, $tag]);
		return $query->fetch(PDO::FETCH_ASSOC) and true or false;
	}

	// check if the given task has no tags
	// return: true or false
	public function has_notags($task) {
		$query = $this->db->prepare('SELECT * FROM tags WHERE task=?');
		$query->execute([$task]);
		foreach ($query->fetchAll(PDO::FETCH_ASSOC) as $row)
			if (intval($row['tag'] > 38)) // ignore the first 38 special tags
				return false;
		return true;
	}

/////////////////////////////////////////////////////////////////////////////////////////
// create a new task
// return: 1 or nil and error message
//function eng.new_task(task)
// create a new tag
// return: 1 or nil and error message
//function eng.new_tag(name)
// remove a task or go to next if it's recurrent
// return: 1 or nil and error message
//function eng.del_task(taskid, force)
// remove the tag from any task and remove the tag
// return: 1 or nil and error message
//function eng.del_tag(tag)
// add to the given task the given tag
// return: 1 or nil and error message
//function eng.set_tag(task, tag)
// remove from the given task the given tag
// return: 1 or nil and error message
//function eng.clear_tag(task, tag)
// update (rename) the given task
// return: 1 or nil and error message
//function eng.upd_task(task)
// update (rename) the given tag
// return: 1 or nil and error message
//function eng.upd_tag(tag, newname)
// put off till next date what should be done today
// return: 1 or nil and error message
//function eng.go_next(taskid)
/////////////////////////////////////////////////////////////////////////////////////////

	// return a table with tasks or from given tag
	public function get_tasks($tag) {
		switch ($tag) {
			case 'all':
				return $this->db->query('SELECT * FROM tasks ORDER BY name')->fetchAll(PDO::FETCH_ASSOC);
			case 'none':
				return $this->db->query('SELECT * FROM tasks WHERE id NOT IN (SELECT task FROM tags WHERE tag > 38) ORDER BY name')->fetchAll(PDO::FETCH_ASSOC);
			default:
				$query = $this->db->prepare('SELECT id, name, date, comment, recurrent FROM tasks LEFT JOIN tags ON id=task WHERE tag=? ORDER BY name');
				$query->execute([$tag]);
				return $query->fetchAll(PDO::FETCH_ASSOC);
		}
	}

	// return a table with the given task
	public function get_task($task) {
		if (!$this->has_id($task, 'tasks'))
			return ['error' => 'Engine: no task'];
		$query = $this->db->prepare('SELECT * FROM tasks WHERE id=?');
		$query->execute([$task]);
		return $query->fetch(PDO::FETCH_ASSOC);
	}

	// return a table with all tags or the task's tags
	public function get_tags($task = 0) {
		if ($task == 0) {
			// ignore the first 38 special tags
			return $this->db->query('SELECT * FROM tagnames WHERE id > 38 ORDER BY name')->fetchAll(PDO::FETCH_ASSOC);
		} else {
			if (!$this->has_id($task, 'tasks'))
				return ['error' => 'Engine: no task'];
			$query = $this->db->prepare('
				SELECT tag, name FROM tags
				JOIN tagnames ON tag=id WHERE task=?
				ORDER BY name');
			$query->execute([$task]);
			return $query->fetchAll(PDO::FETCH_ASSOC);
		}
	}

	// return true if d is an unespecified time
	public function isanytime($d) {
		return !$d or $d == '' or $d == 'anytime';
	}

	// return true if d is tomorrow
	public function istomorrow($d) {
		return floor(
			(strtotime($d) - strtotime(date($this->dateformat)))
			/ (60 * 60 * 24)
		) == 1;
	}

	// return true if d is in the future but not tomorrow
	public function isfuture($d) {
		return floor(
			(strtotime($d) - strtotime(date($this->dateformat)))
			/ (60 * 60 * 24)
		) > 1;
	}

	// return true if d is today
	public function istoday($d) {
		return floor(
			(strtotime($d) - strtotime(date($this->dateformat)))
			/ (60 * 60 * 24)
		) == 0;
	}

	// return true if d is yesterday
	public function isyesterday($d) {
		return floor(
			(strtotime($d) - strtotime(date($this->dateformat)))
			/ (60 * 60 * 24)
		) == -1;
	}

	// return true if d is in the past but not yesterday
	public function islate($d) {
		return floor(
			(strtotime($d) - strtotime(date($this->dateformat)))
			/ (60 * 60 * 24)
		) < -1;
	}

	// return the number of days in a month
	public function daysmonth($month, $year) {
		while ($month > 12) $month -= 12;
		return $month == 2 ?
			($year % 4 ? 28 : ($year % 100 ? 29 : ($year % 400 ? 28 : 29))) :
				(($month - 1) % 7 % 2 ? 30 : 31);
	}

	public function get_options() {
		$result = [];
		foreach ($this->db->query('SELECT * FROM options') as $row)
			$result[$row['name']] = $row['value'];
		return $result;
	}

	public function set_option($option, $value) {
		$query = $this->db->prepare('UPDATE options SET value=? WHERE name=?');
		$query->execute([$value, $option]);
	}

	public function last_insert_rowid() {
		return $this->db->query('SELECT last_insert_rowid()')->fetch()[0];
	}

}

$app->get('/{dbname}/tasks/{id}', function (Request $request, Response $response, $args): Response {
	$eng = new Engine($args['dbname']);
	$response->getBody()->write(json_encode($eng->get_tasks($args['id']), JSON_INVALID_UTF8_SUBSTITUTE));
	return $response->withHeader('Content-type', 'application/json');
});

$app->get('/{dbname}/task/{id}', function (Request $request, Response $response, $args): Response {
	$eng = new Engine($args['dbname']);
	$response->getBody()->write(json_encode($eng->get_task($args['id']), JSON_INVALID_UTF8_SUBSTITUTE));
	return $response->withHeader('Content-type', 'application/json');
});

$app->get('/{dbname}/tags[/{id}]', function (Request $request, Response $response, $args): Response {
	$eng = new Engine($args['dbname']);
	$response->getBody()->write(json_encode($eng->get_tags($args['id']), JSON_INVALID_UTF8_SUBSTITUTE));
	return $response->withHeader('Content-type', 'application/json');
});

$app->get('/{dbname}/options', function (Request $request, Response $response, $args): Response {
	$eng = new Engine($args['dbname']);
	$response->getBody()->write(json_encode($eng->get_options(), JSON_INVALID_UTF8_SUBSTITUTE));
	return $response->withHeader('Content-type', 'application/json');
});

$app->put('/{dbname}/option/{option}/{value}', function (Request $request, Response $response, $args): Response {
	$eng = new Engine($args['dbname']);
	$eng->set_option($args['option'], $args['value']);
	$response->getBody()->write(json_encode($eng->get_options(), JSON_INVALID_UTF8_SUBSTITUTE));
	return $response->withHeader('Content-type', 'application/json');
});

$app->get('/{dbname}/last_insert_rowid', function (Request $request, Response $response, $args): Response {
	$eng = new Engine($args['dbname']);
	$response->getBody()->write(json_encode($eng->last_insert_rowid(), JSON_INVALID_UTF8_SUBSTITUTE));
	return $response->withHeader('Content-type', 'application/json');
});

$app->get('/', function (Request $request, Response $response, $args): Response {
	$eng = new Engine('Breno');
	$response->getBody()->write(json_encode([$eng->islate('2021-08-15') == true]));
	$response->getBody()->write(json_encode([$eng->islate('2021-08-16') == false]));
	$response->getBody()->write(json_encode([$eng->islate('2021-08-17') == false]));
	$response->getBody()->write(json_encode([$eng->islate('2021-08-18') == false]));
	$response->getBody()->write(json_encode([$eng->islate('2021-08-19') == false]));
	// tomorrow, future, today, yesterday, late
	return $response;
});

$app->run();
