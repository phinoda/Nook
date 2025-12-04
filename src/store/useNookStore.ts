import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { ListsSlice } from './slices/listsSlice';
import type { ItemsSlice } from './slices/itemsSlice';
import type { TagsSlice } from './slices/tagsSlice';

export type NookStore = ListsSlice & ItemsSlice & TagsSlice;

// Import after type definition to avoid circular dependency
import { createListsSlice } from './slices/listsSlice';
import { createItemsSlice } from './slices/itemsSlice';
import { createTagsSlice } from './slices/tagsSlice';

export const useNookStore = create<NookStore>()(
    persist(
        (...a) => ({
            ...createListsSlice(...a),
            ...createItemsSlice(...a),
            ...createTagsSlice(...a),
        }),
        {
            name: 'nook-storage',
        }
    )
);
