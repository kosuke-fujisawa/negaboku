import { Character, RelationshipMatrix } from './Character';

export interface SaveData {
  id: string;
  slotNumber: number;
  playerName: string;
  playTime: number;
  saveDate: Date;
  gameProgress: GameProgress;
  party: Character[];
  relationships: RelationshipMatrix;
  inventory: InventoryItem[];
  clearedDungeons: string[];
  availableDungeons: string[];
  orbs: number;
  gold: number;
  level: number;
  experience: number;
  dlcUnlocked: boolean;
}

export interface GameProgress {
  currentDungeon?: string;
  currentFloor: number;
  storyFlags: Record<string, boolean>;
  eventFlags: Record<string, boolean>;
  endingsSeen: string[];
}

export interface InventoryItem {
  id: string;
  name: string;
  quantity: number;
  type: ItemType;
  description: string;
}

export enum ItemType {
  CONSUMABLE = 'consumable',
  WEAPON = 'weapon',
  ARMOR = 'armor',
  ACCESSORY = 'accessory',
  KEY_ITEM = 'key_item'
}

export interface SaveSlot {
  slotNumber: number;
  isOccupied: boolean;
  saveData?: SaveData;
  lastModified?: Date;
}