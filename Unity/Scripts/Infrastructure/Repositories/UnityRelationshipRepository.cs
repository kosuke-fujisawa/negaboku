using System.Collections.Generic;
using UnityEngine;
using NegabokuRPG.Application.Interfaces;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Domain.ValueObjects;

namespace NegabokuRPG.Infrastructure.Repositories
{
    /// <summary>
    /// Unity PlayerPrefs を使用した関係値リポジトリ実装
    /// </summary>
    public class UnityRelationshipRepository : IRelationshipRepository
    {
        private const string RELATIONSHIP_KEY_PREFIX = "Relationship_";
        
        public void Save(RelationshipAggregate aggregate)
        {
            var relationships = aggregate.GetAllRelationships();
            
            foreach (var kvp in relationships)
            {
                var (char1, char2) = kvp.Key;
                var relationship = kvp.Value;
                var key = GetRelationshipKey(char1, char2);
                
                PlayerPrefs.SetInt(key, relationship.Value);
            }
            
            PlayerPrefs.Save();
        }
        
        public RelationshipAggregate Load(List<CharacterId> characterIds)
        {
            var aggregate = new RelationshipAggregate();
            
            // 全てのキャラクターペアの関係値を読み込み
            foreach (var char1 in characterIds)
            {
                foreach (var char2 in characterIds)
                {
                    if (char1 != char2)
                    {
                        var key = GetRelationshipKey(char1, char2);
                        var value = PlayerPrefs.GetInt(key, RelationshipValue.DEFAULT_VALUE);
                        
                        aggregate.InitializeRelationship(char1, char2, new RelationshipValue(value));
                    }
                }
            }
            
            return aggregate;
        }
        
        public bool Exists(CharacterId character1, CharacterId character2)
        {
            var key = GetRelationshipKey(character1, character2);
            return PlayerPrefs.HasKey(key);
        }
        
        public void Clear()
        {
            // 全ての関係値キーを削除
            // 注意: 実際の実装では、より効率的な方法を検討する必要があります
            var keys = new List<string>();
            
            // PlayerPrefsには全キーを取得する方法がないため、
            // アプリケーションで管理されているキャラクターIDから推測
            // より良い実装では、保存されているキーのリストを別途管理する
        }
        
        private string GetRelationshipKey(CharacterId character1, CharacterId character2)
        {
            // キャラクターIDをソートして一意なキーを生成
            var sortedIds = new[] { character1.Value, character2.Value };
            System.Array.Sort(sortedIds);
            
            return $"{RELATIONSHIP_KEY_PREFIX}{sortedIds[0]}_{sortedIds[1]}";
        }
    }
}