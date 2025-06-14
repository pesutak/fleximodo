// Lazy Video Loading Implementation
(function() {
  'use strict';

  let videoObserver;
  let initialized = false;

  function initLazyVideos() {
    if (initialized) return;
    initialized = true;

    const videos = document.querySelectorAll('video.lazy-video-element[data-lazy-video-src]');
    
    if (videos.length === 0) return;

    if ('IntersectionObserver' in window) {
      videoObserver = new IntersectionObserver(function(entries, observer) {
        entries.forEach(function(entry) {
          if (entry.isIntersecting) {
            const video = entry.target;
            const src = video.getAttribute('data-lazy-video-src');
            
            if (src && !video.querySelector('source')) {
              // Create and add the source element
              const source = document.createElement('source');
              source.src = src;
              source.type = 'video/mp4';
              video.appendChild(source);
              
              // Remove the data attribute
              video.removeAttribute('data-lazy-video-src');
              
              // Load the video
              video.load();
            }
            
            observer.unobserve(video);
          }
        });
      }, {
        rootMargin: '50px 0px',
        threshold: 0.01
      });

      videos.forEach(function(video) {
        videoObserver.observe(video);
      });
    } else {
      // Fallback for browsers without IntersectionObserver
      videos.forEach(function(video) {
        const src = video.getAttribute('data-lazy-video-src');
        if (src && !video.querySelector('source')) {
          const source = document.createElement('source');
          source.src = src;
          source.type = 'video/mp4';
          video.appendChild(source);
          video.removeAttribute('data-lazy-video-src');
          video.load();
        }
      });
    }
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initLazyVideos);
  } else {
    initLazyVideos();
  }

  // Re-initialize when new content is added (for SPA-like behavior)
  window.addEventListener('lazyVideoRecheck', initLazyVideos);

})();
