export interface Dungeon {
  id: string;
  name: string;
  description: string;
  floors: DungeonFloor[];
  requiredOrbs: number;
  isUnlocked: boolean;
  isCleared: boolean;
  difficulty: DungeonDifficulty;
  rewards: DungeonReward[];
}

export interface DungeonFloor {
  floorNumber: number;
  events: DungeonEvent[];
  enemyEncounters: EnemyEncounter[];
  treasures: TreasureChest[];
  isBossFloor: boolean;
  bossEncounter?: BossEncounter;
}

export interface DungeonEvent {
  id: string;
  type: DungeonEventType;
  title: string;
  description: string;
  choices: DungeonChoice[];
  conditions?: EventCondition[];
}

export enum DungeonEventType {
  STORY = 'story',
  CHOICE = 'choice',
  RELATIONSHIP = 'relationship',
  TREASURE = 'treasure',
  TRAP = 'trap',
  REST = 'rest',
  MERCHANT = 'merchant'
}

export interface DungeonChoice {
  id: string;
  text: string;
  description?: string;
  consequences: ChoiceConsequence[];
  requirements?: ChoiceRequirement[];
}

export interface ChoiceConsequence {
  type: ConsequenceType;
  value: number;
  targetId?: string;
  characterId?: string;
}

export enum ConsequenceType {
  HP_CHANGE = 'hp_change',
  MP_CHANGE = 'mp_change',
  RELATIONSHIP_CHANGE = 'relationship_change',
  GOLD_CHANGE = 'gold_change',
  ITEM_GAIN = 'item_gain',
  ITEM_LOSS = 'item_loss',
  EXPERIENCE_GAIN = 'experience_gain',
  STATUS_EFFECT = 'status_effect',
  UNLOCK_SKILL = 'unlock_skill'
}

export interface ChoiceRequirement {
  type: RequirementType;
  value: number;
  targetId?: string;
  characterId?: string;
}

export enum RequirementType {
  CHARACTER_LEVEL = 'character_level',
  RELATIONSHIP_VALUE = 'relationship_value',
  ITEM_POSSESSION = 'item_possession',
  GOLD_AMOUNT = 'gold_amount',
  PARTY_MEMBER = 'party_member',
  STORY_FLAG = 'story_flag'
}

export interface EventCondition {
  type: RequirementType;
  value: number;
  targetId?: string;
  characterId?: string;
}

export interface EnemyEncounter {
  id: string;
  enemies: string[];
  encounterRate: number;
  canEscape: boolean;
  ambushChance: number;
}

export interface BossEncounter {
  id: string;
  bossId: string;
  preDialogue?: string;
  postDialogue?: string;
  specialRewards: string[];
  unlocksDungeon?: string;
}

export interface TreasureChest {
  id: string;
  contents: TreasureContent[];
  isHidden: boolean;
  requiresKey?: string;
  trapChance: number;
}

export interface TreasureContent {
  itemId: string;
  quantity: number;
  rarity: TreasureRarity;
}

export enum TreasureRarity {
  COMMON = 'common',
  UNCOMMON = 'uncommon',
  RARE = 'rare',
  LEGENDARY = 'legendary'
}

export enum DungeonDifficulty {
  EASY = 'easy',
  NORMAL = 'normal',
  HARD = 'hard',
  NIGHTMARE = 'nightmare'
}

export interface DungeonReward {
  itemId: string;
  quantity: number;
  isGuaranteed: boolean;
}

export interface ExplorationState {
  currentDungeon: string;
  currentFloor: number;
  visitedRooms: string[];
  triggeredEvents: string[];
  obtainedTreasures: string[];
  partyStatus: PartyStatus;
}

export interface PartyStatus {
  hp: Record<string, number>;
  mp: Record<string, number>;
  statusEffects: Record<string, string[]>;
}