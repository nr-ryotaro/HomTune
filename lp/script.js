// ═══════════ Intersection Observer for scroll animations ═══════════
document.addEventListener('DOMContentLoaded', () => {
  // Animate elements on scroll
  const observerOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.15
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        // Re-trigger health bar animation
        const healthFill = entry.target.querySelector('.health-fill-animate');
        if (healthFill) {
          healthFill.style.animation = 'none';
          healthFill.offsetHeight; // reflow
          healthFill.style.animation = '';
        }
      }
    });
  }, observerOptions);

  // Observe feature rows, value cards, health rules, pricing cards
  document.querySelectorAll(
    '.feature-row, .value-card, .health-rule, .pricing-card, .health-badges-demo, .health-demo'
  ).forEach(el => {
    el.classList.add('fade-up');
    observer.observe(el);
  });

  // Nav background opacity on scroll
  const nav = document.querySelector('.nav');
  window.addEventListener('scroll', () => {
    if (window.scrollY > 40) {
      nav.classList.add('nav-scrolled');
    } else {
      nav.classList.remove('nav-scrolled');
    }
  });
});
