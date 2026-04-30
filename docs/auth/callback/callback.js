(function () {
  'use strict';

  var DEEP_LINK_SCHEME = 'io.supabase.budgiebreeding://login-callback/';

  var hash = window.location.hash.substring(1);
  var params = new URLSearchParams(hash);
  var accessToken = params.get('access_token');

  if (hash && window.history && window.history.replaceState) {
    window.history.replaceState(
      null,
      document.title,
      window.location.pathname + window.location.search
    );
  }

  var queryParams = new URLSearchParams(window.location.search);
  var errorParam = queryParams.get('error');
  var errorDescription = queryParams.get('error_description');

  if (errorParam) {
    document.getElementById('loading').classList.add('hidden');
    document.getElementById('error').classList.remove('hidden');
    document.getElementById('error-msg').textContent =
      errorDescription || 'Verification failed. Please try again.';
    return;
  }

  if (accessToken) {
    var deepLink = DEEP_LINK_SCHEME + '#' + hash;
    document.getElementById('loading').classList.add('hidden');
    document.getElementById('success').classList.remove('hidden');
    document.getElementById('deeplink-btn').href = deepLink;

    setTimeout(function () {
      window.location.href = deepLink;
    }, 1500);

    setTimeout(function () {
      document.getElementById('auto-redirect-msg').textContent =
        "If the app didn't open, tap the button above.";
    }, 3000);
  } else {
    setTimeout(function () {
      document.getElementById('loading').classList.add('hidden');
      document.getElementById('success').classList.remove('hidden');
      document.getElementById('deeplink-btn').href = DEEP_LINK_SCHEME;
      document.getElementById('auto-redirect-msg').textContent =
        'Tap the button to open the app.';
    }, 1500);
  }
})();
