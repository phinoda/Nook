import { useNookStore } from '@/store';
import type { Item as ItemType } from '@/types';
import { Trash2, GripVertical } from 'lucide-react';
import { useState, useRef, useEffect } from 'react';

interface ItemProps {
    item: ItemType;
    listId: string;
    previousItemId?: string;
    depth?: number;
    dragHandleProps?: {
        ref: (element: HTMLElement | null) => void;
        [key: string]: unknown;
    };
}

export function Item({ item, listId, previousItemId, depth = 0, dragHandleProps }: ItemProps) {
    const { toggleItemDone, deleteItem, updateItem, indentItem, unindentItem, createItemAfter } = useNookStore();
    const [isEditing, setIsEditing] = useState(false);
    const [editText, setEditText] = useState(item.text);
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    const adjustTextareaHeight = (element: HTMLTextAreaElement) => {
        element.style.height = 'auto';
        element.style.height = `${element.scrollHeight}px`;
    };

    // Sync editText with item.text when item changes
    // Sync editText with item.text when item changes (derived state)
    const [prevText, setPrevText] = useState(item.text);
    if (item.text !== prevText) {
        setPrevText(item.text);
        setEditText(item.text);
    }

    const handleToggle = (e: React.MouseEvent) => {
        e.stopPropagation();
        toggleItemDone(listId, item.id);
    };

    const handleDelete = (e: React.MouseEvent) => {
        e.stopPropagation();
        deleteItem(listId, item.id);
    };

    const handleItemClick = () => {
        setIsEditing(true);
    };

    const handleSave = () => {
        const trimmedText = editText.trim();
        if (trimmedText !== item.text) {
            updateItem(listId, item.id, { text: trimmedText });
        }
        setIsEditing(false);
    };

    const handleBlur = () => {
        handleSave();
    };

    const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault(); // Prevent new line
            handleSave();
            createItemAfter(listId, item.id);
        } else if (e.key === 'Backspace' && editText === '') {
            e.preventDefault();
            deleteItem(listId, item.id);
        } else if (e.key === 'Escape') {
            setEditText(item.text);
            setIsEditing(false);
        } else if (e.key === 'Tab') {
            e.preventDefault();
            if (e.shiftKey) {
                // Shift+Tab: Unindent
                unindentItem(listId, item.id);
            } else if (previousItemId) {
                // Tab: Indent (only if there's a previous sibling)
                indentItem(listId, item.id, previousItemId);
            }
        }
    };

    // Focus input when entering edit mode
    useEffect(() => {
        if (isEditing && textareaRef.current) {
            textareaRef.current.focus();
            adjustTextareaHeight(textareaRef.current);
            // Move cursor to end of text
            const length = textareaRef.current.value.length;
            textareaRef.current.setSelectionRange(length, length);
        }
    }, [isEditing]);

    // Auto-enter edit mode for new/empty items
    useEffect(() => {
        if (!item.text && !isEditing) {
            setIsEditing(true);
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    // Auto-enter edit mode for new/empty items
    useEffect(() => {
        if (!item.text && !isEditing) {
            setIsEditing(true);
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    // Handle Tab key when not editing
    const handleItemKeyDown = (e: React.KeyboardEvent<HTMLDivElement>) => {
        if (e.key === 'Tab' && !isEditing) {
            e.preventDefault();
            if (e.shiftKey) {
                // Shift+Tab: Unindent
                unindentItem(listId, item.id);
            } else if (previousItemId) {
                // Tab: Indent (only if there's a previous sibling)
                indentItem(listId, item.id, previousItemId);
            }
        }
    };

    return (
        <>
            <div
                className={`group flex items-start gap-3 py-2.5 hover:bg-accent/50 transition-colors ${item.isDone ? 'opacity-60' : ''}`}
                style={{ paddingLeft: `${24 + depth * 24}px`, paddingRight: '24px' }}
                onKeyDown={handleItemKeyDown}
                tabIndex={0}
            >
                {/* Drag Handle (visible on hover) */}
                <div
                    {...(dragHandleProps || {})}
                    className="opacity-0 group-hover:opacity-100 flex-shrink-0 cursor-grab active:cursor-grabbing p-0.5 rounded hover:bg-muted transition-opacity"
                    aria-label="Drag item"
                >
                    <GripVertical className="w-4 h-4 text-muted-foreground/50" />
                </div>

                {/* Checkbox */}
                <div className="flex-shrink-0">
                    <div
                        onClick={handleToggle}
                        className={`mt-0.5 w-4 h-4 rounded border-2 transition-colors flex items-center justify-center cursor-pointer ${item.isDone
                            ? 'bg-primary border-primary'
                            : 'border-muted-foreground/30 group-hover:border-muted-foreground/50'
                            }`}
                    >
                        {item.isDone && (
                            <svg
                                className="w-3 h-3 text-primary-foreground"
                                fill="none"
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth="2"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                            >
                                <polyline points="20 6 9 17 4 12" />
                            </svg>
                        )}
                    </div>
                </div>

                {/* Item text or input */}
                <div className="flex-1 min-w-0" onClick={handleItemClick}>
                    {isEditing ? (
                        <textarea
                            ref={textareaRef}
                            value={editText}
                            onChange={(e) => {
                                setEditText(e.target.value);
                                adjustTextareaHeight(e.target);
                            }}
                            onBlur={handleBlur}
                            onKeyDown={handleKeyDown}
                            rows={1}
                            className="w-full text-sm leading-6 bg-transparent border-none outline-none focus:ring-0 p-0 m-0 resize-none overflow-hidden font-inherit block"
                            style={{ height: 'auto', minHeight: '24px' }}
                        />
                    ) : (
                        <p className={`text-sm leading-6 cursor-text m-0 whitespace-pre-wrap min-h-[24px] block ${item.isDone ? 'line-through text-muted-foreground' : ''}`}>
                            {item.text || <span className="text-muted-foreground italic">Untitled</span>}
                        </p>
                    )}
                </div>

                {/* Delete button (fixed width container to prevent layout shift) */}
                <div className="flex-shrink-0 w-6 h-6 flex items-center justify-center">
                    <button
                        onClick={handleDelete}
                        className="opacity-0 group-hover:opacity-100 transition-opacity p-1 rounded hover:bg-muted"
                        aria-label="Delete item"
                    >
                        <Trash2 className="w-4 h-4 text-muted-foreground" />
                    </button>
                </div>
            </div>
        </>
    );
}

