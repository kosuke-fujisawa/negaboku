import { Character, RelationshipMatrix } from '../types/Character';
import { initialCharacters, dlcCharacters } from '../data/characters';

export class RelationshipSystem {
  private relationships: RelationshipMatrix;

  constructor() {
    this.relationships = {};
    this.initializeRelationships();
  }

  private initializeRelationships(): void {
    const allCharacters = [...initialCharacters, ...dlcCharacters];
    
    for (const character of allCharacters) {
      this.relationships[character.id] = { ...character.defaultRelationships };
    }
  }

  getRelationshipValue(characterId: string, targetCharacterId: string): number {
    return this.relationships[characterId]?.[targetCharacterId] ?? 50;
  }

  setRelationshipValue(characterId: string, targetCharacterId: string, value: number): void {
    if (!this.relationships[characterId]) {
      this.relationships[characterId] = {};
    }
    this.relationships[characterId][targetCharacterId] = Math.max(-25, Math.min(100, value));
  }

  modifyRelationship(characterId: string, targetCharacterId: string, change: number): void {
    const currentValue = this.getRelationshipValue(characterId, targetCharacterId);
    this.setRelationshipValue(characterId, targetCharacterId, currentValue + change);
  }

  getRelationshipLevel(value: number): string {
    if (value >= 80) return '親密';
    if (value >= 60) return '友好';
    if (value >= 40) return '普通';
    if (value >= 20) return '冷淡';
    if (value >= 0) return '険悪';
    return '敵対';
  }

  canUseCooperationSkill(characterId: string, targetCharacterId: string, requiredValue: number = 70): boolean {
    return this.getRelationshipValue(characterId, targetCharacterId) >= requiredValue;
  }

  canUseConflictSkill(characterId: string, targetCharacterId: string, requiredValue: number = 30): boolean {
    return this.getRelationshipValue(characterId, targetCharacterId) <= requiredValue;
  }

  handleBattleEvent(eventType: BattleEventType, characterId: string, targetCharacterId?: string): void {
    if (!targetCharacterId) return;

    switch (eventType) {
      case BattleEventType.COOPERATION:
        this.modifyRelationship(characterId, targetCharacterId, 2);
        this.modifyRelationship(targetCharacterId, characterId, 2);
        break;
      case BattleEventType.FRIENDLY_FIRE:
        this.modifyRelationship(characterId, targetCharacterId, -3);
        this.modifyRelationship(targetCharacterId, characterId, -3);
        break;
      case BattleEventType.PROTECTION:
        this.modifyRelationship(characterId, targetCharacterId, 3);
        this.modifyRelationship(targetCharacterId, characterId, 1);
        break;
      case BattleEventType.RIVALRY:
        this.modifyRelationship(characterId, targetCharacterId, -1);
        this.modifyRelationship(targetCharacterId, characterId, -1);
        break;
    }
  }

  getAllRelationships(): RelationshipMatrix {
    return { ...this.relationships };
  }

  loadRelationships(relationships: RelationshipMatrix): void {
    this.relationships = { ...relationships };
  }
}

export enum BattleEventType {
  COOPERATION = 'cooperation',
  FRIENDLY_FIRE = 'friendly_fire',
  PROTECTION = 'protection',
  RIVALRY = 'rivalry'
}