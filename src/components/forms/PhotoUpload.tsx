import SecurePhotoUpload from './SecurePhotoUpload';

interface PhotoUploadProps {
  selectedPhoto: string | null;
  onPhotoSelect: (photo: string) => void;
}

const PhotoUpload = ({ selectedPhoto, onPhotoSelect }: PhotoUploadProps) => {
  // Use secure upload component
  return <SecurePhotoUpload selectedPhoto={selectedPhoto} onPhotoSelect={onPhotoSelect} />;
};

export default PhotoUpload;
