import React, { memo, useMemo } from 'react';
import { useLanguage } from '@/contexts/LanguageContext';
import { useAuth } from '@/hooks/useAuth';
import ComponentErrorBoundary from '@/components/errors/ComponentErrorBoundary';

const WelcomeHeader: React.FC = () => {
  const { t } = useLanguage();
  const { profile } = useAuth();

  // Memoized welcome message with time-based greeting
  const welcomeMessage = useMemo(() => {
    const firstName = profile?.first_name;
    const lastName = profile?.last_name;
    
    // Get current hour to determine time of day
    const currentHour = new Date().getHours();
    
    // Determine greeting based on time
    let timeGreeting = '';
    if (currentHour >= 5 && currentHour < 12) {
      timeGreeting = t('home.goodMorning');
    } else if (currentHour >= 12 && currentHour < 17) {
      timeGreeting = t('home.goodAfternoon');
    } else if (currentHour >= 17 && currentHour < 22) {
      timeGreeting = t('home.goodEvening');
    } else {
      timeGreeting = t('home.goodNight');
    }
    
    // Combine greeting with name
    if (firstName && lastName) {
      return `${timeGreeting}, ${firstName} ${lastName}`;
    } else if (firstName) {
      return `${timeGreeting}, ${firstName}`;
    } else {
      return timeGreeting;
    }
  }, [profile?.first_name, profile?.last_name, t]);

  return (
    <ComponentErrorBoundary>
      <div className="text-center space-y-4 w-full max-w-lg mx-auto px-2" role="banner" aria-label="Hoş geldiniz başlığı">
        {/* Professional Logo Design */}
        <div className="flex flex-col items-center justify-center space-y-3 pt-4 mb-4">
          {/* Logo Container */}
          <div className="relative mb-2" style={{width: 120, height: 120}}>
            <svg viewBox="0 0 120 120" width="120" height="120" xmlns="http://www.w3.org/2000/svg">
              {/* Outer Circle (Nest) */}
              <circle cx="60" cy="60" r="56" fill="#FEF3C7" stroke="#3B82F6" strokeWidth="3" />
              {/* Nest Pattern */}
              <g opacity="0.18">
                <circle cx="40" cy="50" r="2" fill="#8B5C2B" />
                <circle cx="80" cy="60" r="1.5" fill="#8B5C2B" />
                <circle cx="60" cy="80" r="2" fill="#8B5C2B" />
                <circle cx="70" cy="40" r="1.5" fill="#8B5C2B" />
                <circle cx="50" cy="70" r="1.5" fill="#8B5C2B" />
              </g>
              {/* Budgie Bird */}
              <g transform="translate(60,68)">
                {/* Animated Eggs Behind Budgie */}
                <ellipse className="budgie-egg budgie-egg-1" cx="-16" cy="18" rx="7" ry="10" fill="#fffbe9" stroke="#e0c48c" strokeWidth="1.5" />
                <ellipse className="budgie-egg budgie-egg-2" cx="0" cy="24" rx="8" ry="11" fill="#fffbe9" stroke="#e0c48c" strokeWidth="1.5" />
                <ellipse className="budgie-egg budgie-egg-3" cx="16" cy="18" rx="7" ry="10" fill="#fffbe9" stroke="#e0c48c" strokeWidth="1.5" />
                {/* Body */}
                <ellipse cx="0" cy="2" rx="18" ry="22" fill="#34D399" stroke="#059669" strokeWidth="2" />
                {/* Head */}
                <circle cx="0" cy="-16" r="13" fill="#34D399" stroke="#059669" strokeWidth="2" />
                {/* Eye */}
                <circle cx="4" cy="-19" r="3.5" fill="#1F2937" />
                <circle cx="4.5" cy="-19.5" r="1.2" fill="white" />
                {/* Beak */}
                <polygon points="13,-13 4,-13 8.5,-7" fill="#F59E0B" stroke="#D97706" strokeWidth="1.2" />
                {/* Wing */}
                <g className="budgie-wing-animation">
                  <ellipse cx="-14" cy="2" rx="10" ry="14" fill="#10B981" stroke="#059669" strokeWidth="1.2" />
                </g>
                {/* Tail */}
                <rect x="-3" y="22" width="6" height="18" rx="3" fill="#2563EB" stroke="#1D4ED8" strokeWidth="1.2" />
                {/* Feet */}
                <line x1="-4" y1="28" x2="-4" y2="36" stroke="#8B4513" strokeWidth="2" />
                <line x1="4" y1="28" x2="4" y2="36" stroke="#8B4513" strokeWidth="2" />
                {/* Cheek Patch */}
                <circle cx="-8" cy="-10" r="4" fill="#FBBF24" />
                <circle cx="8" cy="-10" r="4" fill="#FBBF24" />
                {/* Crown */}
                <ellipse cx="0" cy="-28" rx="7" ry="3" fill="#FBBF24" />
              </g>
            </svg>
          </div>

          {/* App Title and Tagline */}
          <div className="space-y-3 text-center">
            {/* Professional Title with Enhanced Typography */}
            <div className="relative">
              <h1 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-extrabold bg-gradient-to-r from-blue-500 via-purple-500 to-teal-400 bg-clip-text text-transparent leading-tight tracking-tight relative z-10 animate-budgie-title drop-shadow-[0_2px_8px_rgba(80,0,180,0.18)]">
                BudgieBreedingTracker
              </h1>
              {/* Title Shadow Effect */}
              <h1 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-extrabold text-gray-400/60 absolute inset-0 leading-tight tracking-tight -z-10 transform scale-105">
                BudgieBreedingTracker
              </h1>
            </div>
            
            {/* Professional Subtitle */}
            <p className="text-sm sm:text-base text-gray-600 dark:text-gray-400 font-medium max-w-md mx-auto">
              Profesyonel Muhabbet Kuşu Üretim Yönetim Sistemi
            </p>
            
            {/* Professional Feature Badges */}
            <div className="flex flex-wrap items-center justify-center gap-2 sm:gap-3 text-xs sm:text-sm">
              <div className="flex items-center space-x-1.5 px-3 py-1.5 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-950/30 dark:to-indigo-950/30 rounded-full border border-blue-200/50 dark:border-blue-800/50 shadow-sm">
                <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                <span className="font-semibold text-blue-700 dark:text-blue-300">{t('home.professional')}</span>
              </div>
              <div className="flex items-center space-x-1.5 px-3 py-1.5 bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-950/30 dark:to-emerald-950/30 rounded-full border border-green-200/50 dark:border-green-800/50 shadow-sm">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                <span className="font-semibold text-green-700 dark:text-green-300">{t('home.breeding')}</span>
              </div>
              <div className="flex items-center space-x-1.5 px-3 py-1.5 bg-gradient-to-r from-purple-50 to-violet-50 dark:from-purple-950/30 dark:to-violet-950/30 rounded-full border border-purple-200/50 dark:border-purple-800/50 shadow-sm">
                <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
                <span className="font-semibold text-purple-700 dark:text-purple-300">{t('home.tracking')}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Welcome Message */}
        <div className="pt-4">
          <div className="relative">
            <p className="text-muted-foreground text-sm sm:text-base font-medium leading-relaxed bg-gradient-to-r from-gray-600 to-gray-800 dark:from-gray-300 dark:to-gray-100 bg-clip-text text-transparent px-4 py-2 rounded-lg bg-gradient-to-r from-gray-50/50 to-gray-100/50 dark:from-gray-800/30 dark:to-gray-900/30 border border-gray-200/50 dark:border-gray-700/50">
              {welcomeMessage}
            </p>
            {/* Decorative accent */}
            <div className="absolute -top-1 left-1/2 transform -translate-x-1/2 w-8 h-1 bg-gradient-to-r from-blue-400 to-purple-400 rounded-full opacity-60"></div>
          </div>
        </div>
      </div>
      
      {/* Professional Animations CSS */}
      <style>{`
        @keyframes budgie-wing-flap {
          0%, 100% { transform: rotate(-15deg) scaleY(1); }
          50% { transform: rotate(25deg) scaleY(0.8); }
        }
        
        @keyframes budgie-breathe {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.05); }
        }
        
        @keyframes budgie-particle-float {
          0% { 
            transform: translateY(0) translateX(0) rotate(0deg);
            opacity: 0;
          }
          10% { opacity: 1; }
          90% { opacity: 1; }
          100% { 
            transform: translateY(-20px) translateX(10px) rotate(360deg);
            opacity: 0;
          }
        }
        
        @keyframes budgie-particle-float-2 {
          0% { 
            transform: translateY(0) translateX(0) rotate(0deg);
            opacity: 0;
          }
          20% { opacity: 1; }
          80% { opacity: 1; }
          100% { 
            transform: translateY(-15px) translateX(-8px) rotate(-360deg);
            opacity: 0;
          }
        }
        
        @keyframes budgie-particle-float-3 {
          0% { 
            transform: translateY(0) translateX(0) rotate(0deg);
            opacity: 0;
          }
          15% { opacity: 1; }
          85% { opacity: 1; }
          100% { 
            transform: translateY(-25px) translateX(5px) rotate(180deg);
            opacity: 0;
          }
        }
        
        @keyframes budgie-particle-float-4 {
          0% { 
            transform: translateY(0) translateX(0) rotate(0deg);
            opacity: 0;
          }
          25% { opacity: 1; }
          75% { opacity: 1; }
          100% { 
            transform: translateY(-18px) translateX(-12px) rotate(-180deg);
            opacity: 0;
          }
        }
        
        .budgie-wing-animation {
          transform-origin: -8px 2px;
          animation: budgie-wing-flap 2s ease-in-out infinite;
        }
        
        .budgie-bird {
          animation: budgie-breathe 3s ease-in-out infinite;
        }
        
        .budgie-particle {
          position: absolute;
          width: 4px;
          height: 4px;
          background: linear-gradient(45deg, #3B82F6, #8B5CF6);
          border-radius: 50%;
          pointer-events: none;
        }
        
        .budgie-particle-1 {
          top: 20%;
          left: 30%;
          animation: budgie-particle-float 4s ease-in-out infinite;
          animation-delay: 0s;
        }
        
        .budgie-particle-2 {
          top: 60%;
          right: 25%;
          animation: budgie-particle-float-2 5s ease-in-out infinite;
          animation-delay: 1s;
        }
        
        .budgie-particle-3 {
          bottom: 30%;
          left: 40%;
          animation: budgie-particle-float-3 4.5s ease-in-out infinite;
          animation-delay: 2s;
        }
        
        .budgie-particle-4 {
          top: 40%;
          right: 40%;
          animation: budgie-particle-float-4 5.5s ease-in-out infinite;
          animation-delay: 3s;
        }
        
        /* Hover effects */
        .group:hover .budgie-wing-animation {
          animation-duration: 1.5s;
        }
        
        .group:hover .budgie-bird {
          animation-duration: 2s;
        }
        
        .group:hover .budgie-particle {
          animation-duration: 3s;
        }

        @keyframes budgie-title-glow {
          0%,100% { filter: drop-shadow(0 2px 8px #8b5cf6aa) brightness(1.1); }
          50% { filter: drop-shadow(0 4px 16px #06b6d4cc) brightness(1.3); }
        }
        @keyframes budgie-title-gradient {
          0% { background-position: 0% 50%; }
          100% { background-position: 100% 50%; }
        }
        .animate-budgie-title {
          animation: budgie-title-glow 2.5s ease-in-out infinite, budgie-title-gradient 4s linear infinite;
          background-size: 200% 200%;
        }
        /* Yumurtalar aşağıya kayarken en altta aniden kaybolur: */
        @keyframes budgie-egg-slide1 { 0%{transform:translateY(0);opacity:1;} 99%{transform:translateY(24px);opacity:1;} 100%{transform:translateY(0);opacity:0;} }
        @keyframes budgie-egg-slide2 { 0%{transform:translateY(-8px);opacity:1;} 99%{transform:translateY(20px);opacity:1;} 100%{transform:translateY(-8px);opacity:0;} }
        @keyframes budgie-egg-slide3 { 0%{transform:translateY(-4px);opacity:1;} 99%{transform:translateY(28px);opacity:1;} 100%{transform:translateY(-4px);opacity:0;} }
        .budgie-egg-1{animation:budgie-egg-slide1 2.2s linear infinite;}
        .budgie-egg-2{animation:budgie-egg-slide2 2.7s linear infinite;}
        .budgie-egg-3{animation:budgie-egg-slide3 2.4s linear infinite;}
      `}</style>
    </ComponentErrorBoundary>
  );
};

WelcomeHeader.displayName = 'WelcomeHeader';

export default memo(WelcomeHeader);