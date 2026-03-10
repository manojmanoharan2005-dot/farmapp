/* ============================================
   Tab Switcher JS
   Used by: purchase_history.html,
            equipment_rental_history.html
   ============================================ */

function showTab(tab) {
    var config = document.getElementById('tab-config');
    var tab1Id = config.getAttribute('data-tab1');
    var tab2Id = config.getAttribute('data-tab2');

    document.getElementById('section-' + tab1Id).style.display = (tab === tab1Id) ? 'block' : 'none';
    document.getElementById('section-' + tab2Id).style.display = (tab === tab2Id) ? 'block' : 'none';

    document.getElementById('tab-' + tab1Id).className = 'tab-btn ' + (tab === tab1Id ? 'active' : 'inactive');
    document.getElementById('tab-' + tab2Id).className = 'tab-btn ' + (tab === tab2Id ? 'active' : 'inactive');
}
