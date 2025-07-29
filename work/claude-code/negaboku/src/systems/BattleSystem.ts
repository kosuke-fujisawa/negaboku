import { Character, Skill, SkillType } from '../types/Character';
import { BattleCharacter, BattleAction, BattleActionType, BattleResult, Enemy, StatusEffect, StatusEffectType } from '../types/Battle';
import { RelationshipSystem, BattleEventType } from './RelationshipSystem';

export class BattleSystem {
  private playerParty: BattleCharacter[];
  private enemies: Enemy[];
  private relationshipSystem: RelationshipSystem;
  private turnOrder: string[];
  private currentTurn: number;

  constructor(party: Character[], enemies: Enemy[], relationshipSystem: RelationshipSystem) {
    this.playerParty = party.map(char => this.characterToBattleCharacter(char));
    this.enemies = enemies.map(enemy => this.initializeEnemy(enemy));
    this.relationshipSystem = relationshipSystem;
    this.turnOrder = [];
    this.currentTurn = 0;
    this.initializeTurnOrder();
  }

  private initializeEnemy(enemy: Enemy): Enemy {
    return {
      ...enemy,
      currentHp: enemy.hp,
      statusEffects: []
    };
  }

  private characterToBattleCharacter(character: Character): BattleCharacter {
    return {
      ...character,
      currentHp: character.hp,
      currentMp: character.mp,
      statusEffects: [],
      position: 0
    };
  }

  private initializeTurnOrder(): void {
    const allCombatants = [
      ...this.playerParty.map(char => ({ id: char.id, speed: char.speed, type: 'player' })),
      ...this.enemies.map(enemy => ({ id: enemy.id, speed: enemy.speed, type: 'enemy' }))
    ];

    this.turnOrder = allCombatants
      .sort((a, b) => b.speed - a.speed)
      .map(combatant => combatant.id);
  }

  executeAction(action: BattleAction): void {
    const actor = this.getCombatantById(action.actorId);
    if (!actor || this.isDefeated(actor)) return;

    switch (action.type) {
      case BattleActionType.ATTACK:
        this.executeBasicAttack(action);
        break;
      case BattleActionType.SKILL:
        this.executeSkill(action);
        break;
      case BattleActionType.DEFEND:
        this.executeDefend(action);
        break;
    }

    this.processStatusEffects();
    this.nextTurn();
  }

  private executeBasicAttack(action: BattleAction): void {
    const attacker = this.getCombatantById(action.actorId);
    const target = this.getCombatantById(action.targetIds[0]);
    
    if (!attacker || !target) return;

    const damage = Math.max(1, attacker.attack - target.defense);
    this.dealDamage(target, damage);
  }

  private executeSkill(action: BattleAction): void {
    const caster = this.getCombatantById(action.actorId);
    if (!caster || !action.skillId) return;

    const skill = this.getSkillById(caster, action.skillId);
    if (!skill) return;

    const currentMp = 'currentMp' in caster ? caster.currentMp : 0;
    if (currentMp < skill.mpCost) return;

    if ('currentMp' in caster) {
      caster.currentMp -= skill.mpCost;
    }

    switch (skill.type) {
      case SkillType.NORMAL:
        this.executeNormalSkill(caster, skill, action.targetIds);
        break;
      case SkillType.COOPERATION:
        this.executeCooperationSkill(caster, skill, action.targetIds);
        break;
      case SkillType.CONFLICT:
        this.executeConflictSkill(caster, skill, action.targetIds);
        break;
    }
  }

  private executeNormalSkill(caster: BattleCharacter | Enemy, skill: Skill, targetIds: string[]): void {
    for (const targetId of targetIds) {
      const target = this.getCombatantById(targetId);
      if (!target) continue;

      if (skill.power > 0) {
        const damage = skill.power;
        this.dealDamage(target, damage);
      } else if (skill.power < 0) {
        const healing = Math.abs(skill.power);
        this.heal(target, healing);
      }
    }
  }

  private executeCooperationSkill(caster: BattleCharacter | Enemy, skill: Skill, targetIds: string[]): void {
    const partnerId = skill.requiredCharacters?.[0];
    if (partnerId && this.relationshipSystem.canUseCooperationSkill(caster.id, partnerId)) {
      const enhancedPower = skill.power * 1.5;
      
      for (const targetId of targetIds) {
        const target = this.getCombatantById(targetId);
        if (target) {
          this.dealDamage(target, enhancedPower);
        }
      }

      this.relationshipSystem.handleBattleEvent(BattleEventType.COOPERATION, caster.id, partnerId);
    }
  }

  private executeConflictSkill(caster: BattleCharacter | Enemy, skill: Skill, targetIds: string[]): void {
    const rivalId = skill.requiredCharacters?.[0];
    if (rivalId && this.relationshipSystem.canUseConflictSkill(caster.id, rivalId)) {
      const enhancedPower = skill.power * 1.3;
      
      for (const targetId of targetIds) {
        const target = this.getCombatantById(targetId);
        if (target) {
          this.dealDamage(target, enhancedPower);
        }
      }

      this.relationshipSystem.handleBattleEvent(BattleEventType.RIVALRY, caster.id, rivalId);
    }
  }

  private executeDefend(action: BattleAction): void {
    const defender = this.getCombatantById(action.actorId);
    if (!defender) return;

    const defenseBoost: StatusEffect = {
      id: 'defense_boost',
      name: '防御',
      duration: 1,
      type: StatusEffectType.DEFENSE_UP,
      value: Math.floor(defender.defense * 0.5)
    };

    defender.statusEffects.push(defenseBoost);
  }

  private dealDamage(target: BattleCharacter | Enemy, damage: number): void {
    const finalDamage = Math.max(1, damage);
    target.currentHp = Math.max(0, target.currentHp - finalDamage);
  }

  private heal(target: BattleCharacter | Enemy, healing: number): void {
    let maxHp: number;
    if ('maxHp' in target && target.maxHp !== undefined) {
      maxHp = target.maxHp;
    } else if ('hp' in target) {
      maxHp = target.hp;
    } else {
      maxHp = 100; // デフォルト値
    }
    target.currentHp = Math.min(maxHp, target.currentHp + healing);
  }

  private processStatusEffects(): void {
    const allCombatants: (BattleCharacter | Enemy)[] = [...this.playerParty, ...this.enemies];
    
    for (const combatant of allCombatants) {
      combatant.statusEffects = combatant.statusEffects.filter((effect: StatusEffect) => {
        this.applyStatusEffect(combatant, effect);
        effect.duration--;
        return effect.duration > 0;
      });
    }
  }

  private applyStatusEffect(combatant: BattleCharacter | Enemy, effect: StatusEffect): void {
    switch (effect.type) {
      case StatusEffectType.POISON:
        this.dealDamage(combatant, effect.value);
        break;
    }
  }

  private getCombatantById(id: string): BattleCharacter | Enemy | undefined {
    return this.playerParty.find(char => char.id === id) || 
           this.enemies.find(enemy => enemy.id === id);
  }

  private getSkillById(combatant: BattleCharacter | Enemy, skillId: string): Skill | undefined {
    if ('skills' in combatant && Array.isArray(combatant.skills)) {
      return (combatant.skills as Skill[]).find(skill => skill.id === skillId);
    }
    return undefined;
  }

  private isDefeated(combatant: BattleCharacter | Enemy): boolean {
    return combatant.currentHp <= 0;
  }

  private nextTurn(): void {
    this.currentTurn = (this.currentTurn + 1) % this.turnOrder.length;
  }

  isBattleOver(): boolean {
    const playersAlive = this.playerParty.some(char => !this.isDefeated(char));
    const enemiesAlive = this.enemies.some(enemy => !this.isDefeated(enemy));
    
    return !playersAlive || !enemiesAlive;
  }

  getBattleResult(): BattleResult {
    const playersWon = this.enemies.every(enemy => this.isDefeated(enemy));
    
    return {
      winner: playersWon ? 'player' : 'enemy',
      experience: playersWon ? this.enemies.reduce((sum, enemy) => sum + enemy.experience, 0) : 0,
      gold: playersWon ? this.enemies.reduce((sum, enemy) => sum + enemy.gold, 0) : 0,
      items: playersWon ? this.enemies.flatMap(enemy => enemy.dropItems) : [],
      relationshipChanges: this.relationshipSystem.getAllRelationships()
    };
  }

  getCurrentTurnActor(): string {
    return this.turnOrder[this.currentTurn];
  }

  getPlayerParty(): BattleCharacter[] {
    return [...this.playerParty];
  }

  getEnemies(): Enemy[] {
    return [...this.enemies];
  }
}