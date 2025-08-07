//! UIコンポーネント定義
//!
//! Bevyコンポーネントとして画面要素を定義
//! ロジックは含めず、純粋なデータ構造のみ

use bevy::prelude::*;

/// テキスト表示コンポーネント（ロジック層中心設計）
#[derive(Component)]
pub struct DialogueText {
    pub full_text: String,
    pub current_char: usize,
    pub timer: Timer,
    pub is_complete: bool,
}

impl DialogueText {
    pub fn new(text: String) -> Self {
        Self {
            full_text: text,
            current_char: 0,
            timer: Timer::from_seconds(0.05, TimerMode::Repeating),
            is_complete: false,
        }
    }
}

/// 背景制御コンポーネント（ロジック層中心設計）
#[derive(Component)]
pub struct BackgroundController {
    pub backgrounds: Vec<Color>,
    pub current_index: usize,
}

impl BackgroundController {
    pub fn new() -> Self {
        Self {
            backgrounds: vec![
                Color::srgb(0.1, 0.2, 0.6), // 青（夜）
                Color::srgb(0.8, 0.7, 0.4), // 黄（昼）
                Color::srgb(0.2, 0.6, 0.2), // 緑（森）
                Color::srgb(0.6, 0.3, 0.1), // 茶（遺跡）
            ],
            current_index: 0,
        }
    }
}

/// メニューボタンコンポーネント
#[derive(Component)]
pub struct MenuButton {
    pub button_type: MenuButtonType,
    pub is_hovered: bool,
    pub is_pressed: bool,
    pub bounds: ButtonBounds,
}

/// タイトル画面の要素をマークするコンポーネント
#[derive(Component)]
pub struct TitleScreenElement;

/// ストーリー画面の要素をマークするコンポーネント
#[derive(Component)]
pub struct StoryScreenElement;

/// ビジュアルノベル要素をマークするコンポーネント
#[derive(Component)]
pub struct VisualNovelElement;

/// ビジュアルノベル用コンポーネント
#[derive(Component)]
pub struct VNTextBox;

#[derive(Component)]
pub struct VNCharacterName {
    pub name: String,
}

#[derive(Component)]
pub struct VNDialogue {
    pub full_text: String,
    pub current_char: usize,
    pub timer: Timer,
    pub is_complete: bool,
}

impl VNDialogue {
    pub fn new(text: String) -> Self {
        Self {
            full_text: text,
            current_char: 0,
            timer: Timer::from_seconds(0.05, TimerMode::Repeating), // 50ms/文字
            is_complete: false,
        }
    }
}

/// VNUIボタンタイプ
#[derive(Debug, Clone)]
pub enum VNButtonType {
    Skip,
    Auto,
    Save,
    Load,
}

/// VNUIボタン
#[derive(Component)]
pub struct VNUIButton {
    pub button_type: VNButtonType,
}

/// ログ関連コンポーネント
#[derive(Component)]
pub struct LogScrollContainer;

#[derive(Component)]
pub struct LogButton;

#[derive(Component)]
pub struct LogCloseButton;

#[derive(Component)]
pub struct LogWindow;

#[derive(Component)]
pub struct LogEntry;

/// ゲーム画面の種類
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum GameScreen {
    Title,
    Story,
    Settings,
    Gallery,
    Battle,
}

/// リソース：ゲームモード
#[derive(Resource)]
pub struct GameMode {
    pub is_story_mode: bool,
    pub current_screen: GameScreen,
}

impl Default for GameMode {
    fn default() -> Self {
        Self {
            is_story_mode: false,
            current_screen: GameScreen::Title,
        }
    }
}

/// リソース：メニューカーソル
#[derive(Resource)]
pub struct MenuCursor {
    pub current_index: usize,
    pub max_buttons: usize,
}

impl Default for MenuCursor {
    fn default() -> Self {
        Self {
            current_index: 0,
            max_buttons: 5,
        }
    }
}

/// リソース：アプリケーション状態
#[derive(Resource)]
pub struct AppState {
    pub font_load_checked: bool,
    pub init_state: InitState,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            font_load_checked: false,
            init_state: InitState::LoadingFonts,
        }
    }
}

/// 初期化状態
#[derive(Debug, Default, PartialEq)]
pub enum InitState {
    #[default]
    LoadingFonts,  // フォント読み込み待機
    FontsReady,    // UI初期化準備完了
    UIReady,       // 通常ゲーム処理
}

/// リソース：ダイアログログ
#[derive(Resource, Default)]
pub struct DialogueLog {
    pub entries: Vec<DialogueEntry>,
    pub is_visible: bool,
}

/// ダイアログログエントリ
#[derive(Debug, Clone)]
pub struct DialogueEntry {
    pub character_name: String,
    pub text: String,
}

/// リソース：シナリオ状態
#[derive(Resource, Default)]
pub struct ScenarioState {
    pub lines: Vec<String>,
    pub current_index: usize,
    pub is_complete: bool,
}

/// リソース：ゲームアセット
#[derive(Resource)]
pub struct GameAssets {
    pub main_font: Handle<Font>,
    pub background_souma_home: Handle<Image>,
    pub character_souma: Handle<Image>,
}

#[derive(Clone)]
pub struct ButtonBounds {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
}

#[derive(Debug, Clone, PartialEq)]
pub enum MenuButtonType {
    NewGame,  // はじめから
    Continue, // つづきから
    Settings, // 設定
    Gallery,  // ギャラリー
    Exit,     // ゲーム終了
}

impl MenuButton {
    pub fn new(button_type: MenuButtonType, x: f32, y: f32, width: f32, height: f32) -> Self {
        Self {
            button_type,
            is_hovered: false,
            is_pressed: false,
            bounds: ButtonBounds {
                x,
                y,
                width,
                height,
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dialogue_text_creation() {
        let dialogue = DialogueText::new("Test message".to_string());
        assert_eq!(dialogue.full_text, "Test message");
        assert_eq!(dialogue.current_char, 0);
        assert!(!dialogue.is_complete);
    }

    #[test]
    fn test_vn_dialogue_creation() {
        let dialogue = VNDialogue::new("VN Test message".to_string());
        assert_eq!(dialogue.full_text, "VN Test message");
        assert_eq!(dialogue.current_char, 0);
        assert!(!dialogue.is_complete);
    }

    #[test]
    fn test_background_controller_creation() {
        let controller = BackgroundController::new();
        assert_eq!(controller.current_index, 0);
        assert_eq!(controller.backgrounds.len(), 4);
    }

    #[test]
    fn test_menu_button_creation() {
        let button = MenuButton::new(MenuButtonType::NewGame, 0.0, 0.0, 100.0, 50.0);
        assert_eq!(button.button_type, MenuButtonType::NewGame);
        assert!(!button.is_hovered);
        assert!(!button.is_pressed);
    }

    #[test]
    fn test_game_mode_default() {
        let game_mode = GameMode::default();
        assert!(!game_mode.is_story_mode);
        assert_eq!(game_mode.current_screen, GameScreen::Title);
    }

    #[test]
    fn test_menu_cursor_default() {
        let cursor = MenuCursor::default();
        assert_eq!(cursor.current_index, 0);
        assert_eq!(cursor.max_buttons, 5);
    }

    #[test]
    fn test_dialogue_log_default() {
        let log = DialogueLog::default();
        assert!(log.entries.is_empty());
        assert!(!log.is_visible);
    }

    #[test]
    fn test_app_state_default() {
        let app_state = AppState::default();
        assert!(!app_state.font_load_checked);
        assert_eq!(app_state.init_state, InitState::LoadingFonts);
    }
}
