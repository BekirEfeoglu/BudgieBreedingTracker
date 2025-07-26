import React, { memo } from 'react';
import { Bird } from '@/types';

interface BirdPhotoProps {
  bird: Bird;
}

const BirdPhoto = memo(({ bird }: BirdPhotoProps) => {
  return (
    <div className="flex justify-center" role="img" aria-label={`${bird.name} fotoğrafı`}>
      <div className="w-32 h-32 rounded-full bg-gradient-to-br from-budgie-green to-budgie-yellow flex items-center justify-center text-4xl shadow-lg">
        {bird.photo ? (
          <img 
            src={bird.photo} 
            alt={bird.name}
            className="w-full h-full rounded-full object-cover"
            loading="lazy"
          />
        ) : (
          <span aria-hidden="true">🦜</span>
        )}
      </div>
    </div>
  );
});

BirdPhoto.displayName = 'BirdPhoto';

export default BirdPhoto;
