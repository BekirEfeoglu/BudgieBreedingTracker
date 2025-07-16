import React from 'react';
import { MainLayout } from '@/layouts/MainLayout';

const Index = () => {
  return (
    <MainLayout>
      <div className="min-h-screen bg-background p-4">
        <div className="max-w-4xl mx-auto space-y-6">
          {/* Header */}
          <div className="text-center space-y-4">
            <h1 className="text-3xl font-bold text-primary">
              🐦 BudgieBreedingTracker
            </h1>
            <p className="text-muted-foreground">
              Muhabbet kuşu üretim takip uygulaması
            </p>
          </div>

          {/* Quick Stats */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-card border rounded-lg p-6 text-center">
              <h3 className="text-2xl font-bold text-primary">0</h3>
              <p className="text-sm text-muted-foreground">Toplam Kuş</p>
            </div>
            <div className="bg-card border rounded-lg p-6 text-center">
              <h3 className="text-2xl font-bold text-green-600">0</h3>
              <p className="text-sm text-muted-foreground">Aktif Üreme</p>
            </div>
            <div className="bg-card border rounded-lg p-6 text-center">
              <h3 className="text-2xl font-bold text-blue-600">0</h3>
              <p className="text-sm text-muted-foreground">Toplam Yumurta</p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <button className="bg-primary text-primary-foreground p-4 rounded-lg hover:bg-primary/90 transition-colors">
              <div className="text-center">
                <div className="text-2xl mb-2">🐦</div>
                <h3 className="font-semibold">Yeni Kuş Ekle</h3>
                <p className="text-sm opacity-90">Muhabbet kuşu kaydet</p>
              </div>
            </button>
            
            <button className="bg-green-600 text-white p-4 rounded-lg hover:bg-green-700 transition-colors">
              <div className="text-center">
                <div className="text-2xl mb-2">💕</div>
                <h3 className="font-semibold">Üreme Başlat</h3>
                <p className="text-sm opacity-90">Yeni çiftleşme kaydet</p>
              </div>
            </button>
          </div>

          {/* Recent Activity */}
          <div className="bg-card border rounded-lg p-6">
            <h3 className="text-lg font-semibold mb-4">Son Aktiviteler</h3>
            <div className="text-center text-muted-foreground py-8">
              <div className="text-4xl mb-2">📝</div>
              <p>Henüz aktivite bulunmuyor</p>
              <p className="text-sm">Kuş ekleyerek başlayın</p>
            </div>
          </div>

          {/* Success Message */}
          <div className="bg-green-50 border border-green-200 rounded-lg p-4 text-center">
            <div className="text-green-600">
              <div className="text-2xl mb-2">✅</div>
              <h3 className="font-semibold">Uygulama Başarıyla Yüklendi!</h3>
              <p className="text-sm">Mobil cihazınızda düzgün çalışıyor.</p>
            </div>
          </div>
        </div>
      </div>
    </MainLayout>
  );
};

export default Index;
