/**
 * ゲーム内用語の一貫性チェックルール
 * 正しいゲーム用語のスペルと表記をチェック
 */
module.exports = function(context) {
  const { Syntax, getSource, report, RuleError } = context;

  // 正しいゲーム内用語の定義
  const correctTerminology = {
    '願い石': ['ねがいいし', '願石', 'ねがい石'],
    '遺跡': ['いせき', '遺跡群', '古代遺跡'],
    '魔法': ['まほう', 'マジック', 'magic'],
    '冒険者': ['ぼうけんしゃ', 'アドベンチャラー'],
    '古代文字': ['こだいもじ', '古代の文字', '古文字'],
    '石造り': ['いしづくり', '石作り'],
    'ECS': ['ecs', 'Ecs'],
    'Bevy': ['bevy', 'BEVY'],
    'Rust': ['rust', 'RUST'],
    'アーキテクチャ': ['アーキテクチャー', 'architecture']
  };

  // 技術用語の半角・全角間スペース統一
  const technicalTerms = [
    'Rust',
    'Bevy',
    'ECS',
    'DDD',
    'TDD',
    'UI',
    'API'
  ];

  return {
    [Syntax.Str](node) {
      const text = getSource(node);

      // ゲーム用語の表記統一チェック
      Object.keys(correctTerminology).forEach(correctTerm => {
        const wrongVariants = correctTerminology[correctTerm];

        wrongVariants.forEach(wrongTerm => {
          const index = text.indexOf(wrongTerm);
          if (index !== -1) {
            const ruleError = new RuleError(
              `ゲーム用語は「${correctTerm}」で統一してください（「${wrongTerm}」→「${correctTerm}」）`,
              {
                index: index
              }
            );
            report(node, ruleError);
          }
        });
      });

      // 技術用語の前後スペースチェック
      technicalTerms.forEach(term => {
        // 日本語文字の直後に技術用語がある場合（スペースなし）
        const noSpaceAfterJapanese = new RegExp(`([ぁ-んァ-ヶー一-龠])${term}`, 'g');
        let match;
        while ((match = noSpaceAfterJapanese.exec(text)) !== null) {
          const ruleError = new RuleError(
            `技術用語「${term}」の前に半角スペースを入れてください（「${match[1]}${term}」→「${match[1]} ${term}」）`,
            {
              index: match.index + match[1].length
            }
          );
          report(node, ruleError);
        }

        // 技術用語の直後に日本語文字がある場合（スペースなし）
        const noSpaceBeforeJapanese = new RegExp(`${term}([ぁ-んァ-ヶー一-龠])`, 'g');
        while ((match = noSpaceBeforeJapanese.exec(text)) !== null) {
          const ruleError = new RuleError(
            `技術用語「${term}」の後に半角スペースを入れてください（「${term}${match[1]}」→「${term} ${match[1]}」）`,
            {
              index: match.index + term.length
            }
          );
          report(node, ruleError);
        }
      });

      // 「版」の前後スペースチェック
      const versionPattern = /([A-Za-z]+)版/g;
      let versionMatch;
      while ((versionMatch = versionPattern.exec(text)) !== null) {
        // 「Rust版」などの場合、「Rust 版」に修正を提案
        if (!text.charAt(versionMatch.index - 1).match(/\s/)) {
          const ruleError = new RuleError(
            `技術用語と「版」の間に半角スペースを入れてください（「${versionMatch[1]}版」→「${versionMatch[1]} 版」）`,
            {
              index: versionMatch.index + versionMatch[1].length
            }
          );
          report(node, ruleError);
        }
      }
    }
  };
};

module.exports.meta = {
  docs: {
    description: "ゲーム内用語の一貫性をチェックするルール",
    category: "style"
  },
  fixable: false,
  type: "suggestion"
};
