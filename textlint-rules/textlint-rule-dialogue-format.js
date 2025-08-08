/**
 * セリフ記法正規化ルール
 * **キャラクター名**「セリフ」形式の統一をチェック
 */
module.exports = function(context) {
  const { Syntax, getSource, report, RuleError } = context;

  return {
    [Syntax.Str](node) {
      const text = getSource(node);
      const lines = text.split('\n');

      lines.forEach((line, lineIndex) => {
        const trimmedLine = line.trim();

        // 空行やコメント行をスキップ
        if (!trimmedLine || trimmedLine.startsWith('<!--')) {
          return;
        }

        // セリフらしき行をチェック
        // 1. 「」があるがキャラクター名が**で囲まれていない
        const quoteWithoutBold = /^[^*]*[「『].*[」』]/;
        if (quoteWithoutBold.test(trimmedLine)) {
          const quoteMatch = trimmedLine.match(/([^「『]*)[「『](.*)[」』]/);
          if (quoteMatch) {
            const possibleName = quoteMatch[1].trim();
            if (possibleName && possibleName.length < 10) { // 名前らしき文字列
              const lineStartIndex = text.indexOf(line);
              const suggestion = `**${possibleName}**「${quoteMatch[2]}」`;
              const ruleError = new RuleError(
                `セリフ記法は「**キャラクター名**「セリフ」」形式で統一してください（例: ${suggestion}）`,
                {
                  index: lineStartIndex
                }
              );
              report(node, ruleError);
              return; // この行の他のチェックをスキップ
            }
          }
        }

        // 2. *が1つだけ
        const singleAsterisk = /^\*[^*]*\*[「『].*[」』]/;
        if (singleAsterisk.test(trimmedLine)) {
          const lineStartIndex = text.indexOf(line);
          const suggestion = trimmedLine.replace(/^\*([^*]*)\*/, '**$1**');
          const ruleError = new RuleError(
            `キャラクター名は**（アスタリスク2つ）で囲んでください（例: ${suggestion}）`,
            {
              index: lineStartIndex
            }
          );
          report(node, ruleError);
        }

        // 3. *が3つ以上
        const multipleAsterisk = /^\*{3,}[^*]*\*{3,}[「『].*[」』]/;
        if (multipleAsterisk.test(trimmedLine)) {
          const lineStartIndex = text.indexOf(line);
          const suggestion = trimmedLine.replace(/^\*{3,}([^*]*)\*{3,}/, '**$1**');
          const ruleError = new RuleError(
            `キャラクター名は**（アスタリスク2つ）で囲んでください（例: ${suggestion}）`,
            {
              index: lineStartIndex
            }
          );
          report(node, ruleError);
        }

        // 4. コロンを使っている
        const colonPattern = /^\*\*([^*]+)\*\*\s*[：:]\s*(.*)/;
        if (colonPattern.test(trimmedLine)) {
          const colonMatch = trimmedLine.match(colonPattern);
          if (colonMatch) {
            const lineStartIndex = text.indexOf(line);
            const suggestion = `**${colonMatch[1]}**「${colonMatch[2]}」`;
            const ruleError = new RuleError(
              `セリフにはコロン（:）ではなく鉤括弧「」を使用してください（例: ${suggestion}）`,
              {
                index: lineStartIndex
              }
            );
            report(node, ruleError);
          }
        }

        // 正しい記法の細かい問題をチェック
        const correctDialogueMatch = trimmedLine.match(/^\*\*([^*]+)\*\*([「『])(.*)[」』](.*)$/);
        if (correctDialogueMatch) {
          const characterName = correctDialogueMatch[1];
          const openQuote = correctDialogueMatch[2];
          const dialogue = correctDialogueMatch[3];
          const afterQuote = correctDialogueMatch[4];

          // キャラクター名の前後に余計なスペースがないかチェック
          if (characterName !== characterName.trim()) {
            const lineStartIndex = text.indexOf(line);
            const ruleError = new RuleError(
              'キャラクター名の前後に余計なスペースがあります',
              {
                index: lineStartIndex
              }
            );
            report(node, ruleError);
          }

          // セリフの後に余計な文字がないかチェック
          if (afterQuote.trim() !== '') {
            const lineStartIndex = text.indexOf(line);
            const ruleError = new RuleError(
              'セリフの鉤括弧の後に余計な文字があります',
              {
                index: lineStartIndex
              }
            );
            report(node, ruleError);
          }

          // 開き括弧と閉じ括弧の統一チェック
          const closeQuote = openQuote === '「' ? '」' : '』';
          if (!trimmedLine.includes(closeQuote)) {
            const lineStartIndex = text.indexOf(line);
            const ruleError = new RuleError(
              `開き括弧「${openQuote}」に対応する閉じ括弧「${closeQuote}」を使用してください`,
              {
                index: lineStartIndex
              }
            );
            report(node, ruleError);
          }
        }
      });
    }
  };
};

module.exports.meta = {
  docs: {
    description: "セリフ記法の正規化をチェックするルール",
    category: "style"
  },
  fixable: false,
  type: "suggestion"
};
