export type ItemType = 'task' | 'group';

export interface Item {
    id: string;
    type: ItemType;
    text: string;
    isDone: boolean; // only meaningful for tasks
    children: Item[]; // only meaningful for groups
    note: string | null;
    tagIds: string[]; // references to Tag IDs
    createdAt: Date;
    updatedAt: Date;
}
