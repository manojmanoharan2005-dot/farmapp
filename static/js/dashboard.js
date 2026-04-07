/**
 * Smart Farming Assistant - Dashboard Core JS
 * Extracted from dashboard.html
 */

// Global Variables & Data Initialization
let dashboardData = {};
try {
    const dataElement = document.getElementById('dashboard-data');
    if (dataElement) {
        dashboardData = JSON.parse(dataElement.textContent);
    }
} catch (e) {
    console.error('Failed to parse dashboard data:', e);
}

const currentUserId = dashboardData.userId || '';
const userState = dashboardData.userState || '';
const userDistrict = dashboardData.userDistrict || '';

// Modal Variables
let currentViewCropId = '';
let currentViewCropName = '';
let currentViewCropStage = '';
let currentViewCropNotes = '';
let currentFertilizerName = '';

// Charts
let priceTrendChart = null;
let expenseChart = null;
const expenseHistory = [];

/**
 * UI & Sidebar Functions
 */

/**
 * Notification Panel Functions
 */
function toggleNotificationPanel() {
    const panel = document.getElementById('notificationPanel');
    if (panel.style.display === 'none') {
        panel.style.display = 'block';
    } else {
        panel.style.display = 'none';
    }
}

// Close notification panel when clicking outside
document.addEventListener('click', function (event) {
    const panel = document.getElementById('notificationPanel');
    const btn = document.querySelector('.notification-toggle-btn');
    if (panel && btn && !panel.contains(event.target) && !btn.contains(event.target)) {
        panel.style.display = 'none';
    }
});

function markAllRead() {
    fetch('/mark-notifications-read', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                toggleNotificationPanel();
                showToast('All notifications marked as read', 'success');
                // Remove badge
                const badge = document.querySelector('.notification-toggle-btn span');
                if (badge) badge.remove();
                // Clear list
                const list = document.querySelector('.panel-body');
                if (list) {
                    list.innerHTML = '<div style="padding: 32px; text-align: center; color: #64748b;"><i class="fas fa-bell-slash" style="font-size: 24px; margin-bottom: 8px; opacity: 0.5;"></i><p style="margin: 0; font-size: 13px;">No new alerts</p></div>';
                }
            } else {
                showToast('Failed to mark notifications', 'error');
            }
        })
        .catch(error => {
            console.error('Error:', error);
            showToast('Error marking notifications', 'error');
        });
}

/**
 * Live Clock and dynamic greeting
 */
function updateLiveClock() {
    const clockEl = document.getElementById('liveClock');
    if (!clockEl) return;
    
    const now = new Date();
    const timeStr = now.toLocaleTimeString('en-US', { 
        hour: '2-digit', 
        minute: '2-digit', 
        second: '2-digit',
        hour12: true 
    });
    clockEl.textContent = timeStr;
}

// Start clock
setInterval(updateLiveClock, 1000);
updateLiveClock();

/**
 * Toast Notification System
 */
function showToast(message, type = 'info') {
    const toastContainer = document.getElementById('toast-container') || createToastContainer();
    const toast = document.createElement('div');
    toast.className = `toast-message ${type}`;
    
    let icon = 'ℹ️';
    if (type === 'success') icon = '✅';
    if (type === 'error') icon = '🔴';
    if (type === 'warning') icon = '⚠️';
    
    toast.innerHTML = `
        <div style="display: flex; align-items: center; gap: 10px;">
            <span>${icon}</span>
            <div style="font-size: 13px; font-weight: 500;">${message}</div>
        </div>
    `;
    
    toastContainer.appendChild(toast);
    
    // Animate in
    setTimeout(() => toast.style.opacity = '1', 10);
    
    // Remove after 4 seconds
    setTimeout(() => {
        toast.style.opacity = '0';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

function createToastContainer() {
    const container = document.createElement('div');
    container.id = 'toast-container';
    container.style.cssText = 'position: fixed; top: 100px; right: 20px; z-index: 10000; display: flex; flex-direction: column; gap: 10px; pointer-events: none;';
    document.body.appendChild(container);
    
    // Add CSS for toasts if not in file
    const style = document.createElement('style');
    style.innerHTML = `
        .toast-message {
            background: rgba(30, 41, 59, 0.95);
            color: white;
            padding: 12px 20px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            border: 1px solid rgba(255,255,255,0.1);
            min-width: 250px;
            opacity: 0;
            transition: all 0.3s ease;
            pointer-events: auto;
        }
        .toast-message.success { border-left: 4px solid #10b981; }
        .toast-message.error { border-left: 4px solid #ef4444; }
        .toast-message.warning { border-left: 4px solid #f59e0b; }
        .toast-message.info { border-left: 4px solid #3b82f6; }
    `;
    document.head.appendChild(style);
    return container;
}

/**
 * Professional Notification/Alerts Panel Logic
 */
function toggleNotificationPanel(e) {
    if (e) e.stopPropagation();
    const panel = document.getElementById('notificationPanel');
    const downloadPanel = document.getElementById('downloadPanel');
    
    if (downloadPanel) downloadPanel.style.display = 'none';
    
    if (panel.style.display === 'block') {
        panel.style.display = 'none';
    } else {
        panel.style.display = 'block';
    }
}

function filterNotifs(category) {
    // Update tabs UI
    const tabs = document.querySelectorAll('.notif-tab');
    tabs.forEach(tab => {
        if (tab.dataset.filter === category) {
            tab.classList.add('active');
        } else {
            tab.classList.remove('active');
        }
    });

    // Filter items
    const items = document.querySelectorAll('.notif-item-panel');
    let found = 0;
    
    // Hide default empty message if any tab other than 'all' is picked
    const defaultEmpty = document.querySelector('.empty-notif:not(.filter-empty-msg)');
    if (defaultEmpty) defaultEmpty.style.display = 'none';

    items.forEach(item => {
        if (category === 'all' || item.classList.contains(category)) {
            item.style.display = 'flex';
            found++;
        } else {
            item.style.display = 'none';
        }
    });

    // Handle empty state within panel
    const body = document.querySelector('.floating-panel.notification .panel-body');
    let emptyMsg = body.querySelector('.filter-empty-msg');
    
    if (found === 0) {
        if (!emptyMsg) {
            emptyMsg = document.createElement('div');
            emptyMsg.className = 'filter-empty-msg empty-notif';
            emptyMsg.innerHTML = `
                <div class="empty-notif-icon"><i class="fas fa-filter" style="opacity:0.5;"></i></div>
                <p style="color: var(--text-secondary); font-size: 13px;">No ${category} alerts present</p>
            `;
            body.appendChild(emptyMsg);
        }
        emptyMsg.style.display = 'block';
    } else {
        if (emptyMsg) emptyMsg.style.display = 'none';
        // If 'all' and no items still, show default empty message
        if (category === 'all' && found === 0 && defaultEmpty) {
            defaultEmpty.style.display = 'block';
        }
    }
}

function handleNotifAction(type, title) {
    if (type === 'market') {
        showToast(`Opening latest market price analyzer for ${title}...`, 'info');
        // Logic to navigate or open modal
    } else if (type === 'warning') {
        showToast("Loading detailed weather forecast advisory...", 'warning');
    } else {
        showToast(`Reviewing ${title}...`, 'info');
    }
    
    // Toggle side effect: vibration on mobile if supported
    if ('vibrate' in navigator) {
        navigator.vibrate(20);
    }
}

/**
 * Download Panel Functions
 */
function toggleDownloadPanel() {
    const panel = document.getElementById('downloadPanel');
    if (panel.style.display === 'none') {
        panel.style.display = 'block';
    } else {
        panel.style.display = 'none';
    }
}

// Close download panel when clicking outside
document.addEventListener('click', function (event) {
    const panel = document.getElementById('downloadPanel');
    const btn = document.querySelector('.download-toggle-btn');
    if (panel && btn && !panel.contains(event.target) && !btn.contains(event.target)) {
        panel.style.display = 'none';
    }
});

// Handlers for Data Attributes in HTML
function handleCropView(btn) {
    const d = btn.dataset;
    openCropViewModal(d.id, d.crop, d.stage, parseFloat(d.progress), parseInt(d.day), d.started, d.notes);
}

function handleCropEdit(btn) {
    const d = btn.dataset;
    openCropEditModal(d.id, d.crop, d.stage, d.notes);
}

function handleFertilizerView(btn) {
    const d = btn.dataset;
    openFertilizerViewModal(d.id, d.fertilizer, d.crop, d.date, d.soil, d.n, d.p, d.k);
}

function handleFertilizerDetailView(btn) {
    const d = btn.dataset;
    viewFertilizerDetails(d.id, d.name, d.crop, d.n, d.p, d.k, d.soil, d.date);
}

/**
 * Crop Modal Functions
 */
function openCropViewModal(id, cropName, stage, progress, currentDay, startDate, notes) {
    currentViewCropId = id;
    currentViewCropName = cropName;
    currentViewCropStage = stage;
    currentViewCropNotes = notes || '';

    const els = {
        'viewCropName': cropName,
        'viewCropStage': stage,
        'viewProgressText': progress + '%',
        'viewCurrentDay': currentDay,
        'viewStartDate': startDate,
        'viewNotes': notes || 'No notes added yet.'
    };

    for (const [id, val] of Object.entries(els)) {
        const el = document.getElementById(id);
        if (el) el.textContent = val;
    }

    // Update progress circle
    const circle = document.getElementById('viewProgressCircle');
    if (circle) {
        const circumference = 314.16;
        const offset = circumference - (circumference * progress / 100);
        circle.style.strokeDashoffset = offset;
    }

    // Generate timeline
    generateTimeline(stage, progress);

    const modal = document.getElementById('cropViewModal');
    if (modal) modal.style.display = 'flex';

    // Setup Action Buttons
    const editBtn = document.getElementById('editCropBtn');
    if (editBtn) {
        editBtn.onclick = function () {
            closeCropViewModal();
            setTimeout(() => {
                openCropEditModal(currentViewCropId, currentViewCropName, currentViewCropStage, currentViewCropNotes);
            }, 100);
        };
    }

    const fullViewBtn = document.getElementById('fullViewCropBtn');
    if (fullViewBtn) {
        fullViewBtn.onclick = function () {
            window.location.href = '/growing/view/' + id;
        };
    }
}

function closeCropViewModal() {
    const modal = document.getElementById('cropViewModal');
    if (modal) modal.style.display = 'none';
}

function generateTimeline(currentStage, progress) {
    const stages = [
        { name: 'Seed Sowing', icon: '🌱', days: '1-7' },
        { name: 'Germination', icon: '🌿', days: '7-14' },
        { name: 'Seedling', icon: '🌾', days: '14-30' },
        { name: 'Vegetative Growth', icon: '🌳', days: '30-60' },
        { name: 'Flowering', icon: '🌸', days: '60-75' },
        { name: 'Fruit Development', icon: '🍎', days: '75-90' },
        { name: 'Maturity', icon: '✅', days: '90-110' },
        { name: 'Harvest Ready', icon: '🎉', days: '110+' }
    ];

    const currentIndex = stages.findIndex(s => s.name === currentStage);
    const timeline = document.getElementById('viewTimeline');
    if (!timeline) return;

    timeline.innerHTML = '';

    stages.forEach((stage, index) => {
        const isCompleted = index < currentIndex;
        const isCurrent = index === currentIndex;

        const item = document.createElement('div');
        item.style.cssText = 'display: flex; gap: 12px; margin-bottom: 16px; position: relative;';

        // Vertical line
        if (index < stages.length - 1) {
            item.innerHTML += `<div style="position: absolute; left: 11px; top: 28px; bottom: -16px; width: 2px; background: ${isCompleted ? '#10b981' : '#e2e8f0'};"></div>`;
        }

        // Icon circle
        const iconBg = isCompleted ? '#10b981' : (isCurrent ? '#3b82f6' : '#e2e8f0');
        const iconColor = isCompleted || isCurrent ? 'white' : '#94a3b8';

        item.innerHTML += `
            <div style="width: 24px; height: 24px; border-radius: 50%; background: ${iconBg}; display: flex; align-items: center; justify-content: center; font-size: 12px; flex-shrink: 0; z-index: 1;">
                ${isCompleted ? '✓' : stage.icon}
            </div>
            <div style="flex: 1;">
                <div style="font-size: 13px; font-weight: 600; color: ${isCurrent ? '#3b82f6' : (isCompleted ? '#10b981' : '#64748b')};">
                    ${stage.name} ${isCurrent ? '(Current)' : ''}
                </div>
                <div style="font-size: 11px; color: #94a3b8;">Days ${stage.days}</div>
            </div>
        `;

        timeline.appendChild(item);
    });
}

function openCropEditModal(id, cropName, stage, notes) {
    const els = {
        'editCropId': id,
        'editCropName': cropName,
        'editCropStage': stage,
        'editCropNotes': notes || ''
    };

    for (const [elId, val] of Object.entries(els)) {
        const el = document.getElementById(elId);
        if (el) el.value = val;
    }

    const title = document.getElementById('editCropTitle');
    if (title) title.textContent = 'Editing: ' + cropName;

    const modal = document.getElementById('cropEditModal');
    if (modal) modal.style.display = 'flex';
}

function closeCropEditModal() {
    const modal = document.getElementById('cropEditModal');
    if (modal) modal.style.display = 'none';
}

/**
 * Fertilizer functions
 */
function openFertilizerViewModal(id, fertilizerName, crop, date, soilType, nitrogen, phosphorus, potassium) {
    currentFertilizerName = fertilizerName || 'fertilizer';

    const els = {
        'viewFertilizerName': fertilizerName || 'Fertilizer',
        'viewFertilizerCrop': crop || '-',
        'viewFertilizerSoil': soilType || 'Not specified',
        'viewFertilizerDate': date || '-',
        'viewFertilizerN': nitrogen || '-',
        'viewFertilizerP': phosphorus || '-',
        'viewFertilizerK': potassium || '-'
    };

    for (const [id, val] of Object.entries(els)) {
        const el = document.getElementById(id);
        if (el) el.textContent = val;
    }

    const modal = document.getElementById('fertilizerViewModal');
    if (modal) modal.style.display = 'flex';
}

function closeFertilizerViewModal() {
    const modal = document.getElementById('fertilizerViewModal');
    if (modal) modal.style.display = 'none';
}

function openAmazonLink() {
    let fertilizerName = currentFertilizerName || 'fertilizer';
    if (!fertilizerName || fertilizerName === '') {
        fertilizerName = 'fertilizer';
    }
    // Clean up the search query
    let searchQuery = fertilizerName.trim();
    // Open Amazon India with search
    const url = 'https://www.amazon.in/s?k=' + encodeURIComponent(searchQuery);
    window.open(url, '_blank', 'noopener,noreferrer');
}

function openIndiamartLink() {
    let fertilizerName = currentFertilizerName || 'fertilizer';
    if (!fertilizerName || fertilizerName === '') {
        fertilizerName = 'fertilizer';
    }
    // Clean up the search query
    let searchQuery = fertilizerName.trim();
    // Open IndiaMART with search
    const url = 'https://www.indiamart.com/search.mp?ss=' + encodeURIComponent(searchQuery);
    window.open(url, '_blank', 'noopener,noreferrer');
}

/**
 * Buy Dropdown
 */
function toggleBuyDropdown(button) {
    const container = button.parentElement;
    const dropdown = container.querySelector('.buy-dropdown');

    // Close all other dropdowns first
    document.querySelectorAll('.buy-dropdown').forEach(d => {
        if (d !== dropdown) d.style.display = 'none';
    });

    // Toggle this dropdown
    if (dropdown) {
        dropdown.style.display = dropdown.style.display === 'none' ? 'block' : 'none';
    }
}

/**
 * Delete Functions
 */
function deleteCropActivity(activityId) {
    if (confirm('Are you sure you want to delete this crop activity?')) {
        fetch('/growing/delete/' + activityId, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    location.reload();
                } else {
                    alert('Failed to delete: ' + (data.message || 'Unknown error'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Failed to delete activity');
            });
    }
}

function viewFertilizerDetails(id, name, crop, n, p, k, soilType, savedDate) {
    // Create modal if it doesn't exist
    let modal = document.getElementById('fertilizerDetailModal');
    if (!modal) {
        modal = document.createElement('div');
        modal.id = 'fertilizerDetailModal';
        modal.style.cssText = 'display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100vh; background: rgba(0,0,0,0.5); z-index: 10000; align-items: center; justify-content: center; overflow-y: auto; padding: 20px;';
        document.body.appendChild(modal);
    }
    
    // Use current date if no saved date provided
    const displayDate = savedDate || new Date().toLocaleDateString('en-US', { month: 'short', day: '2-digit', year: 'numeric' });
    const displaySoilType = soilType || 'Neutral Soil';
    
    modal.innerHTML = `
        <div style="background: white; border-radius: 20px; max-width: 540px; width: 100%; max-height: 90vh; overflow-y: auto; box-shadow: 0 20px 60px rgba(0,0,0,0.3);">
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #8b5cf6, #7c3aed); padding: 28px 24px; color: white; position: relative; border-radius: 20px 20px 0 0;">
                <button onclick="closeFertilizerDetailModal()" style="position: absolute; top: 16px; right: 16px; background: rgba(255,255,255,0.2); border: none; color: white; width: 36px; height: 36px; border-radius: 50%; cursor: pointer; font-size: 24px; display: flex; align-items: center; justify-content: center; transition: all 0.2s;">×</button>
                <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 12px;">
                    <div style="font-size: 36px;">🧪</div>
                    <div>
                        <h2 style="margin: 0; font-size: 24px; font-weight: 700;">${name || 'Fertilizer'}</h2>
                        <div style="display: flex; align-items: center; gap: 6px; margin-top: 6px; font-size: 14px; opacity: 0.9;">
                            <span>🌱</span>
                            <span style="font-weight: 500;">For: ${crop || 'General Use'}</span>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Content -->
            <div style="padding: 24px;">
                <!-- Fertilizer Details -->
                <div style="margin-bottom: 24px;">
                    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 16px;">
                        <span style="color: #8b5cf6; font-size: 18px;">ℹ️</span>
                        <h3 style="margin: 0; font-size: 16px; font-weight: 700; color: #1e293b;">Fertilizer Details</h3>
                    </div>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                        <div style="background: #f8fafc; padding: 16px; border-radius: 12px; border: 1px solid #e2e8f0;">
                            <div style="font-size: 12px; color: #64748b; margin-bottom: 6px; font-weight: 600;">SOIL TYPE</div>
                            <div style="font-size: 16px; font-weight: 700; color: #1e293b;">${displaySoilType}</div>
                        </div>
                        <div style="background: #f8fafc; padding: 16px; border-radius: 12px; border: 1px solid #e2e8f0;">
                            <div style="font-size: 12px; color: #64748b; margin-bottom: 6px; font-weight: 600;">SAVED ON</div>
                            <div style="font-size: 16px; font-weight: 700; color: #1e293b;">${displayDate}</div>
                        </div>
                    </div>
                </div>
                
                <!-- Soil NPK Values -->
                <div style="margin-bottom: 24px;">
                    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 16px;">
                        <span style="color: #10b981; font-size: 18px;">📊</span>
                        <h3 style="margin: 0; font-size: 16px; font-weight: 700; color: #1e293b;">Soil NPK Values</h3>
                    </div>
                    <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px;">
                        <div style="background: #dcfce7; padding: 16px; border-radius: 12px; text-align: center;">
                            <div style="font-size: 11px; color: #166534; margin-bottom: 8px; font-weight: 600; letter-spacing: 0.5px;">NITROGEN (N)</div>
                            <div style="font-size: 32px; font-weight: 700; color: #166534;">${n || '0'}</div>
                        </div>
                        <div style="background: #fef3c7; padding: 16px; border-radius: 12px; text-align: center;">
                            <div style="font-size: 11px; color: #92400e; margin-bottom: 8px; font-weight: 600; letter-spacing: 0.5px;">PHOSPHORUS (P)</div>
                            <div style="font-size: 32px; font-weight: 700; color: #92400e;">${p || '0'}</div>
                        </div>
                        <div style="background: #e0e7ff; padding: 16px; border-radius: 12px; text-align: center;">
                            <div style="font-size: 11px; color: #4338ca; margin-bottom: 8px; font-weight: 600; letter-spacing: 0.5px;">POTASSIUM (K)</div>
                            <div style="font-size: 32px; font-weight: 700; color: #4338ca;">${k || '0'}</div>
                        </div>
                    </div>
                </div>
                
                <!-- Application Tips -->
                <div style="margin-bottom: 24px;">
                    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 16px;">
                        <span style="font-size: 18px;">💡</span>
                        <h3 style="margin: 0; font-size: 16px; font-weight: 700; color: #1e293b;">Application Tips</h3>
                    </div>
                    <div style="background: #fffbeb; padding: 16px; border-radius: 12px; border-left: 4px solid #f59e0b;">
                        <ul style="margin: 0; padding-left: 20px; color: #78350f;">
                            <li style="margin-bottom: 8px;">Apply fertilizer in early morning or late evening</li>
                            <li style="margin-bottom: 8px;">Water the soil before and after application</li>
                            <li style="margin-bottom: 8px;">Keep away from plant stem to avoid burning</li>
                            <li>Follow recommended dosage for best results</li>
                        </ul>
                    </div>
                </div>
                
                <!-- Buy From -->
                <div style="margin-bottom: 8px;">
                    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 16px;">
                        <span style="font-size: 18px;">🛒</span>
                        <h3 style="margin: 0; font-size: 16px; font-weight: 700; color: #1e293b;">Buy Fertilizer</h3>
                    </div>
                    <button onclick="window.open('https://agri-e-commerce.vercel.app', '_blank')" 
                        style="width: 100%; background: #059669; color: white; border: none; border-radius: 12px; padding: 20px 16px; cursor: pointer; font-weight: 600; font-size: 16px; transition: all 0.2s; display: flex; align-items: center; justify-content: center; gap: 12px;"
                        onmouseover="this.style.transform='translateY(-2px)'; this.style.boxShadow='0 6px 20px rgba(5,150,105,0.3)'"
                        onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='none'">
                        <div style="font-size: 28px;">🌾</div>
                        <div>Shop at Agri E-Commerce</div>
                    </button>
                </div>
            </div>
        </div>
    `;
    
    modal.style.display = 'flex';
    
    // Close on outside click
    modal.onclick = function(event) {
        if (event.target === modal) {
            closeFertilizerDetailModal();
        }
    };
}

function closeFertilizerDetailModal() {
    const modal = document.getElementById('fertilizerDetailModal');
    if (modal) modal.style.display = 'none';
}

function deleteFertilizer(fertilizerId) {
    if (confirm('Are you sure you want to delete this fertilizer recommendation?')) {
        fetch('/fertilizer/delete/' + fertilizerId, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    location.reload();
                } else {
                    alert('Failed to delete: ' + (data.message || 'Unknown error'));
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Failed to delete recommendation');
            });
    }
}

/**
 * Chatbot Functions
 */
function toggleChatbot() {
    const win = document.getElementById('chatbotWindow');
    if (win) win.classList.toggle('active');
}

function openChatbotModal() {
    const win = document.getElementById('chatbotWindow');
    if (win) win.classList.add('active');
}

function handleChatKeypress(event) {
    if (event.key === 'Enter') {
        sendChatMessage();
    }
}

function sendChatMessage() {
    const input = document.getElementById('chatInput');
    const message = input.value.trim();
    if (!message) return;

    const messagesContainer = document.getElementById('chatMessages');

    // Add user message
    messagesContainer.innerHTML += `
        <div class="chat-message user">
            <div class="message-avatar">👤</div>
            <div class="message-content">${message}</div>
        </div>
    `;

    input.value = '';
    messagesContainer.scrollTop = messagesContainer.scrollHeight;

    // Send to server
    fetch('/chat/message', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: message })
    })
        .then(response => response.json())
        .then(data => {
            if (data.success && data.response) {
                messagesContainer.innerHTML += `
                    <div class="chat-message bot">
                        <div class="message-avatar">🤖</div>
                        <div class="message-content">${data.response}</div>
                    </div>
                `;
            } else {
                const errorMsg = data.error || 'Sorry, I couldn\'t process your request. Please try again.';
                messagesContainer.innerHTML += `
                    <div class="chat-message bot">
                        <div class="message-avatar">🤖</div>
                        <div class="message-content">${errorMsg}</div>
                    </div>
                `;
            }
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        })
        .catch(error => {
            console.error('Fetch error:', error);
            messagesContainer.innerHTML += `
                <div class="chat-message bot">
                    <div class="message-avatar">🤖</div>
                    <div class="message-content">Sorry, I couldn't process your request. Please try again.</div>
                </div>
            `;
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        });
}

/**
 * Price Trend Analysis
 */
function loadPriceTrend(commodity, days = 7) {
    if (!commodity) return;

    console.log('Loading price trend for:', commodity, 'days:', days);

    // Update active button state
    const btn7 = document.getElementById('btn-7d');
    const btn30 = document.getElementById('btn-30d');
    if (btn7) btn7.classList.toggle('active', days === 7);
    if (btn30) btn30.classList.toggle('active', days === 30);

    fetch(`/api/price-trend/${encodeURIComponent(commodity)}?state=${encodeURIComponent(userState)}&district=${encodeURIComponent(userDistrict)}&days=${days}`)
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            console.log('Price trend data received:', data);
            if (data.success) {
                renderTrendChart(data);
            } else {
                console.error('Trend data error:', data.error);
                console.warn(`Using fallback data for ${commodity}`);
                // Show a less intrusive message or try to show chart anyway
                if (data.trend_data && data.trend_data.length > 0) {
                    renderTrendChart(data);
                }
            }
        })
        .catch(error => {
            console.error('Error fetching trend:', error);
            // Don't show alert, just log it
            console.warn('Price trend unavailable, skipping chart render');
        });
}

function renderTrendChart(data) {
    console.log('renderTrendChart called with data:', data);

    // Hide loading indicator and show canvas
    const loadingEl = document.getElementById('chart-loading');
    const canvas = document.getElementById('priceTrendChart');
    
    if (!canvas) {
        console.error('Canvas element not found!');
        return;
    }

    console.log('Canvas found:', canvas);

    if (typeof Chart === 'undefined') {
        console.error('Chart.js is not loaded!');
        if (loadingEl) {
            loadingEl.innerHTML = '<i class="fas fa-exclamation-triangle" style="font-size: 24px; margin-bottom: 8px; color: rgba(239, 68, 68, 0.5);"></i><div style="font-size: 13px;">Chart library not loaded</div>';
        }
        return;
    }

    const ctx = canvas.getContext('2d');

    if (!data.trend_data || data.trend_data.length === 0) {
        console.error('No trend data available');
        // Show "No data" message
        if (loadingEl) {
            loadingEl.style.display = 'flex';
            loadingEl.innerHTML = '<i class="fas fa-chart-line" style="font-size: 24px; margin-bottom: 8px; color: rgba(255,255,255,0.3);"></i><div style="font-size: 13px;">No price data available</div>';
        }
        canvas.style.display = 'none';
        return;
    }

    // Hide loading and show canvas
    if (loadingEl) loadingEl.style.display = 'none';
    canvas.style.display = 'block';

    const labels = data.trend_data.map(item => {
        const date = new Date(item.date);
        return date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
    });

    const prices = data.trend_data.map(item => item.modal_price / 100); // per kg

    console.log('Labels:', labels);
    console.log('Prices:', prices);

    if (priceTrendChart) {
        priceTrendChart.destroy();
    }

    // Create smooth green gradient for area chart
    const gradient = ctx.createLinearGradient(0, 0, 0, 200);
    gradient.addColorStop(0, 'rgba(34, 197, 94, 0.35)');   // #22C55E with opacity
    gradient.addColorStop(0.5, 'rgba(34, 197, 94, 0.15)');
    gradient.addColorStop(1, 'rgba(34, 197, 94, 0)');

    try {
        priceTrendChart = new Chart(ctx, {
            type: 'line',  // Changed from 'bar' to 'line' for area chart
            data: {
                labels: labels,
                datasets: [{
                    label: `${data.commodity} Price`,
                    data: prices,
                    fill: true,  // Enable area fill
                    backgroundColor: gradient,
                    borderColor: '#22C55E',  // Soft green line
                    borderWidth: 2.5,
                    pointRadius: 4,
                    pointBackgroundColor: '#22C55E',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointHoverRadius: 6,
                    pointHoverBackgroundColor: '#22C55E',
                    pointHoverBorderColor: '#fff',
                    pointHoverBorderWidth: 2.5,
                    tension: 0.4  // Smooth curve
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                    mode: 'index',
                    intersect: false
                },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        mode: 'index',
                        intersect: false,
                        backgroundColor: 'rgba(30, 41, 59, 0.95)',
                        titleColor: '#fff',
                        bodyColor: '#fff',
                        borderColor: '#22C55E',
                        borderWidth: 1.5,
                        padding: 12,
                        displayColors: false,
                        titleFont: { size: 13, weight: 'bold' },
                        bodyFont: { size: 12 },
                        callbacks: {
                            label: function (context) {
                                return `Price: ₹${context.raw.toFixed(2)}/kg`;
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        grid: {
                            display: false,
                            drawBorder: false
                        },
                        ticks: {
                            color: 'rgba(255, 255, 255, 0.6)',
                            font: { size: 11, family: "'Inter', sans-serif" },
                            maxRotation: 0,
                            padding: 8
                        }
                    },
                    y: {
                        beginAtZero: false,
                        grid: {
                            color: 'rgba(255, 255, 255, 0.06)',
                            drawBorder: false,
                            lineWidth: 1
                        },
                        ticks: {
                            color: 'rgba(255, 255, 255, 0.6)',
                            font: { size: 11, family: "'Inter', sans-serif" },
                            padding: 8,
                            callback: function (value) { return '₹' + value.toFixed(0); }
                        }
                    }
                }
            }
        });

        console.log('Chart created successfully:', priceTrendChart);
    } catch (error) {
        console.error('Error creating chart:', error);
        // Show error message
        if (loadingEl) {
            loadingEl.style.display = 'block';
            loadingEl.innerHTML = '<i class="fas fa-exclamation-triangle" style="font-size: 24px; margin-bottom: 8px; color: rgba(239, 68, 68, 0.5);"></i><div style="font-size: 13px;">Error loading chart</div>';
        }
    }

    // Update summary info
    const nameEl = document.getElementById('trend-commodity-name');
    if (nameEl) nameEl.textContent = data.commodity;

    const locationInfo = document.getElementById('trend-location-info');
    if (locationInfo) {
        if (data.data_level === 'district') {
            locationInfo.textContent = `Price analysis in ${userDistrict}`;
        } else if (data.data_level === 'state') {
            locationInfo.textContent = `Price analysis in ${userState} Avg`;
        } else {
            locationInfo.textContent = `Price analysis (National Avg)`;
        }
    }

    const dirEl = document.getElementById('trend-direction');
    const changeEl = document.getElementById('trend-change');
    const iconEl = document.getElementById('trend-direction-icon');
    const recEl = document.getElementById('trend-recommendation');
    const badgeEl = document.getElementById('trend-recommendation-badge');

    if (dirEl) dirEl.textContent = data.analysis.direction;
    if (changeEl) {
        changeEl.textContent = (data.analysis.change_percent >= 0 ? '+' : '') + data.analysis.change_percent + '%';
    }

    if (iconEl && recEl && badgeEl) {
        if (data.analysis.direction === 'Rising') {
            // WAIT - Yellow/Amber badge
            iconEl.className = 'fas fa-arrow-trend-up';
            iconEl.style.color = '#10b981';
            if (changeEl) changeEl.style.color = '#10b981';

            badgeEl.style.background = 'rgba(234, 179, 8, 0.15)';
            badgeEl.style.borderColor = '#EAB308';
            badgeEl.querySelector('i').className = 'fas fa-clock';
            badgeEl.querySelector('i').style.color = '#EAB308';
            recEl.innerHTML = '<span style="color: #EAB308; font-weight: 700;">WAIT</span> - Price is increasing, consider selling after 3 days.';

        } else if (data.analysis.direction === 'Falling') {
            // SELL NOW - Green badge
            iconEl.className = 'fas fa-arrow-trend-down';
            iconEl.style.color = '#ef4444';
            if (changeEl) changeEl.style.color = '#ef4444';

            badgeEl.style.background = 'rgba(34, 197, 94, 0.15)';
            badgeEl.style.borderColor = '#22C55E';
            badgeEl.querySelector('i').className = 'fas fa-circle-check';
            badgeEl.querySelector('i').style.color = '#22C55E';
            recEl.innerHTML = '<span style="color: #22C55E; font-weight: 700;">SELL NOW</span> - Price might drop further, sell today.';

        } else {
            // HOLD/SELL - Orange badge
            iconEl.className = 'fas fa-arrows-left-right';
            iconEl.style.color = '#f97316';
            if (changeEl) changeEl.style.color = '#f97316';

            badgeEl.style.background = 'rgba(249, 115, 22, 0.15)';
            badgeEl.style.borderColor = '#F97316';
            badgeEl.querySelector('i').className = 'fas fa-pause-circle';
            badgeEl.querySelector('i').style.color = '#F97316';
            recEl.innerHTML = '<span style="color: #F97316; font-weight: 700;">HOLD/SELL</span> - Price is stable, you can sell if needed.';
        }
    }
}

function viewTrend(commodity) {
    const select = document.getElementById('commodity-select');
    if (select) select.value = commodity;

    const nameEl = document.getElementById('trend-commodity-name');
    if (nameEl) nameEl.textContent = commodity;

    loadPriceTrend(commodity);
    const card = document.getElementById('trend-card');
    if (card) card.scrollIntoView({ behavior: 'smooth' });
}

/**
 * Profile & Weather Modal

/**
 * Calculators & Schemes

/**
 * Equipment & Rentals
 */
function toggleEquipmentForm() {
    const form = document.getElementById('equipmentListingForm');
    const list = document.getElementById('equipmentListContainer');
    const btn = document.getElementById('toggleEquipFormBtn');
    const title = document.getElementById('equipmentModalTitle');
    const subtitle = document.getElementById('equipmentModalSubtitle');

    if (!form || !list || !btn) return;

    if (form.style.display === 'none') {
        form.style.display = 'block';
        list.style.display = 'none';
        btn.innerHTML = '<i class="fas fa-list"></i> View Listings';
        if (title) title.textContent = 'List Equipment';
        if (subtitle) subtitle.textContent = 'Help fellow farmers by sharing your machinery.';
    } else {
        form.style.display = 'none';
        list.style.display = 'grid';
        btn.innerHTML = '<i class="fas fa-plus"></i> List Your Equipment';
        if (title) title.textContent = 'Rent Farm Machinery';
        if (subtitle) subtitle.textContent = 'Connect with local farmers.';
        fetchEquipmentings();
    }
}

function fetchEquipmentings() {
    const container = document.getElementById('equipmentListContainer');
    if (!container) return;

    fetch('/api/equipment')
        .then(res => res.json())
        .then(data => {
            if (data.length === 0) {
                container.innerHTML = `<div style="grid-column: 1/-1; text-align: center; padding: 40px;"><h4>No equipment listed yet</h4></div>`;
                return;
            }

            container.innerHTML = data.map(item => {
                const isOwner = item.owner_id === currentUserId;
                let btnText = 'Rent Now';
                let btnDisabled = '';
                let btnStyle = '';

                if (isOwner) {
                    btnText = 'Your Listing';
                    btnDisabled = 'disabled';
                    btnStyle = 'background: #3b82f6; opacity: 0.8; cursor: default;';
                } else if (item.status === 'rented') {
                    btnText = 'Rented';
                    btnDisabled = 'disabled';
                    btnStyle = 'background: #94a3b8;';
                } else if (item.status === 'requested') {
                    btnText = 'Requested';
                    btnDisabled = 'disabled';
                    btnStyle = 'background: #f59e0b;';
                }

                return `
                    <div class="equipment-card">
                        <div class="equipment-image">
                            ${item.image_emoji || '🚜'} 
                            <div class="equipment-badge" style="background: ${item.status === 'available' ? '#dcfce7' : '#fee2e2'};">
                                ${item.status}
                            </div>
                        </div>
                        <div class="equipment-content">
                            <h4>${item.name}</h4>
                            <div><i class="fas fa-map-marker-alt"></i> ${item.location}</div>
                            <div class="equipment-stats">
                                <div>Rate: ₹${item.rate}/${item.rate_unit}</div>
                            </div>
                            <button class="rent-btn" onclick="rentEquipment('${item._id}')" ${btnDisabled} style="${btnStyle}">
                                ${btnText}
                            </button>
                        </div>
                    </div>
                `;
            }).join('');
        })
        .catch(() => { if (container) container.innerHTML = '<p>Error loading.</p>'; });
}

function submitEquipmentListing() {
    const submitBtn = document.querySelector('#addEquipmentForm button[type="submit"]');
    if (!submitBtn) return;

    submitBtn.disabled = true;
    submitBtn.textContent = 'Listing...';

    const data = {
        name: document.getElementById('equipName').value,
        type: document.getElementById('equipType').value,
        rate: document.getElementById('equipRate').value,
        rate_unit: document.getElementById('equipRateUnit').value,
        description: document.getElementById('equipDesc').value,
        image_emoji: document.getElementById('equipType').value === 'Tractor' ? '🚜' : '🛠️'
    };

    fetch('/api/equipment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    })
        .then(res => res.json())
        .then(res => {
            if (res.success) {
                showToast('Equipment listed!', 'success');
                const form = document.getElementById('addEquipmentForm');
                if (form) form.reset();
                toggleEquipmentForm();
            } else {
                showToast(res.error || 'Failed', 'error');
            }
        })
        .catch(() => showToast('Error', 'error'))
        .finally(() => {
            submitBtn.disabled = false;
            submitBtn.textContent = 'List Equipment';
        });
}

function rentEquipment(id) {
    if (!confirm('Are you sure you want to rent this equipment?')) return;
    fetch(`/api/equipment/${id}/rent`, { method: 'POST' })
        .then(res => res.json())
        .then(res => {
            if (res.success) {
                showToast('Rental request sent!', 'success');
                fetchEquipmentings();
            } else {
                showToast(res.error || 'Failed', 'error');
            }
        });
}

/**
 * Expense Benchmarks
async function saveExpenseEntry() {
    const getVal = id => {
        const val = parseFloat(document.getElementById(id)?.value);
        return isNaN(val) ? 0 : val;
    };
    
    const entryDate = document.getElementById('entryDate')?.value;
    const cropType = document.getElementById('cropType')?.value;
    
    if (!entryDate) {
        showToast('Please select a date', 'warning');
        return;
    }

    const saveBtn = document.querySelector('button[onclick="saveExpenseEntry()"]');
    const originalText = saveBtn ? saveBtn.innerHTML : '';
    if (saveBtn) {
        saveBtn.disabled = true;
        saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
    }

    const entry = {
        date: entryDate,
        cropType: cropType,
        expenses: {
            seed: getVal('seedCost'),
            fertilizer: getVal('fertilizerCost'),
            pesticide: getVal('pesticideCost'),
            irrigation: getVal('irrigationCost'),
            labor: getVal('laborCost'),
            machinery: getVal('machineryCost'),
            other: getVal('otherCost')
        },
        landArea: getVal('landArea'),
        expectedYield: getVal('expectedYield'),
        marketPrice: getVal('marketPrice'),
        total_expense: Object.values({
            seed: getVal('seedCost'),
            fertilizer: getVal('fertilizerCost'),
            pesticide: getVal('pesticideCost'),
            irrigation: getVal('irrigationCost'),
            labor: getVal('laborCost'),
            machinery: getVal('machineryCost'),
            other: getVal('otherCost')
        }).reduce((a, b) => a + b, 0)
    };

    try {
        const res = await fetch('/api/expenses', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(entry)
        });
        const result = await res.json();
        
        if (result.success) {
            showToast('Expense entry saved successfully!', 'success');
            // Optional: close modal after save? User didn't request but it's good practice
            // closeCalculatorModal();
        } else {
            showToast('Failed to save: ' + (result.message || 'Unknown error'), 'error');
        }
    } catch (e) {
        console.error('Error saving expense:', e);
        showToast('Network error while saving.', 'error');
    } finally {
        if (saveBtn) {
            saveBtn.disabled = false;
            saveBtn.innerHTML = originalText;
        }
    }
}

/**
 * PDF & Reports
 */
function openDownloadModal() {
    const modal = document.getElementById('downloadModal');
    if (modal) modal.style.display = 'flex';
}

function closeDownloadModal() {
    const modal = document.getElementById('downloadModal');
    if (modal) modal.style.display = 'none';
}

function exportToPDF() {
    if (typeof window.jspdf === 'undefined') return alert('Loading PDF lib...');
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();
    doc.text('Farming Expense Report', 105, 20, { align: 'center' });
    doc.text(`Crop: ${document.getElementById('cropType')?.value}`, 20, 40);
    doc.text(`Total Expense: ${document.getElementById('totalExpense')?.textContent}`, 20, 50);
    doc.save('report.pdf');
}

async function generateReport(cardElement, reportName) {
    if (typeof html2pdf === 'undefined') return alert('Loading PDF library... Please try again in a moment.');

    cardElement.classList.add('report-loading');
    const btnIcon = cardElement.querySelector('i');
    const originalClass = btnIcon ? btnIcon.className : '';
    if (btnIcon) btnIcon.className = 'fas fa-spinner fa-spin';

    try {
        let endpoint = '';
        if (reportName === 'Crop Plan PDF') endpoint = '/api/report/crop-plan';
        else if (reportName === 'Harvest Report') endpoint = '/api/report/harvest';
        else if (reportName === 'Profit Summary') endpoint = '/api/report/profit';
        else if (reportName === 'Market Report') endpoint = '/api/report/market-watch';
        else if (reportName === 'Weather Report') endpoint = '/api/report/weather';

        const res = await fetch(endpoint);
        const result = await res.json();

        if (!result.success) throw new Error(result.message);

        // --- Build Rich HTML Content ---
        const data = result.data;
        const user = data.user;
        const dateStr = new Date().toLocaleDateString('en-GB');

        // Base Wrapper
        let htmlContent = `
            <div style="font-family: 'Segoe UI', sans-serif; background: white; padding: 25px; max-width: 625px; margin: 0 auto; box-sizing: border-box;">
                <!-- Common Top Header -->
                <div style="text-align: center; margin-bottom: 30px;">
                    <h1 style="color: #047857; margin: 0; font-size: 28px; font-weight: 600;">${reportName}</h1>
                    <div style="color: #64748b; font-size: 14px; margin-top: 10px; line-height: 1.6;">
                        <div>Generated on: ${dateStr}</div>
                        <div>Farmer: ${user.name.toUpperCase()}</div>
                        <div>Location: ${user.district}, ${user.state}</div>
                    </div>
                </div>
        `;

        if (reportName === 'Crop Plan PDF') {
            const activeCrops = data.crops.length;
            const avgProgress = Math.round(data.crops.reduce((acc, c) => acc + c.progress, 0) / (activeCrops || 1));

            htmlContent += `
                <!-- Dark Blue Header -->
                <div style="background: #1e3a8a; color: white; padding: 15px; text-align: center; margin-bottom: 30px; border-radius: 4px;">
                    <h2 style="margin: 0; font-size: 18px; font-weight: 600; letter-spacing: 1px;">CROP CULTIVATION PLAN</h2>
                </div>

                <p style="color: #475569; font-size: 14px; margin-bottom: 20px;">
                    Detailed cultivation schedule and status report for active crops.
                </p>

                <!-- 3 Cards Row -->
                <div style="display: flex; gap: 20px; margin-bottom: 40px;">
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">TOTAL CROPS</div>
                        <div style="font-size: 32px; font-weight: 700;">${activeCrops}</div>
                    </div>
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">AVG PROGRESS</div>
                        <div style="font-size: 32px; font-weight: 700;">${avgProgress}%</div>
                    </div>
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">ACTIVE STAGES</div>
                        <div style="font-size: 32px; font-weight: 700;">${activeCrops}</div>
                    </div>
                </div>

                <!-- Table -->
                <h3 style="color: #1e293b; font-size: 16px; margin-bottom: 15px;">Active Crop Status:</h3>
                <table style="width: 100%; border-collapse: collapse; font-size: 12px; margin-bottom: 40px;">
                    <thead>
                        <tr style="background: #0f172a; color: white; text-transform: uppercase;">
                            <th style="padding: 8px; text-align: left;">Crop</th>
                            <th style="padding: 8px; text-align: left;">Stage</th>
                            <th style="padding: 8px; text-align: center;">Progress</th>
                            <th style="padding: 8px; text-align: center;">Started</th>
                            <th style="padding: 8px; text-align: left;">Notes</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.crops.map((c, i) => `
                            <tr style="border-bottom: 1px solid #e2e8f0; page-break-inside: avoid; background: ${i % 2 === 0 ? '#fff' : '#f8fafc'};">
                                <td style="padding: 8px; font-weight: 600; color: #475569;">${c.crop}</td>
                                <td style="padding: 8px; color: #334155;">${c.stage}</td>
                                <td style="padding: 8px; text-align: center;">
                                    <div style="background: #e2e8f0; height: 6px; width: 60px; margin: 0 auto; border-radius: 3px; overflow: hidden;">
                                        <div style="background: #10b981; width: ${c.progress}%; height: 100%;"></div>
                                    </div>
                                    <span style="font-size: 10px; color: #64748b;">${c.progress}%</span>
                                </td>
                                <td style="padding: 8px; text-align: center; color: #64748b;">${c.started}</td>
                                <td style="padding: 8px; color: #64748b; font-style: italic;">${c.notes || '-'}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>

                <!-- Advisory Section -->
                <h3 style="color: #2563eb; font-size: 14px; text-transform: uppercase; margin-bottom: 10px;">AGRONOMIST NOTES:</h3>
                <div style="border: 2px solid #2563eb; background: #eff6ff; border-radius: 8px; padding: 20px;">
                    <p style="margin: 0; color: #334155; line-height: 1.6; font-size: 13px;">
                        <strong>[GENERAL ADVICE]</strong> Regular monitoring of crop stages is crucial. Ensure irrigation aligns with changes in crop water requirements as they progress.
                    </p>
                </div>
             `;

        } else if (reportName === 'Harvest Report') {
            const readyCount = data.crops.filter(c => c.progress >= 90).length;
            const upcomingCount = data.crops.length - readyCount;

            htmlContent += `
                <!-- Dark Blue Header -->
                <div style="background: #1e3a8a; color: white; padding: 15px; text-align: center; margin-bottom: 30px; border-radius: 4px;">
                    <h2 style="margin: 0; font-size: 18px; font-weight: 600; letter-spacing: 1px;">HARVEST SCHEDULE & ESTIMATES</h2>
                </div>

                <p style="color: #475569; font-size: 14px; margin-bottom: 20px;">
                    Estimated harvest windows and yield projections.
                </p>

                <!-- 3 Cards Row -->
                <div style="display: flex; gap: 20px; margin-bottom: 40px;">
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">READY TO HARVEST</div>
                        <div style="font-size: 32px; font-weight: 700;">${readyCount}</div>
                    </div>
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">UPCOMING</div>
                        <div style="font-size: 32px; font-weight: 700;">${upcomingCount}</div>
                    </div>
                </div>

                <!-- Table -->
                <h3 style="color: #1e293b; font-size: 16px; margin-bottom: 15px;">Harvest Schedule:</h3>
                <table style="width: 100%; border-collapse: collapse; font-size: 12px; margin-bottom: 40px;">
                    <thead>
                        <tr style="background: #0f172a; color: white; text-transform: uppercase;">
                            <th style="padding: 8px; text-align: left;">Crop</th>
                            <th style="padding: 8px; text-align: left;">Stage</th>
                            <th style="padding: 8px; text-align: left;">Estimated Yield</th>
                            <th style="padding: 8px; text-align: left;">Harvest Window</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.crops.map((c, i) => `
                            <tr style="border-bottom: 1px solid #e2e8f0; page-break-inside: avoid; background: ${i % 2 === 0 ? '#fff' : '#f8fafc'};">
                                <td style="padding: 8px; font-weight: 600; color: #475569;">${c.crop}</td>
                                <td style="padding: 8px; color: #334155;">${c.stage}</td>
                                <td style="padding: 8px; font-weight: 600; color: #15803d;">${c.estimated_yield}</td>
                                <td style="padding: 8px; color: #b91c1c; font-weight: 500;">${c.harvest_window}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>

                <!-- Advisory Section -->
                <h3 style="color: #2563eb; font-size: 14px; text-transform: uppercase; margin-bottom: 10px;">HARVEST ADVISORY:</h3>
                <div style="border: 2px solid #2563eb; background: #eff6ff; border-radius: 8px; padding: 20px;">
                    <p style="margin: 0; color: #334155; line-height: 1.6; font-size: 13px;">
                        <strong>[POST-HARVEST]</strong> Plan for proper storage and transport immediately after harvest to minimize losses. Check market prices before selling.
                    </p>
                </div>
             `;

        } else if (reportName === 'Profit Summary') {
            htmlContent += `
                <!-- Dark Blue Header -->
                <div style="background: #1e3a8a; color: white; padding: 15px; text-align: center; margin-bottom: 30px; border-radius: 4px;">
                    <h2 style="margin: 0; font-size: 18px; font-weight: 600; letter-spacing: 1px;">FINANCIAL PERFORMANCE REPORT</h2>
                </div>

                <p style="color: #475569; font-size: 14px; margin-bottom: 20px;">
                    Overview of expenses, revenue, and profitability.
                </p>

                <!-- 3 Cards Row -->
                <div style="display: flex; gap: 20px; margin-bottom: 40px;">
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">REVENUE</div>
                        <div style="font-size: 24px; font-weight: 700;">₹${data.total_revenue.toLocaleString()}</div>
                    </div>
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">EXPENSE</div>
                        <div style="font-size: 24px; font-weight: 700;">₹${data.total_expenses.toLocaleString()}</div>
                    </div>
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">NET PROFIT</div>
                        <div style="font-size: 24px; font-weight: 700;">₹${data.net_profit.toLocaleString()}</div>
                    </div>
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">ROI</div>
                        <div style="font-size: 24px; font-weight: 700;">${data.roi}%</div>
                    </div>
                </div>

                <!-- Table -->
                <h3 style="color: #1e293b; font-size: 16px; margin-bottom: 15px;">Crop-wise Financial Breakdown:</h3>
                <table style="width: 100%; border-collapse: collapse; font-size: 12px; margin-bottom: 40px;">
                    <thead>
                        <tr style="background: #0f172a; color: white; text-transform: uppercase;">
                            <th style="padding: 8px; text-align: left;">Crop</th>
                            <th style="padding: 8px; text-align: right;">Revenue</th>
                            <th style="padding: 8px; text-align: right;">Expenses</th>
                            <th style="padding: 8px; text-align: right;">Profit</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${Object.entries(data.crop_wise).map(([crop, val], i) => `
                            <tr style="border-bottom: 1px solid #e2e8f0; page-break-inside: avoid; background: ${i % 2 === 0 ? '#fff' : '#f8fafc'};">
                                <td style="padding: 8px; font-weight: 600; color: #475569;">${crop}</td>
                                <td style="padding: 8px; text-align: right; color: #166534;">₹${val.revenue.toLocaleString()}</td>
                                <td style="padding: 8px; text-align: right; color: #991b1b;">₹${val.expenses.toLocaleString()}</td>
                                <td style="padding: 8px; text-align: right; font-weight: 600; color: ${(val.revenue - val.expenses) >= 0 ? '#15803d' : '#b91c1c'};">
                                    ₹${(val.revenue - val.expenses).toLocaleString()}
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>

                <!-- Advisory Section -->
                <h3 style="color: #2563eb; font-size: 14px; text-transform: uppercase; margin-bottom: 10px;">FINANCIAL ADVISORY:</h3>
                <div style="border: 2px solid #2563eb; background: #eff6ff; border-radius: 8px; padding: 20px;">
                    <p style="margin: 0; color: #334155; line-height: 1.6; font-size: 13px;">
                        <strong>[ANALYSIS]</strong> Review crops with low ROI. Consider reducing input costs through bulk purchasing or optimizing fertilizer usage.
                    </p>
                </div>
            `;

        } else if (reportName === 'Market Report') {
            const prices = data.prices;
            const maxPrice = Math.max(...prices.map(p => p.modal_price)).toFixed(1);
            const minPrice = Math.min(...prices.map(p => p.modal_price)).toFixed(1);

            htmlContent += `
                <!-- Dark Blue Header -->
                <div style="background: #1e3a8a; color: white; padding: 15px; text-align: center; margin-bottom: 30px; border-radius: 4px;">
                    <h2 style="margin: 0; font-size: 18px; font-weight: 600; letter-spacing: 1px;">MARKET INTELLIGENCE REPORT</h2>
                </div>

                <p style="color: #475569; font-size: 14px; margin-bottom: 20px;">
                    Real-time commodity prices and market trends in ${user.district}.
                </p>

                <!-- 3 Cards Row -->
                <div style="display: flex; gap: 20px; margin-bottom: 40px;">
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">COMMODITIES</div>
                        <div style="font-size: 32px; font-weight: 700;">${prices.length}</div>
                    </div>
                     <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">HIGHEST PRICE</div>
                        <div style="font-size: 32px; font-weight: 700;">₹${maxPrice}</div>
                    </div>
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">LOWEST PRICE</div>
                        <div style="font-size: 32px; font-weight: 700;">₹${minPrice}</div>
                    </div>
                </div>

                <!-- Table -->
                <h3 style="color: #1e293b; font-size: 16px; margin-bottom: 15px;">Commodity Prices:</h3>
                <table style="width: 100%; border-collapse: collapse; font-size: 12px; margin-bottom: 40px;">
                    <thead>
                        <tr style="background: #0f172a; color: white; text-transform: uppercase;">
                            <th style="padding: 8px; text-align: left;">Commodity</th>
                            <th style="padding: 8px; text-align: right;">Modal Price</th>
                            <th style="padding: 8px; text-align: right;">Min Price</th>
                            <th style="padding: 8px; text-align: right;">Max Price</th>
                            <th style="padding: 8px; text-align: right;">Market</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${prices.map((item, i) => `
                            <tr style="border-bottom: 1px solid #e2e8f0; page-break-inside: avoid; background: ${i % 2 === 0 ? '#fff' : '#f8fafc'};">
                                <td style="padding: 8px; font-weight: 600; color: #475569;">${item.commodity}</td>
                                <td style="padding: 8px; text-align: right; font-weight: 700; color: #1e293b;">₹${item.modal_price.toFixed(1)}</td>
                                <td style="padding: 8px; text-align: right; color: #64748b;">₹${item.min_price.toFixed(1)}</td>
                                <td style="padding: 8px; text-align: right; color: #64748b;">₹${item.max_price.toFixed(1)}</td>
                                <td style="padding: 8px; text-align: right; color: #475569; font-size: 10px;">${item.market}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>

                 <!-- Advisory Section -->
                <h3 style="color: #2563eb; font-size: 14px; text-transform: uppercase; margin-bottom: 10px;">MARKET ADVISORY:</h3>
                <div style="border: 2px solid #2563eb; background: #eff6ff; border-radius: 8px; padding: 20px;">
                    <p style="margin: 0; color: #334155; line-height: 1.6; font-size: 13px;">
                        <strong>[STRATEGY]</strong> Prices fluctuate daily. It is advisable to sell when prices are stable or rising. Check trend graphs for detailed 30-day analysis.
                    </p>
                </div>
            `;

        } else if (reportName === 'Weather Report') {
            const today = data.weather.current;
            const forecast = data.weather.forecast || [];

            // Helper for moon phase (mock logic for visual completeness)
            const phases = ['New Moon', 'Waxing Crescent', 'First Quarter', 'Waxing Gibbous', 'Full Moon', 'Waning Gibbous', 'Last Quarter', 'Waning Crescent'];
            const getPhase = (i) => phases[i % 8];

            htmlContent += `
                <!-- Dark Blue Header -->
                <div style="background: #1e3a8a; color: white; padding: 15px; text-align: center; margin-bottom: 30px; border-radius: 4px;">
                    <h2 style="margin: 0; font-size: 18px; font-weight: 600; letter-spacing: 1px;">METEOROLOGICAL ADVISORY DASHBOARD</h2>
                </div>

                <p style="color: #475569; font-size: 14px; margin-bottom: 20px;">
                    7-day agricultural forecast and field advisories for ${user.district}.
                </p>

                <!-- 3 Cards Row -->
                <div style="display: flex; gap: 20px; margin-bottom: 40px;">
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">CURRENT TEMP</div>
                        <div style="font-size: 32px; font-weight: 700;">${Math.round(today.temperature)}°C</div>
                    </div>
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">HUMIDITY</div>
                        <div style="font-size: 32px; font-weight: 700;">${today.humidity}%</div>
                    </div>
                    <div style="flex: 1; background: #2563eb; color: white; padding: 25px 15px; border-radius: 8px; text-align: center;">
                        <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px; opacity: 0.9;">WIND SPEED</div>
                        <div style="font-size: 32px; font-weight: 700;">${today.wind_speed} KM/H</div>
                    </div>
                </div>

                <!-- Forecast Table -->
                <h3 style="color: #1e293b; font-size: 16px; margin-bottom: 15px;">7-Day Daily Forecast:</h3>
                <table style="width: 100%; border-collapse: collapse; font-size: 12px; margin-bottom: 40px;">
                    <thead>
                        <tr style="background: #0f172a; color: white; text-transform: uppercase;">
                            <th style="padding: 8px; text-align: left;">DAY</th>
                            <th style="padding: 8px; text-align: left;">CONDITION</th>
                            <th style="padding: 8px; text-align: center;">TEMP (L/H)</th>
                            <th style="padding: 8px; text-align: center;">UV/RAIN</th>
                            <th style="padding: 8px; text-align: left;">MOON PHASE</th>
                            <th style="padding: 8px; text-align: right;">WIND</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${forecast.map((day, index) => `
                            <tr style="border-bottom: 1px solid #e2e8f0; page-break-inside: avoid; background: ${index % 2 === 0 ? '#fff' : '#f8fafc'};">
                                <td style="padding: 8px; font-weight: 600; color: #475569;">
                                    ${index === 0 ? 'TODAY' : (index === 1 ? 'TOMORROW' : `DAY ${index + 1}`)}
                                </td>
                                <td style="padding: 8px; color: #334155;">
                                    ${day.code <= 3 ? 'Sunny/Clear' : (day.code <= 60 ? 'Cloudy' : 'Rain/Showers')}
                                </td>
                                <td style="padding: 8px; text-align: center; font-weight: 600;">
                                    ${Math.round(day.temp_min)}°C - ${Math.round(day.temp_max)}°C
                                </td>
                                <td style="padding: 8px; text-align: center; color: #64748b;">
                                    UV ${Math.floor(Math.random() * 5) + 1} / ${day.precipitation || 0}%
                                </td>
                                <td style="padding: 8px; color: #475569;">
                                    ${getPhase(new Date().getDate() + index)}
                                </td>
                                <td style="padding: 8px; text-align: right; color: #475569;">
                                    ${Math.round(day.wind_max || 12)}kph
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>

                <!-- Advisory Section -->
                <h3 style="color: #2563eb; font-size: 14px; text-transform: uppercase; margin-bottom: 10px;">FIELD-LEVEL AGRICULTURAL ADVISORY:</h3>
                <div style="border: 2px solid #2563eb; background: #eff6ff; border-radius: 8px; padding: 20px;">
                    <p style="margin: 0; color: #334155; line-height: 1.6; font-size: 13px;">
                        <strong>[GENERAL ADVICE]</strong> Favorable conditions for field operations. Maintain standard irrigation schedules. Monitor for pest activity given the humidity levels.
                        <br><br>
                        <strong>[CROP SPECIFIC]</strong> Ensure proper drainage if rain is expected. Apply fertilizers during clear sky windows for maximum efficiency.
                    </p>
                </div>
            `;
        } else {
            htmlContent += `
                <div style="margin-top: 50px; border-top: 1px solid #e2e8f0; padding-top: 20px; text-align: center; color: #94a3b8; font-size: 12px;">
                    <p>Generated by Smart Farming Assistant • helping farmers grow better</p>
                </div>
            `;
        }

        htmlContent += `
                <div style="margin-top: 60px; text-align: center; color: #94a3b8; font-size: 10px;">
                    Smart Farming Assistant - Generated via User Dashboard
                </div>
            `;

        // Generate PDF
        const element = document.createElement('div');
        element.innerHTML = htmlContent;
        // Adjusted width to prevent cutoff on right side (A4 is ~794px at 96dpi, but margins eat in)
        // 750px was still too wide. 625px is safer (794 - 96 = 698 max).
        element.style.width = '625px';

        const opt = {
            margin: [0.5, 0.5, 0.5, 0.5], // standard margins
            filename: `${reportName.toLowerCase().replace(/ /g, '_')}_${Date.now()}.pdf`,
            image: { type: 'jpeg', quality: 0.98 },
            html2canvas: { scale: 2, useCORS: true },
            jsPDF: { unit: 'in', format: 'a4', orientation: 'portrait' }
        };

        await html2pdf().set(opt).from(element).save();

        showToast('Report Generated Successfully!', 'success');

        const storageKey = 'last_gen_' + reportName.toLowerCase().replace(/ /g, '-');
        localStorage.setItem(storageKey, Date.now());
        updateLastGeneratedDates();

    } catch (e) {
        console.error(e);
        showToast(e.message || 'Error generating report', 'error');
    } finally {
        cardElement.classList.remove('report-loading');
        if (btnIcon) btnIcon.className = originalClass;
    }
}

function updateLastGeneratedDates() {
    const reportIds = ['crop-plan-pdf', 'harvest-report', 'profit-summary', 'market-report', 'weather-report'];
    reportIds.forEach(id => {
        const timestamp = localStorage.getItem(`last_gen_${id}`);
        const element = document.getElementById(`last-gen-${id}`);
        if (timestamp && element) {
            const diffDays = Math.floor((Date.now() - parseInt(timestamp)) / (1000 * 60 * 60 * 24));
            element.textContent = diffDays === 0 ? 'Last Generated: Today' : `Last Generated: ${diffDays} days ago`;
        }
    });
}

function resetCalculator() {
    ['seedCost', 'fertilizerCost', 'pesticideCost', 'irrigationCost', 'laborCost', 'machineryCost', 'otherCost', 'landArea', 'expectedYield', 'marketPrice'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.value = '';
    });
    calculateTotal();
}

/**
 * Weather Refresh
 */
function refreshWeather() {
    const card = document.querySelector('.weather-card');
    if (card) card.style.opacity = '0.7';

    fetch('/api/weather-update')
        .then(res => res.json())
        .then(data => {
            if (data.error) return;
            const c = data.current;
            const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
            set('weather-temp', Math.round(c.temperature) + '°C');
            set('weather-humidity', c.humidity + '%');
            set('weather-wind', c.wind_speed + ' km/h');
            set('weather-desc', c.condition);
            set('weather-location', c.location);
            set('weather-visibility', c.visibility + ' km');
            const icon = document.querySelector('.weather-icon-large');
            if (icon) icon.textContent = c.icon;

            // Update forecast section if available
            if (data.forecast) {
                const forecastSection = document.getElementById('weather-forecast-section');
                if (forecastSection) {
                    const forecastHTML = data.forecast.slice(0, 7).map(day => `
                        <div style="display: flex; align-items: center; justify-content: space-between; padding: 8px 10px; background: rgba(255,255,255,0.05); border-radius: 8px; font-size: 12px;">
                            <div style="flex: 1; font-weight: 600; color: rgba(255,255,255,0.9);">${day.day}</div>
                            <div style="flex: 0 0 30px; text-align: center; font-size: 18px;">${day.icon}</div>
                            <div style="flex: 2; text-align: center; font-size: 11px; color: rgba(255,255,255,0.7);">${day.condition.length > 15 ? day.condition.substring(0, 15) + '...' : day.condition}</div>
                            <div style="flex: 1; text-align: right;">
                                <span style="font-weight: 700; color: #fbbf24;">${day.high}°</span>
                                <span style="color: rgba(255,255,255,0.5); margin-left: 4px; font-size: 11px;">${day.low}°</span>
                            </div>
                            <div style="flex: 0 0 45px; text-align: right; font-size: 11px; color: #60a5fa;">
                                <i class="fas fa-tint"></i> ${day.rain_chance}%
                            </div>
                        </div>
                    `).join('');

                    const forecastContainer = forecastSection.querySelector('div[style*="flex-direction: column"]');
                    if (forecastContainer) {
                        forecastContainer.innerHTML = forecastHTML;
                    }
                }
            }

            if (card) card.style.opacity = '1';
        })
        .catch(() => { });
}

// Global Initialization
document.addEventListener('DOMContentLoaded', function () {
    // Sidebar Links Interaction
    const sidebarLinks = document.querySelectorAll('.sidebar-link');
    sidebarLinks.forEach(link => {
        link.addEventListener('click', function () {
            sidebarLinks.forEach(l => l.classList.remove('active'));
            this.classList.add('active');
        });
    });

    // Populate Commodity Select - All 71 Commodities with Categories
    const commodityCategories = {
        "🥬 Vegetables (30)": [
            "Tomato", "Onion", "Potato", "Brinjal", "Cabbage", "Cauliflower",
            "Carrot", "Beetroot", "Green Chilli", "Capsicum (Green)", "Capsicum (Red)",
            "Capsicum (Yellow)", "Beans", "Cluster Beans", "Lady Finger", "Drumstick",
            "Bottle Gourd", "Ridge Gourd", "Snake Gourd", "Bitter Gourd", "Pumpkin",
            "Ash Gourd", "Radish", "Turnip", "Sweet Corn", "Peas", "Garlic",
            "Ginger", "Coriander Leaves", "Spinach"
        ],
        "🍎 Fruits (20)": [
            "Apple", "Banana", "Orange", "Mosambi", "Grapes", "Pomegranate",
            "Papaya", "Pineapple", "Watermelon", "Muskmelon", "Mango", "Guava",
            "Lemon", "Custard Apple", "Sapota", "Strawberry", "Kiwi", "Pear",
            "Plum", "Peach"
        ],
        "🌾 Cereals (8)": [
            "Paddy (Rice – Common)", "Paddy (Basmati)", "Wheat", "Maize (Corn)", "Barley",
            "Jowar (Sorghum)", "Bajra (Pearl Millet)", "Ragi (Finger Millet)"
        ],
        "🌱 Pulses (7)": [
            "Red Gram (Tur/Arhar)", "Green Gram (Moong)", "Black Gram (Urad)", "Bengal Gram (Chana)",
            "Lentil (Masur)", "Horse Gram", "Field Pea"
        ],
        "🌰 Oilseeds (7)": [
            "Groundnut", "Mustard Seed", "Soybean", "Sunflower Seed", "Sesame (Gingelly)",
            "Castor Seed", "Linseed"
        ],
        "🧂 Spices (7)": [
            "Dry Chilli", "Turmeric", "Coriander Seed", "Cumin Seed (Jeera)", "Pepper (Black)",
            "Cardamom", "Clove"
        ],
        "🍬 Commercial (7)": [
            "Sugarcane", "Cotton", "Jute", "Copra (Dry Coconut)", "Tobacco", "Tea Leaves", "Coffee Beans"
        ],
        "🥜 Dry Fruits (6)": [
            "Coconut", "Cashew Nut", "Groundnut Kernel", "Almond", "Walnut", "Raisins"
        ],
        "🐄 Animal Products (6)": [
            "Milk", "Cow Ghee", "Buffalo Ghee", "Egg", "Poultry Chicken", "Fish (Common Varieties)"
        ]
    };

    const select = document.getElementById('commodity-select');
    if (select) {
        // Add each category as an optgroup
        Object.entries(commodityCategories).forEach(([category, items]) => {
            const optgroup = document.createElement('optgroup');
            optgroup.label = category;

            items.forEach(commodity => {
                const opt = document.createElement('option');
                opt.value = commodity;
                opt.textContent = commodity;
                opt.style.color = "#1e293b";
                optgroup.appendChild(opt);
            });

            select.appendChild(optgroup);
        });

        const def = dashboardData.defaultCommodity || 'Tomato';
        select.value = def;
        setTimeout(() => loadPriceTrend(def), 1000);
    }

    // Reports & Weather
    updateLastGeneratedDates();
    refreshWeather();
    setInterval(refreshWeather, 15 * 60 * 1000);

    // Form Submits
    const editForm = document.getElementById('editCropForm');
    if (editForm) {
        editForm.addEventListener('submit', function (e) {
            e.preventDefault();
            const id = document.getElementById('editCropId').value;
            const body = {
                stage: document.getElementById('editCropStage').value,
                notes: document.getElementById('editCropNotes').value
            };
            fetch('/growing/update/' + id, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            }).then(r => r.json()).then(d => { if (d.success) location.reload(); });
        });
    }
});

// Expose to Window for Inline HTML Handlers
Object.assign(window, {
    toggleSidebar, handleCropView, handleCropEdit, handleFertilizerView,
    openCropViewModal, closeCropViewModal, openCropEditModal, closeCropEditModal,
    openFertilizerViewModal, closeFertilizerViewModal, openAmazonLink, openIndiamartLink,
    toggleBuyDropdown, deleteCropActivity, deleteFertilizer, toggleChatbot, openChatbotModal,
    loadPriceTrend, viewTrend, handleChatKeypress, sendChatMessage, openProfileModal,
    closeProfileModal, openWeatherModal, closeWeatherModal, searchWeatherByCity,
    fetchWeatherByLocation, openCalculatorModal, closeCalculatorModal, openGovtSchemesModal,
    closeGovtSchemesModal, openEquipmentModal, closeEquipmentModal, openFarmersManualModal,
    closeFarmersManualModal, showManualSection, toggleEquipmentForm, submitEquipmentListing,
    rentEquipment, loadBenchmarkData, calculateTotal, calculateLoan, saveExpenseEntry,
    openDownloadModal, closeDownloadModal, exportToPDF, generateReport, resetCalculator,
    refreshWeather
});
