import { MainView } from '@/components/MainView';
import { useNookStore } from '@/store';
import { useEffect } from 'react';

function App() {
  const { createList, setActiveList, createItem } = useNookStore();

  // Create welcome list with sample tasks on first load
  // Initialize app on mount
  useEffect(() => {
    // Check state directly to avoid reactive dependencies
    const state = useNookStore.getState();
    const hasLists = state.lists.length > 0;
    const hasActiveList = !!state.activeListId;

    if (!hasLists) {
      // Create the welcome list
      createList('Welcome to your nook');

      // Get the newly created list ID
      const newState = useNookStore.getState();
      const newListId = newState.lists[0]?.id;

      if (newListId) {
        // Create sample tasks
        const sampleTasks = [
          'Create your first list',
          'Add your first task to it',
          'Add tags to your tasks',
          'Organize your tasks to your likings',
          'Pour yourself some coffee',
        ];

        sampleTasks.forEach((taskText) => {
          createItem(newListId, taskText, 'task');
        });

        setActiveList(newListId);
      }
    } else if (!hasActiveList) {
      // Restore selection to first list if nothing selected
      setActiveList(state.lists[0].id);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []); // Run once on mount

  return (
    <div className="h-screen w-full bg-background">
      <MainView />
    </div>
  );
}

export default App;
