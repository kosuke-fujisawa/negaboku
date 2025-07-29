import { Character, SkillType } from '../types/Character';

export const initialCharacters: Character[] = [
  {
    id: 'char_001',
    name: 'アキラ',
    level: 1,
    hp: 100,
    maxHp: 100,
    mp: 30,
    maxMp: 30,
    attack: 15,
    defense: 12,
    speed: 10,
    isDLC: false,
    defaultRelationships: {
      'char_002': 50,
      'char_003': 60,
      'char_004': 45,
      'char_005': 55,
      'char_006': 40,
      'char_007': 35,
      'char_008': 50,
      'char_009': 48,
      'char_010': 52
    },
    skills: [
      {
        id: 'skill_001',
        name: '剣撃',
        type: SkillType.NORMAL,
        power: 20,
        mpCost: 0,
        description: '通常の剣攻撃'
      }
    ]
  },
  {
    id: 'char_002',
    name: 'ユキ',
    level: 1,
    hp: 85,
    maxHp: 85,
    mp: 45,
    maxMp: 45,
    attack: 12,
    defense: 10,
    speed: 14,
    isDLC: false,
    defaultRelationships: {
      'char_001': 50,
      'char_003': 65,
      'char_004': 30,
      'char_005': 70,
      'char_006': 55,
      'char_007': 45,
      'char_008': 40,
      'char_009': 60,
      'char_010': 35
    },
    skills: [
      {
        id: 'skill_002',
        name: '氷の矢',
        type: SkillType.NORMAL,
        power: 18,
        mpCost: 8,
        description: '氷属性の魔法攻撃'
      }
    ]
  },
  {
    id: 'char_003',
    name: 'タケシ',
    level: 1,
    hp: 120,
    maxHp: 120,
    mp: 20,
    maxMp: 20,
    attack: 18,
    defense: 16,
    speed: 8,
    isDLC: false,
    defaultRelationships: {
      'char_001': 60,
      'char_002': 65,
      'char_004': 55,
      'char_005': 45,
      'char_006': 50,
      'char_007': 60,
      'char_008': 55,
      'char_009': 40,
      'char_010': 45
    },
    skills: [
      {
        id: 'skill_003',
        name: '強打',
        type: SkillType.NORMAL,
        power: 25,
        mpCost: 5,
        description: '威力の高い物理攻撃'
      }
    ]
  },
  {
    id: 'char_004',
    name: 'サクラ',
    level: 1,
    hp: 75,
    maxHp: 75,
    mp: 55,
    maxMp: 55,
    attack: 10,
    defense: 8,
    speed: 16,
    isDLC: false,
    defaultRelationships: {
      'char_001': 45,
      'char_002': 30,
      'char_003': 55,
      'char_005': 40,
      'char_006': 65,
      'char_007': 70,
      'char_008': 35,
      'char_009': 55,
      'char_010': 60
    },
    skills: [
      {
        id: 'skill_004',
        name: 'ヒール',
        type: SkillType.NORMAL,
        power: -30,
        mpCost: 12,
        description: 'HPを回復する'
      }
    ]
  },
  {
    id: 'char_005',
    name: 'リュウ',
    level: 1,
    hp: 95,
    maxHp: 95,
    mp: 35,
    maxMp: 35,
    attack: 16,
    defense: 14,
    speed: 12,
    isDLC: false,
    defaultRelationships: {
      'char_001': 55,
      'char_002': 70,
      'char_003': 45,
      'char_004': 40,
      'char_006': 50,
      'char_007': 35,
      'char_008': 60,
      'char_009': 45,
      'char_010': 50
    },
    skills: [
      {
        id: 'skill_005',
        name: '火炎弾',
        type: SkillType.NORMAL,
        power: 22,
        mpCost: 10,
        description: '火属性の魔法攻撃'
      }
    ]
  },
  {
    id: 'char_006',
    name: 'ミキ',
    level: 1,
    hp: 80,
    maxHp: 80,
    mp: 50,
    maxMp: 50,
    attack: 11,
    defense: 9,
    speed: 15,
    isDLC: false,
    defaultRelationships: {
      'char_001': 40,
      'char_002': 55,
      'char_003': 50,
      'char_004': 65,
      'char_005': 50,
      'char_007': 60,
      'char_008': 45,
      'char_009': 70,
      'char_010': 40
    },
    skills: [
      {
        id: 'skill_006',
        name: '風刃',
        type: SkillType.NORMAL,
        power: 19,
        mpCost: 7,
        description: '風属性の魔法攻撃'
      }
    ]
  },
  {
    id: 'char_007',
    name: 'ケンジ',
    level: 1,
    hp: 110,
    maxHp: 110,
    mp: 25,
    maxMp: 25,
    attack: 17,
    defense: 15,
    speed: 9,
    isDLC: false,
    defaultRelationships: {
      'char_001': 35,
      'char_002': 45,
      'char_003': 60,
      'char_004': 70,
      'char_005': 35,
      'char_006': 60,
      'char_008': 40,
      'char_009': 50,
      'char_010': 55
    },
    skills: [
      {
        id: 'skill_007',
        name: '盾攻撃',
        type: SkillType.NORMAL,
        power: 15,
        mpCost: 3,
        description: '盾による攻撃'
      }
    ]
  },
  {
    id: 'char_008',
    name: 'アヤ',
    level: 1,
    hp: 70,
    maxHp: 70,
    mp: 60,
    maxMp: 60,
    attack: 9,
    defense: 7,
    speed: 18,
    isDLC: false,
    defaultRelationships: {
      'char_001': 50,
      'char_002': 40,
      'char_003': 55,
      'char_004': 35,
      'char_005': 60,
      'char_006': 45,
      'char_007': 40,
      'char_009': 65,
      'char_010': 55
    },
    skills: [
      {
        id: 'skill_008',
        name: '雷撃',
        type: SkillType.NORMAL,
        power: 24,
        mpCost: 15,
        description: '雷属性の魔法攻撃'
      }
    ]
  },
  {
    id: 'char_009',
    name: 'ハルト',
    level: 1,
    hp: 90,
    maxHp: 90,
    mp: 40,
    maxMp: 40,
    attack: 13,
    defense: 11,
    speed: 13,
    isDLC: false,
    defaultRelationships: {
      'char_001': 48,
      'char_002': 60,
      'char_003': 40,
      'char_004': 55,
      'char_005': 45,
      'char_006': 70,
      'char_007': 50,
      'char_008': 65,
      'char_010': 35
    },
    skills: [
      {
        id: 'skill_009',
        name: '地割れ',
        type: SkillType.NORMAL,
        power: 21,
        mpCost: 9,
        description: '地属性の魔法攻撃'
      }
    ]
  },
  {
    id: 'char_010',
    name: 'ナミ',
    level: 1,
    hp: 85,
    maxHp: 85,
    mp: 45,
    maxMp: 45,
    attack: 14,
    defense: 10,
    speed: 14,
    isDLC: false,
    defaultRelationships: {
      'char_001': 52,
      'char_002': 35,
      'char_003': 45,
      'char_004': 60,
      'char_005': 50,
      'char_006': 40,
      'char_007': 55,
      'char_008': 55,
      'char_009': 35
    },
    skills: [
      {
        id: 'skill_010',
        name: '水流弾',
        type: SkillType.NORMAL,
        power: 20,
        mpCost: 8,
        description: '水属性の魔法攻撃'
      }
    ]
  }
];

export const dlcCharacters: Character[] = [
  {
    id: 'dlc_001',
    name: 'レイ',
    level: 1,
    hp: 105,
    maxHp: 105,
    mp: 35,
    maxMp: 35,
    attack: 19,
    defense: 13,
    speed: 11,
    isDLC: true,
    defaultRelationships: {
      'char_001': 30,
      'char_002': 25,
      'char_003': 35,
      'char_004': 20,
      'char_005': 40,
      'char_006': 25,
      'char_007': 30,
      'char_008': 35,
      'char_009': 25,
      'char_010': 30,
      'dlc_002': 60,
      'dlc_003': 45,
      'dlc_004': 50,
      'dlc_005': 40
    },
    skills: [
      {
        id: 'dlc_skill_001',
        name: '闇撃',
        type: SkillType.NORMAL,
        power: 26,
        mpCost: 12,
        description: '闇属性の強力な攻撃'
      }
    ]
  },
  {
    id: 'dlc_002',
    name: 'エル',
    level: 1,
    hp: 75,
    maxHp: 75,
    mp: 65,
    maxMp: 65,
    attack: 8,
    defense: 6,
    speed: 20,
    isDLC: true,
    defaultRelationships: {
      'char_001': 40,
      'char_002': 55,
      'char_003': 30,
      'char_004': 60,
      'char_005': 35,
      'char_006': 50,
      'char_007': 25,
      'char_008': 45,
      'char_009': 40,
      'char_010': 35,
      'dlc_001': 60,
      'dlc_003': 55,
      'dlc_004': 35,
      'dlc_005': 70
    },
    skills: [
      {
        id: 'dlc_skill_002',
        name: '光線',
        type: SkillType.NORMAL,
        power: 28,
        mpCost: 18,
        description: '光属性の魔法攻撃'
      }
    ]
  },
  {
    id: 'dlc_003',
    name: 'ジン',
    level: 1,
    hp: 130,
    maxHp: 130,
    mp: 15,
    maxMp: 15,
    attack: 22,
    defense: 18,
    speed: 6,
    isDLC: true,
    defaultRelationships: {
      'char_001': 45,
      'char_002': 35,
      'char_003': 65,
      'char_004': 30,
      'char_005': 40,
      'char_006': 35,
      'char_007': 55,
      'char_008': 25,
      'char_009': 50,
      'char_010': 40,
      'dlc_001': 45,
      'dlc_002': 55,
      'dlc_004': 60,
      'dlc_005': 30
    },
    skills: [
      {
        id: 'dlc_skill_003',
        name: '破砕撃',
        type: SkillType.NORMAL,
        power: 30,
        mpCost: 8,
        description: '防御力を無視する物理攻撃'
      }
    ]
  },
  {
    id: 'dlc_004',
    name: 'リン',
    level: 1,
    hp: 80,
    maxHp: 80,
    mp: 55,
    maxMp: 55,
    attack: 12,
    defense: 9,
    speed: 17,
    isDLC: true,
    defaultRelationships: {
      'char_001': 35,
      'char_002': 45,
      'char_003': 40,
      'char_004': 65,
      'char_005': 30,
      'char_006': 60,
      'char_007': 35,
      'char_008': 50,
      'char_009': 45,
      'char_010': 55,
      'dlc_001': 50,
      'dlc_002': 35,
      'dlc_003': 60,
      'dlc_005': 45
    },
    skills: [
      {
        id: 'dlc_skill_004',
        name: '時間停止',
        type: SkillType.NORMAL,
        power: 0,
        mpCost: 25,
        description: '敵の行動を1ターン封じる'
      }
    ]
  },
  {
    id: 'dlc_005',
    name: 'カイ',
    level: 1,
    hp: 95,
    maxHp: 95,
    mp: 40,
    maxMp: 40,
    attack: 15,
    defense: 12,
    speed: 13,
    isDLC: true,
    defaultRelationships: {
      'char_001': 50,
      'char_002': 40,
      'char_003': 35,
      'char_004': 45,
      'char_005': 55,
      'char_006': 30,
      'char_007': 40,
      'char_008': 35,
      'char_009': 60,
      'char_010': 45,
      'dlc_001': 40,
      'dlc_002': 70,
      'dlc_003': 30,
      'dlc_004': 45
    },
    skills: [
      {
        id: 'dlc_skill_005',
        name: '星屑',
        type: SkillType.NORMAL,
        power: 23,
        mpCost: 14,
        description: '星属性の魔法攻撃'
      }
    ]
  }
];