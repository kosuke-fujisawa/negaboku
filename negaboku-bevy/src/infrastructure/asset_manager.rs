//! アセット管理インフラストラクチャ
//!
//! ゲームで使用するアセット（画像・音楽・フォント等）の読み込み・管理を行う

use bevy::prelude::*;
use std::collections::HashMap;

/// アセットの種類
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum AssetType {
    Font,
    BackgroundImage,
    CharacterImage,
    UIImage,
    Sound,
    Music,
}

/// アセット状態
#[derive(Debug, Clone, PartialEq)]
pub enum AssetStatus {
    NotLoaded,
    Loading,
    Loaded,
    Failed(String),
}

/// アセット情報
#[derive(Debug, Clone)]
pub struct AssetInfo {
    pub path: String,
    pub asset_type: AssetType,
    pub status: AssetStatus,
    pub handle: Option<UntypedHandle>,
}

/// アセットマネージャー（Bevy Resource）
#[derive(Resource, Debug)]
pub struct AssetManager {
    assets: HashMap<String, AssetInfo>,
    pub asset_server: Option<Res<'static, AssetServer>>,
}

impl AssetManager {
    pub fn new() -> Self {
        Self {
            assets: HashMap::new(),
            asset_server: None,
        }
    }

    /// アセットを登録
    pub fn register_asset(&mut self, id: &str, path: &str, asset_type: AssetType) {
        let asset_info = AssetInfo {
            path: path.to_string(),
            asset_type,
            status: AssetStatus::NotLoaded,
            handle: None,
        };

        self.assets.insert(id.to_string(), asset_info);
        info!("アセット登録: {} -> {}", id, path);
    }

    /// 標準アセットの一括登録
    pub fn register_default_assets(&mut self) {
        // フォント
        self.register_asset(
            "main_font",
            "fonts/NotoSansJP-VariableFont_wght.ttf",
            AssetType::Font
        );

        // 背景画像
        self.register_asset(
            "bg_souma_home",
            "images/backgrounds/souma_home.png",
            AssetType::BackgroundImage
        );
        self.register_asset(
            "bg_school",
            "images/backgrounds/school.png",
            AssetType::BackgroundImage
        );
        self.register_asset(
            "bg_forest",
            "images/backgrounds/forest.png",
            AssetType::BackgroundImage
        );

        // キャラクター画像
        self.register_asset(
            "char_souma",
            "images/characters/01_souma_kari.png",
            AssetType::CharacterImage
        );
        self.register_asset(
            "char_yuzuki",
            "images/characters/02_yuzuki_kari.png",
            AssetType::CharacterImage
        );
        self.register_asset(
            "char_retsuji",
            "images/characters/03_retsuji_kari.png",
            AssetType::CharacterImage
        );
        self.register_asset(
            "char_kai",
            "images/characters/04_kai_kari.png",
            AssetType::CharacterImage
        );

        // BGM
        self.register_asset(
            "bgm_title",
            "sounds/bgm/title.ogg",
            AssetType::Music
        );
        self.register_asset(
            "bgm_daily",
            "sounds/bgm/daily.ogg",
            AssetType::Music
        );
        self.register_asset(
            "bgm_battle",
            "sounds/bgm/battle.ogg",
            AssetType::Music
        );

        // SE
        self.register_asset(
            "se_click",
            "sounds/se/click.ogg",
            AssetType::Sound
        );
        self.register_asset(
            "se_text",
            "sounds/se/text.ogg",
            AssetType::Sound
        );

        info!("標準アセット登録完了: {}個のアセットを登録", self.assets.len());
    }

    /// アセットの読み込み開始
    pub fn load_asset(&mut self, id: &str, asset_server: &AssetServer) -> Result<UntypedHandle, String> {
        let asset_info = self.assets.get_mut(id)
            .ok_or_else(|| format!("アセット「{}」が見つかりません", id))?;

        if asset_info.status == AssetStatus::Loaded {
            return asset_info.handle.clone()
                .ok_or_else(|| "読み込み済みアセットのハンドルが見つかりません".to_string());
        }

        // ファイル存在確認
        let full_path = format!("assets/{}", asset_info.path);
        if !std::path::Path::new(&full_path).exists() {
            let error_msg = format!("ファイルが見つかりません: {}", full_path);
            asset_info.status = AssetStatus::Failed(error_msg.clone());
            return Err(error_msg);
        }

        // アセットの読み込み開始
        let handle = match asset_info.asset_type {
            AssetType::Font => asset_server.load::<Font>(&asset_info.path).untyped(),
            AssetType::BackgroundImage | AssetType::CharacterImage | AssetType::UIImage => {
                asset_server.load::<Image>(&asset_info.path).untyped()
            },
            AssetType::Sound | AssetType::Music => {
                asset_server.load::<AudioSource>(&asset_info.path).untyped()
            },
        };

        asset_info.status = AssetStatus::Loading;
        asset_info.handle = Some(handle.clone());

        info!("アセット読み込み開始: {} ({})", id, asset_info.path);
        Ok(handle)
    }

    /// アセット状態の更新
    pub fn update_asset_status(&mut self, asset_server: &AssetServer) {
        for (id, asset_info) in self.assets.iter_mut() {
            if let Some(handle) = &asset_info.handle {
                let new_status = match asset_server.load_state(handle) {
                    bevy::asset::LoadState::NotLoaded => AssetStatus::NotLoaded,
                    bevy::asset::LoadState::Loading => AssetStatus::Loading,
                    bevy::asset::LoadState::Loaded => AssetStatus::Loaded,
                    bevy::asset::LoadState::Failed(err) => AssetStatus::Failed(format!("{:?}", err)),
                };

                if asset_info.status != new_status {
                    match &new_status {
                        AssetStatus::Loaded => info!("✅ アセット読み込み完了: {}", id),
                        AssetStatus::Failed(err) => warn!("❌ アセット読み込み失敗: {} - {}", id, err),
                        _ => {}
                    }
                    asset_info.status = new_status;
                }
            }
        }
    }

    /// アセット情報の取得
    pub fn get_asset_info(&self, id: &str) -> Option<&AssetInfo> {
        self.assets.get(id)
    }

    /// アセットハンドルの取得
    pub fn get_handle(&self, id: &str) -> Option<UntypedHandle> {
        self.assets.get(id)?.handle.clone()
    }

    /// 型付きハンドルの取得
    pub fn get_typed_handle<T: Asset>(&self, id: &str) -> Option<Handle<T>> {
        Some(self.get_handle(id)?.typed::<T>())
    }

    /// すべてのアセットが読み込み完了したかチェック
    pub fn all_assets_loaded(&self) -> bool {
        self.assets.values().all(|info| info.status == AssetStatus::Loaded)
    }

    /// 特定タイプのアセットが読み込み完了したかチェック
    pub fn assets_of_type_loaded(&self, asset_type: AssetType) -> bool {
        self.assets.values()
            .filter(|info| info.asset_type == asset_type)
            .all(|info| info.status == AssetStatus::Loaded)
    }

    /// 読み込み失敗したアセットのリスト
    pub fn get_failed_assets(&self) -> Vec<(&String, &AssetInfo)> {
        self.assets.iter()
            .filter(|(_, info)| matches!(info.status, AssetStatus::Failed(_)))
            .collect()
    }

    /// アセット読み込み統計
    pub fn get_loading_stats(&self) -> AssetLoadingStats {
        let total = self.assets.len();
        let loaded = self.assets.values().filter(|info| info.status == AssetStatus::Loaded).count();
        let loading = self.assets.values().filter(|info| info.status == AssetStatus::Loading).count();
        let failed = self.assets.values().filter(|info| matches!(info.status, AssetStatus::Failed(_))).count();

        AssetLoadingStats {
            total,
            loaded,
            loading,
            failed,
            progress: if total > 0 { (loaded as f32 / total as f32) * 100.0 } else { 100.0 },
        }
    }

    /// デバッグ情報の出力
    pub fn print_debug_info(&self) {
        println!("🔍 ===== アセットマネージャー デバッグ情報 =====");
        println!("📊 総アセット数: {}", self.assets.len());

        let stats = self.get_loading_stats();
        println!("📈 読み込み進捗: {:.1}% ({}/{})", stats.progress, stats.loaded, stats.total);
        println!("🔄 読み込み中: {}", stats.loading);
        println!("❌ 失敗: {}", stats.failed);

        for (id, info) in &self.assets {
            let status_icon = match info.status {
                AssetStatus::NotLoaded => "⏳",
                AssetStatus::Loading => "🔄",
                AssetStatus::Loaded => "✅",
                AssetStatus::Failed(_) => "❌",
            };
            println!("{} {}: {} ({:?})", status_icon, id, info.path, info.asset_type);
        }
        println!("===============================================");
    }
}

/// アセット読み込み統計
#[derive(Debug, Clone)]
pub struct AssetLoadingStats {
    pub total: usize,
    pub loaded: usize,
    pub loading: usize,
    pub failed: usize,
    pub progress: f32,
}

impl Default for AssetManager {
    fn default() -> Self {
        let mut manager = Self::new();
        manager.register_default_assets();
        manager
    }
}

/// アセット管理用システム
pub fn asset_management_system(
    mut asset_manager: ResMut<AssetManager>,
    asset_server: Res<AssetServer>,
) {
    asset_manager.update_asset_status(&asset_server);
}

/// アセット一括読み込み用システム
pub fn load_all_assets_system(
    mut asset_manager: ResMut<AssetManager>,
    asset_server: Res<AssetServer>,
    mut app_state: ResMut<crate::presentation::ui_components::AppState>,
) {
    if app_state.init_state != crate::presentation::ui_components::InitState::LoadingFonts {
        return;
    }

    // まだ読み込み開始していない場合
    if !asset_manager.assets.values().any(|info| info.status == AssetStatus::Loading) {
        info!("全アセットの読み込みを開始します");

        for (id, _) in asset_manager.assets.clone().iter() {
            if let Err(err) = asset_manager.load_asset(id, &asset_server) {
                warn!("アセット読み込み開始に失敗: {} - {}", id, err);
            }
        }
    }

    // 読み込み完了チェック
    if asset_manager.all_assets_loaded() && !app_state.font_load_checked {
        info!("🎉 全アセット読み込み完了");
        app_state.font_load_checked = true;
        if app_state.init_state == crate::presentation::ui_components::InitState::LoadingFonts {
            app_state.init_state = crate::presentation::ui_components::InitState::FontsReady;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn asset_manager_creation() {
        let manager = AssetManager::new();
        assert_eq!(manager.assets.len(), 0);
    }

    #[test]
    fn asset_registration() {
        let mut manager = AssetManager::new();
        manager.register_asset("test_font", "fonts/test.ttf", AssetType::Font);

        assert_eq!(manager.assets.len(), 1);
        let asset_info = manager.get_asset_info("test_font").unwrap();
        assert_eq!(asset_info.path, "fonts/test.ttf");
        assert_eq!(asset_info.asset_type, AssetType::Font);
        assert_eq!(asset_info.status, AssetStatus::NotLoaded);
    }

    #[test]
    fn default_assets_registration() {
        let manager = AssetManager::default();
        assert!(manager.assets.len() > 0);

        // 必須アセットの確認
        assert!(manager.get_asset_info("main_font").is_some());
        assert!(manager.get_asset_info("bg_souma_home").is_some());
        assert!(manager.get_asset_info("char_souma").is_some());
    }

    #[test]
    fn loading_stats() {
        let mut manager = AssetManager::new();
        manager.register_asset("test1", "test1.png", AssetType::UIImage);
        manager.register_asset("test2", "test2.png", AssetType::UIImage);

        let stats = manager.get_loading_stats();
        assert_eq!(stats.total, 2);
        assert_eq!(stats.loaded, 0);
        assert_eq!(stats.progress, 0.0);
    }

    #[test]
    fn asset_type_filtering() {
        let mut manager = AssetManager::new();
        manager.register_asset("font1", "font1.ttf", AssetType::Font);
        manager.register_asset("font2", "font2.ttf", AssetType::Font);
        manager.register_asset("image1", "image1.png", AssetType::UIImage);

        // フォントタイプのアセットが読み込み完了していないことを確認
        assert!(!manager.assets_of_type_loaded(AssetType::Font));

        // 手動でステータスを変更してテスト
        for (_, info) in manager.assets.iter_mut() {
            if info.asset_type == AssetType::Font {
                info.status = AssetStatus::Loaded;
            }
        }

        assert!(manager.assets_of_type_loaded(AssetType::Font));
        assert!(!manager.assets_of_type_loaded(AssetType::UIImage));
    }
}
