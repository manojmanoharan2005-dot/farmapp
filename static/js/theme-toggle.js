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
        updateThemeButtons(theme);
    };

    // Update theme toggle buttons icons and text
    const updateThemeButtons = (theme) => {
        const themeToggles = document.querySelectorAll('.theme-toggle');
        themeToggles.forEach(themeToggle => {
            const icon = themeToggle.querySelector('i');
            const text = themeToggle.querySelector('span');
            
            if (theme === 'dark') {
                if (icon) {
                    icon.classList.remove('fa-moon');
                    icon.classList.add('fa-sun');
                }
                themeToggle.setAttribute('title', 'Toggle Light Mode');
                if (text) text.textContent = 'Light Mode';
            } else {
                if (icon) {
                    icon.classList.remove('fa-sun');
                    icon.classList.add('fa-moon');
                }
                themeToggle.setAttribute('title', 'Toggle Dark Mode');
                if (text) text.textContent = 'Dark Mode';
            }
        });
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
        // Just update the buttons, theme is already applied in <head>
        updateThemeButtons(savedTheme);

        // Add click event listener to all theme toggle buttons
        const themeToggles = document.querySelectorAll('.theme-toggle');
        themeToggles.forEach(themeToggle => {
            themeToggle.addEventListener('click', toggleTheme);
        });
    };

    // Run on DOMContentLoaded
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initTheme);
    } else {
        initTheme();
    }
})();