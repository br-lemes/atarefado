<?php
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Factory\AppFactory;

require __DIR__ . '/../vendor/autoload.php';

$app = AppFactory::create();

class Engine {
	private $db;
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
		return $query->fetch() and true or false;
	}

	// check if the given id has in the given table
	// return: true or false
	public function has_id($id, $table) {
		if (!in_array($table, $this->valid_tables)) return false;
		$query = $this->db->prepare("SELECT * FROM {$table} WHERE id=?");
		$query->execute([$id]);
		return $query->fetch() and true or false;
	}

	// check if the given task has the given tag
	// return: true or false
	public function has_tag($task, $tag) {
		$query = $this->db->prepare('SELECT * FROM tags WHERE task=? and tag=?');
		$query->execute([$task, $tag]);
		return $query->fetch() and true or false;
	}

	// check if the given task has no tags
	// return: true or false
	public function has_notags($task) {
		$query = $this->db->prepare('SELECT * FROM tags WHERE task=?');
		$query->execute([$task]);
		foreach ($query->fetchAll() as $row)
			if (intval($row['tag'] > 38)) // ignore the first 38 special tags
				return false;
		return true;
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

	public function last_row() {
		return $this->db->query('SELECT last_insert_rowid()')->fetch()[0];
	}

}

$app->get('/{dbname}/options', function (Request $request, Response $response, $args): Response {
	$eng = new Engine($args['dbname']);
	$response->getBody()->write(json_encode($eng->get_options()));
	return $response->withHeader('Content-type', 'application/json');
});

$app->put('/{dbname}/option/{option}/{value}', function (Request $request, Response $response, $args): Response {
	$eng = new Engine($args['dbname']);
	$eng->set_option($args['option'], $args['value']);
	$response->getBody()->write(json_encode($eng->get_options()));
	return $response->withHeader('Content-type', 'application/json');
});

$app->run();
