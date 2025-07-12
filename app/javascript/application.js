// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@rails/actioncable"

// Theme toggle functionality - use turbo:load instead of DOMContentLoaded
document.addEventListener('turbo:load', function() {
  const themeToggle = document.getElementById('theme-toggle');
  
  if (themeToggle) {
    // Remove any existing listeners to prevent duplicates
    themeToggle.removeEventListener('click', handleThemeToggle);
    themeToggle.addEventListener('click', handleThemeToggle);
    
    // Initialize button state
    const isDark = document.documentElement.classList.contains('dark');
    updateToggleButton(isDark);
  }
});

function handleThemeToggle() {
  const isDark = document.documentElement.classList.contains('dark');
  
  if (isDark) {
    // Switch to light mode
    document.documentElement.classList.remove('dark');
    localStorage.theme = 'light';
    updateToggleButton(false);
  } else {
    // Switch to dark mode
    document.documentElement.classList.add('dark');
    localStorage.theme = 'dark';
    updateToggleButton(true);
  }
}

function updateToggleButton(isDark) {
  const toggle = document.getElementById('theme-toggle');
  if (!toggle) return;
  
  const sunIcon = toggle.querySelector('.sun-icon');
  const moonIcon = toggle.querySelector('.moon-icon');
  
  if (!sunIcon || !moonIcon) {
    return;
  }
  
  if (isDark) {
    sunIcon.classList.remove('hidden');
    moonIcon.classList.add('hidden');
    toggle.setAttribute('aria-label', 'Switch to light mode');
  } else {
    sunIcon.classList.add('hidden');
    moonIcon.classList.remove('hidden');
    toggle.setAttribute('aria-label', 'Switch to dark mode');
  }
}
import "channels"
