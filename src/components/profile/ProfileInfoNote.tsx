
import { Card, CardContent } from '@/components/ui/card';

const ProfileInfoNote = () => {
  return (
    <Card className="budgie-card">
      <CardContent className="pt-6">
        <div className="text-center text-muted-foreground">
          <p className="text-sm">
            Diğer ayarlar için <strong>Ayarlar</strong> sekmesini ziyaret edin.
          </p>
        </div>
      </CardContent>
    </Card>
  );
};

export default ProfileInfoNote;
