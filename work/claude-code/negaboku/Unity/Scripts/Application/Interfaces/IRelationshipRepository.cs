using System.Collections.Generic;
using NegabokuRPG.Domain.Entities;
using NegabokuRPG.Domain.ValueObjects;

namespace NegabokuRPG.Application.Interfaces
{
    /// <summary>
    /// 関係値リポジトリインターフェース
    /// データの永続化を抽象化
    /// </summary>
    public interface IRelationshipRepository
    {
        /// <summary>
        /// 関係値集約を保存
        /// </summary>
        /// <param name="aggregate">関係値集約</param>
        void Save(RelationshipAggregate aggregate);
        
        /// <summary>
        /// 関係値集約を読み込み
        /// </summary>
        /// <param name="characterIds">対象キャラクターIDリスト</param>
        /// <returns>関係値集約</returns>
        RelationshipAggregate Load(List<CharacterId> characterIds);
        
        /// <summary>
        /// 関係値データの存在確認
        /// </summary>
        /// <param name="character1">キャラクター1</param>
        /// <param name="character2">キャラクター2</param>
        /// <returns>存在する場合true</returns>
        bool Exists(CharacterId character1, CharacterId character2);
        
        /// <summary>
        /// 全関係値データをクリア
        /// </summary>
        void Clear();
    }
}