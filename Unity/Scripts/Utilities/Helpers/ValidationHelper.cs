using System.Collections.Generic;
using UnityEngine;
using NegabokuRPG.Characters;

namespace NegabokuRPG.Utilities
{
    /// <summary>
    /// バリデーション処理の一元化
    /// </summary>
    public static class ValidationHelper
    {
        /// <summary>
        /// パーティサイズの検証
        /// </summary>
        public static bool ValidatePartySize(List<PlayerCharacter> party, string methodName)
        {
            if (party == null)
            {
                Debug.LogError($"{methodName}: Party cannot be null");
                return false;
            }
            
            if (party.Count != GameConstants.REQUIRED_PARTY_SIZE)
            {
                Debug.LogError($"{methodName}: Invalid party size. Expected: {GameConstants.REQUIRED_PARTY_SIZE}, Actual: {party.Count}");
                return false;
            }
            
            return true;
        }
        
        /// <summary>
        /// パーティサイズの検証（文字列ID版）
        /// </summary>
        public static bool ValidatePartySize(List<string> characterIds, string methodName)
        {
            if (characterIds == null)
            {
                Debug.LogError($"{methodName}: characterIds cannot be null");
                return false;
            }
            
            if (characterIds.Count != GameConstants.REQUIRED_PARTY_SIZE)
            {
                Debug.LogError($"{methodName}: Invalid party size. Expected: {GameConstants.REQUIRED_PARTY_SIZE}, Actual: {characterIds.Count}. Characters: [{string.Join(", ", characterIds)}]");
                return false;
            }
            
            return true;
        }
        
        /// <summary>
        /// 関係値の範囲検証
        /// </summary>
        public static bool ValidateRelationshipValue(int value, string context = "")
        {
            if (value < RelationshipConstants.MIN_VALUE || value > RelationshipConstants.MAX_VALUE)
            {
                Debug.LogWarning($"Relationship value out of range: {value}. Expected: {RelationshipConstants.MIN_VALUE} to {RelationshipConstants.MAX_VALUE}. Context: {context}");
                return false;
            }
            
            return true;
        }
        
        /// <summary>
        /// 文字列の空値検証
        /// </summary>
        public static bool ValidateNotEmpty(string value, string parameterName, string methodName)
        {
            if (string.IsNullOrEmpty(value))
            {
                Debug.LogError($"{methodName}: {parameterName} cannot be null or empty");
                return false;
            }
            
            return true;
        }
    }
}