import { Button } from '@/components/ui/button';
import { Item } from '@/components/Item';
import { useNookStore } from '@/store';
import { Plus } from 'lucide-react';

export function MainView() {
    const { lists, activeListId, createItem } = useNookStore();

    const activeList = lists.find((list) => list.id === activeListId);

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
                <h2 className="text-2xl font-bold tracking-tight">{activeList.name}</h2>
            </div>

            {/* Items List */}
            <div className="flex-1 overflow-auto pb-20">
                {activeList.items.length === 0 ? (
                    <div className="flex flex-col items-center justify-center h-full px-6">
                        <p className="text-sm text-muted-foreground mb-6">No items yet</p>
                    </div>
                ) : (
                    <div className="py-2">
                        {activeList.items.map((item, index) => (
                            <Item 
                                key={item.id} 
                                item={item} 
                                listId={activeList.id}
                                previousItemId={index > 0 ? activeList.items[index - 1].id : undefined}
                            />
                        ))}
                    </div>
                )}
            </div>

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

