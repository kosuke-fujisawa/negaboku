class_name MarkdownParser
extends RefCounted


# パーサー結果のデータ構造
class ParsedElement:
	enum Type { COMMAND, TEXT, SPEAKER, SEPARATOR }  # [bg storage=xxx] 等のコマンド  # テキスト内容  # **スピーカー名**「セリフ」  # --- セパレーター

	var type: Type
	var content: String = ""
	var speaker: String = ""
	var parameters: Dictionary = {}

	func _init(
		p_type: Type, p_content: String = "", p_speaker: String = "", p_params: Dictionary = {}
	):
		type = p_type
		content = p_content
		speaker = p_speaker
		parameters = p_params.duplicate()


# 正規表現パターン
var command_regex: RegEx
var speaker_text_regex: RegEx
var separator_regex: RegEx


func _init():
	_compile_regex_patterns()


func _compile_regex_patterns():
	# 正規表現パターンをコンパイル#
	# コマンドパターン: [bg storage=forest.jpg time=500]
	command_regex = RegEx.new()
	command_regex.compile(r"\[([a-zA-Z_]+)([^\]]*)\]")

	# スピーカーテキストパターン: **ソウマ**「こんにちは」
	speaker_text_regex = RegEx.new()
	speaker_text_regex.compile(r"\*\*([^*]+)\*\*[「『]([^」』]+)[」』]")

	# セパレーターパターン: ---
	separator_regex = RegEx.new()
	separator_regex.compile(r"^---+\s*$")


func parse_markdown_file(file_path: String) -> Array:
	# マークダウンファイルを解析してParsedElementの配列を返す#
	var elements: Array = []

	# ファイル読み込み
	var file_content = _read_file_safely(file_path)
	if file_content.is_empty():
		print("エラー: ファイル読み込み失敗またはファイルが空: %s" % file_path)
		return elements

	# 行ごとに解析
	var lines = file_content.split("\n")
	for line_number in range(lines.size()):
		var line = lines[line_number].strip_edges()

		# 空行をスキップ
		if line.is_empty():
			continue

		# 見出し行をスキップ（# で始まる行）
		if line.begins_with("#"):
			continue

		# セパレーター検出
		if separator_regex.search(line):
			elements.append(ParsedElement.new(ParsedElement.Type.SEPARATOR))
			continue

		# コマンド検出
		var command_element = _parse_command_line(line)
		if command_element:
			elements.append(command_element)
			continue

		# スピーカーテキスト検出
		var speaker_element = _parse_speaker_text(line)
		if speaker_element:
			elements.append(speaker_element)
			continue

		# 通常テキスト
		if not line.is_empty():
			elements.append(ParsedElement.new(ParsedElement.Type.TEXT, line))

	print("マークダウン解析完了: %d要素を解析" % elements.size())
	return elements


func _read_file_safely(file_path: String) -> String:
	# 安全なファイル読み込み（開発時は常に最新を読み込み）#
	# パス検証
	if not file_path.begins_with("res://") and not file_path.begins_with("user://"):
		print("エラー: 不正なファイルパス形式: %s" % file_path)
		return ""

	# ファイル存在チェック
	if not FileAccess.file_exists(file_path):
		print("エラー: ファイルが存在しません: %s" % file_path)
		return ""

	# ファイル読み込み（開発時は常に最新ファイルを読み込む）
	print("MarkdownParser: ファイル読み込み - %s" % file_path)
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("エラー: ファイルを開けません: %s" % file_path)
		return ""

	var content = file.get_as_text()
	file.close()

	# エンコーディング確認（UTF-8前提）
	if content.is_empty():
		print("警告: ファイルが空です: %s" % file_path)
	else:
		print("MarkdownParser: ファイル読み込み成功 - %d文字" % content.length())

	return content


func _parse_command_line(line: String) -> ParsedElement:
	# コマンド行を解析#
	var result = command_regex.search(line)
	if not result:
		return null

	var command_name = result.get_string(1)
	var params_string = result.get_string(2)

	# パラメータ解析
	var parameters = _parse_command_parameters(params_string)

	return ParsedElement.new(ParsedElement.Type.COMMAND, command_name, "", parameters)


func _parse_command_parameters(params_string: String) -> Dictionary:
	# コマンドパラメータを解析 (key=value形式)#
	var parameters = {}

	# パラメータ文字列をクリーンアップ
	var cleaned_params = params_string.strip_edges()
	if cleaned_params.is_empty():
		return parameters

	# key=value パターンの正規表現
	var param_regex = RegEx.new()
	param_regex.compile(r"([a-zA-Z_]+)\s*=\s*([^\s]+)")

	var results = param_regex.search_all(cleaned_params)
	for result in results:
		var key = result.get_string(1)
		var value = result.get_string(2)

		# 値のクォート除去
		if value.begins_with('"') and value.ends_with('"'):
			value = value.substr(1, value.length() - 2)
		elif value.begins_with("'") and value.ends_with("'"):
			value = value.substr(1, value.length() - 2)

		parameters[key] = value

	return parameters


func _parse_speaker_text(line: String) -> ParsedElement:
	# スピーカーテキスト行を解析#
	var result = speaker_text_regex.search(line)
	if not result:
		return null

	var speaker_name = result.get_string(1)
	var text_content = result.get_string(2)

	return ParsedElement.new(ParsedElement.Type.SPEAKER, text_content, speaker_name)


func get_commands_by_type(elements: Array, command_type: String) -> Array:
	# 指定されたコマンドタイプの要素を取得#
	var filtered_elements: Array = []

	for element in elements:
		if element.type == ParsedElement.Type.COMMAND and element.content == command_type:
			filtered_elements.append(element)

	return filtered_elements


func get_text_elements(elements: Array) -> Array:
	# テキスト要素（SPEAKER + TEXT）を取得#
	var text_elements: Array = []

	for element in elements:
		if element.type == ParsedElement.Type.SPEAKER or element.type == ParsedElement.Type.TEXT:
			text_elements.append(element)

	return text_elements


func validate_syntax(elements: Array) -> Dictionary:
	# マークダウン構文の検証#
	var validation_result = {"is_valid": true, "errors": [], "warnings": []}

	for i in range(elements.size()):
		var element = elements[i]

		# コマンド検証
		if element.type == ParsedElement.Type.COMMAND:
			_validate_command(element, validation_result)

	# 結果まとめ
	validation_result.is_valid = validation_result.errors.size() == 0

	return validation_result


func _validate_command(element: ParsedElement, validation_result: Dictionary):
	# 個別コマンドの検証#
	match element.content:
		"bg":
			if not element.parameters.has("storage"):
				validation_result.errors.append("bgコマンドにstorageパラメータが必要です")
		"chara_show":
			if not element.parameters.has("name"):
				validation_result.errors.append("chara_showコマンドにnameパラメータが必要です")
			if not element.parameters.has("pos"):
				validation_result.warnings.append("chara_showコマンドにposパラメータが推奨されます")
		"chara_hide":
			if not element.parameters.has("name"):
				validation_result.errors.append("chara_hideコマンドにnameパラメータが必要です")
		"wait":
			if not element.parameters.has("time"):
				validation_result.errors.append("waitコマンドにtimeパラメータが必要です")
		_:
			validation_result.warnings.append("未知のコマンド: %s" % element.content)


# デバッグ・テスト用ユーティリティ
func print_parsed_elements(elements: Array):
	# 解析結果をデバッグ出力#
	print("=== 解析結果 (%d要素) ===" % elements.size())

	for i in range(elements.size()):
		var element = elements[i]
		var type_name = _get_type_name(element.type)

		match element.type:
			ParsedElement.Type.COMMAND:
				print("[%d] %s: %s (%s)" % [i, type_name, element.content, element.parameters])
			ParsedElement.Type.SPEAKER:
				print("[%d] %s: %s「%s」" % [i, type_name, element.speaker, element.content])
			ParsedElement.Type.TEXT:
				print("[%d] %s: %s" % [i, type_name, element.content])
			ParsedElement.Type.SEPARATOR:
				print("[%d] %s" % [i, type_name])


func _get_type_name(type: ParsedElement.Type) -> String:
	# タイプ名を文字列で取得#
	match type:
		ParsedElement.Type.COMMAND:
			return "COMMAND"
		ParsedElement.Type.TEXT:
			return "TEXT"
		ParsedElement.Type.SPEAKER:
			return "SPEAKER"
		ParsedElement.Type.SEPARATOR:
			return "SEPARATOR"
		_:
			return "UNKNOWN"
