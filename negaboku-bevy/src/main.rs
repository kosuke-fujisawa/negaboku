use bevy::prelude::*;

// モジュール宣言
mod domain;
mod application;
mod infrastructure;
mod presentation;

// 使用する型をインポート
use domain::character::CharacterRegistry;
use application::scenario_system::{
    MarkdownScenarioState, markdown_scenario_system,
    markdown_scenario_input_system, load_markdown_scenario_system,
    scenario_progression_system
};
use application::command_executor::BackgroundImage;
use presentation::ui_components::*;
use presentation::screen_systems::*;
use presentation::systems::*;

fn main() {
    App::new()
        // Bevy基本機能
        .add_plugins(DefaultPlugins
            .set(WindowPlugin {
                primary_window: Some(Window {
                    title: "願い石と僕たちの絆 (Rust + Bevy)".to_string(),
                    resolution: (1920.0, 1080.0).into(),
                    ..default()
                }),
                ..default()
            })
            .set(AssetPlugin {
                file_path: {
                    let assets_path = std::env::current_exe()
                        .ok()
                        .and_then(|exe_path| exe_path.parent().map(|parent| parent.to_path_buf()))
                        .and_then(|parent| {
                            // target/debug/ から プロジェクトルートに移動
                            if parent.file_name()?.to_str()? == "debug" {
                                parent.parent().and_then(|p| p.parent()).map(|p| p.to_path_buf())
                            } else {
                                Some(parent)
                            }
                        })
                        .unwrap_or_else(|| std::env::current_dir().unwrap())
                        .join("assets");
                    assets_path.to_string_lossy().to_string()
                },
                ..default()
            }))
        // リソース追加
        .init_resource::<GameMode>()
        .init_resource::<MenuCursor>()
        .init_resource::<AppState>()
        .init_resource::<DialogueLog>()
        .init_resource::<ScenarioState>()
        .init_resource::<MarkdownScenarioState>()
        .init_resource::<CharacterRegistry>()
        // システム追加
        .add_systems(Startup, (setup_assets, setup_character_registry))
        .add_systems(Update, (
            initialization_system,
            asset_loading_system,
            debug_asset_system,
            presentation::systems::menu_input_system,
            presentation::systems::mouse_input_system,
            presentation::text_systems::story_mouse_input_system,
            presentation::text_systems::text_typing_system,
            presentation::text_systems::vn_typing_system,
            presentation::systems::background_system,
            presentation::systems::button_visual_system,
            presentation::text_systems::log_input_system,
            presentation::text_systems::log_ui_system,
            presentation::text_systems::dialogue_completion_system,
            scenario_progression_system,
            // マークダウンシナリオシステム
            load_markdown_scenario_system,
            markdown_scenario_system,
            markdown_scenario_input_system,
        ))
        .run();
}
