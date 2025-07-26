// Edge Function Test Scripti
const testEdgeFunction = async () => {
  const supabaseUrl = "https://etkvuonkmmzihsjwbcrl.supabase.co";
  
  const testData = {
    feedbackData: {
      type: 'test',
      title: 'Edge Function Test',
      description: 'Bu bir test mesajıdır',
      userEmail: 'test@example.com',
      userName: 'Test Kullanıcı'
    }
  };

  try {
    console.log('🔄 Edge Function test ediliyor...');
    console.log('🔍 URL:', `${supabaseUrl}/functions/v1/send-email`);
    
    const response = await fetch(`${supabaseUrl}/functions/v1/send-email`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(testData),
    });

    console.log('📊 Response Status:', response.status);
    console.log('📊 Response Headers:', Object.fromEntries(response.headers.entries()));

    if (response.ok) {
      const result = await response.json();
      console.log('✅ Başarılı!');
      console.log('📄 Response:', result);
    } else {
      const errorText = await response.text();
      console.log('❌ Hata!');
      console.log('📄 Error Response:', errorText);
    }
  } catch (error) {
    console.log('❌ Network Hatası:', error.message);
  }
};

// Test'i çalıştır
testEdgeFunction(); 