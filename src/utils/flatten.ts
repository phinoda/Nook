import type { Item } from '@/types';

export interface FlatItem {
    id: string;
    text: string;
    isDone: boolean;
    depth: number;
    parentId: string | null;
    index: number;
    item: Item; // Keep reference to original item with children
}

/**
 * Flattens a hierarchical array of items into a flat array for drag-and-drop.
 * Each flat item includes depth, parentId, and index information.
 */
export function flattenItems(items: Item[], parentId: string | null = null, depth: number = 0): FlatItem[] {
    const result: FlatItem[] = [];

    items.forEach((item, index) => {
        // Add the current item
        result.push({
            id: item.id,
            text: item.text,
            isDone: item.isDone,
            depth,
            parentId,
            index,
            item, // Keep full item reference (includes children)
        });

        // Recursively add children
        if (item.children && item.children.length > 0) {
            result.push(...flattenItems(item.children, item.id, depth + 1));
        }
    });

    return result;
}
