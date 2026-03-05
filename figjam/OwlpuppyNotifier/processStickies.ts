import {TargetDateCell} from "./findFutureCells";
import {OWLPUPPY_API_URL} from "./SETTINGS";

export async function processStickiesForCells(table: TableNode, targetCells: TargetDateCell[]): Promise<number> {
  const allStickies = figma.currentPage.findAll(node => node.type === "STICKY") as StickyNode[];

  const tableBounds = table.absoluteBoundingBox;
  if (!tableBounds) {
    console.error("Error: Could not get table bounds.");
    return 0;
  }
  const tableStickies = allStickies
    .filter(sticky => !sticky.removed)
    .filter((sticky) => {
      const {cx, cy} = getCenterPosition(sticky);
      return cx >= tableBounds.x && cx < tableBounds.x + tableBounds.width && cy >= tableBounds.y && cy < tableBounds.y + tableBounds.height;
    });
  if (tableStickies.length === 0) {
    console.log("There is no stickies found in the table.");
    return 0;
  }
  const {left, right, top, bottom} = getBounds(table);
  const cellStickies = new Map<string, StickyNode[]>();

  for (const sticky of tableStickies) {
    const {cx, cy} = getCenterPosition(sticky);
    const stickyColumn = getIndexBetween(cx, left, right);
    const stickyRow = getIndexBetween(cy, top, bottom);
    if (stickyColumn < 0 || stickyRow < 0) continue;

    const key = `${stickyColumn},${stickyRow}`;
    const list = cellStickies.get(key) || [];
    list.push(sticky);
    cellStickies.set(key, list);
  }

  const payload: OwlpuppyItem[] = [];
  for (const targetCell of targetCells) {
    const key = `${targetCell.colIndex},${targetCell.rowIndex}`;
    const stickies = cellStickies.get(key) || [];

    for (const sticky of stickies) {
      const {dateTime, message} = getCalendarItem(sticky, targetCell);
      payload.push({
        isoDateTime: toLocalISOString(dateTime),
        message,
      });
    }
  }
  console.log("Owlpuppy: remind items", payload);
  try {
    const response = await fetch(OWLPUPPY_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        items: payload
      })
    });
    console.log("Owlpuppy: remind response: ", response.status, response.statusText);
  }
  catch (e) {
    console.error(e);
  }

  return payload.length;
}

function getCalendarItem(sticky: StickyNode, cell: TargetDateCell): { dateTime: Date, message: string } {
  const lines = sticky.text.characters.split('\n');
  if (lines.length < 2) return {dateTime: new Date(), message: ""};

  const timeStr = lines[0];
  const timeRegex = /\d{1,2}:\d{2}/;
  const match = timeStr.match(timeRegex);
  if (!match) return {dateTime: new Date(), message: ""};

  const hhmm = match[0].split(":");
  if (hhmm.length !== 2) return {dateTime: new Date(), message: ""};

  const dt = new Date(cell.parsedDate);
  dt.setHours(parseInt(hhmm[0]), parseInt(hhmm[1]));

  return {
    dateTime: dt,
    message: sticky.text.characters.trim(),
  }
}

type OwlpuppyItem = {
  isoDateTime: string;
  message: string;
}

function toLocalISOString(date: Date): string {
  const tzo = -date.getTimezoneOffset();
  const dif = tzo >= 0 ? '+' : '-';
  const pad = (num: number) => (num < 10 ? '0' : '') + num;

  return date.getFullYear() +
    '-' + pad(date.getMonth() + 1) +
    '-' + pad(date.getDate()) +
    'T' + pad(date.getHours()) +
    ':' + pad(date.getMinutes()) +
    ':' + pad(date.getSeconds()) +
    dif + pad(Math.floor(Math.abs(tzo) / 60)) +
    ':' + pad(Math.abs(tzo) % 60);
}


function getBounds(table: TableNode) {
  const tableBounds = table.absoluteBoundingBox;
  if (!tableBounds) {
    return {left: [], right: [], top: [], bottom: []};
  }
  const left: number[] = []
  const right: number[] = []
  let x = tableBounds.x;
  for (let column = 0; column < table.numColumns; column++) {
    left.push(x);
    x = x + table.cellAt(0, column).width;
    right.push(x);
  }
  const top: number[] = []
  const bottom: number[] = []
  let y = tableBounds.y;
  for (let row = 0; row < table.numRows; row++) {
    top.push(y);
    y = y + table.cellAt(row, 0).height;
    bottom.push(y);
  }
  return {left, right, top, bottom}
}

function getCenterPosition(sticky: StickyNode): { cx: number; cy: number } {
  const cx = sticky.x + sticky.width / 2;
  const cy = sticky.y + sticky.height / 2;
  return {cx, cy}
}

function getIndexBetween(value: number, from: number[], to: number[]): number {
  for (let index = 0; index < from.length; index++) {
    if (value >= from[index] && value < to[index]) {
      return index
    }
  }
  return -1;
}