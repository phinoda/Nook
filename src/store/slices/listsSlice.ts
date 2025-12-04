import type { StateCreator } from 'zustand';
import type { List } from '@/types';
import { generateId } from '@/utils/id';

export interface ListsSlice {
    lists: List[];
    activeListId: string | null;

    createList: (name: string) => void;
    deleteList: (id: string) => void;
    updateList: (id: string, updates: Partial<List>) => void;
    setActiveList: (id: string | null) => void;
}

export const createListsSlice: StateCreator<ListsSlice> = (set) => ({
    lists: [],
    activeListId: null,

    createList: (name: string) => {
        const newList: List = {
            id: generateId(),
            name,
            items: [],
            createdAt: new Date(),
            updatedAt: new Date(),
        };
        set((state) => ({
            lists: [...state.lists, newList],
            activeListId: newList.id,
        }));
    },

    deleteList: (id: string) => {
        set((state) => ({
            lists: state.lists.filter((list) => list.id !== id),
            activeListId: state.activeListId === id ? null : state.activeListId,
        }));
    },

    updateList: (id: string, updates: Partial<List>) => {
        set((state) => ({
            lists: state.lists.map((list) =>
                list.id === id
                    ? { ...list, ...updates, updatedAt: new Date() }
                    : list
            ),
        }));
    },

    setActiveList: (id: string | null) => {
        set({ activeListId: id });
    },
});
