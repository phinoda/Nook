import { useNookStore } from '@/store';
import type { Item as ItemType } from '@/types';
import { Trash2 } from 'lucide-react';
import { useState, useRef, useEffect } from 'react';

interface ItemProps {
    item: ItemType;
    listId: string;
    previousItemId?: string;
    depth?: number;
}

export function Item({ item, listId, previousItemId, depth = 0 }: ItemProps) {
    const { toggleItemDone, deleteItem, updateItem, indentItem, unindentItem } = useNookStore();
    const [isEditing, setIsEditing] = useState(false);
    const [editText, setEditText] = useState(item.text);
    const inputRef = useRef<HTMLInputElement>(null);

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
        if (editText.trim() !== item.text) {
            updateItem(listId, item.id, { text: editText.trim() });
        }
        setIsEditing(false);
    };

    const handleBlur = () => {
        handleSave();
    };

    const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Enter') {
            handleSave();
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
        if (isEditing && inputRef.current) {
            inputRef.current.focus();
            // Move cursor to end of text
            const length = inputRef.current.value.length;
            inputRef.current.setSelectionRange(length, length);
        }
    }, [isEditing]);

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
                className="group flex items-start gap-3 py-2.5 hover:bg-accent/50 transition-colors"
                style={{ paddingLeft: `${24 + depth * 24}px`, paddingRight: '24px' }}
                onKeyDown={handleItemKeyDown}
                tabIndex={0}
            >
                {/* Checkbox */}
                <div
                    onClick={handleToggle}
                    className={`mt-0.5 w-4 h-4 rounded border-2 transition-colors flex-shrink-0 flex items-center justify-center cursor-pointer ${
                        item.isDone
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

                {/* Item text or input */}
                <div className="flex-1 min-w-0" onClick={handleItemClick}>
                    {isEditing ? (
                        <input
                            ref={inputRef}
                            type="text"
                            value={editText}
                            onChange={(e) => setEditText(e.target.value)}
                            onBlur={handleBlur}
                            onKeyDown={handleKeyDown}
                            className="w-full text-sm leading-relaxed bg-transparent border-none outline-none focus:ring-0 p-0"
                        />
                    ) : (
                        <p className={`text-sm leading-relaxed cursor-text ${item.isDone ? 'line-through text-muted-foreground' : ''}`}>
                            {item.text || <span className="text-muted-foreground italic">Untitled</span>}
                        </p>
                    )}
                </div>

                {/* Delete button (visible on hover) */}
                <button
                    onClick={handleDelete}
                    className="opacity-0 group-hover:opacity-100 transition-opacity p-1 rounded"
                    aria-label="Delete item"
                >
                    <Trash2 className="w-4 h-4" style={{ color: '#737373' }} />
                </button>
            </div>

            {/* Render children recursively */}
            {item.children && item.children.length > 0 && (
                <>
                    {item.children.map((child, index) => (
                        <Item
                            key={child.id}
                            item={child}
                            listId={listId}
                            previousItemId={index > 0 ? item.children[index - 1].id : undefined}
                            depth={depth + 1}
                        />
                    ))}
                </>
            )}
        </>
    );
}

