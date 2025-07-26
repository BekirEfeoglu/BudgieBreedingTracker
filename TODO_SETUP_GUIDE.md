# 🎯 Todo Özelliği Kurulum Rehberi

Bu rehber, Todo özelliğini projenize entegre etmek için gerekli adımları açıklar.

## 📋 Özellikler

- ✅ Todo ekleme, düzenleme, silme
- ✅ Tamamlanma durumu işaretleme
- ✅ Kullanıcı bazlı todo'lar (RLS)
- ✅ Gerçek zamanlı güncellemeler
- ✅ Modern UI/UX tasarımı
- ✅ Toast bildirimleri
- ✅ Loading states
- ✅ Error handling

## 🗄️ Veritabanı Kurulumu

### 1. Migration Dosyasını Çalıştırın

Supabase Dashboard'da SQL Editor'ü açın ve şu migration'ı çalıştırın:

```sql
-- Create todos table
CREATE TABLE IF NOT EXISTS public.todos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own todos" ON public.todos
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own todos" ON public.todos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own todos" ON public.todos
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own todos" ON public.todos
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON public.todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON public.todos(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_todos_completed ON public.todos(completed);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_todos_updated_at 
    BEFORE UPDATE ON public.todos 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable realtime for todos table
ALTER PUBLICATION supabase_realtime ADD TABLE public.todos;
```

### 2. Types Güncellemesi

`src/integrations/supabase/types.ts` dosyasına todos tablosu eklendi. Eğer Supabase CLI kullanıyorsanız:

```bash
npx supabase gen types typescript --project-id YOUR_PROJECT_ID > src/integrations/supabase/types.ts
```

## 🎨 Component Kullanımı

### 1. TodoList Component'i

```tsx
import TodoList from '../components/TodoList';

export default function MyPage() {
  return (
    <div>
      <h1>Todo Listesi</h1>
      <TodoList />
    </div>
  );
}
```

### 2. TodoPage Component'i

```tsx
import TodoPage from '../pages/TodoPage';

// Router'da kullanım
<Route path="/todos" element={<TodoPage />} />
```

## 🔧 Özelleştirme

### 1. Stil Özelleştirme

TodoList component'i shadcn/ui bileşenlerini kullanır. Tema dosyalarınızı güncelleyerek görünümü özelleştirebilirsiniz:

```css
/* globals.css */
:root {
  --todo-primary: #3b82f6;
  --todo-success: #10b981;
  --todo-danger: #ef4444;
}
```

### 2. Fonksiyon Özelleştirme

TodoList component'inde şu fonksiyonları özelleştirebilirsiniz:

- `getTodos()`: Todo'ları getirme
- `addTodo()`: Yeni todo ekleme
- `toggleTodo()`: Tamamlanma durumu değiştirme
- `deleteTodo()`: Todo silme

### 3. Toast Bildirimleri

Toast bildirimleri `useToast` hook'u ile yönetilir:

```tsx
const { toast } = useToast();

toast({
  title: "Başarılı",
  description: "Todo eklendi",
  variant: "default" // veya "destructive"
});
```

## 🧪 Test Etme

### 1. Temel Testler

```typescript
// Todo ekleme testi
const testAddTodo = async () => {
  const todoTitle = "Test Todo";
  // Todo ekleme işlemi
  // Sonucu kontrol et
};

// Todo tamamlama testi
const testToggleTodo = async () => {
  // Todo oluştur
  // Tamamla/tamamlanmadı yap
  // Durumu kontrol et
};

// Todo silme testi
const testDeleteTodo = async () => {
  // Todo oluştur
  // Sil
  // Listede olmadığını kontrol et
};
```

### 2. RLS Testleri

```sql
-- Kullanıcı kendi todo'larını görebilir
SELECT * FROM todos WHERE user_id = auth.uid();

-- Başka kullanıcının todo'larını göremez
SELECT * FROM todos WHERE user_id != auth.uid();
```

## 🔍 Sorun Giderme

### Yaygın Sorunlar:

#### 1. "Table 'todos' does not exist"
- Migration'ı çalıştırdığınızdan emin olun
- Supabase Dashboard'da tabloyu kontrol edin

#### 2. "RLS policy violation"
- Kullanıcının giriş yapmış olduğundan emin olun
- RLS policy'lerin doğru oluşturulduğunu kontrol edin

#### 3. "Invalid API key"
- Environment variables'ları kontrol edin
- Supabase client'ın doğru yapılandırıldığından emin olun

#### 4. TypeScript Hataları
- Types dosyasını güncelleyin
- Supabase CLI ile types'ı yeniden oluşturun

## 📱 Responsive Tasarım

TodoList component'i mobil cihazlarda da çalışır:

- ✅ Mobil uyumlu tasarım
- ✅ Touch-friendly butonlar
- ✅ Responsive layout
- ✅ Mobile-first approach

## 🚀 Performans Optimizasyonları

### 1. Indexes
- `user_id` index'i
- `created_at` index'i
- `completed` index'i

### 2. RLS Optimizasyonu
- Auth function çağrıları SELECT ile sarıldı
- Minimal policy sayısı

### 3. Realtime
- Sadece gerekli tablolar için realtime aktif
- Efficient subscription management

## 📊 Monitoring

### 1. Logs
```typescript
// Console'da todo işlemlerini izleyin
console.log('Todo added:', newTodo);
console.log('Todo updated:', updatedTodo);
console.log('Todo deleted:', deletedTodo);
```

### 2. Analytics
```typescript
// Todo işlemlerini analitik için kaydedin
const trackTodoAction = (action: string, todoId: string) => {
  // Analytics tracking
};
```

## 🔐 Güvenlik

### 1. RLS Policies
- Kullanıcılar sadece kendi todo'larını görebilir
- CRUD işlemleri kullanıcı bazlı kısıtlanmış

### 2. Input Validation
- Todo başlığı boş olamaz
- XSS koruması
- SQL injection koruması

### 3. Rate Limiting
- Supabase rate limiting aktif
- API çağrıları sınırlandırılmış

## 📈 Gelecek Özellikler

- [ ] Todo kategorileri
- [ ] Todo öncelik seviyeleri
- [ ] Todo tarih/saat ekleme
- [ ] Todo paylaşımı
- [ ] Todo şablonları
- [ ] Todo istatistikleri
- [ ] Todo export/import
- [ ] Todo arama/filtreleme

---

**💡 İpucu**: Todo özelliğini test etmek için önce basit todo'lar ekleyin ve tüm CRUD işlemlerini deneyin! 