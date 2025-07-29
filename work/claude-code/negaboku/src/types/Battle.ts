import { Character } from './Character';

export interface BattleCharacter extends Character {
  currentHp: number;
  currentMp: number;
  statusEffects: StatusEffect[];
  position: number;
}

export interface StatusEffect {
  id: string;
  name: string;
  duration: number;
  type: StatusEffectType;
  value: number;
}

export enum StatusEffectType {
  POISON = 'poison',
  PARALYSIS = 'paralysis',
  SLEEP = 'sleep',
  CONFUSION = 'confusion',
  ATTACK_UP = 'attack_up',
  DEFENSE_UP = 'defense_up',
  SPEED_UP = 'speed_up',
  ATTACK_DOWN = 'attack_down',
  DEFENSE_DOWN = 'defense_down',
  SPEED_DOWN = 'speed_down'
}

export interface BattleAction {
  actorId: string;
  type: BattleActionType;
  skillId?: string;
  targetIds: string[];
  priority: number;
}

export enum BattleActionType {
  ATTACK = 'attack',
  SKILL = 'skill',
  ITEM = 'item',
  DEFEND = 'defend',
  ESCAPE = 'escape'
}

export interface BattleResult {
  winner: 'player' | 'enemy';
  experience: number;
  gold: number;
  items: string[];
  relationshipChanges: Record<string, Record<string, number>>;
}

export interface Enemy {
  id: string;
  name: string;
  level: number;
  hp: number;
  maxHp: number;
  currentHp: number;
  attack: number;
  defense: number;
  speed: number;
  skills: string[];
  statusEffects: StatusEffect[];
  experience: number;
  gold: number;
  dropItems: string[];
}