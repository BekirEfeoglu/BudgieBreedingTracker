import React from 'react';
import TodoList from '../components/TodoList';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';

export default function TodoPage() {
  return (
    <div className="container mx-auto py-8 px-4">
      <div className="max-w-4xl mx-auto">
        <Card className="mb-6">
          <CardHeader>
            <CardTitle className="text-3xl font-bold text-center">
              🎯 Todo Yönetimi
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-center text-muted-foreground">
              Günlük görevlerinizi takip edin ve organize edin
            </p>
          </CardContent>
        </Card>
        
        <TodoList />
      </div>
    </div>
  );
} 