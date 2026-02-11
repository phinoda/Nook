import type { StateCreator } from 'zustand';
import type { Tag } from '@/types';
import { generateId } from '@/utils/id';
import type { NookStore } from '../useNookStore';

export interface TagsSlice {
    tags: Tag[];

    createTag: (label: string, color: string) => Tag;
    deleteTag: (id: string) => void;
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
});
