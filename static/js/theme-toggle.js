// Theme Toggle Functionality
(function() {
    // Theme is already applied in base.html <head> to prevent flash
    
    // Get theme from localStorage or default to light
    const getTheme = () => {
        return localStorage.getItem('theme') || 'light';
    };

    // Set theme and update UI
    const setTheme = (theme) => {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);
        updateThemeButton(theme);
    };

    // Update theme toggle button icon
    const updateThemeButton = (theme) => {
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            const icon = themeToggle.querySelector('i');
            const text = themeToggle.querySelector('span');
            
            if (theme === 'dark') {
                icon.classList.remove('fa-moon');
                icon.classList.add('fa-sun');
                themeToggle.setAttribute('title', 'Toggle Light Mode');
                if (text) text.textContent = 'Light Mode';
            } else {
                icon.classList.remove('fa-sun');
                icon.classList.add('fa-moon');
                themeToggle.setAttribute('title', 'Toggle Dark Mode');
                if (text) text.textContent = 'Dark Mode';
            }
        }
    };

    // Toggle between light and dark themes
    const toggleTheme = () => {
        const currentTheme = getTheme();
        const newTheme = currentTheme === 'light' ? 'dark' : 'light';
        setTheme(newTheme);
    };

    // Initialize theme on page load
    const initTheme = () => {
        const savedTheme = getTheme();
        // Just update the button, theme is already applied
        updateThemeButton(savedTheme);

        // Add click event listener to theme toggle button
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.addEventListener('click', toggleTheme);
        }
    };

    // Run on DOMContentLoaded
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initTheme);
    } else {
        initTheme();
    }
})();