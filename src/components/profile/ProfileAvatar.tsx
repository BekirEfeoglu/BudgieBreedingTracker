
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { User, Camera } from 'lucide-react';

interface ProfileAvatarProps {
  avatarUrl?: string;
  initials: string;
  displayName: string;
}

const ProfileAvatar = ({ avatarUrl, initials, displayName }: ProfileAvatarProps) => {
  return (
    <div className="flex flex-col items-center space-y-4">
      <div className="relative">
        <Avatar className="w-20 h-20">
          <AvatarImage src={avatarUrl || ''} />
          <AvatarFallback className="text-xl font-bold bg-primary text-primary-foreground">
            {initials || <User className="h-8 w-8" />}
          </AvatarFallback>
        </Avatar>
        <Button
          size="sm"
          className="absolute -bottom-2 -right-2 rounded-full w-8 h-8 p-0"
          variant="secondary"
        >
          <Camera className="w-4 h-4" />
        </Button>
      </div>
      <div className="text-center">
        <h3 className="text-lg font-semibold">{displayName}</h3>
        <p className="text-sm text-muted-foreground">
          Muhabbet kuşu sevdalısı
        </p>
      </div>
    </div>
  );
};

export default ProfileAvatar;
