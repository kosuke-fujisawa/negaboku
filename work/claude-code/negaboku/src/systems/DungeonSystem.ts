import { 
  Dungeon, 
  DungeonFloor, 
  DungeonEvent, 
  DungeonChoice, 
  ChoiceConsequence, 
  ConsequenceType,
  ExplorationState,
  PartyStatus,
  DungeonEventType,
  TreasureRarity,
  DungeonDifficulty
} from '../types/Dungeon';
import { Character } from '../types/Character';
import { RelationshipSystem } from './RelationshipSystem';
import { InventoryItem } from '../types/Save';

export class DungeonSystem {
  private dungeons: Map<string, Dungeon>;
  private currentExploration: ExplorationState | null;
  private relationshipSystem: RelationshipSystem;
  private party: Character[];
  private inventory: InventoryItem[];

  constructor(relationshipSystem: RelationshipSystem) {
    this.dungeons = new Map();
    this.currentExploration = null;
    this.relationshipSystem = relationshipSystem;
    this.party = [];
    this.inventory = [];
    this.initializeDungeons();
  }

  private initializeDungeons(): void {
    const starterDungeon: Dungeon = {
      id: 'dungeon_001',
      name: '忘れられた遺跡',
      description: '古代の謎に満ちた遺跡。冒険の始まりの場所。',
      floors: [
        {
          floorNumber: 1,
          events: [
            {
              id: 'event_001',
              type: DungeonEventType.CHOICE,
              title: '分かれ道',
              description: '道が二手に分かれている。左の道は暗く、右の道は光が差している。',
              choices: [
                {
                  id: 'choice_001_left',
                  text: '左の道を進む',
                  description: 'リスクがありそうだが、何か見つかるかもしれない',
                  consequences: [
                    { type: ConsequenceType.GOLD_CHANGE, value: 100 },
                    { type: ConsequenceType.HP_CHANGE, value: -10, characterId: 'random' }
                  ]
                },
                {
                  id: 'choice_001_right',
                  text: '右の道を進む',
                  description: '安全そうだが、平凡な道のりになりそうだ',
                  consequences: [
                    { type: ConsequenceType.MP_CHANGE, value: 5, characterId: 'all' }
                  ]
                }
              ]
            }
          ],
          enemyEncounters: [
            {
              id: 'encounter_001',
              enemies: ['goblin', 'orc'],
              encounterRate: 0.3,
              canEscape: true,
              ambushChance: 0.1
            }
          ],
          treasures: [
            {
              id: 'treasure_001',
              contents: [
                { itemId: 'potion', quantity: 2, rarity: TreasureRarity.COMMON }
              ],
              isHidden: false,
              trapChance: 0.1
            }
          ],
          isBossFloor: false
        },
        {
          floorNumber: 2,
          events: [
            {
              id: 'event_002',
              type: DungeonEventType.RELATIONSHIP,
              title: 'パーティの連携',
              description: 'パーティメンバー同士の連携が試される場面に遭遇した。',
              choices: [
                {
                  id: 'choice_002_cooperate',
                  text: 'チームワークを重視する',
                  consequences: [
                    { type: ConsequenceType.RELATIONSHIP_CHANGE, value: 5, characterId: 'all' }
                  ]
                },
                {
                  id: 'choice_002_individual',
                  text: '個人の実力を重視する',
                  consequences: [
                    { type: ConsequenceType.EXPERIENCE_GAIN, value: 50, characterId: 'all' },
                    { type: ConsequenceType.RELATIONSHIP_CHANGE, value: -2, characterId: 'all' }
                  ]
                }
              ]
            }
          ],
          enemyEncounters: [
            {
              id: 'encounter_002',
              enemies: ['skeleton', 'zombie'],
              encounterRate: 0.4,
              canEscape: true,
              ambushChance: 0.15
            }
          ],
          treasures: [],
          isBossFloor: true,
          bossEncounter: {
            id: 'boss_001',
            bossId: 'ancient_guardian',
            preDialogue: '古代の守護者が立ちはだかる...',
            postDialogue: '守護者を倒し、オーブの欠片を手に入れた！',
            specialRewards: ['orb_fragment_1'],
            unlocksDungeon: 'dungeon_002'
          }
        }
      ],
      requiredOrbs: 0,
      isUnlocked: true,
      isCleared: false,
      difficulty: DungeonDifficulty.EASY,
      rewards: [
        { itemId: 'orb_fragment', quantity: 1, isGuaranteed: true }
      ]
    };

    this.dungeons.set(starterDungeon.id, starterDungeon);
  }

  setParty(party: Character[]): void {
    this.party = [...party];
  }

  setInventory(inventory: InventoryItem[]): void {
    this.inventory = [...inventory];
  }

  startExploration(dungeonId: string, party: Character[]): boolean {
    const dungeon = this.dungeons.get(dungeonId);
    if (!dungeon || !dungeon.isUnlocked) {
      return false;
    }

    this.party = [...party];
    this.currentExploration = {
      currentDungeon: dungeonId,
      currentFloor: 1,
      visitedRooms: [],
      triggeredEvents: [],
      obtainedTreasures: [],
      partyStatus: this.initializePartyStatus(party)
    };

    return true;
  }

  private initializePartyStatus(party: Character[]): PartyStatus {
    const status: PartyStatus = {
      hp: {},
      mp: {},
      statusEffects: {}
    };

    for (const character of party) {
      status.hp[character.id] = character.hp;
      status.mp[character.id] = character.mp;
      status.statusEffects[character.id] = [];
    }

    return status;
  }

  getCurrentFloorEvents(): DungeonEvent[] {
    if (!this.currentExploration) return [];

    const dungeon = this.dungeons.get(this.currentExploration.currentDungeon);
    if (!dungeon) return [];

    const currentFloor = dungeon.floors.find(f => f.floorNumber === this.currentExploration!.currentFloor);
    return currentFloor ? currentFloor.events : [];
  }

  processChoice(eventId: string, choiceId: string): ChoiceConsequence[] {
    if (!this.currentExploration) return [];

    const events = this.getCurrentFloorEvents();
    const event = events.find(e => e.id === eventId);
    if (!event) return [];

    const choice = event.choices.find(c => c.id === choiceId);
    if (!choice) return [];

    this.currentExploration.triggeredEvents.push(eventId);

    for (const consequence of choice.consequences) {
      this.applyConsequence(consequence);
    }

    return choice.consequences;
  }

  private applyConsequence(consequence: ChoiceConsequence): void {
    if (!this.currentExploration) return;

    switch (consequence.type) {
      case ConsequenceType.HP_CHANGE:
        this.applyHPChange(consequence);
        break;
      case ConsequenceType.MP_CHANGE:
        this.applyMPChange(consequence);
        break;
      case ConsequenceType.RELATIONSHIP_CHANGE:
        this.applyRelationshipChange(consequence);
        break;
      case ConsequenceType.GOLD_CHANGE:
        break;
      case ConsequenceType.EXPERIENCE_GAIN:
        this.applyExperienceGain(consequence);
        break;
    }
  }

  private applyHPChange(consequence: ChoiceConsequence): void {
    if (!this.currentExploration) return;

    if (consequence.characterId === 'all') {
      for (const character of this.party) {
        this.currentExploration.partyStatus.hp[character.id] = Math.max(0, 
          Math.min(character.maxHp, this.currentExploration.partyStatus.hp[character.id] + consequence.value)
        );
      }
    } else if (consequence.characterId === 'random') {
      const randomCharacter = this.party[Math.floor(Math.random() * this.party.length)];
      this.currentExploration.partyStatus.hp[randomCharacter.id] = Math.max(0,
        Math.min(randomCharacter.maxHp, this.currentExploration.partyStatus.hp[randomCharacter.id] + consequence.value)
      );
    } else if (consequence.characterId) {
      const character = this.party.find(c => c.id === consequence.characterId);
      if (character) {
        this.currentExploration.partyStatus.hp[character.id] = Math.max(0,
          Math.min(character.maxHp, this.currentExploration.partyStatus.hp[character.id] + consequence.value)
        );
      }
    }
  }

  private applyMPChange(consequence: ChoiceConsequence): void {
    if (!this.currentExploration) return;

    if (consequence.characterId === 'all') {
      for (const character of this.party) {
        this.currentExploration.partyStatus.mp[character.id] = Math.max(0,
          Math.min(character.maxMp, this.currentExploration.partyStatus.mp[character.id] + consequence.value)
        );
      }
    }
  }

  private applyRelationshipChange(consequence: ChoiceConsequence): void {
    if (consequence.characterId === 'all') {
      for (let i = 0; i < this.party.length; i++) {
        for (let j = i + 1; j < this.party.length; j++) {
          this.relationshipSystem.modifyRelationship(this.party[i].id, this.party[j].id, consequence.value);
          this.relationshipSystem.modifyRelationship(this.party[j].id, this.party[i].id, consequence.value);
        }
      }
    }
  }

  private applyExperienceGain(consequence: ChoiceConsequence): void {
    if (consequence.characterId === 'all') {
      for (const character of this.party) {
        character.level += Math.floor(consequence.value / 100);
      }
    }
  }

  moveToNextFloor(): boolean {
    if (!this.currentExploration) return false;

    const dungeon = this.dungeons.get(this.currentExploration.currentDungeon);
    if (!dungeon) return false;

    if (this.currentExploration.currentFloor >= dungeon.floors.length) {
      this.completeDungeon();
      return false;
    }

    this.currentExploration.currentFloor++;
    this.currentExploration.visitedRooms = [];
    this.currentExploration.triggeredEvents = [];
    
    return true;
  }

  private completeDungeon(): void {
    if (!this.currentExploration) return;

    const dungeon = this.dungeons.get(this.currentExploration.currentDungeon);
    if (dungeon) {
      dungeon.isCleared = true;
    }

    this.currentExploration = null;
  }

  getDungeon(dungeonId: string): Dungeon | undefined {
    return this.dungeons.get(dungeonId);
  }

  getAllDungeons(): Dungeon[] {
    return Array.from(this.dungeons.values());
  }

  getUnlockedDungeons(): Dungeon[] {
    return Array.from(this.dungeons.values()).filter(d => d.isUnlocked);
  }

  unlockDungeon(dungeonId: string): void {
    const dungeon = this.dungeons.get(dungeonId);
    if (dungeon) {
      dungeon.isUnlocked = true;
    }
  }

  getCurrentExploration(): ExplorationState | null {
    return this.currentExploration ? { ...this.currentExploration } : null;
  }

  isEventTriggered(eventId: string): boolean {
    return this.currentExploration?.triggeredEvents.includes(eventId) ?? false;
  }

  isTreasureObtained(treasureId: string): boolean {
    return this.currentExploration?.obtainedTreasures.includes(treasureId) ?? false;
  }
}