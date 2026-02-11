import type { Item, ItemType } from '@/types';

/**
 * Finds an item in the tree by its ID.
 */
export const findItemInTree = (items: Item[], itemId: string): Item | null => {
    for (const item of items) {
        if (item.id === itemId) return item;
        if (item.children.length > 0) {
            const found = findItemInTree(item.children, itemId);
            if (found) return found;
        }
    }
    return null;
};

/**
 * Updates an item in the tree.
 * @param items The array of items to traverse.
 * @param itemId The ID of the item to update.
 * @param updateFn A function that takes the old item and returns the new item.
 */
export const updateItemInTree = (
    items: Item[],
    itemId: string,
    updateFn: (item: Item) => Item
): Item[] => {
    return items.map((item) => {
        if (item.id === itemId) {
            return { ...updateFn(item), updatedAt: new Date() };
        }
        if (item.children.length > 0) {
            const newChildren = updateItemInTree(item.children, itemId, updateFn);
            if (newChildren !== item.children) {
                return { ...item, children: newChildren };
            }
        }
        return item;
    });
};

/**
 * Removes an item from the tree.
 * @param items The array of items to traverse.
 * @param itemId The ID of the item to remove.
 */
export const removeItemFromTree = (items: Item[], itemId: string): Item[] => {
    return items
        .filter((item) => item.id !== itemId)
        .map((item) => {
            if (item.children.length > 0) {
                const newChildren = removeItemFromTree(item.children, itemId);
                if (newChildren !== item.children) {
                    return { ...item, children: newChildren };
                }
            }
            return item;
        });
};

/**
 * Adds an item to a parent's children array.
 * @param items The array of items to traverse.
 * @param parentId The ID of the parent item (if null, returns items as is - add at root level manually).
 * @param newItem The new item to add.
 * @param index Optional index to insert at. If undefined, appends to end.
 */
export const addItemToParent = (
    items: Item[],
    parentId: string,
    newItem: Item,
    index?: number
): Item[] => {
    return items.map((item) => {
        if (item.id === parentId) {
            const newChildren = [...item.children];
            if (typeof index === 'number') {
                newChildren.splice(index, 0, newItem);
            } else {
                newChildren.push(newItem);
            }
            return {
                ...item,
                children: newChildren,
                type: 'group' as ItemType,
                updatedAt: new Date(),
            };
        }
        if (item.children.length > 0) {
            const newChildren = addItemToParent(item.children, parentId, newItem, index);
            if (newChildren !== item.children) {
                return { ...item, children: newChildren };
            }
        }
        return item;
    });
};

/**
 * Finds an item and removes it, returning the removed item and the new tree.
 */
export const findAndRemoveItem = (
    items: Item[],
    itemId: string
): { item: Item | null; newItems: Item[] } => {
    let removedItem: Item | null = null;

    const newItems = items
        .filter((item) => {
            if (item.id === itemId) {
                removedItem = item;
                return false;
            }
            return true;
        })
        .map((item) => {
            if (item.children.length > 0) {
                const result = findAndRemoveItem(item.children, itemId);
                if (result.item) {
                    removedItem = result.item;
                    return { ...item, children: result.newItems };
                }
            }
            return item;
        });

    return { item: removedItem, newItems };
};
