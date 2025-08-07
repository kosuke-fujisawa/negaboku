//! シナリオローダー - マークダウンファイルの読み込みと解析
//!
//! # 責務
//! - マークダウンファイルの読み込み
//! - pulldown-cmarkを使用したパース
//! - シーンコマンドとダイアログの抽出

use crate::domain::scenario::{Scene, SceneCommand, DialogueBlock, ScenarioFile};
use std::fs;
use std::path::Path;

/// シナリオローダー
pub struct ScenarioLoader;

impl ScenarioLoader {
    /// マークダウンファイルからシナリオを読み込み
    pub fn load_from_file<P: AsRef<Path>>(path: P) -> Result<ScenarioFile, std::io::Error> {
        let path_ref = path.as_ref();
        println!("🔍 シナリオファイル読み込み試行: {:?}", path_ref);

        // まず相対パスでファイル存在を確認
        if path_ref.exists() {
            println!("✅ 相対パスでファイル発見: {:?}", path_ref);
            let content = fs::read_to_string(&path)?;
            println!("📄 ファイル内容読み込み成功 ({} 文字)", content.len());
            return Ok(Self::parse_markdown(&content));
        } else {
            println!("❌ 相対パスにファイルが見つかりません: {:?}", path_ref);
        }

        // 実行ファイルの場所を基準としたパス解決（Bevyと同様のロジック）
        let assets_root = std::env::current_exe()
            .ok()
            .and_then(|exe_path| {
                exe_path.parent().map(|parent| parent.to_path_buf())
            })
            .and_then(|parent| {
                // target/debug/ から プロジェクトルートに移動
                if let Some(name) = parent.file_name().and_then(|n| n.to_str()) {
                    if name == "debug" {
                        parent.parent().and_then(|p| p.parent()).map(|p| p.to_path_buf())
                    } else {
                        Some(parent)
                    }
                } else {
                    Some(parent)
                }
            })
            .unwrap_or_else(|| std::env::current_dir().unwrap());

        let resolved_path = assets_root.join(path_ref);
        println!("🔍 絶対パス解決試行: {:?}", resolved_path);

        if resolved_path.exists() {
            println!("✅ 絶対パスでファイル発見: {:?}", resolved_path);
            let content = fs::read_to_string(&resolved_path)?;
            println!("📄 ファイル内容読み込み成功 ({} 文字)", content.len());
            return Ok(Self::parse_markdown(&content));
        } else {
            println!("❌ 絶対パスにもファイルが見つかりません: {:?}", resolved_path);
        }

        // 全ての試行が失敗した場合、最終試行
        println!("🔍 最終試行: 元のパスで読み込み");
        fs::read_to_string(&path).map(|content| {
            println!("📄 最終試行成功 ({} 文字)", content.len());
            Self::parse_markdown(&content)
        })
    }

    /// マークダウンコンテンツをパースしてシナリオに変換
    pub fn parse_markdown(content: &str) -> ScenarioFile {
        println!("🔄 マークダウンパース開始 ({} 文字)", content.len());

        // シンプルな行ベース解析を使用（pulldown-cmarkは複雑すぎるため）
        let lines: Vec<&str> = content.lines().collect();
        println!("📝 総行数: {}", lines.len());

        let mut current_scene = Scene {
            commands: Vec::new(),
            dialogue_blocks: Vec::new(),
        };
        let mut scenes = Vec::new();
        let mut title = "無題シナリオ".to_string();
        let mut found_title = false;

        for line in lines {
            let trimmed_line = line.trim();

            if trimmed_line.is_empty() {
                continue;
            }

            // タイトル行の検出（# で始まる）
            if trimmed_line.starts_with("# ") && !found_title {
                title = trimmed_line[2..].trim().to_string();
                found_title = true;
                continue;
            }

            // セクション区切りの検出
            if trimmed_line == "---" {
                if !current_scene.commands.is_empty() || !current_scene.dialogue_blocks.is_empty() {
                    scenes.push(current_scene);
                    current_scene = Scene {
                        commands: Vec::new(),
                        dialogue_blocks: Vec::new(),
                    };
                }
                continue;
            }

            // ヘッダー行でシーン区切り処理（## で始まる）
            if trimmed_line.starts_with("##") {
                // 現在のシーンに内容があれば保存
                if !current_scene.commands.is_empty() || !current_scene.dialogue_blocks.is_empty() {
                    scenes.push(current_scene);
                    current_scene = Scene {
                        commands: Vec::new(),
                        dialogue_blocks: Vec::new(),
                    };
                }
                continue;
            }

            // 行を処理
            Self::process_line(trimmed_line, &mut current_scene);
        }

        // 最後のシーンを追加
        if !current_scene.commands.is_empty() || !current_scene.dialogue_blocks.is_empty() {
            scenes.push(current_scene);
        }

        let scenario_file = ScenarioFile {
            title: title.clone(),
            scenes,
            current_scene_index: 0,
        };

        println!("✅ マークダウンパース完了");
        println!("📋 タイトル: {}", title);
        println!("🎬 シーン数: {}", scenario_file.scenes.len());
        for (i, scene) in scenario_file.scenes.iter().enumerate() {
            println!("  - シーン{}: コマンド{}個, ダイアログ{}個",
                i + 1, scene.commands.len(), scene.dialogue_blocks.len());
        }

        scenario_file
    }

    /// 1行を処理してコマンドまたはダイアログを抽出
    fn process_line(line: &str, scene: &mut Scene) {
        if line.is_empty() {
            return;
        }

        // println!("🔍 処理中の行: '{}'", line);

        // コマンド行の検出（標準形式: [...] と独自形式: `cmd:args`）
        if line.starts_with('[') && line.ends_with(']') {
            // 標準形式: [bg storage=filename time=duration]
            match SceneCommand::parse(line) {
                Ok(command) => {
                    scene.commands.push(command);
                    // println!("📋 コマンド解析成功: {:?}", line);
                }
                Err(error) => {
                    eprintln!("⚠️ コマンド解析エラー: {} - {}", line, error.message);
                }
            }
        } else if line.starts_with('`') && line.ends_with('`') {
            // 独自形式: `bg:backgrounds/file.png` や `char:name:face:pos`
            let inner = &line[1..line.len()-1]; // バッククォートを除去
            if let Some(command) = Self::parse_simple_command(inner) {
                scene.commands.push(command);
                println!("📋 独自コマンド解析成功: {}", inner);
            } else {
                println!("⚠️ 独自コマンド解析失敗: {}", inner);
            }
        } else if let Some(dialogue) = DialogueBlock::parse(line) {
            // ダイアログブロックとして追加
            scene.dialogue_blocks.push(dialogue.clone());
            // println!("💬 ダイアログ解析成功: {:?}", dialogue);
        } else {
            println!("❓ 未処理行: '{}'", line);
        }
    }

    /// 独自コマンド形式をパース
    ///
    /// # 対応形式
    /// - `bg:backgrounds/filename.png` → Background
    /// - `char:name:face:pos` → CharacterShow
    fn parse_simple_command(command_str: &str) -> Option<SceneCommand> {
        let parts: Vec<&str> = command_str.split(':').collect();

        if parts.is_empty() {
            return None;
        }

        match parts[0] {
            "bg" => {
                if parts.len() >= 2 {
                    Some(SceneCommand::Background {
                        storage: parts[1].to_string(),
                        time: Some(500), // デフォルト500ms
                    })
                } else {
                    None
                }
            }
            "char" => {
                if parts.len() >= 4 {
                    // char:name:face:pos形式
                    let name = parts[1].to_string();
                    let face = Some(parts[2].to_string());
                    let pos = Some(crate::domain::scenario::CharacterPosition::from(parts[3]));

                    Some(SceneCommand::CharacterShow { name, face, pos })
                } else if parts.len() >= 2 {
                    // char:name形式（最小限）
                    let name = parts[1].to_string();
                    Some(SceneCommand::CharacterShow {
                        name,
                        face: None,
                        pos: Some(crate::domain::scenario::CharacterPosition::Center)
                    })
                } else {
                    None
                }
            }
            _ => {
                println!("⚠️ 未対応の独自コマンド: {}", parts[0]);
                None
            }
        }
    }

    /// シナリオの統計情報を取得（デバッグ用）
    pub fn get_scenario_stats(scenario: &ScenarioFile) -> ScenarioStats {
        let mut total_commands = 0;
        let mut total_dialogues = 0;
        let mut command_types = std::collections::HashMap::new();

        for scene in &scenario.scenes {
            total_commands += scene.commands.len();
            total_dialogues += scene.dialogue_blocks.len();

            for command in &scene.commands {
                let cmd_type = match command {
                    SceneCommand::Background { .. } => "bg",
                    SceneCommand::CharacterShow { .. } => "chara_show",
                    SceneCommand::CharacterHide { .. } => "chara_hide",
                    SceneCommand::Bgm { .. } => "bgm",
                    SceneCommand::Se { .. } => "se",
                    SceneCommand::Wait { .. } => "wait",
                    SceneCommand::Choice { .. } => "choice",
                };
                *command_types.entry(cmd_type.to_string()).or_insert(0) += 1;
            }
        }

        ScenarioStats {
            title: scenario.title.clone(),
            scene_count: scenario.scenes.len(),
            total_commands,
            total_dialogues,
            command_types,
        }
    }
}

/// シナリオ統計情報
#[derive(Debug)]
pub struct ScenarioStats {
    pub title: String,
    pub scene_count: usize,
    pub total_commands: usize,
    pub total_dialogues: usize,
    pub command_types: std::collections::HashMap<String, usize>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_simple_markdown() {
        let content = r#"
# テストシナリオ

[bg storage=forest_day.jpg time=500]
[chara_show name=souma face=normal pos=left]

**ソウマ**「こんにちは」

地の文です。

---

[bg storage=ruins.jpg]

**ユズキ**「さようなら」
"#;

        let scenario = ScenarioLoader::parse_markdown(content);

        assert_eq!(scenario.title, "テストシナリオ");
        assert_eq!(scenario.scenes.len(), 2);

        // 最初のシーン
        let first_scene = &scenario.scenes[0];
        assert_eq!(first_scene.commands.len(), 2);
        assert_eq!(first_scene.dialogue_blocks.len(), 2);

        // コマンドの確認
        match &first_scene.commands[0] {
            SceneCommand::Background { storage, time } => {
                assert_eq!(storage, "forest_day.jpg");
                assert_eq!(*time, Some(500));
            }
            _ => panic!("期待していた Background コマンドではありません"),
        }

        // ダイアログの確認
        assert_eq!(first_scene.dialogue_blocks[0].speaker, Some("ソウマ".to_string()));
        assert_eq!(first_scene.dialogue_blocks[0].text, "こんにちは");
        assert_eq!(first_scene.dialogue_blocks[1].speaker, None);
        assert_eq!(first_scene.dialogue_blocks[1].text, "地の文です。");
    }

    #[test]
    fn test_scenario_stats() {
        let content = r#"
# テストシナリオ

[bg storage=test.jpg]
[chara_show name=souma pos=left]

**ソウマ**「テスト」
"#;

        let scenario = ScenarioLoader::parse_markdown(content);
        let stats = ScenarioLoader::get_scenario_stats(&scenario);

        assert_eq!(stats.title, "テストシナリオ");
        assert_eq!(stats.scene_count, 1);
        assert_eq!(stats.total_commands, 2);
        assert_eq!(stats.total_dialogues, 1);
        assert_eq!(stats.command_types.get("bg"), Some(&1));
        assert_eq!(stats.command_types.get("chara_show"), Some(&1));
    }

    #[test]
    fn test_parse_simple_command_bg() {
        let command = ScenarioLoader::parse_simple_command("bg:backgrounds/forest.png");
        assert!(command.is_some());

        match command.unwrap() {
            SceneCommand::Background { storage, time } => {
                assert_eq!(storage, "backgrounds/forest.png");
                assert_eq!(time, Some(500));
            }
            _ => panic!("期待していたBackgroundコマンドではありません"),
        }
    }

    #[test]
    fn test_parse_simple_command_char() {
        let command = ScenarioLoader::parse_simple_command("char:souma:normal:left");
        assert!(command.is_some());

        match command.unwrap() {
            SceneCommand::CharacterShow { name, face, pos } => {
                assert_eq!(name, "souma");
                assert_eq!(face, Some("normal".to_string()));
                assert_eq!(pos, Some(crate::domain::scenario::CharacterPosition::Left));
            }
            _ => panic!("期待していたCharacterShowコマンドではありません"),
        }
    }

    #[test]
    fn test_parse_markdown_with_simple_commands() {
        let content = r#"
# テスト用独自コマンド

`bg:backgrounds/test.png`
`char:souma:smile:center`

**ソウマ**: これは独自形式のテストです。

## Section2

`bg:backgrounds/black.png`

ナレーション文章です。
"#;

        let scenario = ScenarioLoader::parse_markdown(content);

        assert_eq!(scenario.title, "テスト用独自コマンド");
        assert_eq!(scenario.scenes.len(), 2);

        // 最初のシーン
        let first_scene = &scenario.scenes[0];
        assert_eq!(first_scene.commands.len(), 2);
        assert_eq!(first_scene.dialogue_blocks.len(), 1);

        // コマンド確認
        match &first_scene.commands[0] {
            SceneCommand::Background { storage, time } => {
                assert_eq!(storage, "backgrounds/test.png");
                assert_eq!(*time, Some(500));
            }
            _ => panic!("期待していた Background コマンドではありません"),
        }

        // ダイアログ確認（コロン形式）
        assert_eq!(first_scene.dialogue_blocks[0].speaker, Some("ソウマ".to_string()));
        assert_eq!(first_scene.dialogue_blocks[0].text, "これは独自形式のテストです。");
    }
}
