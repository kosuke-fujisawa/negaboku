/*!
 * シナリオ整合性テスト
 * シナリオファイル内の画像/BGM参照と実ファイルの突合検証
 */

use std::path::Path;
use std::fs;
use regex::Regex;

/// シナリオファイル内のBGM参照整合性チェック
#[test]
fn test_scenario_bgm_references() {
    let scenario_files = vec![
        "assets/scenarios/scene01.md",
        "assets/scenarios/test_scene01.md",
    ];

    // BGM参照パターン: [bgm play=ファイル名]
    let bgm_pattern = Regex::new(r"\[bgm\s+play=([^\s\]]+)").unwrap();

    for scenario_path in scenario_files {
        let path = Path::new(scenario_path);
        if !path.exists() {
            panic!("シナリオファイルが見つかりません: {}", scenario_path);
        }

        let content = fs::read_to_string(path)
            .expect(&format!("シナリオファイル読み取りエラー: {}", scenario_path));

        // BGM参照を抽出して実ファイル存在確認
        for captures in bgm_pattern.captures_iter(&content) {
            let bgm_file = captures.get(1).unwrap().as_str();
            let bgm_path = format!("assets/sounds/{}", bgm_file);

            assert!(
                Path::new(&bgm_path).exists(),
                "シナリオ「{}」で参照されているBGMファイルが見つかりません: {}",
                scenario_path, bgm_path
            );
        }
    }
}

/// シナリオファイル内の背景画像参照整合性チェック
#[test]
fn test_scenario_background_references() {
    let scenario_files = vec![
        "assets/scenarios/scene01.md",
        "assets/scenarios/test_scene01.md",
    ];

    // 背景画像参照パターン: [bg storage=ファイル名]
    let bg_pattern = Regex::new(r"\[bg\s+storage=([^\s\]]+)").unwrap();

    for scenario_path in scenario_files {
        let path = Path::new(scenario_path);
        if !path.exists() {
            continue; // asset_sanityテストで既にチェック済み
        }

        let content = fs::read_to_string(path)
            .expect(&format!("シナリオファイル読み取りエラー: {}", scenario_path));

        // 背景画像参照を抽出して実ファイル存在確認
        for captures in bg_pattern.captures_iter(&content) {
            let bg_file = captures.get(1).unwrap().as_str();
            let bg_path = format!("assets/images/backgrounds/{}", bg_file);

            assert!(
                Path::new(&bg_path).exists(),
                "シナリオ「{}」で参照されている背景画像が見つかりません: {}",
                scenario_path, bg_path
            );
        }
    }
}

/// シナリオファイル内のキャラクター画像参照整合性チェック
#[test]
fn test_scenario_character_references() {
    let scenario_files = vec![
        "assets/scenarios/scene01.md",
        "assets/scenarios/test_scene01.md",
    ];

    // キャラクター表示パターン: [chara_show name=キャラ名]
    let chara_pattern = Regex::new(r"\[chara_show\s+name=([^\s\]]+)").unwrap();

    // キャラクター名→ファイル名マッピング
    let character_files = [
        ("souma", "01_souma_kari.png"),
        ("yuzuki", "03_yuzuki_kari.jpg"),
        ("retsuji", "02_retsuji_kari.png"),
        ("kai", "06_kai_kari.png"),
    ];

    for scenario_path in scenario_files {
        let path = Path::new(scenario_path);
        if !path.exists() {
            continue;
        }

        let content = fs::read_to_string(path)
            .expect(&format!("シナリオファイル読み取りエラー: {}", scenario_path));

        // キャラクター参照を抽出して実ファイル存在確認
        for captures in chara_pattern.captures_iter(&content) {
            let char_name = captures.get(1).unwrap().as_str();

            // キャラクター名から対応するファイルを検索
            let char_file = character_files.iter()
                .find(|(name, _)| *name == char_name)
                .map(|(_, file)| *file);

            match char_file {
                Some(file) => {
                    let char_path = format!("assets/images/characters/{}", file);
                    assert!(
                        Path::new(&char_path).exists(),
                        "シナリオ「{}」で参照されているキャラクター画像が見つかりません: {} ({})",
                        scenario_path, char_path, char_name
                    );
                },
                None => {
                    panic!(
                        "シナリオ「{}」で未定義のキャラクター「{}」が参照されています",
                        scenario_path, char_name
                    );
                }
            }
        }
    }
}

/// シナリオファイルの基本構文チェック
#[test]
fn test_scenario_syntax_validity() {
    let scenario_files = vec![
        "assets/scenarios/scene01.md",
        "assets/scenarios/test_scene01.md",
    ];

    for scenario_path in scenario_files {
        let path = Path::new(scenario_path);
        if !path.exists() {
            continue;
        }

        let content = fs::read_to_string(path)
            .expect(&format!("シナリオファイル読み取りエラー: {}", scenario_path));

        // 基本的な構文チェック
        assert!(
            !content.trim().is_empty(),
            "シナリオファイルが空です: {}",
            scenario_path
        );

        // 不完全なタグをチェック（開き括弧はあるが閉じ括弧がない）
        let open_brackets = content.matches('[').count();
        let close_brackets = content.matches(']').count();
        assert_eq!(
            open_brackets, close_brackets,
            "シナリオファイル「{}」でタグの括弧が不整合です（開き: {}, 閉じ: {}）",
            scenario_path, open_brackets, close_brackets
        );

        // UTF-8エンコーディング確認
        assert!(
            content.is_ascii() || content.contains("。") || content.contains("、"),
            "シナリオファイル「{}」のエンコーディングに問題があります",
            scenario_path
        );
    }
}
