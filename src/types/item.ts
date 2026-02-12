export type ItemType = 'task' | 'header';

export interface Item {
    id: string;
    type: ItemType;
    text: string;
    isDone: boolean; // only meaningful for tasks
    children: Item[]; // can exist on both tasks and headers for nesting
    note: string | null;
    tagIds: string[]; // references to Tag IDs
    createdAt: Date;
    updatedAt: Date;
}
