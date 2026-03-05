export function findFutureCells(table: TableNode): TargetDateCell[] {
  const targetCell: TargetDateCell[] = [];
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const currentYear = today.getFullYear();

  for (let rowIndex = 0; rowIndex < table.numRows; rowIndex++) {
    for (let colIndex = 0; colIndex < table.numColumns; colIndex++) {
      const cell = table.cellAt(rowIndex, colIndex);
      if (!cell || !cell.text) continue;

      const text = cell.text.characters.trim();
      const dateMatch = text.match(/^(0?[1-9]|1[0-2])\/(0?[1-9]|[12][0-9]|3[01])$/);
      if (dateMatch) {
        const month = parseInt(dateMatch[1], 10);
        const day = parseInt(dateMatch[2], 10);

        const cellDate = new Date(currentYear, month - 1, day);
        cellDate.setHours(0, 0, 0, 0);

        if (cellDate.getTime() >= today.getTime()) {
          targetCell.push({
            colIndex: colIndex,
            rowIndex: rowIndex,
            dateStr: text,
            parsedDate: cellDate
          });
        }
      }
    }
  }
  targetCell.sort((a, b) => a.parsedDate.getDate() - b.parsedDate.getDate());
  return targetCell;
}

export interface TargetDateCell {
  rowIndex: number;
  colIndex: number;
  dateStr: string;
  parsedDate: Date;
}
