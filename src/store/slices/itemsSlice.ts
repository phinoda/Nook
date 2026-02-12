import type { StateCreator } from 'zustand';
import type { Item, ItemType } from '@/types';
import { generateId } from '@/utils/id';
import type { NookStore } from '../useNookStore';
import {
    addItemToParent,
    findAndRemoveItem,
    removeItemFromTree,
    updateItemInTree,
} from '@/utils/treeUtils';
import { flattenItems } from '@/utils/flatten';

export interface ItemsSlice {
    createItem: (listId: string, text: string, type: ItemType, parentId?: string) => void;
    updateItem: (listId: string, itemId: string, updates: Partial<Item>) => void;
    deleteItem: (listId: string, itemId: string) => void;
    toggleItemDone: (listId: string, itemId: string) => void;
    indentItem: (listId: string, itemId: string) => void;
    unindentItem: (listId: string, itemId: string) => void;
    moveItem: (
        listId: string,
        itemId: string,
        newParentId: string | null,
        newIndex: number
    ) => void;
    addTagToItem: (listId: string, itemId: string, tagId: string) => void;
    removeTagFromItem: (listId: string, itemId: string, tagId: string) => void;
    createItemAfter: (listId: string, currentItemId: string, text?: string) => void;
    toggleItemType: (listId: string, itemId: string) => void;
}

export const createItemsSlice: StateCreator<NookStore, [], [], ItemsSlice> = (set) => ({
    createItem: (listId: string, text: string, type: ItemType, parentId?: string) => {
        const newItem: Item = {
            id: generateId(),
            type,
            text,
            isDone: false,
            children: [],
            note: null,
            tagIds: [],
            createdAt: new Date(),
            updatedAt: new Date(),
        };

        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                let newItems: Item[];

                if (!parentId) {
                    newItems = [...list.items, newItem];
                } else {
                    newItems = addItemToParent(list.items, parentId, newItem);
                }

                return {
                    ...list,
                    items: newItems,
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    createItemAfter: (listId: string, currentItemId: string, text: string = '') => {
        const newItem: Item = {
            id: generateId(),
            type: 'task',
            text,
            isDone: false,
            children: [],
            note: null,
            tagIds: [],
            createdAt: new Date(),
            updatedAt: new Date(),
        };

        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                const insertAfterFn = (items: Item[]): Item[] => {
                    return items.flatMap((item) => {
                        if (item.id === currentItemId) {
                            return [item, newItem];
                        }
                        if (item.children.length > 0) {
                            return [{ ...item, children: insertAfterFn(item.children) }];
                        }
                        return [item];
                    });
                };

                return {
                    ...list,
                    items: insertAfterFn(list.items),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    updateItem: (listId: string, itemId: string, updates: Partial<Item>) => {
        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                return {
                    ...list,
                    items: updateItemInTree(list.items, itemId, (item) => ({
                        ...item,
                        ...updates,
                    })),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    deleteItem: (listId: string, itemId: string) => {
        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                return {
                    ...list,
                    items: removeItemFromTree(list.items, itemId),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    toggleItemDone: (listId: string, itemId: string) => {
        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                return {
                    ...list,
                    items: updateItemInTree(list.items, itemId, (item) => ({
                        ...item,
                        isDone: !item.isDone,
                    })),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    indentItem: (listId: string, itemId: string) => {
        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                // Import flattenItems to get visual order
                const flattenedItems = flattenItems(list.items);

                // Find current item's index in flattened list
                const currentIndex = flattenedItems.findIndex(fi => fi.id === itemId);
                if (currentIndex === -1) return list; // Item not found
                if (currentIndex === 0) return list; // First item, cannot indent

                const currentDepth = flattenedItems[currentIndex].depth;

                // To indent by one level, find the last sibling (same depth) above
                const targetDepth = currentDepth;
                let targetParentId: string | null = null;
                for (let i = currentIndex - 1; i >= 0; i--) {
                    if (flattenedItems[i].depth === targetDepth) {
                        targetParentId = flattenedItems[i].id;
                        break;
                    }
                }

                if (!targetParentId) return list;


                // Remove item from current position
                const { item: itemToMove, newItems: itemsWithoutTarget } = findAndRemoveItem(
                    list.items,
                    itemId
                );

                if (!itemToMove) return list;

                // Add item as child of target parent
                const itemsWithMoved = addItemToParent(
                    itemsWithoutTarget,
                    targetParentId,
                    itemToMove
                );

                return {
                    ...list,
                    items: itemsWithMoved,
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    unindentItem: (listId: string, itemId: string) => {
        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                // 1. Find the item and its current parent
                // Since our treeUtils are generic, we might need a specific "findParent" or custom logic here
                // just for unindenting, or we can use the existing logic if we can determine the parent another way.
                // However, the original unindent logic was quite specific about "add after parent".

                // Let's implement a specific specialized traversal for unindent here, 
                // but use treeUtils where possible.
                // Or better, logic:
                // 1. Find and remove item.
                // 2. Find the *old parent*.
                // 3. Insert item *after* the old parent in the *grandparent's* list (or root).

                // BUT, to keep it simple and correct to the "visual" indentation:
                // "Unindent" usually means "become a sibling of your parent".

                // Let's stick closer to the original logic but cleaner.

                let itemToMove: Item | null = null;
                let parentOfItemToMove: Item | null = null;
                let followingSiblings: Item[] = [];

                const findAndRemove = (items: Item[], parent: Item | null = null): Item[] => {
                    const result: Item[] = [];
                    let foundTarget = false;

                    for (const item of items) {
                        if (item.id === itemId) {
                            itemToMove = item;
                            parentOfItemToMove = parent;
                            foundTarget = true;
                            continue; // Don't add to result
                        }

                        // If we found the target in this array, all remaining items are following siblings
                        if (foundTarget && parent === parentOfItemToMove) {
                            followingSiblings.push(item);
                            continue; // Don't add to result
                        }

                        if (item.children.length > 0) {
                            const newChildren = findAndRemove(item.children, item);
                            result.push({ ...item, children: newChildren });
                        } else {
                            result.push(item);
                        }
                    }
                    return result;
                };

                const itemsWithoutTarget = findAndRemove(list.items);

                if (!itemToMove || !parentOfItemToMove) return list; // Already at root or not found

                // Add following siblings as children of the item being unindented
                const itemWithNewChildren: Item = {
                    ...itemToMove!,
                    children: [...itemToMove!.children, ...followingSiblings],
                    updatedAt: new Date(),
                };

                // Now add itemWithNewChildren after parentOfItemToMove
                const addAfterParent = (items: Item[]): Item[] => {
                    return items.flatMap((item) => {
                        if (item.id === parentOfItemToMove!.id) {
                            return [item, itemWithNewChildren];
                        }
                        if (item.children.length > 0) {
                            return [{ ...item, children: addAfterParent(item.children) }];
                        }
                        return [item];
                    });
                };

                return {
                    ...list,
                    items: addAfterParent(itemsWithoutTarget),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    moveItem: (
        listId: string,
        itemId: string,
        newParentId: string | null,
        newIndex: number
    ) => {
        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                const { item: itemToMove, newItems: itemsWithoutTarget } = findAndRemoveItem(
                    list.items,
                    itemId
                );

                if (!itemToMove) return list;

                let newItems: Item[];

                if (newParentId === null) {
                    newItems = [...itemsWithoutTarget];
                    newItems.splice(newIndex, 0, itemToMove);
                } else {
                    newItems = addItemToParent(
                        itemsWithoutTarget,
                        newParentId,
                        itemToMove,
                        newIndex
                    );
                }

                return {
                    ...list,
                    items: newItems,
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    addTagToItem: (listId: string, itemId: string, tagId: string) => {
        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                return {
                    ...list,
                    items: updateItemInTree(list.items, itemId, (item) => ({
                        ...item,
                        tagIds: [...new Set([...item.tagIds, tagId])],
                    })),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    removeTagFromItem: (listId: string, itemId: string, tagId: string) => {
        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                return {
                    ...list,
                    items: updateItemInTree(list.items, itemId, (item) => ({
                        ...item,
                        tagIds: item.tagIds.filter((id) => id !== tagId),
                    })),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    toggleItemType: (listId: string, itemId: string) => {
        set((state) => ({
            lists: state.lists.map((list) => {
                if (list.id !== listId) return list;

                return {
                    ...list,
                    items: updateItemInTree(list.items, itemId, (item) => {
                        const newType: ItemType = item.type === 'task' ? 'header' : 'task';
                        return {
                            ...item,
                            type: newType,
                            // Reset isDone to false when converting to task
                            isDone: newType === 'task' ? false : item.isDone,
                        };
                    }),
                    updatedAt: new Date(),
                };
            }),
        }));
    },
});
