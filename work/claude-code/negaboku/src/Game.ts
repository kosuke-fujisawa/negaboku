import { Character } from './types/Character';
import { SaveData, GameProgress, InventoryItem, ItemType } from './types/Save';
import { Enemy } from './types/Battle';
import { RelationshipSystem } from './systems/RelationshipSystem';
import { BattleSystem } from './systems/BattleSystem';
import { SaveSystem } from './systems/SaveSystem';
import { DungeonSystem } from './systems/DungeonSystem';
import { SkillSystem } from './systems/SkillSystem';
import { initialCharacters, dlcCharacters } from './data/characters';

export class Game {
  private relationshipSystem: RelationshipSystem;
  private battleSystem: BattleSystem | null;
  private saveSystem: SaveSystem;
  private dungeonSystem: DungeonSystem;
  private skillSystem: SkillSystem;
  
  private party: Character[];
  private inventory: InventoryItem[];
  private gameProgress: GameProgress;
  private gold: number;
  private orbs: number;
  private playerName: string;
  private playTime: number;
  private dlcUnlocked: boolean;

  constructor() {
    this.relationshipSystem = new RelationshipSystem();
    this.saveSystem = new SaveSystem();
    this.dungeonSystem = new DungeonSystem(this.relationshipSystem);
    this.skillSystem = new SkillSystem(this.relationshipSystem);
    this.battleSystem = null;
    
    this.party = [];
    this.inventory = [];
    this.gameProgress = {
      currentFloor: 1,
      storyFlags: {},
      eventFlags: {},
      endingsSeen: []
    };
    this.gold = 1000;
    this.orbs = 0;
    this.playerName = '';
    this.playTime = 0;
    this.dlcUnlocked = false;

    this.initializeGame();
  }

  private initializeGame(): void {
    this.party = initialCharacters.slice(0, 2).map(char => ({ ...char }));
    this.skillSystem.updatePartySkills(this.party);
    
    this.inventory = [
      { id: 'potion', name: 'ポーション', quantity: 5, type: ItemType.CONSUMABLE, description: 'HPを50回復する' },
      { id: 'ether', name: 'エーテル', quantity: 3, type: ItemType.CONSUMABLE, description: 'MPを30回復する' }
    ];
  }

  setPlayerName(name: string): void {
    this.playerName = name;
  }

  unlockDLC(): void {
    this.dlcUnlocked = true;
    console.log('DLCキャラクターが解放されました！');
    
    for (const dlcChar of dlcCharacters) {
      console.log(`- ${dlcChar.name} が利用可能になりました`);
    }
  }

  getAvailableCharacters(): Character[] {
    if (this.dlcUnlocked) {
      return [...initialCharacters, ...dlcCharacters];
    }
    return initialCharacters;
  }

  setParty(characterIds: string[]): boolean {
    if (characterIds.length !== 2) {
      console.log('パーティは2人で編成してください');
      return false;
    }

    const availableCharacters = this.getAvailableCharacters();
    const newParty: Character[] = [];

    for (const charId of characterIds) {
      const character = availableCharacters.find(c => c.id === charId);
      if (character) {
        newParty.push({ ...character });
      } else {
        console.log(`キャラクター ${charId} が見つかりません`);
        return false;
      }
    }

    this.party = newParty;
    this.skillSystem.updatePartySkills(this.party);
    console.log('パーティ編成を更新しました');
    return true;
  }

  startBattle(enemies: Enemy[]): boolean {
    if (this.party.length === 0) {
      console.log('パーティが編成されていません');
      return false;
    }

    this.battleSystem = new BattleSystem(this.party, enemies, this.relationshipSystem);
    console.log('戦闘開始！');
    return true;
  }

  exploreDungeon(dungeonId: string): boolean {
    const success = this.dungeonSystem.startExploration(dungeonId, this.party);
    if (success) {
      console.log(`ダンジョン「${dungeonId}」の探索を開始しました`);
      return true;
    } else {
      console.log('ダンジョンの探索を開始できませんでした');
      return false;
    }
  }

  processEvent(eventId: string, choiceId: string): void {
    const consequences = this.dungeonSystem.processChoice(eventId, choiceId);
    console.log('イベントの結果:');
    
    for (const consequence of consequences) {
      switch (consequence.type) {
        case 'gold_change':
          this.gold += consequence.value;
          console.log(`- ゴールド ${consequence.value > 0 ? '+' : ''}${consequence.value}`);
          break;
        case 'relationship_change':
          console.log(`- 関係値が変化しました`);
          break;
        case 'experience_gain':
          console.log(`- 経験値を獲得しました: ${consequence.value}`);
          break;
      }
    }
  }

  viewRelationships(): void {
    console.log('\n=== 現在の関係値 ===');
    
    for (let i = 0; i < this.party.length; i++) {
      for (let j = i + 1; j < this.party.length; j++) {
        const char1 = this.party[i];
        const char2 = this.party[j];
        const relationship = this.relationshipSystem.getRelationshipValue(char1.id, char2.id);
        const level = this.relationshipSystem.getRelationshipLevel(relationship);
        
        console.log(`${char1.name} → ${char2.name}: ${relationship} (${level})`);
      }
    }
  }

  viewAvailableSkills(): void {
    console.log('\n=== 利用可能なスキル ===');
    
    const cooperationSkills = this.skillSystem.getCooperationSkills(this.party);
    const conflictSkills = this.skillSystem.getConflictSkills(this.party);
    
    if (cooperationSkills.length > 0) {
      console.log('\n【共闘技】');
      for (const skill of cooperationSkills) {
        console.log(`- ${skill.name}: ${skill.description}`);
      }
    }
    
    if (conflictSkills.length > 0) {
      console.log('\n【対立技】');
      for (const skill of conflictSkills) {
        console.log(`- ${skill.name}: ${skill.description}`);
      }
    }
    
    if (cooperationSkills.length === 0 && conflictSkills.length === 0) {
      console.log('現在利用可能な特殊スキルはありません');
    }
  }

  saveGame(slotNumber: number): boolean {
    const success = this.saveSystem.save(
      slotNumber,
      this.playerName,
      this.playTime,
      this.gameProgress,
      this.party,
      this.relationshipSystem.getAllRelationships(),
      this.inventory,
      this.dungeonSystem.getAllDungeons().filter(d => d.isCleared).map(d => d.id),
      this.dungeonSystem.getUnlockedDungeons().map(d => d.id),
      this.orbs,
      this.gold,
      Math.max(...this.party.map(c => c.level)),
      0,
      this.dlcUnlocked
    );

    if (success) {
      console.log(`スロット ${slotNumber} にセーブしました`);
    } else {
      console.log('セーブに失敗しました');
    }

    return success;
  }

  loadGame(slotNumber: number): boolean {
    const saveData = this.saveSystem.load(slotNumber);
    if (!saveData) {
      console.log('セーブデータが見つかりません');
      return false;
    }

    this.playerName = saveData.playerName;
    this.playTime = saveData.playTime;
    this.gameProgress = saveData.gameProgress;
    this.party = saveData.party;
    this.inventory = saveData.inventory;
    this.orbs = saveData.orbs;
    this.gold = saveData.gold;
    this.dlcUnlocked = saveData.dlcUnlocked;

    this.relationshipSystem.loadRelationships(saveData.relationships);

    console.log(`スロット ${slotNumber} からロードしました`);
    return true;
  }

  getGameStatus(): any {
    return {
      playerName: this.playerName,
      playTime: this.playTime,
      party: this.party.map(c => ({ id: c.id, name: c.name, level: c.level, hp: c.hp, mp: c.mp })),
      gold: this.gold,
      orbs: this.orbs,
      dlcUnlocked: this.dlcUnlocked,
      availableDungeons: this.dungeonSystem.getUnlockedDungeons().length,
      skillsUnlocked: this.skillSystem.getUnlockedSkillsCount()
    };
  }

  demonstrateRelationshipSystem(): void {
    console.log('\n=== 関係値システムのデモンストレーション ===');
    
    console.log('1. 初期関係値の表示');
    this.viewRelationships();
    
    console.log('\n2. 協力イベントをシミュレート');
    this.relationshipSystem.modifyRelationship(this.party[0].id, this.party[1].id, 10);
    this.relationshipSystem.modifyRelationship(this.party[1].id, this.party[0].id, 10);
    
    console.log('\n3. 関係値変化後');
    this.viewRelationships();
    
    console.log('\n4. スキル解放チェック');
    const newSkills = this.skillSystem.unlockNewSkills(this.party);
    if (newSkills.length > 0) {
      console.log('新しいスキルが解放されました:');
      for (const skill of newSkills) {
        console.log(`- ${skill.name}: ${skill.description}`);
      }
    }
  }

  simulateTrueEnding(): void {
    console.log('\n=== トゥルーエンディングシミュレーション ===');
    
    const partyNames = this.party.map(c => c.name);
    console.log(`現在のパーティ: ${partyNames.join(', ')}`);
    
    let endingType = 'default';
    const avgRelationship = this.calculateAverageRelationship();
    
    if (avgRelationship >= 80) {
      endingType = 'perfect_harmony';
    } else if (avgRelationship <= 20) {
      endingType = 'lonely_hero';
    } else if (this.dlcUnlocked && this.party.some(c => c.isDLC)) {
      endingType = 'new_bonds';
    }
    
    console.log(`\n平均関係値: ${avgRelationship.toFixed(1)}`);
    console.log(`エンディングタイプ: ${endingType}`);
    
    switch (endingType) {
      case 'perfect_harmony':
        console.log('\n【完全調和エンディング】');
        console.log('すべての仲間との絆を深めた主人公は、真の力を発揮し、世界に平和をもたらした。');
        break;
      case 'lonely_hero':
        console.log('\n【孤独な英雄エンディング】');
        console.log('一人の力で世界を救った主人公。しかし、その心は深い孤独に包まれていた。');
        break;
      case 'new_bonds':
        console.log('\n【新たな絆エンディング】');
        console.log('新しい仲間たちとの出会いが、主人公に新たな可能性を示した。');
        break;
      default:
        console.log('\n【標準エンディング】');
        console.log('仲間たちと共に世界を救った主人公。彼らの旅は新たな始まりとなった。');
    }
  }

  private calculateAverageRelationship(): number {
    let total = 0;
    let count = 0;
    
    for (let i = 0; i < this.party.length; i++) {
      for (let j = i + 1; j < this.party.length; j++) {
        total += this.relationshipSystem.getRelationshipValue(this.party[i].id, this.party[j].id);
        count++;
      }
    }
    
    return count > 0 ? total / count : 50;
  }
}