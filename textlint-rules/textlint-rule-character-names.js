/**
 * キャラクター名の表記統一ルール
 * 正しいキャラクター名のスペルと表記をチェック・自動修正
 */
module.exports = function(context) {
  const { Syntax, getSource, report, RuleError, fixer } = context;

  // 正しいキャラクター名の定義
  const correctCharacterNames = {
    'ソウマ': ['そうま', 'SOUMA', 'souma', 'Souma'],
    'ユズキ': ['ゆずき', 'YUZUKI', 'yuzuki', 'Yuzuki'],
    'レツジ': ['れつじ', 'RETSUJI', 'retsuji', 'Retsuji'],
    'カイ': ['かい', 'KAI', 'kai', 'Kai'],
    'レゼル': ['れぜる', 'REZEL', 'rezel', 'Rezel'],
    'マキト': ['まきと', 'MAKITO', 'makito', 'Makito'],
    'セリーヌ': ['せりーぬ', 'CELINE', 'celine', 'Celine']
  };

  // 語境界をチェックする関数（誤検知防止）
  function isWordBoundary(text, index) {
    const char = text.charAt(index);
    return /[\s\n\r\t、。「」『』（）()[\]【】・！？!?]/.test(char) || index === 0 || index === text.length;
  }

  return {
    [Syntax.Str](node) {
      const text = getSource(node);

      // 各キャラクター名について間違った表記をチェック
      Object.keys(correctCharacterNames).forEach(correctName => {
        const wrongVariants = correctCharacterNames[correctName];

        wrongVariants.forEach(wrongName => {
          let searchIndex = 0;
          while (true) {
            const index = text.indexOf(wrongName, searchIndex);
            if (index === -1) break;

            // 語境界チェック（誤検知防止）
            const beforeIndex = index - 1;
            const afterIndex = index + wrongName.length;

            if (isWordBoundary(text, beforeIndex) && isWordBoundary(text, afterIndex)) {
              const ruleError = new RuleError(
                `キャラクター名は「${correctName}」で統一してください（「${wrongName}」→「${correctName}」）`,
                {
                  index: index,
                  fix: fixer.replaceTextRange([index, index + wrongName.length], correctName)
                }
              );
              report(node, ruleError);
            }

            searchIndex = index + 1;
          }
        });
      });

      // セリフ記法内のキャラクター名もチェック（改善版）
      const dialogueRegex = /\*\*([^*]+)\*\*/g;
      let dialogueMatch;
      while ((dialogueMatch = dialogueRegex.exec(text)) !== null) {
        const speakerName = dialogueMatch[1].trim();
        const matchIndex = dialogueMatch.index;

        // 間違った表記の可能性をチェック
        Object.keys(correctCharacterNames).forEach(correctName => {
          const wrongVariants = correctCharacterNames[correctName];
          if (wrongVariants.some(variant => variant.toLowerCase() === speakerName.toLowerCase())) {
            const ruleError = new RuleError(
              `セリフのキャラクター名は「${correctName}」で統一してください（「${speakerName}」→「${correctName}」）`,
              {
                index: matchIndex + 2, // **の後の位置
                fix: fixer.replaceTextRange([matchIndex + 2, matchIndex + 2 + speakerName.length], correctName)
              }
            );
            report(node, ruleError);
          }
        });
      }
    }
  };
};

module.exports.meta = {
  docs: {
    description: "キャラクター名の表記統一をチェック・自動修正するルール",
    category: "style"
  },
  fixable: "code",
  type: "suggestion"
};
