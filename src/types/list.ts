import type { Item } from './item';

export interface List {
    id: string;
    name: string;
    items: Item[];
    createdAt: Date;
    updatedAt: Date;
}
