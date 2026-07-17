window.bbtPrivacyExtraTranslations = Object.freeze({
  tr: Object.freeze({
    skip: 'İçeriğe geç',
    home_aria: 'BudgieBreedingTracker — ana sayfa',
    version_aria: 'Uygulama sürümü',
    contact_email: 'E-posta:',
    contact_web: 'Web:',
    supplemental_sections: `
<section class="policy-section section-reveal" aria-labelledby="community-data">
  <h2 class="section-h2" id="community-data">Topluluk Verileri</h2>
  <p class="section-intro">Topluluk özelliklerini kullandığınızda aşağıdaki veriler işlenir:</p>
  <ul class="policy-list">
    <li><strong>Profil bilgileri:</strong> Kullanıcı adı, avatar, biyografi ve herkese açık görünürlük tercihleri.</li>
    <li><strong>Paylaşımlar:</strong> Gönderi içerikleri (metin, görsel), yorumlar, beğeniler ve bildirim etkileşimleri.</li>
    <li><strong>Takip ilişkileri:</strong> Takipçi ve takip edilen listeleri.</li>
    <li><strong>Moderasyon verileri:</strong> Raporlanan içerik geçmişi ve yalnız yetkili personelin erişebildiği moderasyon notları.</li>
  </ul>
  <p class="section-text" style="margin-top: 14px;">Paylaşımlarınızı hesap ayarlarınızdan silebilirsiniz. Profilinizi kapattığınızda paylaşımlarınız da kaldırılır.</p>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="marketplace-data">
  <h2 class="section-h2" id="marketplace-data">Marketplace Verileri</h2>
  <p class="section-intro">Marketplace özelliğini kullandığınızda aşağıdaki veriler işlenir:</p>
  <ul class="policy-list">
    <li><strong>İlan bilgileri:</strong> Kuş türü, fiyat, açıklama, şehir düzeyinde konum ve fotoğraflar.</li>
    <li><strong>Satıcı/alıcı etkileşimleri:</strong> İlgilenilen ilanlar ve başlatılan konuşmalar.</li>
    <li><strong>Değerlendirmeler:</strong> Herkese açık satıcı derecelendirmeleri ve yorumları.</li>
  </ul>
  <p class="section-text" style="margin-top: 14px;">Uygulama Marketplace işlemleri için ödeme veya kişisel iletişim bilgisi toplamaz; taraflar kendi aralarında anlaşır. İlanınızı istediğiniz zaman kaldırabilirsiniz.</p>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="messaging-data">
  <h2 class="section-h2" id="messaging-data">Mesajlaşma Verileri</h2>
  <p class="section-intro">Özel mesajlaşma özelliğini kullandığınızda:</p>
  <ul class="policy-list">
    <li><strong>Mesaj içerikleri:</strong> Sunucuda konuşma katılımcılarına görünür şekilde saklanır. Mesajlaşma uçtan uca şifrelenmez; aktarım TLS ile korunur.</li>
    <li><strong>Moderasyon:</strong> Kötüye kullanım raporları incelendiğinde yetkili personel raporlanan mesajları görebilir.</li>
    <li><strong>Silme:</strong> Kendi mesajlarınızı silebilirsiniz; konuşmanın tutulması katılımcıların işlemlerine bağlıdır.</li>
  </ul>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="local-ai-data">
  <h2 class="section-h2" id="local-ai-data">Yerel AI Analizi</h2>
  <p class="section-intro">Genetik tahmin AI'ı kuş fotoğrafınızı analiz ederken:</p>
  <ul class="policy-list">
    <li><strong>Ollama (yerel model):</strong> Fotoğraf yalnızca yapılandırdığınız yerel ağdaki Ollama uç noktasına gönderilir; BudgieBreedingTracker bulutuna aktarılmaz.</li>
    <li><strong>OpenRouter (isteğe bağlı):</strong> Açıkça seçildiğinde fotoğraf HTTPS ile OpenRouter API'sine gönderilir; sağlayıcı tarafındaki işleme ve saklama koşulları OpenRouter politikalarına tabidir.</li>
    <li><strong>Saklama ve boyut:</strong> Analiz sonuçları cihazınızda ve/veya hesap senkronizasyonunda saklanır; taranan görseller için 2 MiB ham dosya sınırı uygulanır.</li>
  </ul>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="grace-period">
  <h2 class="section-h2" id="grace-period">Premium Erteleme (Grace Period)</h2>
  <p class="section-intro">Premium aboneliğiniz sona erdiğinde veya yenileme başarısız olduğunda:</p>
  <ul class="policy-list">
    <li>3 günlük erteleme penceresi boyunca premium özelliklere erişim devam eder.</li>
    <li>Süre dolduğunda hesabınız ücretsiz plana döner; verileriniz silinmez, ücretsiz plan sınırları uygulanır.</li>
    <li>Erteleme durumu cihaz önbelleğinde tutulur ve sunucuda RevenueCat yetkileriyle doğrulanır.</li>
  </ul>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="compliance">
  <h2 class="section-h2" id="compliance">Yasal Uyum (KVKK &amp; GDPR)</h2>
  <p class="section-text">BudgieBreedingTracker, Türkiye'de KVKK ve Avrupa Birliği'nde GDPR kapsamındaki yükümlülükleri gözetir. Haklarınız:</p>
  <ul class="policy-list">
    <li>Verilerinize erişme, düzeltme, silme ve taşıma hakkı.</li>
    <li>İşlemeye itiraz hakkı (GDPR Madde 21).</li>
    <li>Otomatik karar verme ve profil çıkarma hakkında bilgilendirilme hakkı.</li>
  </ul>
  <p class="section-text" style="margin-top: 14px;">Taleplerinizi <a href="mailto:privacy@budgiebreedingtracker.online" class="contact-link">privacy@budgiebreedingtracker.online</a> adresine iletebilirsiniz. Veri Sorumlusu: Bekir Efeoğlu.</p>
</section>`,
  }),
  en: Object.freeze({
    skip: 'Skip to content',
    home_aria: 'BudgieBreedingTracker — home page',
    version_aria: 'App version',
    contact_email: 'Email:',
    contact_web: 'Web:',
    supplemental_sections: `
<section class="policy-section section-reveal" aria-labelledby="community-data">
  <h2 class="section-h2" id="community-data">Community Data</h2>
  <p class="section-intro">The following data is processed when you use community features:</p>
  <ul class="policy-list">
    <li><strong>Profile information:</strong> Username, avatar, bio, and public visibility preferences.</li>
    <li><strong>Posts:</strong> Post content (text and images), comments, likes, and notification interactions.</li>
    <li><strong>Following relationships:</strong> Follower and following lists.</li>
    <li><strong>Moderation data:</strong> Reported-content history and moderation notes accessible only to authorized personnel.</li>
  </ul>
  <p class="section-text" style="margin-top: 14px;">You can delete your posts from account settings. Your posts are also removed when you close your profile.</p>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="marketplace-data">
  <h2 class="section-h2" id="marketplace-data">Marketplace Data</h2>
  <p class="section-intro">The following data is processed when you use Marketplace:</p>
  <ul class="policy-list">
    <li><strong>Listing information:</strong> Bird species, price, description, city-level location, and photos.</li>
    <li><strong>Seller/buyer interactions:</strong> Listings of interest and conversations initiated.</li>
    <li><strong>Reviews:</strong> Public seller ratings and reviews.</li>
  </ul>
  <p class="section-text" style="margin-top: 14px;">The app does not collect payment or personal contact information for Marketplace transactions; the parties make their own arrangements. You can remove your listing at any time.</p>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="messaging-data">
  <h2 class="section-h2" id="messaging-data">Messaging Data</h2>
  <p class="section-intro">When you use private messaging:</p>
  <ul class="policy-list">
    <li><strong>Message content:</strong> Stored on the server and visible to conversation participants. Messages are not end-to-end encrypted; transport is protected with TLS.</li>
    <li><strong>Moderation:</strong> Authorized personnel may view reported messages when reviewing abuse reports.</li>
    <li><strong>Deletion:</strong> You can delete your own messages; conversation retention depends on participant actions.</li>
  </ul>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="local-ai-data">
  <h2 class="section-h2" id="local-ai-data">Local AI Analysis</h2>
  <p class="section-intro">When genetics-prediction AI analyzes your bird photo:</p>
  <ul class="policy-list">
    <li><strong>Ollama (local model):</strong> The photo is sent only to the Ollama endpoint you configure on your local network; it is not sent to the BudgieBreedingTracker cloud.</li>
    <li><strong>OpenRouter (optional):</strong> When explicitly selected, the photo is sent to the OpenRouter API over HTTPS; provider-side processing and retention are governed by OpenRouter policies.</li>
    <li><strong>Storage and size:</strong> Analysis results are stored on your device and/or in account sync; scanned images have a 2 MiB raw-file limit.</li>
  </ul>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="grace-period">
  <h2 class="section-h2" id="grace-period">Premium Grace Period</h2>
  <p class="section-intro">When your Premium subscription expires or renewal fails:</p>
  <ul class="policy-list">
    <li>Premium access continues during a 3-day grace window.</li>
    <li>When the window ends, your account returns to the free plan; your data is retained and free-plan limits apply.</li>
    <li>Grace status is cached on your device and verified on the server against RevenueCat entitlements.</li>
  </ul>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="compliance">
  <h2 class="section-h2" id="compliance">Legal Compliance (KVKK &amp; GDPR)</h2>
  <p class="section-text">BudgieBreedingTracker observes applicable obligations under Türkiye's KVKK and the European Union's GDPR. Your rights include:</p>
  <ul class="policy-list">
    <li>The right to access, rectify, delete, and port your data.</li>
    <li>The right to object to processing (GDPR Article 21).</li>
    <li>The right to information about automated decision-making and profiling.</li>
  </ul>
  <p class="section-text" style="margin-top: 14px;">Send requests to <a href="mailto:privacy@budgiebreedingtracker.online" class="contact-link">privacy@budgiebreedingtracker.online</a>. Data Controller: Bekir Efeoğlu.</p>
</section>`,
  }),
  de: Object.freeze({
    skip: 'Zum Inhalt springen',
    home_aria: 'BudgieBreedingTracker — Startseite',
    version_aria: 'App-Version',
    contact_email: 'E-Mail:',
    contact_web: 'Web:',
    supplemental_sections: `
<section class="policy-section section-reveal" aria-labelledby="community-data">
  <h2 class="section-h2" id="community-data">Community-Daten</h2>
  <p class="section-intro">Bei der Nutzung der Community-Funktionen werden folgende Daten verarbeitet:</p>
  <ul class="policy-list">
    <li><strong>Profilinformationen:</strong> Benutzername, Avatar, Biografie und öffentliche Sichtbarkeitseinstellungen.</li>
    <li><strong>Beiträge:</strong> Beitragsinhalte (Text und Bilder), Kommentare, Likes und Benachrichtigungsinteraktionen.</li>
    <li><strong>Folgebeziehungen:</strong> Listen der Follower und gefolgten Konten.</li>
    <li><strong>Moderationsdaten:</strong> Verlauf gemeldeter Inhalte und Moderationsnotizen, auf die nur autorisiertes Personal zugreifen kann.</li>
  </ul>
  <p class="section-text" style="margin-top: 14px;">Sie können Ihre Beiträge in den Kontoeinstellungen löschen. Beim Schließen Ihres Profils werden auch Ihre Beiträge entfernt.</p>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="marketplace-data">
  <h2 class="section-h2" id="marketplace-data">Marketplace-Daten</h2>
  <p class="section-intro">Bei der Nutzung von Marketplace werden folgende Daten verarbeitet:</p>
  <ul class="policy-list">
    <li><strong>Angebotsinformationen:</strong> Vogelart, Preis, Beschreibung, Standort auf Stadtebene und Fotos.</li>
    <li><strong>Interaktionen zwischen Verkäufern und Käufern:</strong> Interessante Angebote und begonnene Unterhaltungen.</li>
    <li><strong>Bewertungen:</strong> Öffentliche Verkäuferbewertungen und Rezensionen.</li>
  </ul>
  <p class="section-text" style="margin-top: 14px;">Die App erhebt für Marketplace-Transaktionen keine Zahlungs- oder persönlichen Kontaktdaten; die Parteien treffen eigene Vereinbarungen. Sie können Ihr Angebot jederzeit entfernen.</p>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="messaging-data">
  <h2 class="section-h2" id="messaging-data">Nachrichtendaten</h2>
  <p class="section-intro">Wenn Sie private Nachrichten verwenden:</p>
  <ul class="policy-list">
    <li><strong>Nachrichteninhalt:</strong> Wird auf dem Server gespeichert und ist für die Gesprächsteilnehmer sichtbar. Nachrichten sind nicht Ende-zu-Ende verschlüsselt; die Übertragung ist durch TLS geschützt.</li>
    <li><strong>Moderation:</strong> Autorisiertes Personal kann gemeldete Nachrichten bei der Prüfung von Missbrauchsmeldungen einsehen.</li>
    <li><strong>Löschung:</strong> Sie können eigene Nachrichten löschen; die Aufbewahrung der Unterhaltung hängt von den Aktionen der Teilnehmer ab.</li>
  </ul>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="local-ai-data">
  <h2 class="section-h2" id="local-ai-data">Lokale KI-Analyse</h2>
  <p class="section-intro">Wenn die KI zur Genetikvorhersage Ihr Vogelfoto analysiert:</p>
  <ul class="policy-list">
    <li><strong>Ollama (lokales Modell):</strong> Das Foto wird nur an den von Ihnen konfigurierten Ollama-Endpunkt im lokalen Netzwerk gesendet, nicht an die BudgieBreedingTracker-Cloud.</li>
    <li><strong>OpenRouter (optional):</strong> Bei ausdrücklicher Auswahl wird das Foto per HTTPS an die OpenRouter-API gesendet; Verarbeitung und Aufbewahrung beim Anbieter richten sich nach den OpenRouter-Richtlinien.</li>
    <li><strong>Speicherung und Größe:</strong> Analyseergebnisse werden auf Ihrem Gerät und/oder in der Kontosynchronisierung gespeichert; für gescannte Bilder gilt eine Rohdateigrenze von 2 MiB.</li>
  </ul>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="grace-period">
  <h2 class="section-h2" id="grace-period">Premium-Nachfrist</h2>
  <p class="section-intro">Wenn Ihr Premium-Abonnement endet oder die Verlängerung fehlschlägt:</p>
  <ul class="policy-list">
    <li>Der Premium-Zugriff bleibt während einer dreitägigen Nachfrist bestehen.</li>
    <li>Danach wechselt Ihr Konto zum kostenlosen Tarif; Ihre Daten bleiben erhalten und die Limits des kostenlosen Tarifs gelten.</li>
    <li>Der Nachfriststatus wird auf Ihrem Gerät zwischengespeichert und serverseitig anhand der RevenueCat-Berechtigungen geprüft.</li>
  </ul>
</section>
<hr class="section-divider">
<section class="policy-section section-reveal" aria-labelledby="compliance">
  <h2 class="section-h2" id="compliance">Rechtliche Konformität (KVKK &amp; DSGVO)</h2>
  <p class="section-text">BudgieBreedingTracker berücksichtigt die anwendbaren Pflichten nach dem türkischen KVKK und der europäischen DSGVO. Ihre Rechte umfassen:</p>
  <ul class="policy-list">
    <li>Das Recht auf Auskunft, Berichtigung, Löschung und Übertragbarkeit Ihrer Daten.</li>
    <li>Das Recht, der Verarbeitung zu widersprechen (Art. 21 DSGVO).</li>
    <li>Das Recht auf Informationen über automatisierte Entscheidungen und Profiling.</li>
  </ul>
  <p class="section-text" style="margin-top: 14px;">Senden Sie Anfragen an <a href="mailto:privacy@budgiebreedingtracker.online" class="contact-link">privacy@budgiebreedingtracker.online</a>. Verantwortlicher: Bekir Efeoğlu.</p>
</section>`,
  }),
});
