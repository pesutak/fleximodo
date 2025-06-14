/**
 * Cookie Consent Functionality
 * Handles user preferences for cookies and manages Google Analytics tracking
 */

// Wait for the window to fully load, not just DOM content
window.addEventListener('load', function() {
  // Cookie utility functions
  const CookieUtils = {
    setCookie: function(name, value, days) {
      const date = new Date();
      date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
      const expires = "expires=" + date.toUTCString();
      document.cookie = name + "=" + value + ";" + expires + ";path=/";
    },
    
    getCookie: function(name) {
      const nameEQ = name + "=";
      const ca = document.cookie.split(';');
      for(let i = 0; i < ca.length; i++) {
        let c = ca[i];
        while (c.charAt(0) === ' ') c = c.substring(1);
        if (c.indexOf(nameEQ) === 0) return c.substring(nameEQ.length, c.length);
      }
      return null;
    },
    
    deleteCookie: function(name) {
      document.cookie = name + "=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/";
    }
  };
  
  // Cookie Consent Manager
  const CookieConsent = {
    consentBanner: document.getElementById('cookie-consent-banner'),
    settingsModal: document.getElementById('cookie-settings-modal'),
    analyticsCheckbox: document.getElementById('analytics-cookies'),
    
    init: function() {
      // Double check if the element exists
      if (!this.consentBanner) {
        this.consentBanner = document.querySelector('[data-cookie-consent-banner]');
      }
      
      // Check if consent has already been given or rejected
      const consentStatus = CookieUtils.getCookie('cookie_consent_status');
      
      if (!consentStatus) {
        // Show the consent banner if no consent decision has been made yet
        if (this.consentBanner) {
          // Force the banner to be visible
          this.consentBanner.style.display = 'block';
          this.consentBanner.style.visibility = 'visible';
          this.consentBanner.style.opacity = '1';
        }
      } else {
        // Hide the banner if consent has already been given or rejected
        if (this.consentBanner) {
          this.hideBanner();
        }
        
        // Apply the saved consent if it exists
        const allowAnalytics = consentStatus === 'all';
        this.applyConsent(allowAnalytics);
      }
      
      this.setupEventListeners();
    },
    
    setupEventListeners: function() {
      // Accept all cookies
      const acceptAllButtons = document.querySelectorAll('[data-cookie-consent="accept-all"]');
      acceptAllButtons.forEach(button => {
        button.addEventListener('click', () => {
          this.setConsent('all');
          this.hideBanner();
        });
      });
      
      // Accept necessary cookies only
      const acceptNecessaryButtons = document.querySelectorAll('[data-cookie-consent="accept-necessary"]');
      acceptNecessaryButtons.forEach(button => {
        button.addEventListener('click', () => {
          this.setConsent('necessary');
          this.hideBanner();
        });
      });
      
      // Open settings modal
      const settingsButtons = document.querySelectorAll('[data-cookie-consent="settings"]');
      settingsButtons.forEach(button => {
        button.addEventListener('click', () => {
          this.showSettingsModal();
        });
      });
      
      // Close settings modal
      const closeModalButtons = document.querySelectorAll('[data-cookie-settings-close]');
      closeModalButtons.forEach(button => {
        button.addEventListener('click', () => {
          this.hideSettingsModal();
        });
      });
      
      // Save settings
      const saveSettingsButtons = document.querySelectorAll('[data-cookie-settings-save]');
      saveSettingsButtons.forEach(button => {
        button.addEventListener('click', () => {
          const allowAnalytics = this.analyticsCheckbox && this.analyticsCheckbox.checked;
          this.setConsent(allowAnalytics ? 'all' : 'necessary');
          this.hideSettingsModal();
          this.hideBanner();
        });
      });
    },
    
    setConsent: function(level) {
      // Save the consent status in a cookie
      CookieUtils.setCookie('cookie_consent_status', level, 365);
      // Apply the consent settings
      const allowAnalytics = level === 'all';
      this.applyConsent(allowAnalytics);
    },
    
    applyConsent: function(allowAnalytics) {
      // Use the global function from google-analytics-consent.html if available
      if (typeof window.updateGoogleAnalyticsConsent === 'function') {
        window.updateGoogleAnalyticsConsent(allowAnalytics);
      } 
      // Fallback to direct gtag calls if the global function isn't available
      else if (typeof window.gtag === 'function') {
        window.gtag('consent', 'update', {
          'analytics_storage': allowAnalytics ? 'granted' : 'denied',
          'ad_storage': allowAnalytics ? 'granted' : 'denied',
          'ad_user_data': allowAnalytics ? 'granted' : 'denied',
          'ad_personalization': allowAnalytics ? 'granted' : 'denied'
        });
        
        // Update Google Analytics tracking status
        this.updateGoogleAnalyticsTracking(allowAnalytics);
      }
    },
    
    updateGoogleAnalyticsTracking: function(enabled) {
      // This function can be used to enable/disable Google Analytics tracking
      if (typeof window.gtag === 'function') {
        if (enabled) {
          // Enable tracking by setting consent parameters
          window.gtag('set', 'url_passthrough', true);
          window.gtag('set', 'ads_data_redaction', false);
        } else {
          // Disable tracking
          window.gtag('set', 'url_passthrough', false);
          window.gtag('set', 'ads_data_redaction', true);
        }
      }
    },
    
    hideBanner: function() {
      if (this.consentBanner) {
        this.consentBanner.style.display = 'none';
        this.consentBanner.style.visibility = 'hidden';
        this.consentBanner.style.opacity = '0';
      }
    },
    
    showSettingsModal: function() {
      if (this.settingsModal) {
        this.settingsModal.style.display = 'block';
        this.settingsModal.classList.remove('hidden');
      }
    },
    
    hideSettingsModal: function() {
      if (this.settingsModal) {
        this.settingsModal.style.display = 'none';
        this.settingsModal.classList.add('hidden');
      }
    }
  };
  
  // Initialize the cookie consent functionality
  CookieConsent.init();
});
