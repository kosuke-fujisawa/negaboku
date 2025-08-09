/**
 * ゲーム内用語の一貫性チェック・自動修正ルール
 * 正しいゲーム用語のスペルと表記をチェック・修正
 */
const fs = require('fs');
const path = require('path');

// 設定ファイルの読み込み（外部設定化）
let terminology = {};
let technicalTerms = [];
try {
  const configPath = path.join(__dirname, 'game-terminology.json');
  if (fs.existsSync(configPath)) {
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    terminology = config.terminology || {};
    technicalTerms = config.technicalTerms || [];
  }
} catch (err) {
  // フォールバック設定
  terminology = {
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
  technicalTerms = ['Rust', 'Bevy', 'ECS', 'DDD', 'TDD', 'UI', 'API'];
}

// Regexのプリコンパイル（パフォーマンス最適化）
const japaneseCharsRegex = /[ぁ-んァ-ヶー一-龠]/;
const technicalTermRegexes = new Map();
technicalTerms.forEach(term => {
  technicalTermRegexes.set(term, {
    noSpaceAfter: new RegExp(`([ぁ-んァ-ヶー一-龠])${term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'g'),
    noSpaceBefore: new RegExp(`${term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}([ぁ-んァ-ヶー一-龠])`, 'g')
  });
});

// 「版」パターンの除外リスト（重複報告防止）
const VERSION_EXCLUSIONS = new Set(['体験版', 'アルファ版', 'ベータ版', '正式版', '完全版']);

module.exports = function(context) {
  const { Syntax, getSource, report, RuleError, fixer } = context;

  return {
    [Syntax.Str](node) {
      const text = getSource(node);

      // ゲーム用語の表記統一チェック（重複検出対応）
      const processedPositions = new Set(); // 重複報告防止

      Object.keys(terminology).forEach(correctTerm => {
        const wrongVariants = terminology[correctTerm];

        wrongVariants.forEach(wrongTerm => {
          let searchIndex = 0;
          while (true) {
            const index = text.indexOf(wrongTerm, searchIndex);
            if (index === -1) break;

            // 位置の重複チェック
            const positionKey = `${index}-${index + wrongTerm.length}`;
            if (!processedPositions.has(positionKey)) {
              processedPositions.add(positionKey);

              const ruleError = new RuleError(
                `ゲーム用語は「${correctTerm}」で統一してください（「${wrongTerm}」→「${correctTerm}」）`,
                {
                  index: index,
                  fix: fixer.replaceTextRange([index, index + wrongTerm.length], correctTerm)
                }
              );
              report(node, ruleError);
            }

            searchIndex = index + 1;
          }
        });
      });

      // 技術用語の前後スペースチェック（プリコンパイル済みRegex使用）
      technicalTerms.forEach(term => {
        const regexes = technicalTermRegexes.get(term);
        if (!regexes) return;

        // 日本語文字の直後に技術用語がある場合（スペースなし）
        let match;
        regexes.noSpaceAfter.lastIndex = 0; // Reset regex state
        while ((match = regexes.noSpaceAfter.exec(text)) !== null) {
          const ruleError = new RuleError(
            `技術用語「${term}」の前に半角スペースを入れてください（「${match[1]}${term}」→「${match[1]} ${term}」）`,
            {
              index: match.index + match[1].length,
              fix: fixer.replaceTextRange([match.index + match[1].length, match.index + match[1].length], ' ')
            }
          );
          report(node, ruleError);
        }

        // 技術用語の直後に日本語文字がある場合（スペースなし）
        regexes.noSpaceBefore.lastIndex = 0; // Reset regex state
        while ((match = regexes.noSpaceBefore.exec(text)) !== null) {
          const ruleError = new RuleError(
            `技術用語「${term}」の後に半角スペースを入れてください（「${term}${match[1]}」→「${term} ${match[1]}」）`,
            {
              index: match.index + term.length,
              fix: fixer.replaceTextRange([match.index + term.length, match.index + term.length], ' ')
            }
          );
          report(node, ruleError);
        }
      });

      // 「版」の前後スペースチェック（重複報告防止・除外リスト対応）
      const versionPattern = /([A-Za-z]+)版/g;
      const reportedVersions = new Set(); // 重複報告防止
      let versionMatch;

      while ((versionMatch = versionPattern.exec(text)) !== null) {
        const fullMatch = versionMatch[0]; // 例：「Rust版」
        const term = versionMatch[1]; // 例：「Rust」

        // 除外リストにある場合はスキップ
        if (VERSION_EXCLUSIONS.has(fullMatch)) {
          continue;
        }

        // 重複報告チェック
        const reportKey = `${versionMatch.index}-${fullMatch}`;
        if (reportedVersions.has(reportKey)) {
          continue;
        }
        reportedVersions.add(reportKey);

        // 「Rust版」などの場合、「Rust 版」に修正を提案
        const termEndIndex = versionMatch.index + term.length;
        const ruleError = new RuleError(
          `技術用語と「版」の間に半角スペースを入れてください（「${fullMatch}」→「${term} 版」）`,
          {
            index: termEndIndex,
            fix: fixer.replaceTextRange([termEndIndex, termEndIndex], ' ')
          }
        );
        report(node, ruleError);
      }
    }
  };
};

module.exports.meta = {
  docs: {
    description: "ゲーム内用語の一貫性をチェック・自動修正するルール",
    category: "style"
  },
  fixable: "code",
  type: "suggestion"
};
