// BloomTrack Frontend Application Engine
const API_BASE = window.location.origin.includes(':3000') || window.location.origin.includes(':8080')
  ? 'http://127.0.0.1:8000/api/v1'
  : '/api/v1';

const state = {
  token: localStorage.getItem('bloomtrack_token') || null,
  user: null,
  currentView: 'dashboard',
  currentDate: new Date().toISOString().split('T')[0],
  dashboardSummary: null,
  tasks: [],
  habits: [],
  gateSubjects: [],
  semesterSubjects: [],
  workouts: [],
};

// --- API Client ---
async function api(endpoint, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...options.headers };
  if (state.token) {
    headers['Authorization'] = `Bearer ${state.token}`;
  }

  try {
    const res = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
    if (res.status === 401 && !endpoint.includes('/auth/login') && !endpoint.includes('/auth/register')) {
      logout();
      showToast('Session expired. Please log in again.', 'info');
      return null;
    }
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: 'API Request failed' }));
      throw new Error(err.detail || 'Request failed');
    }
    return await res.json();
  } catch (error) {
    console.error(`API Error on ${endpoint}:`, error);
    showToast(error.message, 'error');
    throw error;
  }
}

// --- Toast Notifications ---
function showToast(message, type = 'info') {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `<i class="fa-solid fa-${type === 'success' ? 'circle-check' : type === 'error' ? 'circle-exclamation' : 'circle-info'}"></i> <span>${message}</span>`;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// --- Auth Handling ---
async function autoAuthenticate() {
  if (state.token) {
    try {
      const user = await api('/auth/me');
      if (user) {
        state.user = user;
        updateUserUI();
        return;
      }
    } catch (e) {
      // Fallback
    }
  }

  // Auto-login default user for frictionless out-of-the-box demo
  try {
    const form = new URLSearchParams();
    form.append('username', 'user@bloomtrack.com');
    form.append('password', 'SecretPassword123!');
    const res = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: form.toString()
    });
    if (res.ok) {
      const data = await res.json();
      state.token = data.access_token;
      localStorage.setItem('bloomtrack_token', state.token);
      state.user = await api('/auth/me');
      updateUserUI();
      return;
    }
  } catch (e) {}

  // If not existing, register default user
  try {
    const regRes = await fetch(`${API_BASE}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'user@bloomtrack.com',
        password: 'SecretPassword123!',
        full_name: 'BloomTrack Wellness'
      })
    });
    if (regRes.ok) {
      const data = await regRes.json();
      state.token = data.access_token;
      localStorage.setItem('bloomtrack_token', state.token);
      state.user = await api('/auth/me');
      updateUserUI();
    }
  } catch (e) {
    console.error('Registration fallback failed', e);
  }
}

function updateUserUI() {
  if (state.user) {
    document.getElementById('user-display-name').textContent = state.user.full_name;
    document.getElementById('user-display-email').textContent = state.user.email;
    document.getElementById('topbar-greeting').textContent = `Welcome, ${state.user.full_name.split(' ')[0]}!`;
  }
}

function logout() {
  state.token = null;
  state.user = null;
  localStorage.removeItem('bloomtrack_token');
  document.getElementById('user-display-name').textContent = 'Guest';
  document.getElementById('user-display-email').textContent = 'Not logged in';
  openAuthModal();
}

// --- Navigation & Routing ---
function initNavigation() {
  document.querySelectorAll('.sidebar-nav .nav-item, .mobile-bottom-nav .mobile-nav-item').forEach(btn => {
    btn.addEventListener('click', () => {
      const view = btn.dataset.view;
      switchView(view);
    });
  });

  const sidebarToggle = document.getElementById('mobile-sidebar-toggle');
  const sidebar = document.getElementById('sidebar');
  sidebarToggle.addEventListener('click', () => {
    sidebar.classList.toggle('mobile-open');
  });

  document.getElementById('btn-logout-toggle').addEventListener('click', () => {
    if (confirm('Log out of BloomTrack?')) {
      logout();
    }
  });

  document.getElementById('btn-quick-log').addEventListener('click', openQuickLogModal);
  document.getElementById('btn-notifications-dialog').addEventListener('click', openNotificationsModal);

  // Set date display
  const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
  document.getElementById('topbar-date').textContent = new Date().toLocaleDateString('en-IN', options);
}

function switchView(viewName) {
  state.currentView = viewName;
  document.querySelectorAll('.sidebar-nav .nav-item').forEach(el => {
    el.classList.toggle('active', el.dataset.view === viewName);
  });
  document.querySelectorAll('.mobile-bottom-nav .mobile-nav-item').forEach(el => {
    el.classList.toggle('active', el.dataset.view === viewName);
  });
  
  // Close mobile sidebar if open
  document.getElementById('sidebar').classList.remove('mobile-open');

  renderCurrentView();
}

// --- View Renderers ---
async function renderCurrentView() {
  const viewport = document.getElementById('viewport');
  viewport.innerHTML = '<div style="text-align:center; padding: 40px;"><i class="fa-solid fa-spinner fa-spin fa-2x" style="color:var(--primary)"></i></div>';

  switch (state.currentView) {
    case 'dashboard':
      await renderDashboardView(viewport);
      break;
    case 'tasks':
      await renderTasksView(viewport);
      break;
    case 'habits':
      await renderHabitsView(viewport);
      break;
    case 'health':
      await renderHealthView(viewport);
      break;
    case 'digestive':
      await renderDigestiveView(viewport);
      break;
    case 'workouts':
      await renderWorkoutsView(viewport);
      break;
    case 'gate':
      await renderGateView(viewport);
      break;
    case 'semester':
      await renderSemesterView(viewport);
      break;
    case 'excelr':
      await renderExcelRView(viewport);
      break;
    case 'settings':
      await renderSettingsView(viewport);
      break;
    default:
      viewport.innerHTML = '<p>View not found.</p>';
  }
}

// 1. Dashboard View
async function renderDashboardView(container) {
  try {
    const summary = await api(`/analytics/dashboard-summary?target_date=${state.currentDate}`);
    const consistency = await api('/analytics/weekly-consistency');
    const tasks = await api(`/tasks?target_date=${state.currentDate}`);
    state.dashboardSummary = summary;
    state.tasks = tasks;

    // Update tasks badge
    document.getElementById('tasks-badge').textContent = summary.pending_tasks_today;

    const waterRadius = 38;
    const waterCircumference = 2 * Math.PI * waterRadius;
    const waterPercent = Math.min(100, Math.round((summary.water_intake_today_ml / summary.water_target_ml) * 100));
    const waterOffset = waterCircumference - (waterPercent / 100) * waterCircumference;

    const taskRadius = 38;
    const taskCircumference = 2 * Math.PI * taskRadius;
    const taskPercent = Math.round(summary.completion_percentage);
    const taskOffset = taskCircumference - (taskPercent / 100) * taskCircumference;

    container.innerHTML = `
      <div class="dashboard-grid">
        
        <!-- Top Stats Row -->
        <div class="col-3 card stat-card">
          <div class="stat-icon tasks"><i class="fa-solid fa-list-check"></i></div>
          <div class="stat-content">
            <span class="stat-label">Today's Tasks</span>
            <div class="stat-value">${summary.completed_tasks_today} / ${summary.total_tasks_today}</div>
            <span class="stat-sub">${summary.completion_percentage}% Done</span>
          </div>
        </div>

        <div class="col-3 card stat-card">
          <div class="stat-icon water"><i class="fa-solid fa-droplet"></i></div>
          <div class="stat-content">
            <span class="stat-label">Hydration</span>
            <div class="stat-value">${summary.water_intake_today_ml} <span style="font-size:0.9rem">ml</span></div>
            <span class="stat-sub">Target: ${summary.water_target_ml} ml</span>
          </div>
        </div>

        <div class="col-3 card stat-card">
          <div class="stat-icon weight"><i class="fa-solid fa-scale-balanced"></i></div>
          <div class="stat-content">
            <span class="stat-label">Current Weight</span>
            <div class="stat-value">${summary.current_weight_kg} <span style="font-size:0.9rem">kg</span></div>
            <span class="stat-sub">Goal: ${summary.target_weight_kg} kg</span>
          </div>
        </div>

        <div class="col-3 card stat-card">
          <div class="stat-icon study"><i class="fa-solid fa-graduation-cap"></i></div>
          <div class="stat-content">
            <span class="stat-label">GATE CS Covered</span>
            <div class="stat-value">${summary.gate_topics_completed} / ${summary.gate_total_topics}</div>
            <span class="stat-sub">Official Syllabus</span>
          </div>
        </div>

        <!-- Main Today Routine & Progress Rings -->
        <div class="col-7 card">
          <div class="card-header">
            <h2 class="card-title"><i class="fa-solid fa-sun"></i> Today's Schedule & Routine</h2>
            <button class="btn-primary-sm" onclick="openAddTaskModal()"><i class="fa-solid fa-plus"></i> Add Task</button>
          </div>

          <div class="task-list" id="dashboard-task-list">
            ${tasks.slice(0, 7).map(t => `
              <div class="task-item ${t.is_completed ? 'completed' : ''}" data-id="${t.id}">
                <input type="checkbox" class="task-checkbox" ${t.is_completed ? 'checked' : ''} onchange="toggleTaskCompletion(${t.id})">
                <div class="task-details">
                  <div class="task-title">${t.title}</div>
                  <div class="task-meta">
                    <span class="task-time"><i class="fa-regular fa-clock"></i> ${t.scheduled_time || 'Anytime'}</span>
                    <span class="task-category-pill">${t.category}</span>
                  </div>
                </div>
              </div>
            `).join('')}
          </div>

          ${tasks.length > 7 ? `
            <div style="text-align:center; margin-top:16px;">
              <button class="btn-secondary" onclick="switchView('tasks')">View All ${tasks.length} Routine Tasks →</button>
            </div>
          ` : ''}
        </div>

        <!-- Right Side Widgets (Hydration, ExcelR, Health) -->
        <div class="col-5">
          <div class="card" style="margin-bottom:24px;">
            <div class="card-header">
              <h2 class="card-title"><i class="fa-solid fa-glass-water"></i> Hydration Ring</h2>
              <span class="card-badge">${waterPercent}%</span>
            </div>
            
            <div class="progress-ring-container">
              <div class="progress-circle">
                <svg>
                  <circle class="circle-bg" cx="45" cy="45" r="${waterRadius}"></circle>
                  <circle class="circle-bar" cx="45" cy="45" r="${waterRadius}" style="stroke-dasharray: ${waterCircumference}; stroke-dashoffset: ${waterOffset}; stroke: #3a86ff;"></circle>
                </svg>
                <div class="progress-text" style="color: #3a86ff">${waterPercent}%</div>
              </div>
              <div>
                <div style="font-weight:700; font-size:1.1rem; color:var(--text-main);">${summary.water_intake_today_ml} ml logged</div>
                <div style="font-size:0.8rem; color:var(--text-muted); margin-top:2px;">Target: ${summary.water_target_ml} ml</div>
                <div class="quick-water-buttons">
                  <button class="btn-water-quick" onclick="quickAddWater(250)"><i class="fa-solid fa-plus"></i> 250ml</button>
                  <button class="btn-water-quick" onclick="quickAddWater(500)"><i class="fa-solid fa-plus"></i> 500ml</button>
                </div>
              </div>
            </div>
          </div>

          <!-- ExcelR Training Banner -->
          <div class="card" style="margin-bottom:24px; border-left: 4px solid var(--primary);">
            <div class="card-header">
              <h2 class="card-title"><i class="fa-solid fa-laptop-code"></i> ExcelR Training Today</h2>
              <span class="card-badge" style="background:#eaf4f0; color:var(--primary); font-weight:700;">17:00 – 20:00</span>
            </div>
            <p style="font-size:0.86rem; color:var(--text-muted);">
              ${new Date().getDay() === 0 ? 'Sunday is a recovery holiday. No class scheduled.' : 'Placement technical class & coding exercises.'}
            </p>
            <div style="margin-top:14px; display:flex; gap:10px;">
              <button class="btn-primary-sm" onclick="switchView('excelr')">View Placement Tracker</button>
            </div>
          </div>

          <!-- Weekly Consistency Mini Chart -->
          <div class="card">
            <div class="card-header">
              <h2 class="card-title"><i class="fa-solid fa-chart-simple"></i> Weekly Consistency</h2>
            </div>
            <div class="consistency-chart">
              ${consistency.map(d => `
                <div class="chart-bar-group">
                  <div class="chart-bar-track" title="${d.date}: ${d.completion_percentage}%">
                    <div class="chart-bar-fill" style="height: ${Math.max(8, d.completion_percentage)}%;"></div>
                  </div>
                  <span class="chart-day-label">${d.day_name}</span>
                </div>
              `).join('')}
            </div>
          </div>

        </div>

      </div>
    `;
  } catch (e) {
    container.innerHTML = `<div class="card"><p>Failed to load dashboard. Please verify server connection.</p></div>`;
  }
}

// 2. Tasks / Routine View
async function renderTasksView(container) {
  const tasks = await api(`/tasks?target_date=${state.currentDate}`);
  state.tasks = tasks;

  container.innerHTML = `
    <div class="card">
      <div class="card-header">
        <div>
          <h2 class="card-title"><i class="fa-solid fa-list-check"></i> Daily Routine Schedule</h2>
          <p style="font-size:0.82rem; color:var(--text-muted); margin-top:4px;">Asia/Kolkata timezone. Ticking a checkbox immediately saves completion to the persistent database.</p>
        </div>
        <div style="display:flex; gap:10px;">
          <input type="date" class="form-input" style="width:auto; padding:6px 12px;" value="${state.currentDate}" onchange="changeDate(this.value)">
          <button class="btn-primary-sm" onclick="openAddTaskModal()"><i class="fa-solid fa-plus"></i> New Task</button>
        </div>
      </div>

      <div class="task-list">
        ${tasks.map(t => `
          <div class="task-item ${t.is_completed ? 'completed' : ''}" data-id="${t.id}">
            <input type="checkbox" class="task-checkbox" ${t.is_completed ? 'checked' : ''} onchange="toggleTaskCompletion(${t.id})">
            <div class="task-details">
              <div class="task-title">${t.title}</div>
              <div class="task-meta">
                <span class="task-time"><i class="fa-regular fa-clock"></i> ${t.scheduled_time || 'Anytime'}</span>
                <span class="task-category-pill">${t.category}</span>
                ${t.notes ? `<span style="font-style:italic;">— ${t.notes}</span>` : ''}
              </div>
            </div>
            <div>
              <button style="background:none; border:none; color:var(--text-light); cursor:pointer; padding:6px;" onclick="rescheduleTaskPrompt(${t.id})" title="Reschedule"><i class="fa-regular fa-calendar"></i></button>
              <button style="background:none; border:none; color:var(--text-light); cursor:pointer; padding:6px;" onclick="deleteTask(${t.id})" title="Delete"><i class="fa-regular fa-trash-can"></i></button>
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

// 3. Habits & Streaks View
async function renderHabitsView(container) {
  const habits = await api(`/habits?target_date=${state.currentDate}`);
  const heatmap = await api('/habits/heatmap');

  container.innerHTML = `
    <div class="card" style="margin-bottom:24px;">
      <div class="card-header">
        <div>
          <h2 class="card-title"><i class="fa-solid fa-fire" style="color:var(--accent-amber)"></i> Daily Habits & Streaks</h2>
          <p style="font-size:0.82rem; color:var(--text-muted); margin-top:2px;">Consistent daily actions create long-term transformation.</p>
        </div>
      </div>

      <div style="display:grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap:16px;">
        ${habits.map(h => `
          <div class="task-item" style="justify-content:space-between; padding:16px;">
            <div style="display:flex; align-items:center; gap:12px;">
              <button onclick="toggleHabit(${h.id})" style="background:${h.today_completed ? 'var(--primary)' : 'white'}; border: 2px solid var(--primary); color:${h.today_completed ? 'white' : 'transparent'}; width:28px; height:28px; border-radius:8px; cursor:pointer; display:flex; align-items:center; justify-content:center; font-weight:bold;">✓</button>
              <div>
                <div style="font-weight:600; font-size:0.92rem; color:var(--text-main);">${h.title}</div>
                <div style="font-size:0.75rem; color:var(--text-muted);">${h.category} • Target ${h.target_days_per_week}d/week</div>
              </div>
            </div>
            <div style="display:flex; align-items:center; gap:6px; font-weight:700; color:var(--accent-amber); font-size:0.9rem;">
              <i class="fa-solid fa-fire"></i> ${h.current_streak}d
            </div>
          </div>
        `).join('')}
      </div>
    </div>

    <!-- 28-day Heatmap -->
    <div class="card">
      <div class="card-header">
        <h2 class="card-title"><i class="fa-solid fa-calendar-days"></i> 28-Day Habit Consistency Heatmap</h2>
      </div>
      <div class="heatmap-grid">
        ${heatmap.map(c => `
          <div class="heatmap-cell ${c.count >= 6 ? 'level-3' : c.count >= 3 ? 'level-2' : c.count >= 1 ? 'level-1' : ''}" title="${c.date}: ${c.count} habits completed">
            ${c.count}
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

// 4. PCOD, Menstrual & Wellness View
async function renderHealthView(container) {
  const analysis = await api('/health/cycle-analysis');
  const weightProg = await api('/weight/progress');

  container.innerHTML = `
    <!-- Educational Disclaimer Banner -->
    <div class="alert-banner info">
      <i class="fa-solid fa-circle-info"></i>
      <div>
        <strong>PCOD Wellness & Cycle Tracking Advisory</strong><br>
        Because cycles in PCOD typically occur every 2–3 months, 28-day calendar predictions are avoided. BloomTrack logs your historical symptoms without attempting automated medical diagnosis.
      </div>
    </div>

    ${analysis.needs_consultation_alert ? `
      <div class="alert-banner warning">
        <i class="fa-solid fa-triangle-exclamation"></i>
        <div>
          <strong>90-Day Cycle Reminder</strong><br>
          It has been ${analysis.days_since_last_period} days since your last recorded period. Clinical guidelines advise discussing intervals exceeding 90 days with your gynecologist or healthcare clinician.
        </div>
      </div>
    ` : ''}

    <div class="dashboard-grid">
      <!-- Cycle Status Card -->
      <div class="col-6 card">
        <div class="card-header">
          <h2 class="card-title"><i class="fa-solid fa-heart-pulse"></i> Menstrual Health History</h2>
          <button class="btn-primary-sm" onclick="openLogPeriodModal()"><i class="fa-solid fa-plus"></i> Log Period</button>
        </div>
        <div style="margin-bottom:16px;">
          <div style="font-size:0.85rem; color:var(--text-muted);">Days Since Last Period:</div>
          <div style="font-size:2.2rem; font-family:var(--font-heading); font-weight:700; color:var(--primary);">${analysis.days_since_last_period !== null ? analysis.days_since_last_period + ' days' : 'No entries logged yet'}</div>
          <div style="font-size:0.8rem; color:var(--text-light); margin-top:4px;">Average Interval: ${analysis.average_interval_days ? analysis.average_interval_days + ' days' : 'N/A'}</div>
        </div>

        <div style="font-size:0.88rem; font-weight:600; margin-bottom:8px;">Recent Cycles:</div>
        <div style="display:flex; flex-direction:column; gap:8px;">
          ${analysis.cycle_history.length > 0 ? analysis.cycle_history.map(c => `
            <div style="padding:10px 14px; background:#fbfcfb; border:1px solid var(--border-color); border-radius:var(--radius-sm); display:flex; justify-content:space-between; font-size:0.85rem;">
              <span>${c.from_date} → ${c.to_date}</span>
              <span style="font-weight:600; color:var(--primary);">${c.interval_days} days</span>
            </div>
          `).join('') : '<p style="font-size:0.85rem; color:var(--text-muted);">Log your bleeding dates to view interval charts.</p>'}
        </div>
      </div>

      <!-- Weight & Metric Card -->
      <div class="col-6 card">
        <div class="card-header">
          <h2 class="card-title"><i class="fa-solid fa-weight-scale"></i> Weight & Progress</h2>
          <button class="btn-primary-sm" onclick="openLogWeightModal()"><i class="fa-solid fa-plus"></i> Log Weight</button>
        </div>
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:16px;">
          <div>
            <span style="font-size:0.82rem; color:var(--text-muted);">Starting</span>
            <div style="font-weight:700; font-size:1.2rem;">${weightProg.starting_weight_kg} kg</div>
          </div>
          <div style="text-align:center;">
            <span style="font-size:0.82rem; color:var(--text-muted);">Current</span>
            <div style="font-weight:700; font-size:1.6rem; color:var(--primary);">${weightProg.current_weight_kg} kg</div>
          </div>
          <div style="text-align:right;">
            <span style="font-size:0.82rem; color:var(--text-muted);">Long-term Target</span>
            <div style="font-weight:700; font-size:1.2rem;">${weightProg.target_weight_kg} kg</div>
          </div>
        </div>

        <!-- Progress bar -->
        <div style="background:#eef3f0; border-radius:999px; height:12px; overflow:hidden; margin-bottom:10px;">
          <div style="background:linear-gradient(90deg, var(--primary-light), var(--primary)); width:${weightProg.progress_percentage}%; height:100%;"></div>
        </div>
        <div style="display:flex; justify-content:space-between; font-size:0.8rem; color:var(--text-muted);">
          <span>Lost: ${weightProg.weight_lost_kg} kg</span>
          <span>${weightProg.progress_percentage}% toward goal</span>
          <span>Remaining: ${weightProg.remaining_kg} kg</span>
        </div>

        <p style="font-size:0.8rem; color:var(--text-light); margin-top:16px; font-style:italic;">
          "${weightProg.philosophy}"
        </p>
      </div>

    </div>
  `;
}

// 5. Digestive & Gut Health View
async function renderDigestiveView(container) {
  const summary = await api('/digestive/summary');
  const guidance = await api('/digestive/guidance');
  const entries = await api('/digestive/entries?limit=10');

  container.innerHTML = `
    <div class="alert-banner warning">
      <i class="fa-solid fa-shield-heart"></i>
      <div>${guidance.safety_red_flags}</div>
    </div>

    <div class="dashboard-grid">
      <div class="col-7 card">
        <div class="card-header">
          <h2 class="card-title"><i class="fa-solid fa-hand-holding-medical"></i> Digestive Log & Symptoms</h2>
          <button class="btn-primary-sm" onclick="openLogDigestiveModal()"><i class="fa-solid fa-plus"></i> Log Check-in</button>
        </div>

        <div style="display:flex; gap:16px; margin-bottom:20px;">
          <div style="flex:1; padding:12px; background:#f8faf8; border-radius:var(--radius-sm); text-align:center;">
            <span style="font-size:0.75rem; color:var(--text-muted);">Avg Bloating</span>
            <div style="font-size:1.4rem; font-weight:700; color:var(--text-main);">${summary.avg_bloating || 0} / 5</div>
          </div>
          <div style="flex:1; padding:12px; background:#f8faf8; border-radius:var(--radius-sm); text-align:center;">
            <span style="font-size:0.75rem; color:var(--text-muted);">Avg Gas</span>
            <div style="font-size:1.4rem; font-weight:700; color:var(--text-main);">${summary.avg_gas || 0} / 5</div>
          </div>
          <div style="flex:1; padding:12px; background:#f8faf8; border-radius:var(--radius-sm); text-align:center;">
            <span style="font-size:0.75rem; color:var(--text-muted);">Avg Constipation</span>
            <div style="font-size:1.4rem; font-weight:700; color:var(--text-main);">${summary.avg_constipation || 0} / 5</div>
          </div>
        </div>

        <div class="task-list">
          ${entries.map(e => `
            <div class="task-item" style="padding:12px 14px;">
              <div style="flex:1;">
                <div style="display:flex; justify-content:space-between; margin-bottom:4px;">
                  <span style="font-weight:600; font-size:0.88rem;">${e.date} (${e.time_of_day})</span>
                  <span style="font-size:0.78rem; color:var(--text-muted);">Bristol Type: ${e.bristol_stool_type || 'N/A'}</span>
                </div>
                <div style="font-size:0.8rem; color:var(--text-muted);">
                  Bloating: ${e.bloating_severity}/5 • Gas: ${e.gas_burping_severity}/5 • Constipation: ${e.constipation_severity}/5
                </div>
                ${e.suspected_triggers ? `<div style="font-size:0.75rem; color:var(--accent-amber); margin-top:2px;">Triggers: ${e.suspected_triggers}</div>` : ''}
              </div>
            </div>
          `).join('')}
        </div>
      </div>

      <div class="col-5 card">
        <div class="card-header">
          <h2 class="card-title"><i class="fa-solid fa-leaf"></i> Gentle Gut Wellness Guidelines</h2>
        </div>
        <ul style="padding-left:18px; font-size:0.85rem; color:var(--text-muted); display:flex; flex-direction:column; gap:12px;">
          ${guidance.tips.map(t => `<li>${t}</li>`).join('')}
        </ul>
      </div>
    </div>
  `;
}

// 6. Home Workouts View
async function renderWorkoutsView(container) {
  const library = await api('/workouts/library');
  const weekly = await api('/workouts/weekly-progress');

  container.innerHTML = `
    <div class="card" style="margin-bottom:24px;">
      <div class="card-header">
        <div>
          <h2 class="card-title"><i class="fa-solid fa-person-walking"></i> Beginner Home Workouts</h2>
          <p style="font-size:0.82rem; color:var(--text-muted); margin-top:2px;">Manageable sessions progressing towards 150 min/week moderate activity.</p>
        </div>
        <div style="text-align:right;">
          <span style="font-size:0.8rem; color:var(--text-muted);">This Week:</span>
          <div style="font-weight:700; font-size:1.2rem; color:var(--primary);">${weekly.weekly_minutes_active} / ${weekly.weekly_target_minutes} mins (${weekly.progress_percentage}%)</div>
        </div>
      </div>

      <div style="display:grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap:20px;">
        ${library.map(w => `
          <div class="card" style="border:1px solid var(--border-color); padding:18px;">
            <div style="display:flex; justify-content:space-between; margin-bottom:8px;">
              <span class="card-badge">${w.difficulty}</span>
              <span style="font-size:0.8rem; font-weight:600; color:var(--text-muted);"><i class="fa-regular fa-clock"></i> ${w.duration_mins} mins</span>
            </div>
            <h3 style="font-size:1.05rem; font-weight:700; margin-bottom:6px; color:var(--text-main);">${w.name}</h3>
            <p style="font-size:0.84rem; color:var(--text-muted); margin-bottom:12px; line-height:1.4;">${w.description}</p>
            <div style="padding:10px; background:#f8faf8; border-radius:var(--radius-sm); font-size:0.78rem; color:var(--text-muted); margin-bottom:14px;">
              <strong>Instructions:</strong> ${w.instructions}
            </div>
            <button class="btn-primary-sm" style="width:100%; justify-content:center;" onclick="logWorkoutSession(${w.id}, '${w.name}', ${w.duration_mins})">
              <i class="fa-solid fa-check"></i> Mark Completed Today
            </button>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

// 7. GATE CS 2027 View
async function renderGateView(container) {
  const subjects = await api('/gate/subjects');
  const progress = await api('/gate/progress');
  state.gateSubjects = subjects;

  container.innerHTML = `
    <div class="card" style="margin-bottom:24px;">
      <div class="card-header">
        <div>
          <h2 class="card-title"><i class="fa-solid fa-graduation-cap"></i> GATE CS 2027 Preparation Tracker</h2>
          <p style="font-size:0.82rem; color:var(--text-muted); margin-top:2px;">Official syllabus with 12 core areas. Track progress, solve PYQs, and master formulas.</p>
        </div>
        <div style="text-align:right;">
          <div style="font-weight:700; font-size:1.4rem; color:var(--primary);">${progress.completed} / ${progress.total_topics} Topics</div>
          <span style="font-size:0.8rem; color:var(--text-muted);">${progress.completion_percentage}% Syllabus Covered</span>
        </div>
      </div>

      <div style="display:flex; flex-direction:column; gap:16px;">
        ${subjects.map(s => `
          <div style="border:1px solid var(--border-color); border-radius:var(--radius-md); padding:16px; background:#fdfefe;">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
              <h3 style="font-size:1rem; font-weight:700; color:var(--primary-dark);">${s.name} (${s.code})</h3>
              <span class="card-badge">${s.topics.filter(t => t.status === 'Completed').length} / ${s.topics.length} done</span>
            </div>

            <div style="display:flex; flex-direction:column; gap:8px;">
              ${s.topics.map(t => `
                <div style="display:flex; align-items:center; justify-content:space-between; padding:8px 12px; background:white; border:1px solid var(--border-color); border-radius:var(--radius-sm); font-size:0.84rem;">
                  <span style="flex:1; margin-right:12px;">${t.name}</span>
                  <select class="form-select" style="width:auto; padding:4px 8px; font-size:0.78rem;" onchange="updateGateTopicStatus(${t.id}, this.value)">
                    <option value="Not Started" ${t.status === 'Not Started' ? 'selected' : ''}>Not Started</option>
                    <option value="In Progress" ${t.status === 'In Progress' ? 'selected' : ''}>In Progress</option>
                    <option value="Completed" ${t.status === 'Completed' ? 'selected' : ''}>Completed</option>
                    <option value="Needs Revision" ${t.status === 'Needs Revision' ? 'selected' : ''}>Needs Revision</option>
                  </select>
                </div>
              `).join('')}
            </div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

// 8. Semester Exams View
async function renderSemesterView(container) {
  const subjects = await api('/semester/subjects');
  const countdown = await api('/semester/countdown');

  container.innerHTML = `
    <div class="card" style="margin-bottom:24px;">
      <div class="card-header">
        <div>
          <h2 class="card-title"><i class="fa-solid fa-book-bookmark"></i> Seventh Semester Subjects (S1–S5)</h2>
          <p style="font-size:0.82rem; color:var(--text-muted); margin-top:2px;">Examinations expected in December 2026. Edit subject names and track 5 syllabus units each.</p>
        </div>
      </div>

      <div style="display:grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap:20px;">
        ${subjects.map(s => `
          <div class="card" style="border:1px solid var(--border-color); padding:18px;">
            <div style="display:flex; justify-content:space-between; margin-bottom:8px;">
              <span class="card-badge" style="background:#e8f0ec; color:var(--primary);">${s.code}</span>
              <span style="font-size:0.8rem; font-weight:600; color:var(--text-muted);">${s.priority} Priority</span>
            </div>
            <h3 style="font-size:1.05rem; font-weight:700; color:var(--text-main); margin-bottom:12px;">${s.name}</h3>
            
            <div style="font-size:0.8rem; font-weight:600; color:var(--text-muted); margin-bottom:8px;">5 Units Checklist:</div>
            <div style="display:flex; flex-direction:column; gap:6px; margin-bottom:14px;">
              ${s.units.map(u => `
                <label style="display:flex; align-items:center; gap:8px; font-size:0.82rem; cursor:pointer;">
                  <input type="checkbox" ${u.is_completed ? 'checked' : ''} onchange="toggleSemesterUnit(${u.id}, this.checked)">
                  <span style="${u.is_completed ? 'text-decoration:line-through; color:var(--text-light);' : ''}">${u.title}</span>
                </label>
              `).join('')}
            </div>

            <button class="btn-secondary" style="width:100%; font-size:0.8rem;" onclick="renameSemesterSubjectPrompt(${s.id}, '${s.name}')">Edit Subject Name</button>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

// 9. ExcelR Placement Training View
async function renderExcelRView(container) {
  const session = await api(`/excelr/today-session?target_date=${state.currentDate}`);
  const tasks = await api('/excelr/tasks');

  container.innerHTML = `
    <div class="dashboard-grid">
      <div class="col-6 card">
        <div class="card-header">
          <h2 class="card-title"><i class="fa-solid fa-chalkboard-user"></i> Training Schedule</h2>
          <span class="card-badge">Mon–Fri 17:00–20:00 • Sat 14:00–17:00</span>
        </div>
        ${session ? `
          <div style="padding:16px; background:#f8faf8; border-radius:var(--radius-md); margin-bottom:16px;">
            <div style="font-size:0.84rem; color:var(--text-muted);">Session Today (${session.session_date}):</div>
            <div style="font-size:1.3rem; font-weight:700; margin:4px 0; color:var(--primary);">${session.start_time} – ${session.end_time}</div>
            <div style="font-size:0.85rem; margin-bottom:12px;">Status: <strong>${session.status}</strong></div>
            
            <div style="display:flex; gap:10px;">
              <button class="btn-primary-sm" onclick="setTrainingStatus(${session.id}, 'Completed')"><i class="fa-solid fa-check"></i> Present</button>
              <button class="btn-secondary" onclick="setTrainingStatus(${session.id}, 'Missed')">Missed</button>
              <button class="btn-secondary" onclick="setTrainingStatus(${session.id}, 'Cancelled')">Holiday / Cancelled</button>
            </div>
          </div>
        ` : '<p>No training session scheduled for today.</p>'}
      </div>

      <div class="col-6 card">
        <div class="card-header">
          <h2 class="card-title"><i class="fa-solid fa-briefcase"></i> Placement Readiness Checklist</h2>
        </div>
        <div class="task-list">
          ${tasks.map(t => `
            <div class="task-item">
              <div class="task-details">
                <div class="task-title">${t.title}</div>
                <div class="task-meta">
                  <span class="task-category-pill">${t.category}</span>
                  <span>Status: ${t.status}</span>
                </div>
              </div>
              <select class="form-select" style="width:auto; font-size:0.75rem;" onchange="updatePlacementTaskStatus(${t.id}, this.value)">
                <option value="Pending" ${t.status === 'Pending' ? 'selected' : ''}>Pending</option>
                <option value="In Progress" ${t.status === 'In Progress' ? 'selected' : ''}>In Progress</option>
                <option value="Completed" ${t.status === 'Completed' ? 'selected' : ''}>Completed</option>
              </select>
            </div>
          `).join('')}
        </div>
      </div>
    </div>
  `;
}

// 10. Settings & Profile View
async function renderSettingsView(container) {
  const profile = await api('/auth/me');
  const pref = profile.preferences || {};

  container.innerHTML = `
    <div class="card" style="max-width:700px; margin: 0 auto;">
      <div class="card-header">
        <h2 class="card-title"><i class="fa-solid fa-sliders"></i> Personal Preferences & Settings</h2>
      </div>

      <form id="settings-form" onsubmit="savePreferences(event)">
        <div class="dashboard-grid">
          <div class="col-6 form-group">
            <label class="form-label">Full Name</label>
            <input type="text" class="form-input" value="${profile.full_name}" disabled>
          </div>
          <div class="col-6 form-group">
            <label class="form-label">Email</label>
            <input type="email" class="form-input" value="${profile.email}" disabled>
          </div>
          <div class="col-6 form-group">
            <label class="form-label">Height (cm)</label>
            <input type="number" step="0.1" name="height_cm" class="form-input" value="${pref.height_cm || 162.6}">
          </div>
          <div class="col-6 form-group">
            <label class="form-label">Starting Weight (kg)</label>
            <input type="number" step="0.1" name="starting_weight_kg" class="form-input" value="${pref.starting_weight_kg || 66.0}">
          </div>
          <div class="col-6 form-group">
            <label class="form-label">Target Weight (kg)</label>
            <input type="number" step="0.1" name="target_weight_kg" class="form-input" value="${pref.target_weight_kg || 56.0}">
          </div>
          <div class="col-6 form-group">
            <label class="form-label">Water Target (ml)</label>
            <input type="number" name="daily_water_target_ml" class="form-input" value="${pref.daily_water_target_ml || 2200}">
          </div>
          <div class="col-6 form-group">
            <label class="form-label">Timezone</label>
            <input type="text" name="timezone" class="form-input" value="${pref.timezone || 'Asia/Kolkata'}">
          </div>
          <div class="col-6 form-group">
            <label class="form-label">Quiet Hours (Start - End)</label>
            <div style="display:flex; gap:8px;">
              <input type="time" name="quiet_hours_start" class="form-input" value="${pref.quiet_hours_start || '22:15'}">
              <input type="time" name="quiet_hours_end" class="form-input" value="${pref.quiet_hours_end || '06:30'}">
            </div>
          </div>
        </div>

        <div style="margin-top:20px; display:flex; justify-content:space-between; align-items:center;">
          <button type="submit" class="btn-primary">Save Changes</button>
          <div style="display:flex; gap:10px;">
            <button type="button" class="btn-secondary" onclick="exportData('json')"><i class="fa-solid fa-download"></i> Export JSON</button>
            <button type="button" class="btn-secondary" onclick="exportData('csv')"><i class="fa-solid fa-file-csv"></i> Export CSV</button>
          </div>
        </div>
      </form>
    </div>
  `;
}

// --- Action Handlers ---
async function toggleTaskCompletion(taskId) {
  try {
    const updated = await api(`/tasks/${taskId}/toggle`, { method: 'PATCH' });
    showToast(`Task ${updated.is_completed ? 'completed!' : 'marked pending.'}`, 'success');
    renderCurrentView();
  } catch (e) {}
}

async function quickAddWater(ml) {
  try {
    await api('/hydration/add', {
      method: 'POST',
      body: JSON.stringify({ date: state.currentDate, amount_ml: ml })
    });
    showToast(`Added +${ml}ml water!`, 'success');
    renderCurrentView();
  } catch (e) {}
}

async function toggleHabit(habitId) {
  try {
    const res = await api('/habits/toggle', {
      method: 'POST',
      body: JSON.stringify({ habit_id: habitId, date: state.currentDate, completed: true })
    });
    showToast(`Habit updated! Streak: ${res.current_streak}d`, 'success');
    renderCurrentView();
  } catch (e) {}
}

async function updateGateTopicStatus(topicId, status) {
  try {
    await api(`/gate/topics/${topicId}`, {
      method: 'PATCH',
      body: JSON.stringify({ status })
    });
    showToast(`Topic updated to ${status}`, 'success');
  } catch (e) {}
}

async function toggleSemesterUnit(unitId, isCompleted) {
  try {
    await api(`/semester/units/${unitId}`, {
      method: 'PATCH',
      body: JSON.stringify({ is_completed: isCompleted })
    });
    showToast('Unit progress saved', 'success');
  } catch (e) {}
}

async function setTrainingStatus(sessionId, status) {
  try {
    await api(`/excelr/sessions/${sessionId}/status?status_str=${status}`, { method: 'PATCH' });
    showToast(`Session marked as ${status}`, 'success');
    renderCurrentView();
  } catch (e) {}
}

async function updatePlacementTaskStatus(taskId, status) {
  try {
    await api(`/excelr/tasks/${taskId}`, {
      method: 'PATCH',
      body: JSON.stringify({ status })
    });
    showToast(`Task updated to ${status}`, 'success');
  } catch (e) {}
}

async function logWorkoutSession(workoutId, name, duration) {
  try {
    await api('/workouts/sessions', {
      method: 'POST',
      body: JSON.stringify({
        workout_def_id: workoutId,
        date: state.currentDate,
        duration_mins: duration,
        completed: true,
        notes: `Completed ${name}`
      })
    });
    showToast(`Great job! Logged ${duration} mins of ${name}.`, 'success');
    renderCurrentView();
  } catch (e) {}
}

async function savePreferences(event) {
  event.preventDefault();
  const form = event.target;
  const payload = {
    height_cm: parseFloat(form.height_cm.value),
    starting_weight_kg: parseFloat(form.starting_weight_kg.value),
    target_weight_kg: parseFloat(form.target_weight_kg.value),
    daily_water_target_ml: parseInt(form.daily_water_target_ml.value),
    timezone: form.timezone.value,
    quiet_hours_start: form.quiet_hours_start.value,
    quiet_hours_end: form.quiet_hours_end.value,
  };
  try {
    await api('/auth/me/preferences', {
      method: 'PUT',
      body: JSON.stringify(payload)
    });
    showToast('Preferences updated successfully!', 'success');
  } catch (e) {}
}

async function exportData(format) {
  try {
    const data = await api(`/auth/me/export?format=${format}`);
    const blob = new Blob([format === 'csv' ? data.csv_data : JSON.stringify(data, null, 2)], {
      type: format === 'csv' ? 'text/csv' : 'application/json'
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `bloomtrack_export_${state.currentDate}.${format}`;
    a.click();
    showToast(`Exported personal data (${format.toUpperCase()})`, 'success');
  } catch (e) {}
}

function changeDate(newDate) {
  state.currentDate = newDate;
  renderCurrentView();
}

// --- Modals ---
function openModal(title, bodyHtml, onConfirm = null) {
  const overlay = document.getElementById('modal-overlay');
  const box = document.getElementById('modal-box');
  box.innerHTML = `
    <div class="modal-header">
      <h3>${title}</h3>
      <button class="modal-close" onclick="closeModal()">✕</button>
    </div>
    <div class="modal-body">${bodyHtml}</div>
    <div class="modal-footer">
      <button class="btn-secondary" onclick="closeModal()">Cancel</button>
      ${onConfirm ? `<button class="btn-primary" id="modal-confirm-btn">Save</button>` : ''}
    </div>
  `;
  overlay.classList.add('open');
  if (onConfirm) {
    document.getElementById('modal-confirm-btn').onclick = onConfirm;
  }
}

function closeModal() {
  document.getElementById('modal-overlay').classList.remove('open');
}

function openAddTaskModal() {
  const html = `
    <div class="form-group">
      <label class="form-label">Task Title</label>
      <input type="text" id="new-task-title" class="form-input" placeholder="e.g. Solve 10 Discrete Maths PYQs">
    </div>
    <div class="form-group">
      <label class="form-label">Scheduled Time</label>
      <input type="text" id="new-task-time" class="form-input" placeholder="e.g. 14:00 - 15:00">
    </div>
    <div class="form-group">
      <label class="form-label">Category</label>
      <select id="new-task-cat" class="form-select">
        <option value="GATE">GATE CS</option>
        <option value="Semester">Semester Study</option>
        <option value="Placement">ExcelR Placement</option>
        <option value="Health">Health & Fitness</option>
        <option value="Wellness">Wellness & Rest</option>
      </select>
    </div>
  `;
  openModal('Add Custom Task', html, async () => {
    const title = document.getElementById('new-task-title').value.trim();
    const timeStr = document.getElementById('new-task-time').value.trim();
    const cat = document.getElementById('new-task-cat').value;
    if (!title) return alert('Please enter a task title');
    try {
      await api('/tasks', {
        method: 'POST',
        body: JSON.stringify({
          title,
          scheduled_time: timeStr,
          category: cat,
          date: state.currentDate,
          priority: 'medium'
        })
      });
      closeModal();
      showToast('Custom task added', 'success');
      renderCurrentView();
    } catch (e) {}
  });
}

function openLogWeightModal() {
  const html = `
    <div class="form-group">
      <label class="form-label">Weight (kg)</label>
      <input type="number" step="0.1" id="new-weight" class="form-input" placeholder="65.5">
    </div>
    <div class="form-group">
      <label class="form-label">Waist Measurement (cm, optional)</label>
      <input type="number" step="0.5" id="new-waist" class="form-input" placeholder="73.0">
    </div>
    <div class="form-group">
      <label class="form-label">Notes</label>
      <input type="text" id="new-weight-notes" class="form-input" placeholder="Morning weigh-in, feeling energized">
    </div>
  `;
  openModal('Log Weight Check-in', html, async () => {
    const weight = parseFloat(document.getElementById('new-weight').value);
    const waist = parseFloat(document.getElementById('new-waist').value) || null;
    const notes = document.getElementById('new-weight-notes').value;
    if (!weight) return alert('Please enter weight');
    try {
      await api('/weight', {
        method: 'POST',
        body: JSON.stringify({ date: state.currentDate, weight_kg: weight, waist_cm: waist, notes })
      });
      closeModal();
      showToast('Weight entry saved!', 'success');
      renderCurrentView();
    } catch (e) {}
  });
}

function openLogPeriodModal() {
  const html = `
    <div class="form-group">
      <label class="form-label">First Day of Bleeding</label>
      <input type="date" id="period-start" class="form-input" value="${state.currentDate}">
    </div>
    <div class="form-group">
      <label class="form-label">Last Day of Bleeding (optional)</label>
      <input type="date" id="period-end" class="form-input">
    </div>
    <div class="form-group">
      <label class="form-label">Flow Intensity</label>
      <select id="period-flow" class="form-select">
        <option value="Spotting">Spotting</option>
        <option value="Light">Light</option>
        <option value="Medium" selected>Medium</option>
        <option value="Heavy">Heavy</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Cramps Severity (0 to 5)</label>
      <input type="range" min="0" max="5" id="period-cramps" class="form-input" value="1">
    </div>
  `;
  openModal('Log Menstrual Period', html, async () => {
    const start = document.getElementById('period-start').value;
    const end = document.getElementById('period-end').value || null;
    const flow = document.getElementById('period-flow').value;
    const cramps = parseInt(document.getElementById('period-cramps').value);
    try {
      await api('/health/menstrual', {
        method: 'POST',
        body: JSON.stringify({ start_date: start, end_date: end, flow_intensity: flow, cramps_severity: cramps })
      });
      closeModal();
      showToast('Period entry saved!', 'success');
      renderCurrentView();
    } catch (e) {}
  });
}

function openLogDigestiveModal() {
  const html = `
    <div class="form-group">
      <label class="form-label">Bloating Severity (0: None, 5: Severe)</label>
      <input type="range" min="0" max="5" id="dig-bloat" class="form-input" value="1">
    </div>
    <div class="form-group">
      <label class="form-label">Gas / Burping Severity (0 to 5)</label>
      <input type="range" min="0" max="5" id="dig-gas" class="form-input" value="1">
    </div>
    <div class="form-group">
      <label class="form-label">Constipation Severity (0 to 5)</label>
      <input type="range" min="0" max="5" id="dig-const" class="form-input" value="0">
    </div>
    <div class="form-group">
      <label class="form-label">Bristol Stool Scale (1 to 7)</label>
      <select id="dig-bristol" class="form-select">
        <option value="3" selected>Type 3 - Like a sausage with cracks on surface</option>
        <option value="4">Type 4 - Like a sausage or snake, smooth and soft</option>
        <option value="1">Type 1 - Separate hard lumps (very constipated)</option>
        <option value="2">Type 2 - Lumpy and sausage-shaped</option>
        <option value="5">Type 5 - Soft blobs with clear-cut edges</option>
      </select>
    </div>
    <div class="form-group">
      <label class="form-label">Possible Food Triggers</label>
      <input type="text" id="dig-triggers" class="form-input" placeholder="e.g. Dairy, fried snacks, late eating">
    </div>
  `;
  openModal('Log Digestive & Gut Symptoms', html, async () => {
    const bloat = parseInt(document.getElementById('dig-bloat').value);
    const gas = parseInt(document.getElementById('dig-gas').value);
    const constip = parseInt(document.getElementById('dig-const').value);
    const bristol = parseInt(document.getElementById('dig-bristol').value);
    const triggers = document.getElementById('dig-triggers').value;
    try {
      await api('/digestive/entries', {
        method: 'POST',
        body: JSON.stringify({
          date: state.currentDate,
          bloating_severity: bloat,
          gas_burping_severity: gas,
          constipation_severity: constip,
          bristol_stool_type: bristol,
          suspected_triggers: triggers
        })
      });
      closeModal();
      showToast('Digestive check-in saved!', 'success');
      renderCurrentView();
    } catch (e) {}
  });
}

function openQuickLogModal() {
  const html = `
    <div style="display:flex; flex-direction:column; gap:12px;">
      <button class="btn-secondary" style="padding:14px; text-align:left; font-size:0.95rem;" onclick="closeModal(); quickAddWater(250);"><i class="fa-solid fa-glass-water" style="color:#3a86ff"></i> +250ml Water</button>
      <button class="btn-secondary" style="padding:14px; text-align:left; font-size:0.95rem;" onclick="closeModal(); openLogWeightModal();"><i class="fa-solid fa-weight-scale" style="color:var(--primary)"></i> Log Weight Entry</button>
      <button class="btn-secondary" style="padding:14px; text-align:left; font-size:0.95rem;" onclick="closeModal(); openLogDigestiveModal();"><i class="fa-solid fa-hand-holding-medical" style="color:var(--accent-warm)"></i> Log Digestive Check-in</button>
      <button class="btn-secondary" style="padding:14px; text-align:left; font-size:0.95rem;" onclick="closeModal(); openLogPeriodModal();"><i class="fa-solid fa-heart-pulse" style="color:#e63946"></i> Log Menstrual Period</button>
      <button class="btn-secondary" style="padding:14px; text-align:left; font-size:0.95rem;" onclick="closeModal(); openAddTaskModal();"><i class="fa-solid fa-plus" style="color:var(--accent-mint)"></i> Add Custom Task</button>
    </div>
  `;
  openModal('Quick Log', html);
}

function openNotificationsModal() {
  const html = `
    <p style="font-size:0.86rem; color:var(--text-muted); margin-bottom:14px;">
      BloomTrack supports desktop browser notifications and scheduled reminders during waking hours (06:30 – 22:15).
    </p>
    <button class="btn-primary" style="width:100%; margin-bottom:10px;" onclick="requestBrowserNotifications()">Enable Desktop Notifications</button>
    <button class="btn-secondary" style="width:100%;" onclick="testNotification()">Send Test Wake-up Reminder</button>
  `;
  openModal('Notification & Reminder Preferences', html);
}

function requestBrowserNotifications() {
  if ('Notification' in window) {
    Notification.requestPermission().then(permission => {
      if (permission === 'granted') {
        showToast('Notifications enabled for this browser!', 'success');
        new Notification('BloomTrack Reminders Active', {
          body: 'You will receive scheduled study, hydration, and routine prompts.'
        });
      } else {
        showToast('Notification permission was dismissed or blocked.', 'info');
      }
    });
  } else {
    showToast('Notifications are not supported in this browser.', 'error');
  }
}

function testNotification() {
  showToast('Simulated: 06:30 Wake up, drink water, and get daylight!', 'info');
}

// --- App Bootstrap ---
document.addEventListener('DOMContentLoaded', async () => {
  initNavigation();
  await autoAuthenticate();
  renderCurrentView();
});
