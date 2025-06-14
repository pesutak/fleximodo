// Lazy loading implementation for images, videos, and SVGs
document.addEventListener('DOMContentLoaded', function() {
  // Initialize lazy SVGs
  function initLazySVGs() {
    const lazySVGs = document.querySelectorAll('object.lazy-svg');
    
    if ('IntersectionObserver' in window) {
      const svgObserver = new IntersectionObserver(function(entries, observer) {
        entries.forEach(function(entry) {
          if (entry.isIntersecting) {
            const svg = entry.target;
            if (svg.dataset.src) {
              svg.data = svg.dataset.src;
              
              // Add onload event to add the 'loaded' class
              svg.onload = function() {
                svg.classList.add('loaded');
              };
            }
            
            svgObserver.unobserve(svg);
          }
        });
      });
      
      lazySVGs.forEach(function(svg) {
        svgObserver.observe(svg);
      });
    } else {
      // Fallback for browsers that don't support IntersectionObserver
      let lazySVGTimeout;
      
      function lazyLoadSVGs() {
        if (lazySVGTimeout) {
          clearTimeout(lazySVGTimeout);
        }
        
        lazySVGTimeout = setTimeout(function() {
          const scrollTop = window.pageYOffset;
          
          lazySVGs.forEach(function(svg) {
            if (svg.offsetTop < (window.innerHeight + scrollTop)) {
              if (svg.dataset.src) {
                svg.data = svg.dataset.src;
                
                // Add onload event to add the 'loaded' class
                svg.onload = function() {
                  svg.classList.add('loaded');
                };
              }
            }
          });
          
          if (lazySVGs.length === 0) {
            document.removeEventListener('scroll', lazyLoadSVGs);
            window.removeEventListener('resize', lazyLoadSVGs);
            window.removeEventListener('orientationChange', lazyLoadSVGs);
          }
        }, 20);
      }
      
      document.addEventListener('scroll', lazyLoadSVGs);
      window.addEventListener('resize', lazyLoadSVGs);
      window.addEventListener('orientationChange', lazyLoadSVGs);
      
      // Initial load
      lazyLoadSVGs();
    }
  }

  // Initialize lazy loading for images
  function initLazyImages() {
    const lazyImages = document.querySelectorAll('img.lazy-image[data-src]');
    
    if ('IntersectionObserver' in window) {
      const imageObserver = new IntersectionObserver(function(entries, observer) {
        entries.forEach(function(entry) {
          if (entry.isIntersecting) {
            const image = entry.target;
            if (image.dataset.src) {
              image.src = image.dataset.src;
              image.removeAttribute('data-src');
              
              // Add loaded class when image is loaded
              image.onload = function() {
                image.classList.add('loaded');
                const picture = image.closest('picture');
                if (picture) {
                  picture.classList.add('loaded');
                }
              };
            }
            imageObserver.unobserve(image);
          }
        });
      });
      
      lazyImages.forEach(function(image) {
        imageObserver.observe(image);
      });
    } else {
      // Fallback for browsers that don't support IntersectionObserver
      let lazyImageTimeout;
      
      function lazyLoadImages() {
        if (lazyImageTimeout) {
          clearTimeout(lazyImageTimeout);
        }
        
        lazyImageTimeout = setTimeout(function() {
          const scrollTop = window.pageYOffset;
          
          lazyImages.forEach(function(image) {
            if (image.offsetTop < (window.innerHeight + scrollTop)) {
              if (image.dataset.src) {
                image.src = image.dataset.src;
                image.removeAttribute('data-src');
                
                // Add loaded class when image is loaded
                image.onload = function() {
                  image.classList.add('loaded');
                  const picture = image.closest('picture');
                  if (picture) {
                    picture.classList.add('loaded');
                  }
                };
              }
            }
          });
        }, 20);
      }
      
      document.addEventListener('scroll', lazyLoadImages);
      window.addEventListener('resize', lazyLoadImages);
      window.addEventListener('orientationChange', lazyLoadImages);
      
      // Initial load
      lazyLoadImages();
    }
  }
  
  // Add loaded class to all images when they finish loading
  function initImageLoadedClass() {
    const lazyImages = document.querySelectorAll('img.lazy-image:not([data-src])');
    const lazyPictures = document.querySelectorAll('picture.lazy-picture');
    
    // Add loaded class to images when they finish loading
    lazyImages.forEach(function(image) {
      // If the image is already loaded
      if (image.complete) {
        image.classList.add('loaded');
        
        // Find parent picture element and add loaded class
        const picture = image.closest('picture');
        if (picture) {
          picture.classList.add('loaded');
        }
      } else {
        // Add load event listener
        image.addEventListener('load', function() {
          image.classList.add('loaded');
          
          // Find parent picture element and add loaded class
          const picture = image.closest('picture');
          if (picture) {
            picture.classList.add('loaded');
          }
        });
      }
    });
  }
  
  // Initialize lazy loading
  initLazySVGs();
  initLazyImages();
  initImageLoadedClass();
});
