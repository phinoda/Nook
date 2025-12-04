import type { StateCreator } from 'zustand';
import type { Tag } from '@/types';
import { generateId } from '@/utils/id';
import type { NookStore } from '../useNookStore';

export interface TagsSlice {
    tags: Tag[];

    createTag: (label: string, color: string) => Tag;
    deleteTag: (id: string) => void;
    addTagToItem: (listId: string, itemId: string, tagId: string) => void;
    removeTagFromItem: (listId: string, itemId: string, tagId: string) => void;
}

export const createTagsSlice: StateCreator<NookStore, [], [], TagsSlice> = (set) => ({
    tags: [],

    createTag: (label: string, color: string) => {
        const newTag: Tag = {
            id: generateId(),
            label,
            color,
        };
        set((state) => ({
            tags: [...state.tags, newTag],
        }));
        return newTag;
    },

    deleteTag: (id: string) => {
        set((state) => ({
            tags: state.tags.filter((tag) => tag.id !== id),
        }));
    },

    addTagToItem: (listId: string, itemId: string, tagId: string) => {
        set((state: any) => ({
            lists: state.lists.map((list: any) => {
                if (list.id !== listId) return list;

                const addTagInTree = (items: any[]): any[] => {
                    return items.map((item) => {
                        if (item.id === itemId) {
                            return {
                                ...item,
                                tagIds: [...new Set([...item.tagIds, tagId])],
                                updatedAt: new Date(),
                            };
                        }
                        if (item.children.length > 0) {
                            return { ...item, children: addTagInTree(item.children) };
                        }
                        return item;
                    });
                };

                return {
                    ...list,
                    items: addTagInTree(list.items),
                    updatedAt: new Date(),
                };
            }),
        }));
    },

    removeTagFromItem: (listId: string, itemId: string, tagId: string) => {
        set((state: any) => ({
            lists: state.lists.map((list: any) => {
                if (list.id !== listId) return list;

                const removeTagInTree = (items: any[]): any[] => {
                    return items.map((item) => {
                        if (item.id === itemId) {
                            return {
                                ...item,
                                tagIds: item.tagIds.filter((id: string) => id !== tagId),
                                updatedAt: new Date(),
                            };
                        }
                        if (item.children.length > 0) {
                            return { ...item, children: removeTagInTree(item.children) };
                        }
                        return item;
                    });
                };

                return {
                    ...list,
                    items: removeTagInTree(list.items),
                    updatedAt: new Date(),
                };
            }),
        }));
    },
});
