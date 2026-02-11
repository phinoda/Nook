import { Button } from '@/components/ui/button';
import { useNookStore } from '@/store';
import { Plus } from 'lucide-react';
import {
    DndContext,
    closestCenter,
    KeyboardSensor,
    PointerSensor,
    useSensor,
    useSensors,
    DragOverlay,
    defaultDropAnimationSideEffects,
} from '@dnd-kit/core';
import type {
    DragEndEvent,
    DragStartEvent,
    DropAnimation,
} from '@dnd-kit/core';
import {
    SortableContext,
    sortableKeyboardCoordinates,
    verticalListSortingStrategy,
    useSortable,
} from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { flattenItems } from '@/utils/flatten';
import type { FlatItem } from '@/utils/flatten';
import { useMemo, useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Item } from '@/components/Item';

interface SortableItemWrapperProps {
    flatItem: FlatItem;
    listId: string;
}

function SortableItemWrapper({ flatItem, listId }: SortableItemWrapperProps) {
    const {
        attributes,
        listeners,
        setNodeRef,
        transform,
        transition,
        isDragging,
        setActivatorNodeRef,
    } = useSortable({ id: flatItem.id });

    const style = {
        transform: CSS.Translate.toString(transform),
        transition,
        opacity: isDragging ? 0.5 : 1,
    };

    return (
        <div ref={setNodeRef} style={style} {...attributes}>
            <Item
                item={flatItem.item}
                listId={listId}
                depth={flatItem.depth}
                dragHandleProps={{ ref: setActivatorNodeRef, ...listeners }}
            />
        </div>
    );
}

export function MainView() {
    const { lists, activeListId, createItem, moveItem, updateList } = useNookStore();
    const [activeId, setActiveId] = useState<string | null>(null);

    const activeList = lists.find((list) => list.id === activeListId);

    // Local state for list name editing
    const [listName, setListName] = useState(activeList?.name || '');
    const [showCompleted, setShowCompleted] = useState(true);

    // Sync local state when active list changes
    useEffect(() => {
        if (activeList) {
            setListName(activeList.name);
        }
    }, [activeList?.id, activeList?.name]);

    const handleListNameChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setListName(e.target.value);
    };

    const handleListNameBlur = () => {
        if (activeList && listName.trim() !== '' && listName !== activeList.name) {
            updateList(activeList.id, { name: listName });
        } else if (activeList && listName.trim() === '') {
            // Revert if empty
            setListName(activeList.name);
        }
    };

    const handleListNameKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Enter') {
            e.currentTarget.blur();
        }
    };

    const sensors = useSensors(
        useSensor(PointerSensor),
        useSensor(KeyboardSensor, {
            coordinateGetter: sortableKeyboardCoordinates,
        })
    );

    // Flatten items for drag-and-drop
    const flatItems = useMemo(() => {
        if (!activeList) return [];
        const allItems = flattenItems(activeList.items);
        return showCompleted ? allItems : allItems.filter(i => !i.item.isDone);
    }, [activeList, showCompleted]);

    const activeItem = useMemo(() => {
        return activeId ? flatItems.find((item) => item.id === activeId) : null;
    }, [activeId, flatItems]);

    const handleDragStart = (event: DragStartEvent) => {
        setActiveId(event.active.id as string);
    };

    const handleDragEnd = (event: DragEndEvent) => {
        const { active, over } = event;
        setActiveId(null);

        if (!over || active.id === over.id || !activeListId) return;

        const oldIndex = flatItems.findIndex((item) => item.id === active.id);
        const newIndex = flatItems.findIndex((item) => item.id === over.id);

        if (oldIndex === -1 || newIndex === -1) return;

        // Determine the new parent and depth based on the item below the drop position
        const itemBelow = flatItems[newIndex + 1];
        const itemAbove = flatItems[newIndex - 1];

        let newParentId: string | null;
        let indexInParent: number;

        if (itemBelow) {
            // Use the parent and depth of the item below
            newParentId = itemBelow.parentId;
            // Find the index within the parent's children
            if (newParentId === null) {
                // Root level - count root items before this position
                indexInParent = flatItems
                    .slice(0, newIndex + 1)
                    .filter(item => item.parentId === null).length - 1;
            } else {
                // Child level - count siblings before this position
                indexInParent = flatItems
                    .slice(0, newIndex + 1)
                    .filter(item => item.parentId === newParentId).length - 1;
            }
        } else if (itemAbove) {
            // Dropped at the bottom - use the parent of the item above
            newParentId = itemAbove.parentId;
            // Add at the end of the parent's children
            if (newParentId === null) {
                indexInParent = flatItems.filter(item => item.parentId === null).length;
            } else {
                indexInParent = flatItems.filter(item => item.parentId === newParentId).length;
            }
        } else {
            // Empty list
            newParentId = null;
            indexInParent = 0;
        }

        moveItem(activeListId, active.id as string, newParentId, indexInParent);
    };

    const dropAnimationConfig: DropAnimation = {
        sideEffects: defaultDropAnimationSideEffects({
            styles: {
                active: {
                    opacity: '0.5',
                },
            },
        }),
    };

    if (!activeListId || !activeList) {
        return (
            <div className="flex items-center justify-center h-full">
                <p className="text-sm text-muted-foreground">Select a list to get started</p>
            </div>
        );
    }

    const handleCreateItem = () => {
        createItem(activeList.id, '', 'task');
    };

    return (
        <div className="flex flex-col h-full relative">
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-5 border-b">
                <input
                    value={listName}
                    onChange={handleListNameChange}
                    onBlur={handleListNameBlur}
                    onKeyDown={handleListNameKeyDown}
                    className="text-2xl font-bold tracking-tight bg-transparent border-none focus:outline-none w-full placeholder:text-muted-foreground/50"
                    placeholder="List Name"
                />
            </div>

            {/* Progress and Filter */}
            {activeList && flattenItems(activeList.items).length > 0 && (() => {
                const allItems = flattenItems(activeList.items);
                const total = allItems.length;
                const completed = allItems.filter(i => i.item.isDone).length;
                const percent = total > 0 ? (completed / total) * 100 : 0;

                return (
                    <div className="px-6 py-4 flex flex-col gap-4 border-b bg-muted/20">
                        {/* Progress Row */}
                        <div className="flex items-center justify-start gap-4">
                            <div className="h-2 flex-1 max-w-[400px] bg-gray-200 rounded-full overflow-hidden">
                                <div
                                    className="h-full bg-black rounded-full transition-all duration-500 ease-out"
                                    style={{
                                        width: completed > 0 ? `${percent}%` : '8px'
                                    }}
                                />
                            </div>
                            <span className="text-xs text-muted-foreground whitespace-nowrap">
                                {completed === 0 ? "not started yet" : `${completed}/${total} ${completed === 1 ? 'task' : 'tasks'} completed`}
                            </span>
                        </div>

                        {/* Toggle Row */}
                        <div className="flex items-center justify-start gap-4">
                            <button
                                id="hide-done"
                                role="switch"
                                aria-checked={!showCompleted}
                                onClick={() => setShowCompleted(!showCompleted)}
                                className={`w-9 h-5 rounded-full relative transition-colors focus:outline-none ${!showCompleted ? 'bg-black' : 'bg-gray-200'}`}
                            >
                                <span
                                    className={`block w-3.5 h-3.5 bg-white rounded-full shadow-sm transition-transform absolute top-1/2 -translate-y-1/2 left-[3px] ${!showCompleted ? 'translate-x-4' : 'translate-x-0'}`}
                                />
                            </button>
                            <label className="text-xs text-muted-foreground cursor-pointer select-none whitespace-nowrap" htmlFor="hide-done">
                                Hide completed tasks
                            </label>
                        </div>
                    </div>
                );
            })()}

            {/* Items List with Drag and Drop */}
            <DndContext
                sensors={sensors}
                collisionDetection={closestCenter}
                onDragStart={handleDragStart}
                onDragEnd={handleDragEnd}
            >
                <div className="flex-1 overflow-auto pb-20">
                    {flatItems.length === 0 ? (
                        <div className="flex flex-col items-center justify-center h-full px-6">
                            <p className="text-sm text-muted-foreground mb-6">No items yet</p>
                        </div>
                    ) : (
                        <div className="py-2">
                            <SortableContext
                                items={flatItems.map((item) => item.id)}
                                strategy={verticalListSortingStrategy}
                            >
                                {flatItems.map((flatItem) => (
                                    <SortableItemWrapper
                                        key={flatItem.id}
                                        flatItem={flatItem}
                                        listId={activeListId}
                                    />
                                ))}
                            </SortableContext>
                        </div>
                    )}
                </div>

                {createPortal(
                    <DragOverlay dropAnimation={dropAnimationConfig}>
                        {activeItem ? (
                            <div className="bg-background border rounded-md shadow-lg">
                                <Item
                                    item={activeItem.item}
                                    listId={activeListId}
                                    depth={activeItem.depth}
                                />
                            </div>
                        ) : null}
                    </DragOverlay>,
                    document.body
                )}
            </DndContext>

            {/* Fixed Bottom Button */}
            <div className="fixed bottom-0 left-0 right-0 p-4 bg-background border-t">
                <Button
                    onClick={handleCreateItem}
                    variant="ghost"
                    className="w-full shadow-none"
                    style={{ color: '#737373' }}
                    onMouseEnter={(e) => (e.currentTarget.style.color = '#000000')}
                    onMouseLeave={(e) => (e.currentTarget.style.color = '#737373')}
                >
                    <Plus className="w-4 h-4 mr-2" />
                    New task
                </Button>
            </div>
        </div>
    );
}
