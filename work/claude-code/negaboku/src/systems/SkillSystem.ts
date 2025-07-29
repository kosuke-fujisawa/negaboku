import { Skill, SkillType, Character } from '../types/Character';
import { RelationshipSystem } from './RelationshipSystem';
import { getAllSkills, getAvailableSkills } from '../data/skills';

export class SkillSystem {
  private relationshipSystem: RelationshipSystem;
  private allSkills: Skill[];
  private unlockedSkills: Set<string>;

  constructor(relationshipSystem: RelationshipSystem) {
    this.relationshipSystem = relationshipSystem;
    this.allSkills = getAllSkills();
    this.unlockedSkills = new Set();
  }

  initializeCharacterSkills(characters: Character[]): void {
    for (const character of characters) {
      this.updateAvailableSkills(character);
    }
  }

  updateAvailableSkills(character: Character): void {
    const characterIds = [character.id];
    const relationships = this.relationshipSystem.getAllRelationships();
    const levels = { [character.id]: character.level };

    const availableSkills = getAvailableSkills(characterIds, relationships, levels);
    
    for (const skill of availableSkills) {
      if (!character.skills.some(s => s.id === skill.id)) {
        character.skills.push(skill);
        this.unlockedSkills.add(skill.id);
      }
    }
  }

  updatePartySkills(party: Character[]): void {
    const characterIds = party.map(c => c.id);
    const relationships = this.relationshipSystem.getAllRelationships();
    const levels: Record<string, number> = {};
    
    for (const character of party) {
      levels[character.id] = character.level;
    }

    const availableSkills = getAvailableSkills(characterIds, relationships, levels);
    
    const partySkills = new Set<string>();
    for (const character of party) {
      for (const skill of character.skills) {
        partySkills.add(skill.id);
      }
    }

    for (const skill of availableSkills) {
      if (!partySkills.has(skill.id)) {
        const primaryCharacter = this.findPrimaryCharacterForSkill(skill, party);
        if (primaryCharacter && !primaryCharacter.skills.some(s => s.id === skill.id)) {
          primaryCharacter.skills.push(skill);
          this.unlockedSkills.add(skill.id);
        }
      }
    }
  }

  private findPrimaryCharacterForSkill(skill: Skill, party: Character[]): Character | undefined {
    if (!skill.requiredCharacters || skill.requiredCharacters.length === 0) {
      return undefined;
    }

    const primaryCharacterId = skill.requiredCharacters[0];
    return party.find(c => c.id === primaryCharacterId);
  }

  canUseSkill(skill: Skill, caster: Character, party: Character[]): boolean {
    if (caster.mp < skill.mpCost) {
      return false;
    }

    if (skill.requiredLevel && caster.level < skill.requiredLevel) {
      return false;
    }

    if (skill.type === SkillType.NORMAL) {
      return true;
    }

    if (!skill.requiredCharacters || skill.requiredCharacters.length < 2) {
      return false;
    }

    const requiredCharactersInParty = skill.requiredCharacters.every(reqCharId =>
      party.some(p => p.id === reqCharId && p.hp > 0)
    );

    if (!requiredCharactersInParty) {
      return false;
    }

    if (skill.requiredRelationshipValue) {
      const [char1, char2] = skill.requiredCharacters;
      const relationshipValue = this.relationshipSystem.getRelationshipValue(char1, char2);

      if (skill.type === SkillType.COOPERATION) {
        return relationshipValue >= skill.requiredRelationshipValue;
      } else if (skill.type === SkillType.CONFLICT) {
        return relationshipValue <= skill.requiredRelationshipValue;
      }
    }

    return true;
  }

  getSkillPowerModifier(skill: Skill, caster: Character, party: Character[]): number {
    let modifier = 1.0;

    if (skill.type === SkillType.COOPERATION && skill.requiredCharacters && skill.requiredCharacters.length >= 2) {
      const [char1Id, char2Id] = skill.requiredCharacters;
      const relationshipValue = this.relationshipSystem.getRelationshipValue(char1Id, char2Id);
      
      modifier = 1.0 + (relationshipValue - 70) * 0.01;
      modifier = Math.max(1.0, Math.min(1.5, modifier));
      
      const partnersInParty = skill.requiredCharacters.filter(reqCharId =>
        party.some(p => p.id === reqCharId && p.hp > 0)
      ).length;
      
      if (partnersInParty >= skill.requiredCharacters.length) {
        modifier *= 1.2;
      }
    }

    if (skill.type === SkillType.CONFLICT && skill.requiredCharacters && skill.requiredCharacters.length >= 2) {
      const [char1Id, char2Id] = skill.requiredCharacters;
      const relationshipValue = this.relationshipSystem.getRelationshipValue(char1Id, char2Id);
      
      modifier = 1.0 + (30 - relationshipValue) * 0.015;
      modifier = Math.max(1.0, Math.min(1.4, modifier));
      
      if (relationshipValue <= 10) {
        modifier *= 1.3;
      }
    }

    return modifier;
  }

  getUsableSkills(character: Character, party: Character[]): Skill[] {
    return character.skills.filter(skill => this.canUseSkill(skill, character, party));
  }

  getCooperationSkills(party: Character[]): Skill[] {
    const cooperationSkills: Skill[] = [];
    
    for (const character of party) {
      for (const skill of character.skills) {
        if (skill.type === SkillType.COOPERATION && this.canUseSkill(skill, character, party)) {
          cooperationSkills.push(skill);
        }
      }
    }
    
    return cooperationSkills;
  }

  getConflictSkills(party: Character[]): Skill[] {
    const conflictSkills: Skill[] = [];
    
    for (const character of party) {
      for (const skill of character.skills) {
        if (skill.type === SkillType.CONFLICT && this.canUseSkill(skill, character, party)) {
          conflictSkills.push(skill);
        }
      }
    }
    
    return conflictSkills;
  }

  unlockNewSkills(party: Character[]): Skill[] {
    const newlyUnlocked: Skill[] = [];
    const characterIds = party.map(c => c.id);
    const relationships = this.relationshipSystem.getAllRelationships();
    const levels: Record<string, number> = {};
    
    for (const character of party) {
      levels[character.id] = character.level;
    }

    const availableSkills = getAvailableSkills(characterIds, relationships, levels);
    
    for (const skill of availableSkills) {
      if (!this.unlockedSkills.has(skill.id)) {
        const primaryCharacter = this.findPrimaryCharacterForSkill(skill, party);
        if (primaryCharacter && !primaryCharacter.skills.some(s => s.id === skill.id)) {
          primaryCharacter.skills.push(skill);
          this.unlockedSkills.add(skill.id);
          newlyUnlocked.push(skill);
        }
      }
    }

    return newlyUnlocked;
  }

  getSkillById(skillId: string): Skill | undefined {
    return this.allSkills.find(skill => skill.id === skillId);
  }

  getRelationshipRequiredForSkill(skill: Skill): { min?: number; max?: number } {
    if (!skill.requiredRelationshipValue) {
      return {};
    }

    if (skill.type === SkillType.COOPERATION) {
      return { min: skill.requiredRelationshipValue };
    } else if (skill.type === SkillType.CONFLICT) {
      return { max: skill.requiredRelationshipValue };
    }

    return {};
  }

  getSkillsByCharacterPair(char1Id: string, char2Id: string): Skill[] {
    return this.allSkills.filter(skill => 
      skill.requiredCharacters && 
      skill.requiredCharacters.includes(char1Id) && 
      skill.requiredCharacters.includes(char2Id)
    );
  }

  isSkillUnlocked(skillId: string): boolean {
    return this.unlockedSkills.has(skillId);
  }

  getUnlockedSkillsCount(): number {
    return this.unlockedSkills.size;
  }

  getTotalSkillsCount(): number {
    return this.allSkills.length;
  }
}