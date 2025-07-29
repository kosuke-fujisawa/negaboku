import { Game } from './Game';

function demonstrateRoguelikeRPG(): void {
  console.log('='.repeat(60));
  console.log('    人間関係値ローグライクRPG - モックデモンストレーション');
  console.log('='.repeat(60));

  const game = new Game();
  game.setPlayerName('勇者');

  console.log('\n【ゲーム概要】');
  console.log('- 初期キャラクター: 10人');
  console.log('- DLCキャラクター: 5人');
  console.log('- ターン制バトルシステム');
  console.log('- 選択肢形式のダンジョン探索');
  console.log('- 関係値による動的スキル解放');
  console.log('- スロット式セーブシステム');

  console.log('\n【初期状態】');
  console.log(game.getGameStatus());

  console.log('\n【パーティ編成】');
  game.setParty(['char_001', 'char_002', 'char_003', 'char_004']);

  console.log('\n【関係値システムのデモ】');
  game.demonstrateRelationshipSystem();

  console.log('\n【利用可能スキル確認】');
  game.viewAvailableSkills();

  console.log('\n【DLC解放】');
  game.unlockDLC();

  console.log('\n【DLCキャラクターを含む新パーティ】');
  game.setParty(['char_001', 'char_002', 'dlc_001', 'dlc_002']);

  console.log('\n【ダンジョン探索デモ】');
  const dungeonStarted = game.exploreDungeon('dungeon_001');
  if (dungeonStarted) {
    console.log('- 分かれ道のイベントが発生');
    console.log('選択肢: 1) 左の道を進む, 2) 右の道を進む');
    console.log('プレイヤーが「1) 左の道を進む」を選択');
    game.processEvent('event_001', 'choice_001_left');
  }

  console.log('\n【セーブ機能テスト】');
  const saveSuccess = game.saveGame(1);
  if (saveSuccess) {
    console.log('セーブ完了');
    
    console.log('\n【ロード機能テスト】');
    const loadSuccess = game.loadGame(1);
    if (loadSuccess) {
      console.log('ロード完了');
      console.log('ロード後のゲーム状態:', game.getGameStatus());
    }
  }

  console.log('\n【エンディングシミュレーション】');
  console.log('様々なパーティ構成でのエンディング分岐をテスト');
  
  console.log('\n1. 高関係値パーティでのエンディング');
  game.setParty(['char_001', 'char_002', 'char_003', 'char_004']);
  game.simulateTrueEnding();

  console.log('\n2. DLCキャラクター含むパーティでのエンディング');
  game.setParty(['char_001', 'dlc_001', 'dlc_002', 'dlc_003']);
  game.simulateTrueEnding();

  console.log('\n【システム統計】');
  const finalStatus = game.getGameStatus();
  console.log(`- 解放済みスキル数: ${finalStatus.skillsUnlocked}`);
  console.log(`- 利用可能ダンジョン数: ${finalStatus.availableDungeons}`);
  console.log(`- DLC状態: ${finalStatus.dlcUnlocked ? '解放済み' : '未解放'}`);
  console.log(`- 現在の所持金: ${finalStatus.gold}G`);
  console.log(`- 現在のオーブ数: ${finalStatus.orbs}`);

  console.log('\n【技術仕様】');
  console.log('- TypeScript実装');
  console.log('- モジュール化された各システム');
  console.log('- JSON形式でのセーブデータ');
  console.log('- 拡張可能なスキル・キャラクターシステム');
  console.log('- 動的な関係値計算');

  console.log('\n='.repeat(60));
  console.log('              デモンストレーション完了');
  console.log('='.repeat(60));
}

if (require.main === module) {
  demonstrateRoguelikeRPG();
}

export { Game };