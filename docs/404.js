    const translations = {
      tr: {
        title: 'Sayfa Bulunamadı',
        desc: 'Hay aksi! Bu sayfa uçup gitmiş gibi görünüyor. Sizi doğru yere yönlendirelim.',
        button: 'Ana Sayfaya Git',
        quick_title: 'Popüler Sayfalar',
        link_support: 'Destek',
        link_privacy: 'Gizlilik Politikası',
        link_terms: 'Kullanım Koşulları',
        link_community: 'Topluluk Kuralları',
      },
      en: {
        title: 'Page Not Found',
        desc: "Oops! This page seems to have flown away. Let's get you back on track.",
        button: 'Go to Homepage',
        quick_title: 'Popular Pages',
        link_support: 'Support',
        link_privacy: 'Privacy Policy',
        link_terms: 'Terms of Use',
        link_community: 'Community Guidelines',
      },
      de: {
        title: 'Seite nicht gefunden',
        desc: 'Hoppla! Diese Seite scheint davongeflogen zu sein. Lassen Sie uns Sie zurückbringen.',
        button: 'Zur Startseite',
        quick_title: 'Beliebte Seiten',
        link_support: 'Support',
        link_privacy: 'Datenschutzrichtlinie',
        link_terms: 'Nutzungsbedingungen',
        link_community: 'Community-Richtlinien',
      }
    };

    function setLanguage(lang) {
      localStorage.setItem('bbt-lang', lang);
      document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (translations[lang] && translations[lang][key]) {
          el.textContent = translations[lang][key];
        }
      });
      document.querySelectorAll('.lang-btn').forEach(btn => btn.classList.remove('active'));
      const activeBtn = document.getElementById('lang' + lang.charAt(0).toUpperCase() + lang.slice(1));
      if (activeBtn) activeBtn.classList.add('active');
    }

    // Auto-detect language from localStorage or browser preference
    const savedLang = localStorage.getItem('bbt-lang') ||
      (navigator.language.startsWith('de') ? 'de' : navigator.language.startsWith('en') ? 'en' : 'tr');
    setLanguage(savedLang);

    // Cursor glow tracking
    if (window.matchMedia('(pointer: fine)').matches) {
      const g = document.getElementById('cursorGlow');
      document.addEventListener('mousemove', (e) => {
        g.style.left = e.clientX + 'px';
        g.style.top = e.clientY + 'px';
      }, { passive: true });
    }

// ─── CSP-safe event delegation ───
document.addEventListener('click', function (e) {
  var el = e.target.closest('[data-action]');
  if (!el) return;
  if (el.dataset.action === 'setLanguage' && typeof setLanguage === 'function') {
    setLanguage(el.dataset.lang);
  }
});
