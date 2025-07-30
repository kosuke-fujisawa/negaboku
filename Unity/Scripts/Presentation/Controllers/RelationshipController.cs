using UnityEngine;
using NegabokuRPG.Application.UseCases;
using NegabokuRPG.Application.Interfaces;
using NegabokuRPG.Domain.Services;
using NegabokuRPG.Domain.ValueObjects;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Infrastructure.Repositories;
using System.Collections.Generic;
using System;

namespace NegabokuRPG.Presentation.Controllers
{
    /// <summary>
    /// 関係値システムのプレゼンテーション層コントローラー
    /// Unity MonoBehaviour と ドメイン層を繋ぐ役割
    /// </summary>
    public class RelationshipController : MonoBehaviour
    {
        [Header("デバッグ設定")]
        [SerializeField] private bool _enableDebugLogs = true;
        
        // ユースケース
        private ModifyRelationshipUseCase _modifyUseCase;
        private GetRelationshipUseCase _getUseCase;
        
        // インフラ層
        private IRelationshipRepository _repository;
        private RelationshipDomainService _domainService;
        
        // イベント
        public event Action<string, string, RelationshipLevel, RelationshipLevel, string> RelationshipLevelChanged;
        
        private void Awake()
        {
            InitializeDependencies();
        }
        
        /// <summary>
        /// 依存関係の初期化
        /// </summary>
        private void InitializeDependencies()
        {
            // インフラ層
            _repository = new UnityRelationshipRepository();
            
            // ドメイン層
            _domainService = new RelationshipDomainService();
            
            // アプリケーション層
            _modifyUseCase = new ModifyRelationshipUseCase(_repository, _domainService);
            _getUseCase = new GetRelationshipUseCase(_repository, _domainService);
        }
        
        /// <summary>
        /// 関係値を取得
        /// </summary>
        /// <param name="character1Id">キャラクター1のID</param>
        /// <param name="character2Id">キャラクター2のID</param>
        /// <returns>関係値</returns>
        public RelationshipValue GetRelationship(string character1Id, string character2Id)
        {
            try
            {
                var char1 = new CharacterId(character1Id);
                var char2 = new CharacterId(character2Id);
                
                return _getUseCase.Execute(char1, char2);
            }
            catch (Exception ex)
            {
                Debug.LogError($"関係値取得エラー: {ex.Message}");
                return new RelationshipValue();
            }
        }
        
        /// <summary>
        /// 関係値を変更
        /// </summary>
        /// <param name="character1Id">キャラクター1のID</param>
        /// <param name="character2Id">キャラクター2のID</param>
        /// <param name="change">変更値</param>
        /// <param name="reason">理由</param>
        /// <returns>変更後の関係値</returns>
        public RelationshipValue ModifyRelationship(string character1Id, string character2Id, int change, string reason)
        {
            try
            {
                var char1 = new CharacterId(character1Id);
                var char2 = new CharacterId(character2Id);
                
                var result = _modifyUseCase.Execute(char1, char2, change, reason);
                
                if (_enableDebugLogs)
                {
                    Debug.Log($"関係値変更: {character1Id} → {character2Id}: {result.Value} ({result.Level})");
                }
                
                return result;
            }
            catch (Exception ex)
            {
                Debug.LogError($"関係値変更エラー: {ex.Message}");
                return new RelationshipValue();
            }
        }
        
        /// <summary>
        /// 双方向関係値を変更
        /// </summary>
        /// <param name="character1Id">キャラクター1のID</param>
        /// <param name="character2Id">キャラクター2のID</param>
        /// <param name="change">変更値</param>
        /// <param name="reason">理由</param>
        /// <returns>両方向の関係値</returns>
        public (RelationshipValue, RelationshipValue) ModifyMutualRelationship(string character1Id, string character2Id, int change, string reason)
        {
            try
            {
                var char1 = new CharacterId(character1Id);
                var char2 = new CharacterId(character2Id);
                
                var result = _modifyUseCase.ExecuteMutual(char1, char2, change, reason);
                
                if (_enableDebugLogs)
                {
                    Debug.Log($"相互関係値変更: {character1Id} ↔ {character2Id}: {result.Item1.Value} / {result.Item2.Value}");
                }
                
                return result;
            }
            catch (Exception ex)
            {
                Debug.LogError($"相互関係値変更エラー: {ex.Message}");
                return (new RelationshipValue(), new RelationshipValue());
            }
        }
        
        /// <summary>
        /// バトルイベントを処理
        /// </summary>
        /// <param name="eventType">イベントタイプ</param>
        /// <param name="character1Id">キャラクター1のID</param>
        /// <param name="character2Id">キャラクター2のID</param>
        /// <returns>変更後の関係値</returns>
        public (RelationshipValue, RelationshipValue) HandleBattleEvent(BattleEventType eventType, string character1Id, string character2Id)
        {
            try
            {
                var char1 = new CharacterId(character1Id);
                var char2 = new CharacterId(character2Id);
                
                var result = _modifyUseCase.ExecuteBattleEvent(eventType, char1, char2);
                
                if (_enableDebugLogs)
                {
                    Debug.Log($"バトルイベント処理: {eventType} - {character1Id} ↔ {character2Id}");
                }
                
                return result;
            }
            catch (Exception ex)
            {
                Debug.LogError($"バトルイベント処理エラー: {ex.Message}");
                return (new RelationshipValue(), new RelationshipValue());
            }
        }
        
        /// <summary>
        /// パーティの平均関係値を取得
        /// </summary>
        /// <param name="partyMemberIds">パーティメンバーIDリスト</param>
        /// <returns>平均関係値</returns>
        public float GetAveragePartyRelationship(List<string> partyMemberIds)
        {
            try
            {
                var characterIds = partyMemberIds.ConvertAll(id => new CharacterId(id));
                return _getUseCase.GetAveragePartyRelationship(characterIds);
            }
            catch (Exception ex)
            {
                Debug.LogError($"平均関係値取得エラー: {ex.Message}");
                return RelationshipValue.DEFAULT_VALUE;
            }
        }
        
        /// <summary>
        /// 共闘技使用可能なペアを取得
        /// </summary>
        /// <param name="partyMemberIds">パーティメンバーIDリスト</param>
        /// <returns>共闘技可能なペア</returns>
        public List<(string, string)> GetCooperationSkillPairs(List<string> partyMemberIds)
        {
            try
            {
                var characterIds = partyMemberIds.ConvertAll(id => new CharacterId(id));
                var pairs = _getUseCase.GetCooperationSkillPairs(characterIds);
                
                return pairs.ConvertAll(pair => (pair.Item1.Value, pair.Item2.Value));
            }
            catch (Exception ex)
            {
                Debug.LogError($"共闘技ペア取得エラー: {ex.Message}");
                return new List<(string, string)>();
            }
        }
        
        /// <summary>
        /// 対立技使用可能なペアを取得
        /// </summary>
        /// <param name="partyMemberIds">パーティメンバーIDリスト</param>
        /// <returns>対立技可能なペア</returns>
        public List<(string, string)> GetConflictSkillPairs(List<string> partyMemberIds)
        {
            try
            {
                var characterIds = partyMemberIds.ConvertAll(id => new CharacterId(id));
                var pairs = _getUseCase.GetConflictSkillPairs(characterIds);
                
                return pairs.ConvertAll(pair => (pair.Item1.Value, pair.Item2.Value));
            }
            catch (Exception ex)
            {
                Debug.LogError($"対立技ペア取得エラー: {ex.Message}");
                return new List<(string, string)>();
            }
        }
        
        /// <summary>
        /// デバッグ用：現在の関係値を表示
        /// </summary>
        [ContextMenu("Debug Print Current Relationships")]
        public void DebugPrintCurrentRelationships()
        {
            // テスト用のキャラクターIDでデバッグ出力
            var testCharacters = new List<string> { "char1", "char2", "char3" };
            
            foreach (var char1 in testCharacters)
            {
                foreach (var char2 in testCharacters)
                {
                    if (char1 != char2)
                    {
                        var relationship = GetRelationship(char1, char2);
                        Debug.Log($"{char1} → {char2}: {relationship.Value} ({relationship.Level})");
                    }
                }
            }
        }
    }
}