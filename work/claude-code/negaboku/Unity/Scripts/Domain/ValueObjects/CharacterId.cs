using System;

namespace NegabokuRPG.Domain.ValueObjects
{
    /// <summary>
    /// キャラクターID値オブジェクト
    /// </summary>
    public readonly struct CharacterId : IEquatable<CharacterId>
    {
        private readonly string _value;
        
        public string Value => _value ?? "";
        
        public CharacterId(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
                throw new ArgumentException("キャラクターIDは空にできません", nameof(value));
                
            _value = value;
        }
        
        public bool Equals(CharacterId other)
        {
            return string.Equals(_value, other._value, StringComparison.Ordinal);
        }
        
        public override bool Equals(object obj)
        {
            return obj is CharacterId other && Equals(other);
        }
        
        public override int GetHashCode()
        {
            return _value?.GetHashCode() ?? 0;
        }
        
        public static bool operator ==(CharacterId left, CharacterId right)
        {
            return left.Equals(right);
        }
        
        public static bool operator !=(CharacterId left, CharacterId right)
        {
            return !left.Equals(right);
        }
        
        public override string ToString()
        {
            return _value ?? "";
        }
    }
}