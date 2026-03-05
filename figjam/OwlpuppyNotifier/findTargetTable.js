import { MARKER } from "./SETTINGS";
export function findTargetTable() {
    const tables = figma.currentPage.findAll(node => node.type === "TABLE");
    for (const table of tables) {
        const cell = table.cellAt(0, 0);
        const text = cell.text.characters;
        if (text.startsWith(MARKER)) {
            return table;
        }
    }
    return null;
}
