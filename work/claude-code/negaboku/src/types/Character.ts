export interface Character {
  id: string;
  name: string;
  level: number;
  hp: number;
  maxHp: number;
  mp: number;
  maxMp: number;
  attack: number;
  defense: number;
  speed: number;
  isDLC: boolean;
  defaultRelationships: Record<string, number>;
  skills: Skill[];
}

export interface Skill {
  id: string;
  name: string;
  type: SkillType;
  power: number;
  mpCost: number;
  description: string;
  requiredLevel?: number;
  requiredCharacters?: string[];
  requiredRelationshipValue?: number;
}

export enum SkillType {
  NORMAL = 'normal',
  CONFLICT = 'conflict',
  COOPERATION = 'cooperation'
}

export interface RelationshipMatrix {
  [characterId: string]: {
    [targetCharacterId: string]: number;
  };
}