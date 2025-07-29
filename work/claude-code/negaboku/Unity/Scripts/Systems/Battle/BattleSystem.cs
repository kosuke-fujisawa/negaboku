using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using NegabokuRPG.Data;
using NegabokuRPG.Characters;

namespace NegabokuRPG.Systems
{
    /// <summary>
    /// バトルシステム - ターン制戦闘の管理
    /// </summary>
    public class BattleSystem : MonoBehaviour
    {
        [Header("バトル設定")]
        [SerializeField] private float actionAnimationDuration = 1.0f;
        [SerializeField] private float turnDelay = 0.5f;

        // バトル状態
        private List<BattleCharacter> playerParty = new List<BattleCharacter>();
        private List<BattleEnemy> enemies = new List<BattleEnemy>();
        private List<BattleCombatant> turnOrder = new List<BattleCombatant>();
        private int currentTurnIndex = 0;
        private bool battleActive = false;

        // 結果
        private BattleResult battleResult;

        // イベント
        public event Action OnBattleStart;
        public event Action<BattleResult> OnBattleEnd;
        public event Action<BattleCombatant> OnTurnStart;
        public event Action<BattleAction> OnActionExecuted;
        public event Action<BattleCombatant, int> OnDamageDealt;
        public event Action<BattleCombatant, int> OnHealingDone;

        // 依存システム
        private RelationshipSystem relationshipSystem;

        private void Awake()
        {
            relationshipSystem = RelationshipSystem.Instance;
        }

        /// <summary>
        /// バトル開始
        /// </summary>
        public void StartBattle(List<PlayerCharacter> party, List<BattleEnemyData> enemyData)
        {
            InitializeBattle(party, enemyData);
            StartCoroutine(BattleLoop());
        }

        /// <summary>
        /// バトル初期化
        /// </summary>
        private void InitializeBattle(List<PlayerCharacter> party, List<BattleEnemyData> enemyData)
        {
            // プレイヤーパーティの初期化
            playerParty.Clear();
            foreach (var player in party)
            {
                var battleChar = new BattleCharacter(player);
                playerParty.Add(battleChar);
            }

            // 敵の初期化
            enemies.Clear();
            foreach (var data in enemyData)
            {
                var enemy = new BattleEnemy(data);
                enemies.Add(enemy);
            }

            // ターン順序の決定
            InitializeTurnOrder();

            battleActive = true;
            OnBattleStart?.Invoke();
        }

        /// <summary>
        /// ターン順序の初期化
        /// </summary>
        private void InitializeTurnOrder()
        {
            turnOrder.Clear();
            
            // 全戦闘参加者を追加
            turnOrder.AddRange(playerParty.Cast<BattleCombatant>());
            turnOrder.AddRange(enemies.Cast<BattleCombatant>());

            // 速度順でソート
            turnOrder = turnOrder.OrderByDescending(c => c.Speed).ToList();
            currentTurnIndex = 0;
        }

        /// <summary>
        /// バトルメインループ
        /// </summary>
        private IEnumerator BattleLoop()
        {
            while (battleActive)
            {
                var currentCombatant = turnOrder[currentTurnIndex];

                // 戦闘不能者はスキップ
                if (currentCombatant.IsDefeated)
                {
                    NextTurn();
                    continue;
                }

                // ターン開始通知
                OnTurnStart?.Invoke(currentCombatant);

                // ステータス効果処理
                currentCombatant.ProcessStatusEffects();

                // 行動実行
                if (!currentCombatant.IsDefeated)
                {
                    yield return StartCoroutine(ExecuteTurn(currentCombatant));
                }

                // バトル終了判定
                if (IsBattleOver())
                {
                    yield return StartCoroutine(EndBattle());
                    break;
                }

                yield return new WaitForSeconds(turnDelay);
                NextTurn();
            }
        }

        /// <summary>
        /// 1ターンの実行
        /// </summary>
        private IEnumerator ExecuteTurn(BattleCombatant combatant)
        {
            BattleAction action = null;

            if (combatant is BattleCharacter playerChar)
            {
                // プレイヤーキャラクターの行動選択（UI待ち）
                action = yield return StartCoroutine(WaitForPlayerAction(playerChar));
            }
            else if (combatant is BattleEnemy enemy)
            {
                // 敵の行動決定（AI）
                action = DetermineEnemyAction(enemy);
            }

            if (action != null)
            {
                yield return StartCoroutine(ExecuteAction(action));
            }
        }

        /// <summary>
        /// プレイヤーの行動選択を待機
        /// </summary>
        private IEnumerator WaitForPlayerAction(BattleCharacter character)
        {
            // UIシステムからの入力待ち
            BattleAction selectedAction = null;
            bool actionSelected = false;

            // UIイベントリスナー設定
            System.Action<BattleAction> onActionSelected = (action) => {
                selectedAction = action;
                actionSelected = true;
            };

            // UI通知（実際の実装ではUIManagerを通して行う）
            NotifyUIForActionSelection(character, onActionSelected);

            // 行動選択まで待機
            yield return new WaitUntil(() => actionSelected);

            yield return selectedAction;
        }

        /// <summary>
        /// 敵の行動決定
        /// </summary>
        private BattleAction DetermineEnemyAction(BattleEnemy enemy)
        {
            // 簡単なAI：ランダムで通常攻撃かスキル使用
            var availableSkills = enemy.GetUsableSkills();
            
            if (availableSkills.Count > 0 && UnityEngine.Random.value < 0.3f)
            {
                var skill = availableSkills[UnityEngine.Random.Range(0, availableSkills.Count)];
                var targets = SelectTargetsForSkill(skill, false);
                
                return new BattleAction
                {
                    actor = enemy,
                    actionType = BattleActionType.Skill,
                    skill = skill,
                    targets = targets
                };
            }
            else
            {
                // 通常攻撃
                var target = SelectRandomTarget(true); // プレイヤーをターゲット
                return new BattleAction
                {
                    actor = enemy,
                    actionType = BattleActionType.Attack,
                    targets = new List<BattleCombatant> { target }
                };
            }
        }

        /// <summary>
        /// 行動実行
        /// </summary>
        private IEnumerator ExecuteAction(BattleAction action)
        {
            OnActionExecuted?.Invoke(action);

            switch (action.actionType)
            {
                case BattleActionType.Attack:
                    yield return StartCoroutine(ExecuteAttack(action));
                    break;
                case BattleActionType.Skill:
                    yield return StartCoroutine(ExecuteSkill(action));
                    break;
                case BattleActionType.Item:
                    yield return StartCoroutine(ExecuteItem(action));
                    break;
                case BattleActionType.Defend:
                    yield return StartCoroutine(ExecuteDefend(action));
                    break;
            }

            yield return new WaitForSeconds(actionAnimationDuration);
        }

        /// <summary>
        /// 通常攻撃実行
        /// </summary>
        private IEnumerator ExecuteAttack(BattleAction action)
        {
            if (action.targets.Count > 0)
            {
                var target = action.targets[0];
                int damage = CalculatePhysicalDamage(action.actor, target);
                
                ApplyDamage(target, damage);
                OnDamageDealt?.Invoke(target, damage);
            }
            yield return null;
        }

        /// <summary>
        /// スキル実行
        /// </summary>
        private IEnumerator ExecuteSkill(BattleAction action)
        {
            var skill = action.skill;
            var caster = action.actor;

            // MP消費
            caster.ModifyMP(-skill.mpCost);

            // 関係値による威力修正
            float powerModifier = 1.0f;
            if (skill.skillType != SkillType.Normal && relationshipSystem != null)
            {
                var relationships = relationshipSystem.GetAllRelationships();
                powerModifier = skill.CalculatePowerModifier(relationships);
            }

            // ターゲットに効果適用
            foreach (var target in action.targets)
            {
                int effectValue = Mathf.RoundToInt(skill.basePower * powerModifier);

                if (skill.basePower > 0) // ダメージ
                {
                    ApplyDamage(target, effectValue);
                    OnDamageDealt?.Invoke(target, effectValue);
                }
                else if (skill.basePower < 0) // 回復
                {
                    int healing = Mathf.Abs(effectValue);
                    ApplyHealing(target, healing);
                    OnHealingDone?.Invoke(target, healing);
                }

                // ステータス効果適用
                foreach (var statusEffect in skill.statusEffects)
                {
                    target.AddStatusEffect(statusEffect.effectType, statusEffect.value, statusEffect.duration);
                }
            }

            // 関係値変化処理
            HandleSkillRelationshipEffects(skill, caster);

            yield return null;
        }

        /// <summary>
        /// アイテム使用実行
        /// </summary>
        private IEnumerator ExecuteItem(BattleAction action)
        {
            // アイテム効果の実装
            yield return null;
        }

        /// <summary>
        /// 防御実行
        /// </summary>
        private IEnumerator ExecuteDefend(BattleAction action)
        {
            // 防御バフ付与
            action.actor.AddStatusEffect(StatusEffectType.DefenseUp, 
                Mathf.RoundToInt(action.actor.Defense * 0.5f), 1);
            yield return null;
        }

        /// <summary>
        /// 物理ダメージ計算
        /// </summary>
        private int CalculatePhysicalDamage(BattleCombatant attacker, BattleCombatant target)
        {
            int baseDamage = attacker.Attack - target.Defense;
            baseDamage = Mathf.Max(1, baseDamage); // 最低1ダメージ

            // クリティカル判定
            if (UnityEngine.Random.value < 0.1f) // 10%でクリティカル
            {
                baseDamage = Mathf.RoundToInt(baseDamage * 1.5f);
            }

            return baseDamage;
        }

        /// <summary>
        /// ダメージ適用
        /// </summary>
        private void ApplyDamage(BattleCombatant target, int damage)
        {
            target.ModifyHP(-damage);
        }

        /// <summary>
        /// 回復適用
        /// </summary>
        private void ApplyHealing(BattleCombatant target, int healing)
        {
            target.ModifyHP(healing);
        }

        /// <summary>
        /// スキルによる関係値変化を処理
        /// </summary>
        private void HandleSkillRelationshipEffects(SkillData skill, BattleCombatant caster)
        {
            if (relationshipSystem == null || skill.requiredCharacterIds.Count < 2) return;

            string casterId = caster.CharacterId;
            
            // 共闘技の場合、関係値向上
            if (skill.skillType == SkillType.Cooperation)
            {
                foreach (var partnerId in skill.requiredCharacterIds)
                {
                    if (partnerId != casterId)
                    {
                        relationshipSystem.HandleBattleEvent(BattleEventType.Cooperation, casterId, partnerId);
                    }
                }
            }
            // 対立技の場合、関係値悪化
            else if (skill.skillType == SkillType.Conflict)
            {
                foreach (var rivalId in skill.requiredCharacterIds)
                {
                    if (rivalId != casterId)
                    {
                        relationshipSystem.HandleBattleEvent(BattleEventType.Rivalry, casterId, rivalId);
                    }
                }
            }
        }

        /// <summary>
        /// スキル用ターゲット選択
        /// </summary>
        private List<BattleCombatant> SelectTargetsForSkill(SkillData skill, bool isPlayerAction)
        {
            var targets = new List<BattleCombatant>();

            switch (skill.targetType)
            {
                case TargetType.Self:
                    // 実装時はキャスターを返す
                    break;
                case TargetType.SingleEnemy:
                    if (isPlayerAction)
                        targets.Add(SelectRandomTarget(false)); // 敵をターゲット
                    else
                        targets.Add(SelectRandomTarget(true));  // プレイヤーをターゲット
                    break;
                case TargetType.AllEnemies:
                    if (isPlayerAction)
                        targets.AddRange(enemies.Where(e => !e.IsDefeated).Cast<BattleCombatant>());
                    else
                        targets.AddRange(playerParty.Where(p => !p.IsDefeated).Cast<BattleCombatant>());
                    break;
                // 他のターゲットタイプも実装
            }

            return targets;
        }

        /// <summary>
        /// ランダムターゲット選択
        /// </summary>
        private BattleCombatant SelectRandomTarget(bool selectPlayer)
        {
            if (selectPlayer)
            {
                var alivePlayers = playerParty.Where(p => !p.IsDefeated).ToList();
                return alivePlayers.Count > 0 ? alivePlayers[UnityEngine.Random.Range(0, alivePlayers.Count)] : null;
            }
            else
            {
                var aliveEnemies = enemies.Where(e => !e.IsDefeated).ToList();
                return aliveEnemies.Count > 0 ? aliveEnemies[UnityEngine.Random.Range(0, aliveEnemies.Count)] : null;
            }
        }

        /// <summary>
        /// バトル終了判定
        /// </summary>
        private bool IsBattleOver()
        {
            bool allPlayersDefeated = playerParty.All(p => p.IsDefeated);
            bool allEnemiesDefeated = enemies.All(e => e.IsDefeated);

            return allPlayersDefeated || allEnemiesDefeated;
        }

        /// <summary>
        /// バトル終了処理
        /// </summary>
        private IEnumerator EndBattle()
        {
            battleActive = false;

            bool playerVictory = enemies.All(e => e.IsDefeated);
            
            battleResult = new BattleResult
            {
                victory = playerVictory,
                experience = playerVictory ? enemies.Sum(e => e.ExpReward) : 0,
                gold = playerVictory ? enemies.Sum(e => e.GoldReward) : 0,
                items = playerVictory ? enemies.SelectMany(e => e.ItemRewards).ToList() : new List<string>()
            };

            OnBattleEnd?.Invoke(battleResult);
            yield return null;
        }

        /// <summary>
        /// 次のターンへ進む
        /// </summary>
        private void NextTurn()
        {
            currentTurnIndex = (currentTurnIndex + 1) % turnOrder.Count;
        }

        /// <summary>
        /// UI通知（実際の実装ではUIManagerを使用）
        /// </summary>
        private void NotifyUIForActionSelection(BattleCharacter character, System.Action<BattleAction> callback)
        {
            // UIシステムへの通知処理
            // 実際の実装では、UIManagerを通してUI表示し、プレイヤーの選択を待つ
        }

        /// <summary>
        /// 外部からの行動入力受付
        /// </summary>
        public void InputPlayerAction(BattleAction action)
        {
            // UIからの行動入力を受け取る
            // 実際の実装では、現在の行動選択待ちキャラクターと照合してから処理
        }
    }

    /// <summary>
    /// バトル行動データ
    /// </summary>
    [Serializable]
    public class BattleAction
    {
        public BattleCombatant actor;
        public BattleActionType actionType;
        public SkillData skill;
        public string itemId;
        public List<BattleCombatant> targets;
    }

    /// <summary>
    /// バトル行動タイプ
    /// </summary>
    public enum BattleActionType
    {
        Attack,
        Skill,
        Item,
        Defend,
        Escape
    }

    /// <summary>
    /// バトル結果
    /// </summary>
    [Serializable]
    public class BattleResult
    {
        public bool victory;
        public int experience;
        public int gold;
        public List<string> items;
    }
}