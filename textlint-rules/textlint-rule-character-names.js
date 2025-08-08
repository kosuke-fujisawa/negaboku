/**
 * キャラクター名の表記統一ルール
 * 正しいキャラクター名のスペルと表記をチェック
 */
module.exports = function(context) {
  const { Syntax, getSource, report, RuleError } = context;

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

  return {
    [Syntax.Str](node) {
      const text = getSource(node);

      // 各キャラクター名について間違った表記をチェック
      Object.keys(correctCharacterNames).forEach(correctName => {
        const wrongVariants = correctCharacterNames[correctName];

        wrongVariants.forEach(wrongName => {
          const index = text.indexOf(wrongName);
          if (index !== -1) {
            const ruleError = new RuleError(
              `キャラクター名は「${correctName}」で統一してください（「${wrongName}」→「${correctName}」）`,
              {
                index: index
              }
            );
            report(node, ruleError);
          }
        });
      });

      // セリフ記法内のキャラクター名もチェック
      const dialogueMatches = text.match(/\*\*([^*]+)\*\*/g);
      if (dialogueMatches) {
        dialogueMatches.forEach(match => {
          const speakerName = match.replace(/\*\*/g, '');
          const index = text.indexOf(match);

          // 間違った表記の可能性をチェック
          Object.keys(correctCharacterNames).forEach(correctName => {
            const wrongVariants = correctCharacterNames[correctName];
            if (wrongVariants.includes(speakerName)) {
              const ruleError = new RuleError(
                `セリフのキャラクター名は「${correctName}」で統一してください（「${speakerName}」→「${correctName}」）`,
                {
                  index: index
                }
              );
              report(node, ruleError);
            }
          });
        });
      }
    }
  };
};

module.exports.meta = {
  docs: {
    description: "キャラクター名の表記統一をチェックするルール",
    category: "style"
  },
  fixable: false,
  type: "suggestion"
};
