import { Skill, SkillType } from '../types/Character';

export const cooperationSkills: Skill[] = [
  {
    id: 'coop_001',
    name: '双剣連撃',
    type: SkillType.COOPERATION,
    power: 45,
    mpCost: 20,
    description: 'アキラとタケシの連携攻撃。友好度70以上で使用可能',
    requiredLevel: 5,
    requiredCharacters: ['char_001', 'char_003'],
    requiredRelationshipValue: 70
  },
  {
    id: 'coop_002',
    name: '氷炎融合',
    type: SkillType.COOPERATION,
    power: 50,
    mpCost: 25,
    description: 'ユキとリュウの協力魔法。氷と炎の力を合わせた攻撃',
    requiredLevel: 6,
    requiredCharacters: ['char_002', 'char_005'],
    requiredRelationshipValue: 75
  },
  {
    id: 'coop_003',
    name: 'ヒーリングサークル',
    type: SkillType.COOPERATION,
    power: -60,
    mpCost: 30,
    description: 'サクラとミキの治癒魔法。パーティ全体を回復',
    requiredLevel: 4,
    requiredCharacters: ['char_004', 'char_006'],
    requiredRelationshipValue: 65
  },
  {
    id: 'coop_004',
    name: '雷風嵐',
    type: SkillType.COOPERATION,
    power: 55,
    mpCost: 35,
    description: 'アヤとミキの合体魔法。雷と風の複合攻撃',
    requiredLevel: 7,
    requiredCharacters: ['char_008', 'char_006'],
    requiredRelationshipValue: 80
  },
  {
    id: 'coop_005',
    name: '守護の盾',
    type: SkillType.COOPERATION,
    power: 0,
    mpCost: 15,
    description: 'タケシとケンジの防御連携。パーティの防御力を大幅上昇',
    requiredLevel: 5,
    requiredCharacters: ['char_003', 'char_007'],
    requiredRelationshipValue: 70
  },
  {
    id: 'coop_dlc_001',
    name: '光闇調和',
    type: SkillType.COOPERATION,
    power: 65,
    mpCost: 40,
    description: 'レイとエルの究極連携。光と闇の力を調和させた攻撃',
    requiredLevel: 10,
    requiredCharacters: ['dlc_001', 'dlc_002'],
    requiredRelationshipValue: 85
  },
  {
    id: 'coop_dlc_002',
    name: '時空砕破',
    type: SkillType.COOPERATION,
    power: 70,
    mpCost: 45,
    description: 'ジンとリンの時空操作技。物理法則を無視した攻撃',
    requiredLevel: 12,
    requiredCharacters: ['dlc_003', 'dlc_004'],
    requiredRelationshipValue: 80
  }
];

export const conflictSkills: Skill[] = [
  {
    id: 'conflict_001',
    name: '競争心',
    type: SkillType.CONFLICT,
    power: 40,
    mpCost: 15,
    description: 'ライバルへの対抗意識から生まれる力。関係値30以下で使用可能',
    requiredLevel: 3,
    requiredCharacters: ['char_001', 'char_005'],
    requiredRelationshipValue: 30
  },
  {
    id: 'conflict_002',
    name: '反発の炎',
    type: SkillType.CONFLICT,
    power: 42,
    mpCost: 18,
    description: 'ユキとサクラの対立から生まれる炎の魔法',
    requiredLevel: 4,
    requiredCharacters: ['char_002', 'char_004'],
    requiredRelationshipValue: 25
  },
  {
    id: 'conflict_003',
    name: '独立斬',
    type: SkillType.CONFLICT,
    power: 38,
    mpCost: 12,
    description: '他者に頼らない意志から生まれる独特の剣技',
    requiredLevel: 5,
    requiredCharacters: ['char_001', 'char_007'],
    requiredRelationshipValue: 25
  },
  {
    id: 'conflict_004',
    name: '嫉妬の雷',
    type: SkillType.CONFLICT,
    power: 44,
    mpCost: 20,
    description: 'アヤの嫉妬心から生まれる強力な雷撃',
    requiredLevel: 6,
    requiredCharacters: ['char_008', 'char_009'],
    requiredRelationshipValue: 20
  },
  {
    id: 'conflict_005',
    name: '対立の地震',
    type: SkillType.CONFLICT,
    power: 46,
    mpCost: 22,
    description: 'ハルトとナミの意見対立から生まれる地震攻撃',
    requiredLevel: 7,
    requiredCharacters: ['char_009', 'char_010'],
    requiredRelationshipValue: 30
  },
  {
    id: 'conflict_dlc_001',
    name: '闇の独走',
    type: SkillType.CONFLICT,
    power: 50,
    mpCost: 25,
    description: 'レイの孤独感から生まれる闇の力',
    requiredLevel: 8,
    requiredCharacters: ['dlc_001', 'char_001'],
    requiredRelationshipValue: 25
  },
  {
    id: 'conflict_dlc_002',
    name: '時間の歪み',
    type: SkillType.CONFLICT,
    power: 48,
    mpCost: 30,
    description: 'リンの孤立感が時間を歪ませる特殊攻撃',
    requiredLevel: 9,
    requiredCharacters: ['dlc_004', 'dlc_005'],
    requiredRelationshipValue: 20
  }
];

export const advancedCooperationSkills: Skill[] = [
  {
    id: 'ultimate_coop_001',
    name: '絆の極意',
    type: SkillType.COOPERATION,
    power: 80,
    mpCost: 50,
    description: '最高レベルの信頼関係から生まれる究極技。3人以上の連携が必要',
    requiredLevel: 15,
    requiredCharacters: ['char_001', 'char_002', 'char_003'],
    requiredRelationshipValue: 90
  },
  {
    id: 'ultimate_coop_002',
    name: '四元素融合',
    type: SkillType.COOPERATION,
    power: 85,
    mpCost: 60,
    description: '火・水・風・雷の四元素を融合させた最強魔法',
    requiredLevel: 18,
    requiredCharacters: ['char_002', 'char_005', 'char_006', 'char_008'],
    requiredRelationshipValue: 85
  },
  {
    id: 'ultimate_dlc_001',
    name: '新旧調和',
    type: SkillType.COOPERATION,
    power: 90,
    mpCost: 55,
    description: '初期メンバーとDLCメンバーの完全調和技',
    requiredLevel: 20,
    requiredCharacters: ['char_001', 'dlc_001'],
    requiredRelationshipValue: 95
  }
];

export const ultimateConflictSkills: Skill[] = [
  {
    id: 'ultimate_conflict_001',
    name: '孤高の剣',
    type: SkillType.CONFLICT,
    power: 75,
    mpCost: 40,
    description: '完全な孤立状態から生まれる最強の一撃',
    requiredLevel: 12,
    requiredCharacters: ['char_001'],
    requiredRelationshipValue: 10
  },
  {
    id: 'ultimate_conflict_002',
    name: '憎悪の炎',
    type: SkillType.CONFLICT,
    power: 70,
    mpCost: 45,
    description: '深い憎しみから生まれる破壊の炎',
    requiredLevel: 14,
    requiredCharacters: ['char_002', 'char_004'],
    requiredRelationshipValue: 5
  },
  {
    id: 'ultimate_dlc_conflict_001',
    name: '絶対零度',
    type: SkillType.CONFLICT,
    power: 85,
    mpCost: 50,
    description: 'DLCキャラクターの完全な孤立から生まれる絶対零度攻撃',
    requiredLevel: 16,
    requiredCharacters: ['dlc_001'],
    requiredRelationshipValue: 0
  }
];

export function getAllSkills(): Skill[] {
  return [
    ...cooperationSkills,
    ...conflictSkills,
    ...advancedCooperationSkills,
    ...ultimateConflictSkills
  ];
}

export function getSkillsByType(type: SkillType): Skill[] {
  return getAllSkills().filter(skill => skill.type === type);
}

export function getAvailableSkills(characterIds: string[], relationshipMatrix: Record<string, Record<string, number>>, levels: Record<string, number>): Skill[] {
  const availableSkills: Skill[] = [];
  
  for (const skill of getAllSkills()) {
    if (isSkillAvailable(skill, characterIds, relationshipMatrix, levels)) {
      availableSkills.push(skill);
    }
  }
  
  return availableSkills;
}

function isSkillAvailable(
  skill: Skill, 
  characterIds: string[], 
  relationshipMatrix: Record<string, Record<string, number>>, 
  levels: Record<string, number>
): boolean {
  if (!skill.requiredCharacters) return false;
  
  const hasRequiredCharacters = skill.requiredCharacters.every(reqCharId => 
    characterIds.includes(reqCharId)
  );
  
  if (!hasRequiredCharacters) return false;
  
  if (skill.requiredLevel) {
    const hasRequiredLevel = skill.requiredCharacters.some(charId => 
      levels[charId] >= skill.requiredLevel!
    );
    if (!hasRequiredLevel) return false;
  }
  
  if (skill.requiredRelationshipValue && skill.requiredCharacters.length >= 2) {
    const [char1, char2] = skill.requiredCharacters;
    const relationshipValue = relationshipMatrix[char1]?.[char2] ?? 50;
    
    if (skill.type === SkillType.COOPERATION) {
      return relationshipValue >= skill.requiredRelationshipValue;
    } else if (skill.type === SkillType.CONFLICT) {
      return relationshipValue <= skill.requiredRelationshipValue;
    }
  }
  
  return true;
}