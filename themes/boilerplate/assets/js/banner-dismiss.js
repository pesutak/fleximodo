/**
 * Banner dismiss functionality
 * Adds event listeners to banner dismiss buttons to hide banners when clicked
 */
document.addEventListener('DOMContentLoaded', function() {
  // Find all banner dismiss buttons
  const dismissButtons = document.querySelectorAll('[data-dismiss-banner]');
  
  // Add click event listener to each button
  dismissButtons.forEach(button => {
    button.addEventListener('click', function() {
      // Find the parent banner element
      const banner = this.closest('[data-banner]');
      if (banner) {
        // Hide the banner
        banner.style.display = 'none';
        
        // If the banner has an ID, store its state in localStorage
        if (banner.id) {
          localStorage.setItem(`banner-${banner.id}-dismissed`, 'true');
        }
      }
    });
  });
  
  // Check for previously dismissed banners
  const banners = document.querySelectorAll('[data-banner]');
  banners.forEach(banner => {
    if (banner.id && localStorage.getItem(`banner-${banner.id}-dismissed`) === 'true') {
      banner.style.display = 'none';
    }
  });
});
