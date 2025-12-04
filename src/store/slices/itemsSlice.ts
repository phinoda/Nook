import type { StateCreator } from 'zustand';
import type { Item, ItemType } from '@/types';
import { generateId } from '@/utils/id';
import type { NookStore } from '../useNookStore';

export interface ItemsSlice {
    createItem: (listId: string, text: string, type: ItemType, parentId?: string) => void;
    updateItem: (listId: string, itemId: string, updates: Partial<Item>) => void;
    deleteItem: (listId: string, itemId: string) => void;
    toggleItemDone: (listId: string, itemId: string) => void;
    indentItem: (listId: string, itemId: string, newParentId: string) => void;
    unindentItem: (listId: string, itemId: string) => void;
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

        set((state: any) => ({
            lists: state.lists.map((list: any) => {
                if (list.id !== listId) return list;

                if (!parentId) {
                    // Add to root level
                    return {
                        ...list,
                        items: [...list.items, newItem],
                        updatedAt: new Date(),
                    };
                } else {
                    // Add as child to parent
                    const addToParent = (items: Item[]): Item[] => {
                        return items.map((item) => {
                            if (item.id === parentId) {
                                return {
                                    ...item,
                                    children: [...item.children, newItem],
                                    type: 'group' as ItemType, // Convert to group when adding child
                                };
                            }
                            if (item.children.length > 0) {
                                return { ...item, children: addToParent(item.children) };
                            }
                            return item;
                        });
                    };

                    return {
                        ...list,
                        items: addToParent(list.items),
                        updatedAt: new Date(),
                    };
                }
            }),
        }));
    },

    updateItem: (listId: string, itemId: string, updates: Partial<Item>) => {
        set((state: any) => ({
            lists: state.lists.map((list: any) => {
                if (list.id !== listId) return list;

                const updateInTree = (items: Item[]): Item[] => {
                    return items.map((item) => {
                        if (item.id === itemId) {
                            return { ...item, ...updates, updatedAt: new Date() };
                        }
                        if (item.children.length > 0) {
                            return { ...item, children: updateInTree(item.children) };
                        }
                        return item;
                    });
                };

                return {
                    ...list,
                    items: updateInTree(list.items),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    deleteItem: (listId: string, itemId: string) => {
        set((state: any) => ({
            lists: state.lists.map((list: any) => {
                if (list.id !== listId) return list;

                const deleteFromTree = (items: Item[]): Item[] => {
                    return items
                        .filter((item) => item.id !== itemId)
                        .map((item) => ({
                            ...item,
                            children: deleteFromTree(item.children),
                        }));
                };

                return {
                    ...list,
                    items: deleteFromTree(list.items),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    toggleItemDone: (listId: string, itemId: string) => {
        set((state: any) => ({
            lists: state.lists.map((list: any) => {
                if (list.id !== listId) return list;

                const toggleInTree = (items: Item[]): Item[] => {
                    return items.map((item) => {
                        if (item.id === itemId) {
                            return { ...item, isDone: !item.isDone, updatedAt: new Date() };
                        }
                        if (item.children.length > 0) {
                            return { ...item, children: toggleInTree(item.children) };
                        }
                        return item;
                    });
                };

                return {
                    ...list,
                    items: toggleInTree(list.items),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    indentItem: (listId: string, itemId: string, newParentId: string) => {
        set((state: any) => ({
            lists: state.lists.map((list: any) => {
                if (list.id !== listId) return list;

                let itemToMove: Item | null = null;

                // Find and remove the item from its current location
                const removeItem = (items: Item[]): Item[] => {
                    return items
                        .filter((item) => {
                            if (item.id === itemId) {
                                itemToMove = item;
                                return false;
                            }
                            return true;
                        })
                        .map((item) => ({
                            ...item,
                            children: removeItem(item.children),
                        }));
                };

                // Add the item as a child to the new parent
                const addToParent = (items: Item[]): Item[] => {
                    return items.map((item) => {
                        if (item.id === newParentId && itemToMove) {
                            return {
                                ...item,
                                children: [...item.children, itemToMove],
                                type: 'group' as ItemType,
                                updatedAt: new Date(),
                            };
                        }
                        if (item.children.length > 0) {
                            return { ...item, children: addToParent(item.children) };
                        }
                        return item;
                    });
                };

                const itemsWithoutTarget = removeItem(list.items);
                const itemsWithMoved = addToParent(itemsWithoutTarget);

                return {
                    ...list,
                    items: itemsWithMoved,
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    unindentItem: (listId: string, itemId: string) => {
        set((state: any) => ({
            lists: state.lists.map((list: any) => {
                if (list.id !== listId) return list;

                let itemToMove: Item | null = null;
                let parentOfItemToMove: Item | null = null;

                // Find the item, its parent, and remove it from current location
                const findAndRemove = (items: Item[], parent: Item | null = null): Item[] => {
                    const result: Item[] = [];
                    
                    for (const item of items) {
                        if (item.id === itemId) {
                            itemToMove = item;
                            parentOfItemToMove = parent;
                            // Don't add this item to result (removing it)
                            continue;
                        }
                        
                        // Recursively process children
                        if (item.children.length > 0) {
                            const newChildren = findAndRemove(item.children, item);
                            result.push({ ...item, children: newChildren });
                        } else {
                            result.push(item);
                        }
                    }
                    
                    return result;
                };

                // Add the item at the same level as its parent
                const addAtParentLevel = (items: Item[]): Item[] => {
                    if (!itemToMove || !parentOfItemToMove) return items;

                    return items.flatMap((item) => {
                        if (item.id === parentOfItemToMove!.id) {
                            // Found the parent - add the item right after it
                            return [item, itemToMove!];
                        }
                        
                        // Recursively search in children
                        if (item.children.length > 0) {
                            const newChildren = addAtParentLevel(item.children);
                            // If children changed, it means we found and added the item
                            if (newChildren !== item.children) {
                                return [{ ...item, children: newChildren }];
                            }
                        }
                        
                        return [item];
                    });
                };

                const itemsWithoutTarget = findAndRemove(list.items);
                
                // If item has no parent, it's already at root level, can't unindent
                if (!parentOfItemToMove) {
                    return list;
                }

                const itemsWithMoved = addAtParentLevel(itemsWithoutTarget);

                return {
                    ...list,
                    items: itemsWithMoved,
                    updatedAt: new Date(),
                };
            }),
        }));
    },
});
