class_name AssetResourceManager
extends RefCounted

# アセットリソース管理システム
# 背景・キャラクター画像の読み込み、フォールバック処理、プレースホルダー生成

# アセットタイプ
enum AssetType {
	BACKGROUND,
	CHARACTER,
	EFFECT,
	UI
}

# 基本パス設定
const ASSET_PATHS = {
	AssetType.BACKGROUND: "res://Assets/images/backgrounds/",
	AssetType.CHARACTER: "res://Assets/images/characters/",
	AssetType.EFFECT: "res://Assets/images/effects/",
	AssetType.UI: "res://Assets/images/ui/"
}

# 対応拡張子
const SUPPORTED_EXTENSIONS = [".png", ".jpg", ".jpeg", ".webp"]

# フォールバック色設定
const FALLBACK_COLORS = {
	AssetType.BACKGROUND: Color.DARK_SLATE_GRAY,
	AssetType.CHARACTER: Color.LIGHT_GRAY,
	AssetType.EFFECT: Color.WHITE,
	AssetType.UI: Color.GRAY
}

# キャッシュシステム
var texture_cache: Dictionary = {}
var fallback_texture_cache: Dictionary = {}

func get_background_texture(background_name: String) -> Dictionary:
	"""背景テクスチャを取得
	Returns: {"texture": Texture2D, "is_fallback": bool, "source_path": String}
	"""
	return get_asset_texture(AssetType.BACKGROUND, background_name)

func get_character_texture(character_name: String, face_expression: String = "normal") -> Dictionary:
	"""キャラクターテクスチャを取得
	Returns: {"texture": Texture2D, "is_fallback": bool, "source_path": String}
	"""
	var full_name = "%s_%s" % [character_name.to_lower(), face_expression]
	return get_asset_texture(AssetType.CHARACTER, full_name)

func get_asset_texture(asset_type: AssetType, asset_name: String) -> Dictionary:
	"""汎用アセットテクスチャ取得"""
	var result = {
		"texture": null,
		"is_fallback": false,
		"source_path": "",
		"error_message": ""
	}
	
	# キャッシュチェック
	var cache_key = "%d_%s" % [asset_type, asset_name]
	if texture_cache.has(cache_key):
		var cached_result = texture_cache[cache_key]
		print("AssetResourceManager: キャッシュから取得 - %s" % cache_key)
		return cached_result
	
	# 実際のファイルパスを解決
	var file_path = _resolve_asset_path(asset_type, asset_name)
	
	if not file_path.is_empty():
		# ファイルが存在する場合、読み込み試行
		var texture = _load_texture_safely(file_path)
		if texture:
			result.texture = texture
			result.source_path = file_path
			result.is_fallback = false
			texture_cache[cache_key] = result
			print("AssetResourceManager: 読み込み成功 - %s" % file_path)
			return result
	
	# フォールバックテクスチャ生成
	result = _generate_fallback_texture(asset_type, asset_name, cache_key)
	texture_cache[cache_key] = result
	
	return result

func _resolve_asset_path(asset_type: AssetType, asset_name: String) -> String:
	"""アセットファイルパスを解決"""
	var base_path = ASSET_PATHS[asset_type]
	
	# 拡張子を含まない場合、各拡張子を試行
	if not _has_extension(asset_name):
		for ext in SUPPORTED_EXTENSIONS:
			var full_path = base_path + asset_name + ext
			if ResourceLoader.exists(full_path):
				return full_path
			# プレースホルダーファイルのチェック
			var placeholder_path = full_path + ".placeholder"
			if FileAccess.file_exists(placeholder_path):
				print("プレースホルダー発見: %s" % placeholder_path)
				# プレースホルダーの場合は空文字を返し、フォールバック処理させる
				return ""
	else:
		# 拡張子付きの場合、そのまま確認
		var full_path = base_path + asset_name
		if ResourceLoader.exists(full_path):
			return full_path
	
	print("AssetResourceManager: ファイルが見つかりません - %s%s" % [base_path, asset_name])
	return ""

func _has_extension(filename: String) -> bool:
	"""ファイル名に拡張子が含まれているかチェック"""
	for ext in SUPPORTED_EXTENSIONS:
		if filename.ends_with(ext):
			return true
	return false

func _load_texture_safely(file_path: String) -> Texture2D:
	"""安全なテクスチャ読み込み"""
	if not ResourceLoader.exists(file_path):
		return null
	
	var resource = ResourceLoader.load(file_path)
	if resource is Texture2D:
		return resource as Texture2D
	else:
		print("警告: %s はTexture2Dではありません" % file_path)
		return null

func _generate_fallback_texture(asset_type: AssetType, asset_name: String, cache_key: String) -> Dictionary:
	"""フォールバックテクスチャを生成"""
	var result = {
		"texture": null,
		"is_fallback": true,
		"source_path": "generated_fallback",
		"error_message": "Asset not found: %s" % asset_name
	}
	
	# フォールバックテクスチャキャッシュチェック
	if fallback_texture_cache.has(cache_key):
		result.texture = fallback_texture_cache[cache_key]
		return result
	
	# 動的にフォールバックテクスチャを生成
	var fallback_texture = _create_colored_texture(asset_type, asset_name)
	fallback_texture_cache[cache_key] = fallback_texture
	result.texture = fallback_texture
	
	print("AssetResourceManager: フォールバック生成 - %s" % asset_name)
	return result

func _create_colored_texture(asset_type: AssetType, asset_name: String) -> ImageTexture:
	"""色付きフォールバックテクスチャを作成"""
	var size = _get_default_size_for_type(asset_type)
	var color = FALLBACK_COLORS.get(asset_type, Color.GRAY)
	
	# Image作成
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	image.fill(color)
	
	# テキスト描画（アセット名）
	_draw_text_on_image(image, asset_name, size)
	
	# ImageTextureに変換
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	return texture

func _get_default_size_for_type(asset_type: AssetType) -> Vector2i:
	"""アセットタイプに応じたデフォルトサイズを取得"""
	match asset_type:
		AssetType.BACKGROUND:
			return Vector2i(1024, 576)  # 16:9 HD解像度
		AssetType.CHARACTER:
			return Vector2i(512, 1024)  # 立ち絵用縦長
		AssetType.EFFECT:
			return Vector2i(256, 256)   # エフェクト用正方形
		AssetType.UI:
			return Vector2i(128, 128)   # UI要素用小サイズ
		_:
			return Vector2i(256, 256)

func _draw_text_on_image(image: Image, text: String, size: Vector2i):
	"""画像にテキストを描画（簡易実装）"""
	# Godot 4では画像への直接テキスト描画が制限されているため
	# 簡易的な実装として中央に点を描画
	var center_x = size.x / 2
	var center_y = size.y / 2
	
	# 中央に小さな十字を描画してプレースホルダーを示す
	for i in range(-10, 11):
		if center_x + i >= 0 and center_x + i < size.x:
			image.set_pixel(center_x + i, center_y, Color.WHITE)
	for i in range(-10, 11):
		if center_y + i >= 0 and center_y + i < size.y:
			image.set_pixel(center_x, center_y + i, Color.WHITE)

# キャッシュ管理

func clear_cache():
	"""キャッシュをクリア"""
	texture_cache.clear()
	fallback_texture_cache.clear()
	print("AssetResourceManager: キャッシュクリア完了")

func get_cache_info() -> Dictionary:
	"""キャッシュ情報を取得"""
	return {
		"texture_cache_size": texture_cache.size(),
		"fallback_cache_size": fallback_texture_cache.size(),
		"total_cache_entries": texture_cache.size() + fallback_texture_cache.size()
	}

# プリロード機能

func preload_common_assets():
	"""よく使用されるアセットをプリロード"""
	print("AssetResourceManager: 共通アセットのプリロード開始")
	
	# 共通背景
	var common_backgrounds = ["forest_day", "ruins_entrance", "ruins_interior"]
	for bg_name in common_backgrounds:
		get_background_texture(bg_name)
	
	# 共通キャラクター
	var common_characters = [
		{"name": "souma", "faces": ["normal", "surprised", "happy"]},
		{"name": "yuzuki", "faces": ["normal", "smile", "worried"]}
	]
	for char_data in common_characters:
		for face in char_data.faces:
			get_character_texture(char_data.name, face)
	
	print("AssetResourceManager: プリロード完了")

# デバッグ機能

func debug_print_cache():
	"""キャッシュ内容をデバッグ出力"""
	print("=== テクスチャキャッシュ ===")
	for key in texture_cache.keys():
		var entry = texture_cache[key]
		print("  %s: %s (fallback: %s)" % [key, entry.source_path, entry.is_fallback])
	
	print("=== フォールバックキャッシュ ===")
	for key in fallback_texture_cache.keys():
		print("  %s: generated" % key)

func test_asset_loading():
	"""アセット読み込みテスト"""
	print("=== アセット読み込みテスト ===")
	
	# 背景テスト
	var test_backgrounds = ["forest_day", "nonexistent_bg"]
	for bg_name in test_backgrounds:
		var result = get_background_texture(bg_name)
		print("背景 %s: %s (fallback: %s)" % [bg_name, 
			"成功" if result.texture else "失敗", 
			result.is_fallback])
	
	# キャラクターテスト
	var test_characters = [
		{"name": "souma", "face": "normal"},
		{"name": "nonexistent", "face": "normal"}
	]
	for char_data in test_characters:
		var result = get_character_texture(char_data.name, char_data.face)
		print("キャラクター %s_%s: %s (fallback: %s)" % [char_data.name, char_data.face,
			"成功" if result.texture else "失敗",
			result.is_fallback])
	
	print("テスト完了")

# 静的インスタンス（シングルトン的使用）
static var _instance: AssetResourceManager = null

static func get_instance() -> AssetResourceManager:
	"""シングルトンインスタンスを取得"""
	if _instance == null:
		_instance = AssetResourceManager.new()
	return _instance