import {findTargetTable} from "./findTargetTable";
import {findFutureCells} from "./findFutureCells";
import {processStickiesForCells} from "./processStickies";

// RUN ONE TIME PLUGIN
main();

async function main() {
  console.log("🐶 Owlpuppy Notifier started!");
  const targetTable = findTargetTable();
  if (!targetTable) {
    figma.closePlugin("❌ 対象のテーブル（🐶マーク）が見つかりませんでした。");
    return;
  }
  const targetCells = findFutureCells(targetTable);
  if (targetCells.length === 0) {
    figma.closePlugin("ℹ️ 今日以降の日付が見つかりませんでした。");
    return;
  }
  const sentCount = await processStickiesForCells(targetTable, targetCells);

  if ((sentCount || 0) > 0) {
    figma.closePlugin(`✅ ${sentCount} 件の新しいリマインダーをOwlpuppyに送信しました！`);
  } else {
    figma.closePlugin("ℹ️ 新しく送信するリマインダーはありませんでした。");
  }
}
