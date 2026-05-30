document.addEventListener('DOMContentLoaded', () => {
  const header = document.querySelector('.site-header');
  const layout = document.querySelector('.layout');
  const inner = header?.querySelector('.site-header-inner');
  if (!header || !inner) return;

  const navHidden = localStorage.getItem('nav-hidden') !== 'false';
  const sidebarHidden = localStorage.getItem('sidebar-hidden') !== 'false';

  if (navHidden) header.classList.add('nav-hidden');
  if (layout && sidebarHidden) layout.classList.add('sidebar-hidden');

  const wrap = document.createElement('div');
  wrap.className = 'ui-toggles';

  const navBtn = document.createElement('button');
  navBtn.className = 'ui-toggle-btn';
  navBtn.setAttribute('aria-label', '切換導覽列');
  navBtn.textContent = navHidden ? '≡' : '✕';
  navBtn.addEventListener('click', () => {
    const hidden = header.classList.toggle('nav-hidden');
    navBtn.textContent = hidden ? '≡' : '✕';
    localStorage.setItem('nav-hidden', hidden ? 'true' : 'false');
  });

  const sidebarBtn = document.createElement('button');
  sidebarBtn.className = 'ui-toggle-btn';
  sidebarBtn.setAttribute('aria-label', '切換側邊欄');
  sidebarBtn.textContent = sidebarHidden ? '▶' : '◀';
  sidebarBtn.addEventListener('click', () => {
    if (!layout) return;
    const hidden = layout.classList.toggle('sidebar-hidden');
    sidebarBtn.textContent = hidden ? '▶' : '◀';
    localStorage.setItem('sidebar-hidden', hidden ? 'true' : 'false');
  });

  wrap.appendChild(navBtn);
  wrap.appendChild(sidebarBtn);
  inner.appendChild(wrap);
});
