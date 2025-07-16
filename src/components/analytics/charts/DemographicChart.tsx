import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';
import { useLanguage } from '@/contexts/LanguageContext';

interface DemographicChartProps {
  birds: Array<{ gender?: string; status?: string; birthDate?: string }>;
}

const COLORS = ['#3b82f6', '#ec4899', '#6b7280', '#f59e42', '#10b981'];

const DemographicChart: React.FC<DemographicChartProps> = ({ birds }) => {
  const { t } = useLanguage();

  // Güvenli veri kontrolü
  const safeBirds = Array.isArray(birds) ? birds : [];

  // Cinsiyet dağılımı
  const genderData = [
    { name: t('analytics.male'), value: safeBirds.filter(b => b.gender === 'male').length },
    { name: t('analytics.female'), value: safeBirds.filter(b => b.gender === 'female').length },
    { name: t('analytics.unknown'), value: safeBirds.filter(b => !b.gender || b.gender === 'unknown').length },
  ].filter(d => d.value > 0);

  // Durum dağılımı
  const statusData = [
    { name: t('analytics.alive'), value: safeBirds.filter(b => b.status === 'alive' || !b.status).length },
    { name: t('analytics.dead'), value: safeBirds.filter(b => b.status === 'dead').length },
    { name: t('analytics.sold'), value: safeBirds.filter(b => b.status === 'sold').length },
  ].filter(d => d.value > 0);

  // Yaş dağılımı (0-1, 1-2, 2-3, 3+ yıl)
  const today = new Date();
  const ageBuckets = [0, 1, 2, 3];
  const ageData = ageBuckets.map((start, i) => {
    const end = ageBuckets[i + 1] || 100;
    const count = safeBirds.filter(b => {
      if (!b.birthDate) return false;
      try {
        const birthDate = new Date(b.birthDate);
        if (isNaN(birthDate.getTime())) return false;
        const age = (today.getTime() - birthDate.getTime()) / (1000 * 60 * 60 * 24 * 365.25);
        return age >= start && age < end;
      } catch (error) {
        console.error('Error calculating age for bird:', b, error);
        return false;
      }
    }).length;
    return { name: end === 100 ? `3+ ${t('analytics.years')}` : `${start}-${end} ${t('analytics.years')}`, value: count };
  }).filter(d => d.value > 0);

  // Veri yoksa mesaj göster
  if (safeBirds.length === 0) {
    return (
      <Card className="enhanced-card">
        <CardHeader>
          <CardTitle>{t('analytics.demographics')}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-gray-500">
            <p>Henüz kuş verisi bulunmuyor.</p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="enhanced-card">
      <CardHeader>
        <CardTitle>{t('analytics.demographics')}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Cinsiyet Dağılımı */}
          <div>
            <div className="font-semibold mb-2">{t('analytics.genderDistribution')}</div>
            {genderData.length > 0 ? (
              <ResponsiveContainer width="100%" height={180}>
                <PieChart>
                  <Pie data={genderData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={60} label>
                    {genderData.map((entry, idx) => (
                      <Cell key={`gender-${idx}`} fill={COLORS[idx % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-center py-8 text-gray-500">
                <p>Cinsiyet verisi bulunmuyor</p>
              </div>
            )}
          </div>
          {/* Durum Dağılımı */}
          <div>
            <div className="font-semibold mb-2">{t('analytics.statusDistribution')}</div>
            {statusData.length > 0 ? (
              <ResponsiveContainer width="100%" height={180}>
                <PieChart>
                  <Pie data={statusData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={60} label>
                    {statusData.map((entry, idx) => (
                      <Cell key={`status-${idx}`} fill={COLORS[idx % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-center py-8 text-gray-500">
                <p>Durum verisi bulunmuyor</p>
              </div>
            )}
          </div>
          {/* Yaş Dağılımı */}
          <div>
            <div className="font-semibold mb-2">{t('analytics.ageDistribution')}</div>
            {ageData.length > 0 ? (
              <ResponsiveContainer width="100%" height={180}>
                <BarChart data={ageData}>
                  <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                  <YAxis allowDecimals={false} />
                  <Tooltip />
                  <Bar dataKey="value" fill="#3b82f6" />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-center py-8 text-gray-500">
                <p>Yaş verisi bulunmuyor</p>
              </div>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default DemographicChart; 