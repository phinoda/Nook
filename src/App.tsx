import { MainView } from '@/components/MainView';
import { useNookStore } from '@/store';
import { useEffect, useRef } from 'react';

function App() {
  const { lists, createList, setActiveList, createItem } = useNookStore();
  const initialized = useRef(false);

  // Create welcome list with sample tasks on first load
  useEffect(() => {
    // Prevent double initialization in React Strict Mode
    if (initialized.current) return;

    if (lists.length === 0) {
      initialized.current = true;

      // Create the welcome list
      createList('Welcome to your nook');

      // Get the newly created list ID
      const newListId = useNookStore.getState().lists[0]?.id;

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
    } else if (!useNookStore.getState().activeListId) {
      setActiveList(lists[0].id);
    }
  }, [lists, createList, setActiveList, createItem]);

  return (
    <div className="h-screen w-full bg-background">
      <MainView />
    </div>
  );
}

export default App;
