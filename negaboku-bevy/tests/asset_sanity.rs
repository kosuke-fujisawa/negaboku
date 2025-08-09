/*!
 * アセット健全性テスト
 * 必須フォント・画像・音声ファイルの存在とロード可能性を検証
 */

use std::path::Path;

/// 必須フォントファイルの存在確認
#[test]
fn test_required_fonts_exist() {
    let font_paths = vec![
        "assets/fonts/FiraSans-Bold.otf",
        "assets/fonts/NotoSansJP-VariableFont_wght.ttf",
    ];

    for font_path in font_paths {
        let path = Path::new(font_path);
        assert!(
            path.exists(),
            "必須フォントファイルが見つかりません: {}",
            font_path
        );

        // ファイルが空でないことを確認
        let metadata = std::fs::metadata(path)
            .expect(&format!("フォントファイルのメタデータ取得に失敗: {}", font_path));
        assert!(
            metadata.len() > 0,
            "フォントファイルが空です: {}",
            font_path
        );
    }
}

/// 必須背景画像の存在確認
#[test]
fn test_required_backgrounds_exist() {
    let bg_paths = vec![
        "assets/images/backgrounds/black.png",
        "assets/images/backgrounds/ruins_entrance.jpg",
        "assets/images/backgrounds/ruins_interior.jpg",
        "assets/images/backgrounds/souma_home.png",
    ];

    for bg_path in bg_paths {
        let path = Path::new(bg_path);
        assert!(
            path.exists(),
            "必須背景画像が見つかりません: {}",
            bg_path
        );

        // ファイルサイズ確認（画像として妥当なサイズか）
        let metadata = std::fs::metadata(path)
            .expect(&format!("背景画像のメタデータ取得に失敗: {}", bg_path));
        assert!(
            metadata.len() > 1000, // 1KB以上
            "背景画像のファイルサイズが小さすぎます: {} ({} bytes)",
            bg_path, metadata.len()
        );
    }
}

/// 必須キャラクター画像の存在確認
#[test]
fn test_required_character_images_exist() {
    let character_paths = vec![
        "assets/images/characters/01_souma_kari.png",
        "assets/images/characters/02_retsuji_kari.png",
        "assets/images/characters/03_yuzuki_kari.jpg",
        "assets/images/characters/06_kai_kari.png",
    ];

    for char_path in character_paths {
        let path = Path::new(char_path);
        assert!(
            path.exists(),
            "必須キャラクター画像が見つかりません: {}",
            char_path
        );

        let metadata = std::fs::metadata(path)
            .expect(&format!("キャラクター画像のメタデータ取得に失敗: {}", char_path));
        assert!(
            metadata.len() > 5000, // 5KB以上（キャラクター画像として妥当）
            "キャラクター画像のファイルサイズが小さすぎます: {} ({} bytes)",
            char_path, metadata.len()
        );
    }
}

/// 必須音声ファイルの存在確認
#[test]
fn test_required_audio_exist() {
    let audio_paths = vec![
        "assets/sounds/01_lyrical_stadelate.mp3",
    ];

    for audio_path in audio_paths {
        let path = Path::new(audio_path);
        assert!(
            path.exists(),
            "必須音声ファイルが見つかりません: {}",
            audio_path
        );

        let metadata = std::fs::metadata(path)
            .expect(&format!("音声ファイルのメタデータ取得に失敗: {}", audio_path));
        assert!(
            metadata.len() > 10000, // 10KB以上
            "音声ファイルのファイルサイズが小さすぎます: {} ({} bytes)",
            audio_path, metadata.len()
        );
    }
}

/// 必須シナリオファイルの存在とフォーマット確認
#[test]
fn test_required_scenarios_exist_and_valid() {
    let scenario_paths = vec![
        "assets/scenarios/scene01.md",
        "assets/scenarios/test_scene01.md",
    ];

    for scenario_path in scenario_paths {
        let path = Path::new(scenario_path);
        assert!(
            path.exists(),
            "必須シナリオファイルが見つかりません: {}",
            scenario_path
        );

        // ファイル内容が読み取り可能かテスト
        let content = std::fs::read_to_string(path)
            .expect(&format!("シナリオファイルの読み取りに失敗: {}", scenario_path));

        assert!(
            !content.trim().is_empty(),
            "シナリオファイルが空です: {}",
            scenario_path
        );

        // UTF-8エンコーディング確認（日本語が含まれているか）
        assert!(
            content.contains("。") || content.contains("、"),
            "シナリオファイルに日本語が含まれていません: {}",
            scenario_path
        );
    }
}

/// アセット全体のディレクトリ構造確認
#[test]
fn test_asset_directory_structure() {
    let required_dirs = vec![
        "assets",
        "assets/fonts",
        "assets/images",
        "assets/images/backgrounds",
        "assets/images/characters",
        "assets/sounds",
        "assets/scenarios",
    ];

    for dir_path in required_dirs {
        let path = Path::new(dir_path);
        assert!(
            path.exists() && path.is_dir(),
            "必須アセットディレクトリが見つかりません: {}",
            dir_path
        );
    }
}
