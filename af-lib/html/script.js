(function() {
    'use strict';

    var DOM = {
        notificationContainer: document.getElementById('notification-container'),
        progressContainer: document.getElementById('progress-container'),
        progressLabel: document.getElementById('progress-label'),
        progressBar: document.getElementById('progress-bar'),
        progressPercent: document.getElementById('progress-percent'),
        progressCancel: document.getElementById('progress-cancel'),
        dialogOverlay: document.getElementById('dialog-overlay'),
        dialogTitle: document.getElementById('dialog-title'),
        dialogBody: document.getElementById('dialog-body'),
        dialogConfirm: document.getElementById('dialog-confirm'),
        dialogCancel: document.getElementById('dialog-cancel'),
        dialogClose: document.getElementById('dialog-close'),
        menuOverlay: document.getElementById('menu-overlay'),
        menuTitle: document.getElementById('menu-title'),
        menuBody: document.getElementById('menu-body'),
        menuClose: document.getElementById('menu-close'),
        sliderOverlay: document.getElementById('slider-overlay'),
        sliderTitle: document.getElementById('slider-title'),
        sliderDescription: document.getElementById('slider-description'),
        sliderInput: document.getElementById('slider-input'),
        sliderValue: document.getElementById('slider-value'),
        sliderMinLabel: document.getElementById('slider-min-label'),
        sliderMaxLabel: document.getElementById('slider-max-label'),
        sliderConfirm: document.getElementById('slider-confirm'),
        sliderCancel: document.getElementById('slider-cancel'),
        sliderClose: document.getElementById('slider-close')
    };

    var progressInterval = null;
    var progressTimeout = null;
    var dialogId = null;
    var menuId = null;
    var sliderId = null;
    var isProgressActive = false;
    var progressRestartCallback = null;
    var progressId = null;

    // ========================================
    // NOTIFICATION
    // ========================================
    function showNotification(data) {
        if (!DOM.notificationContainer) return;

        var type = data.type || 'info';
        var iconMap = {
            success: 'fa-check-circle',
            error: 'fa-times-circle',
            warning: 'fa-exclamation-triangle',
            info: 'fa-info-circle'
        };
        var icon = iconMap[type] || 'fa-info-circle';

        var position = data.position || 'top-right';
        DOM.notificationContainer.setAttribute('data-position', position);

        var notif = document.createElement('div');
        notif.className = 'notification notification-' + type;

        notif.innerHTML = `
            <div class="notification-wrapper">
                <div class="notification-line"></div>
                <div class="notification-content">
                    <div class="notification-title">${data.title || 'Info'}</div>
                    <div class="notification-text">${data.text || ''}</div>
                </div>
                <div class="notification-icon notification-icon-${type}">
                    <i class="fas ${icon}"></i>
                </div>
            </div>
            <div class="notification-cooldown notification-cooldown-${type}">
                <div class="notification-cooldown-bar" style="width: 100%;"></div>
            </div>
        `;

        DOM.notificationContainer.appendChild(notif);

        var duration = data.duration || 3000;
        var cooldownBar = notif.querySelector('.notification-cooldown-bar');
        var startTime = Date.now();

        var cooldownInterval = setInterval(function() {
            var elapsed = Date.now() - startTime;
            var remaining = Math.max(0, 1 - (elapsed / duration));
            cooldownBar.style.width = (remaining * 100) + '%';
        }, 50);

        setTimeout(function() {
            clearInterval(cooldownInterval);
            notif.classList.add('fade-out');
            setTimeout(function() {
                if (notif.parentNode) notif.remove();
            }, 300);
        }, duration);
    }

    // ========================================
    // PROGRESS BAR - FIXED
    // ========================================
    function showProgress(data) {
        if (!DOM.progressContainer) return;

        var duration = data.duration || 3000;
        var label = data.label || 'Processing...';
        var isLast = data.isLast || false;
        var canCancel = data.canCancel !== undefined ? data.canCancel : true;
        var callback = data.restartCallback || null;
        progressId = data.id || null;

        // Tampilkan atau sembunyikan tombol cancel
        if (DOM.progressCancel) {
            if (canCancel) {
                DOM.progressCancel.style.display = 'flex';
                DOM.progressCancel.style.opacity = '1';
            } else {
                DOM.progressCancel.style.display = 'none';
                DOM.progressCancel.style.opacity = '0';
            }
        }

        // Jika progress sudah aktif, reset dan mulai ulang
        if (isProgressActive) {
            if (progressInterval) {
                clearInterval(progressInterval);
                progressInterval = null;
            }
            if (progressTimeout) {
                clearTimeout(progressTimeout);
                progressTimeout = null;
            }

            DOM.progressBar.style.width = '0%';
            DOM.progressPercent.textContent = '0%';
            DOM.progressLabel.textContent = label;
            progressRestartCallback = callback;

            DOM.progressContainer.style.display = 'block';
            DOM.progressContainer.style.opacity = '1';
            DOM.progressContainer.classList.remove('fade-out');
            
            startProgressAnimation(duration, isLast);
            return;
        }

        isProgressActive = true;
        progressRestartCallback = callback;

        DOM.progressLabel.textContent = label;
        DOM.progressBar.style.width = '0%';
        DOM.progressPercent.textContent = '0%';

        DOM.progressContainer.style.display = 'block';
        DOM.progressContainer.style.opacity = '1';
        DOM.progressContainer.classList.remove('fade-out');
        DOM.progressContainer.style.animation = 'none';
        DOM.progressContainer.offsetHeight;
        DOM.progressContainer.style.animation = 'scaleIn 0.25s ease forwards';

        startProgressAnimation(duration, isLast);
    }

    function startProgressAnimation(duration, isLast) {
        var progress = 0;
        var interval = 50;
        var step = (interval / duration) * 100;

        if (progressInterval) {
            clearInterval(progressInterval);
            progressInterval = null;
        }

        progressInterval = setInterval(function() {
            progress += step;
            if (progress >= 100) {
                progress = 100;
                DOM.progressBar.style.width = progress + '%';
                DOM.progressPercent.textContent = Math.round(progress) + '%';
                
                clearInterval(progressInterval);
                progressInterval = null;
                
                if (isLast) {
                    if (progressTimeout) {
                        clearTimeout(progressTimeout);
                        progressTimeout = null;
                    }
                    
                    progressTimeout = setTimeout(function() {
                        hideProgress();
                        
                        fetch('https://af-lib/progressComplete', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ 
                                id: progressId,
                                success: true 
                            })
                        });
                    }, 300);
                } else {
                    DOM.progressContainer.classList.add('fade-out');
                    
                    if (progressTimeout) {
                        clearTimeout(progressTimeout);
                        progressTimeout = null;
                    }
                    
                    progressTimeout = setTimeout(function() {
                        DOM.progressContainer.style.display = 'none';
                        DOM.progressContainer.classList.remove('fade-out');
                        
                        DOM.progressBar.style.width = '0%';
                        DOM.progressPercent.textContent = '0%';
                        
                        fetch('https://af-lib/progressComplete', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ 
                                id: progressId,
                                success: true 
                            })
                        });
                    }, 300);
                }
                return;
            }
            DOM.progressBar.style.width = progress + '%';
            DOM.progressPercent.textContent = Math.round(progress) + '%';
        }, interval);
    }

    function hideProgress() {
        if (progressInterval) {
            clearInterval(progressInterval);
            progressInterval = null;
        }
        if (progressTimeout) {
            clearTimeout(progressTimeout);
            progressTimeout = null;
        }
        if (DOM.progressContainer) {
            DOM.progressContainer.classList.add('fade-out');
            setTimeout(function() {
                DOM.progressContainer.style.display = 'none';
                DOM.progressContainer.classList.remove('fade-out');
                isProgressActive = false;
                progressRestartCallback = null;
            }, 300);
        } else {
            isProgressActive = false;
            progressRestartCallback = null;
        }
    }

    // ========================================
    // DIALOG
    // ========================================
    function showDialog(data) {
        if (!DOM.dialogOverlay) return;

        dialogId = data.id || null;
        DOM.dialogTitle.textContent = data.title || 'Input';
        DOM.dialogBody.innerHTML = '';

        if (data.inputs && data.inputs.length > 0) {
            for (var i = 0; i < data.inputs.length; i++) {
                var input = data.inputs[i];
                
                var group = document.createElement('div');
                group.className = 'dialog-input-group';

                var label = document.createElement('label');
                label.textContent = input.label || '';
                group.appendChild(label);

                var element = null;

                if (input.type === 'select') {
                    element = document.createElement('select');
                    if (input.options) {
                        for (var j = 0; j < input.options.length; j++) {
                            var option = document.createElement('option');
                            option.value = input.options[j];
                            option.textContent = input.options[j];
                            element.appendChild(option);
                        }
                    }
                } else if (input.type === 'textarea') {
                    element = document.createElement('textarea');
                    element.placeholder = input.placeholder || '';
                    element.rows = input.rows || 3;
                } else if (input.type === 'number') {
                    element = document.createElement('input');
                    element.type = 'number';
                    element.placeholder = input.placeholder || '';
                    element.step = input.step || 'any';
                    element.min = input.min || '';
                    element.max = input.max || '';
                } else {
                    element = document.createElement('input');
                    element.type = input.type || 'text';
                    element.placeholder = input.placeholder || '';
                }

                group.appendChild(element);
                DOM.dialogBody.appendChild(group);
            }
        }

        DOM.dialogOverlay.style.display = 'flex';

        setTimeout(function() {
            var firstInput = DOM.dialogBody.querySelector('input, select, textarea');
            if (firstInput) firstInput.focus();
        }, 150);
    }

    function closeDialog(canceled) {
        if (!DOM.dialogOverlay) return;
        
        var results = null;
        if (!canceled) {
            var inputs = DOM.dialogBody.querySelectorAll('input, select, textarea');
            results = [];
            for (var i = 0; i < inputs.length; i++) {
                results.push(inputs[i].value);
            }
        }

        DOM.dialogOverlay.style.display = 'none';

        fetch('https://af-lib/dialogResult', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: dialogId, result: results })
        });
        dialogId = null;
    }

    // ========================================
    // MENU
    // ========================================
    function showMenu(data) {
        if (!DOM.menuOverlay) return;

        menuId = data.id || null;
        DOM.menuTitle.textContent = data.title || 'Menu';
        DOM.menuBody.innerHTML = '';

        if (data.options && data.options.length > 0) {
            for (var i = 0; i < data.options.length; i++) {
                var option = data.options[i];
                var item = document.createElement('div');
                item.className = 'menu-option';
                item.innerHTML = `
                    <div class="left">
                        <div class="icon"><i class="${option.icon || 'fa-solid fa-circle'}"></i></div>
                        <div class="info">
                            <div class="name">${option.title || ''}</div>
                            ${option.description ? '<div class="sub">' + option.description + '</div>' : ''}
                        </div>
                    </div>
                    <div class="right"><i class="fas fa-chevron-right"></i></div>
                `;

                (function(opt) {
                    item.onclick = function() {
                        var result = opt.value !== undefined ? opt.value : opt.title;
                        fetch('https://af-lib/menuResult', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ id: menuId, result: result })
                        });
                        closeMenu();
                    };
                })(option);

                DOM.menuBody.appendChild(item);
            }
        }

        DOM.menuOverlay.style.display = 'flex';
    }

    function closeMenu() {
        if (!DOM.menuOverlay) return;
        DOM.menuOverlay.style.display = 'none';
        if (menuId) {
            fetch('https://af-lib/menuResult', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id: menuId, result: null })
            });
            menuId = null;
        }
    }

    // ========================================
    // SLIDER
    // ========================================
    function showSlider(data) {
        if (!DOM.sliderOverlay) return;

        sliderId = data.id || null;
        DOM.sliderTitle.textContent = data.title || 'Slider';
        DOM.sliderDescription.textContent = data.description || '';

        var min = data.min || 0;
        var max = data.max || 100;
        var step = data.step || 1;
        var defaultValue = data.default || 0;

        DOM.sliderInput.min = min;
        DOM.sliderInput.max = max;
        DOM.sliderInput.step = step;
        DOM.sliderInput.value = defaultValue;
        DOM.sliderValue.textContent = defaultValue;
        DOM.sliderMinLabel.textContent = min;
        DOM.sliderMaxLabel.textContent = max;

        DOM.sliderInput.oninput = function() {
            DOM.sliderValue.textContent = this.value;
        };

        DOM.sliderOverlay.style.display = 'flex';
    }

    function closeSlider(canceled) {
        if (!DOM.sliderOverlay) return;
        DOM.sliderOverlay.style.display = 'none';

        var value = null;
        if (!canceled) {
            value = parseInt(DOM.sliderInput.value);
        }

        fetch('https://af-lib/sliderResult', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: sliderId, result: value })
        });
        sliderId = null;
    }

    // ========================================
    // NUI LISTENER
    // ========================================
    window.addEventListener('message', function(event) {
        var data = event.data;
        if (!data || !data.action) return;
        
        switch(data.action) {
            case 'showNotification': 
                showNotification(data.data); 
                break;
            case 'showProgress': 
                showProgress(data.data); 
                break;
            case 'showDialog': 
                showDialog(data.data); 
                break;
            case 'showMenu': 
                showMenu(data.data); 
                break;
            case 'showSlider': 
                showSlider(data.data); 
                break;
            case 'hideProgress': 
                hideProgress(); 
                break;
        }
    });

    // ========================================
    // EVENT LISTENERS
    // ========================================

    // ===== PROGRESS CANCEL (Tombol UI) =====
    if (DOM.progressCancel) {
        DOM.progressCancel.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            if (!isProgressActive) return;
            
            fetch('https://af-lib/progressCancel', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    id: progressId 
                })
            });
            
            hideProgress();
        });
    }

    // ===== DIALOG =====
    if (DOM.dialogConfirm) {
        DOM.dialogConfirm.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            closeDialog(false);
        });
    }

    if (DOM.dialogCancel) {
        DOM.dialogCancel.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            closeDialog(true);
        });
    }

    if (DOM.dialogClose) {
        DOM.dialogClose.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            closeDialog(true);
        });
    }

    // ===== MENU =====
    if (DOM.menuClose) {
        DOM.menuClose.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            closeMenu();
        });
    }

    // ===== SLIDER =====
    if (DOM.sliderConfirm) {
        DOM.sliderConfirm.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            closeSlider(false);
        });
    }

    if (DOM.sliderCancel) {
        DOM.sliderCancel.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            closeSlider(true);
        });
    }

    if (DOM.sliderClose) {
        DOM.sliderClose.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            closeSlider(true);
        });
    }

    // Fallback: keyup event juga
    document.addEventListener('keyup', function(event) {
        if ((event.key === 'x' || event.key === 'X') && isProgressActive) {
            event.preventDefault();
            event.stopPropagation();
            
            console.log('Key X released - Cancelling progress');
            
            fetch('https://af-lib/progressCancel', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    id: progressId 
                })
            });
            
            hideProgress();
            return;
        }
    }, true);

    // ========================================
    // KEYBOARD SHORTCUTS (X untuk cancel progress)
    // ========================================
    document.addEventListener('keydown', function(event) {
        // Tombol X untuk cancel progress (hanya jika progress aktif)
        if ((event.key === 'x' || event.key === 'X') && isProgressActive) {
            event.preventDefault();
            event.stopPropagation();
            
            console.log('Key X pressed - Cancelling progress');
            
            fetch('https://af-lib/progressCancel', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    id: progressId 
                })
            });
            
            hideProgress();
            return;
        }

        // ESC untuk close dialog/menu/slider
        if (event.key !== 'Escape') return;

        if (DOM.dialogOverlay && DOM.dialogOverlay.style.display === 'flex') {
            event.preventDefault();
            event.stopPropagation();
            closeDialog(true);
        } else if (DOM.menuOverlay && DOM.menuOverlay.style.display === 'flex') {
            event.preventDefault();
            event.stopPropagation();
            closeMenu();
        } else if (DOM.sliderOverlay && DOM.sliderOverlay.style.display === 'flex') {
            event.preventDefault();
            event.stopPropagation();
            closeSlider(true);
        }
    }, true); // <- Gunakan capture phase agar event pasti tertangkap               

    console.log('AF-Lib UI Loaded');

})();