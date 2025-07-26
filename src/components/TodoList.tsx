import React, { useState, useEffect } from 'react';
import { supabase } from '../integrations/supabase/client';
import { Tables } from '../integrations/supabase/types';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Checkbox } from './ui/checkbox';
import { Trash2, Plus, Loader2 } from 'lucide-react';
import { useToast } from '../hooks/use-toast';

type Todo = Tables<'todos'>;

export default function TodoList() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newTodoTitle, setNewTodoTitle] = useState('');
  const [addingTodo, setAddingTodo] = useState(false);
  const { toast } = useToast();

  useEffect(() => {
    getTodos();
  }, []);

  const getTodos = async () => {
    try {
      setLoading(true);
      setError(null);

      const { data: todos, error } = await supabase
        .from('todos')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error fetching todos:', error.message);
        setError(error.message);
        toast({
          title: "Hata",
          description: "Todo listesi yüklenirken bir hata oluştu: " + error.message,
          variant: "destructive"
        });
        return;
      }

      if (todos && todos.length > 0) {
        setTodos(todos);
      } else {
        setTodos([]);
      }
    } catch (error) {
      console.error('Error fetching todos:', error);
      setError('Beklenmeyen bir hata oluştu');
      toast({
        title: "Hata",
        description: "Todo listesi yüklenirken beklenmeyen bir hata oluştu",
        variant: "destructive"
      });
    } finally {
      setLoading(false);
    }
  };

  const addTodo = async () => {
    if (!newTodoTitle.trim()) {
      toast({
        title: "Uyarı",
        description: "Todo başlığı boş olamaz",
        variant: "destructive"
      });
      return;
    }

    try {
      setAddingTodo(true);
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        toast({
          title: "Hata",
          description: "Kullanıcı oturumu bulunamadı",
          variant: "destructive"
        });
        return;
      }

      const { data, error } = await supabase
        .from('todos')
        .insert([
          { 
            title: newTodoTitle.trim(), 
            completed: false,
            user_id: user.id 
          }
        ])
        .select();

      if (error) {
        console.error('Error adding todo:', error.message);
        toast({
          title: "Hata",
          description: "Todo eklenirken bir hata oluştu: " + error.message,
          variant: "destructive"
        });
        return;
      }

      if (data && data.length > 0) {
        const newTodo = data[0] as Todo;
        setTodos(prevTodos => [newTodo, ...prevTodos]);
        setNewTodoTitle('');
        toast({
          title: "Başarılı",
          description: "Todo başarıyla eklendi"
        });
      }
    } catch (error) {
      console.error('Error adding todo:', error);
      toast({
        title: "Hata",
        description: "Todo eklenirken beklenmeyen bir hata oluştu",
        variant: "destructive"
      });
    } finally {
      setAddingTodo(false);
    }
  };

  const toggleTodo = async (id: string, completed: boolean) => {
    try {
      const { error } = await supabase
        .from('todos')
        .update({ completed: !completed })
        .eq('id', id);

      if (error) {
        console.error('Error updating todo:', error.message);
        toast({
          title: "Hata",
          description: "Todo güncellenirken bir hata oluştu: " + error.message,
          variant: "destructive"
        });
        return;
      }

      setTodos(prevTodos =>
        prevTodos.map(todo =>
          todo.id === id ? { ...todo, completed: !completed } : todo
        )
      );

      toast({
        title: "Başarılı",
        description: completed ? "Todo tamamlanmadı olarak işaretlendi" : "Todo tamamlandı olarak işaretlendi"
      });
    } catch (error) {
      console.error('Error updating todo:', error);
      toast({
        title: "Hata",
        description: "Todo güncellenirken beklenmeyen bir hata oluştu",
        variant: "destructive"
      });
    }
  };

  const deleteTodo = async (id: string) => {
    try {
      const { error } = await supabase
        .from('todos')
        .delete()
        .eq('id', id);

      if (error) {
        console.error('Error deleting todo:', error.message);
        toast({
          title: "Hata",
          description: "Todo silinirken bir hata oluştu: " + error.message,
          variant: "destructive"
        });
        return;
      }

      setTodos(prevTodos => prevTodos.filter(todo => todo.id !== id));
      toast({
        title: "Başarılı",
        description: "Todo başarıyla silindi"
      });
    } catch (error) {
      console.error('Error deleting todo:', error);
      toast({
        title: "Hata",
        description: "Todo silinirken beklenmeyen bir hata oluştu",
        variant: "destructive"
      });
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      addTodo();
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4" />
          <p className="text-muted-foreground">Todo listesi yükleniyor...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <p className="text-destructive mb-4">Hata: {error}</p>
          <Button onClick={getTodos} variant="outline">
            Tekrar Dene
          </Button>
        </div>
      </div>
    );
  }

  return (
    <Card className="w-full max-w-2xl mx-auto">
      <CardHeader>
        <CardTitle className="text-2xl font-bold text-center">Todo Listesi</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Add Todo Form */}
        <div className="flex gap-2">
          <Input
            placeholder="Yeni todo ekle..."
            value={newTodoTitle}
            onChange={(e) => setNewTodoTitle(e.target.value)}
            onKeyPress={handleKeyPress}
            disabled={addingTodo}
            className="flex-1"
          />
          <Button 
            onClick={addTodo} 
            disabled={addingTodo || !newTodoTitle.trim()}
            size="sm"
          >
            {addingTodo ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Plus className="h-4 w-4" />
            )}
          </Button>
        </div>

        {/* Todo List */}
        {todos.length === 0 ? (
          <div className="text-center py-8">
            <p className="text-muted-foreground mb-4">Henüz todo yok</p>
            <Button 
              onClick={() => setNewTodoTitle('İlk Todo')} 
              variant="outline"
              size="sm"
            >
              İlk Todo'yu Ekle
            </Button>
          </div>
        ) : (
          <div className="space-y-2">
            {todos.map((todo) => (
              <div
                key={todo.id}
                className="flex items-center gap-3 p-3 border rounded-lg hover:bg-muted/50 transition-colors"
              >
                <Checkbox
                  checked={todo.completed}
                  onCheckedChange={() => toggleTodo(todo.id, todo.completed)}
                  className="flex-shrink-0"
                />
                <span 
                  className={`flex-1 ${
                    todo.completed 
                      ? 'line-through text-muted-foreground' 
                      : 'text-foreground'
                  }`}
                >
                  {todo.title}
                </span>
                <Button
                  onClick={() => deleteTodo(todo.id)}
                  variant="ghost"
                  size="sm"
                  className="text-destructive hover:text-destructive hover:bg-destructive/10"
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            ))}
          </div>
        )}

        {/* Stats */}
        {todos.length > 0 && (
          <div className="text-center text-sm text-muted-foreground pt-4 border-t">
            {todos.filter(t => t.completed).length} / {todos.length} tamamlandı
          </div>
        )}
      </CardContent>
    </Card>
  );
} 