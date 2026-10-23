import React, { useEffect, useState } from 'react';
import { api } from './Erp.jsx';
import MessageDialog from './MessageDialog.jsx';

export function Icon({ name = 'grid', size = 20 }) {
  const paths = {
    view: <><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></>,
    edit: <><path d="m15 4 5 5M4 20l5-1L21 7a2 2 0 0 0-5-5L4 14l-1 7 6-2"/></>,
    delete: <><path d="M3 6h18M9 6V3h6v3M5 6l1 15h12l1-15M10 10v7m4-7v7"/></>,
    grid: <><rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/></>,
    users: <><circle cx="9" cy="8" r="3"/><path d="M3 21v-3a6 6 0 0 1 12 0v3M16 5a3 3 0 0 1 0 6m2 3a5 5 0 0 1 3 4v3"/></>,
    book: <><path d="M12 5v16M12 5C8 2 4 3 2 4v15c4-2 7-1 10 2 3-3 6-4 10-2V4c-3-1-7-2-10 1Z"/></>,
    settings: <><path d="m10 3-1 3-3 1-3 3 2 2-1 3 3 3 3-1 2 2 3-1 1-3 3-1 1-3-2-2 1-3-3-2-3 1-2-2Z"/><circle cx="12" cy="11" r="3"/></>,
    lock: <><rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V6a4 4 0 0 1 8 0v4m-4 5v2"/></>,
    logout: <><path d="M9 4H4v16h5m5-12 4 4-4 4m-7-4h13"/></>,
    menu: <path d="M4 6h16M4 12h16M4 18h16"/>,
    search: <><circle cx="10" cy="10" r="6"/><path d="m15 15 5 5"/></>,
    arrow: <path d="M5 12h14m-5-5 5 5-5 5"/>,
    check: <><circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/></>,
  };
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name] || paths.grid}</svg>;
}

function NoticeUpdates({ notices }) {
  return <section className="overview-panel"><div className="panel-heading"><div><h2>Notice Update</h2><p>Latest notices from Dashboard Setup</p></div><Icon name="book"/></div><div className="dashboard-updates">{notices.length ? notices.map(notice => <article key={notice.notice_id}><h3>{notice.notice_title}</h3>{notice.notice_date && <time dateTime={notice.notice_date}>{notice.notice_date}</time>}{notice.notice_description && <p>{notice.notice_description}</p>}{notice.downloadable && <a href={'/api/dashboard-content/notices/'+notice.notice_id+'/file'}>{notice.notice_file_path}</a>}</article>) : <p className="dashboard-empty">No notices available.</p>}</div></section>;
}

export default function DashboardOverview({ user, onNavigate, notices=[] }) {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const admin = user.role_name === 'Admin';
  useEffect(() => {
    if (!admin) return;
    let current = true;
    const refresh = () => api('/api/admin/dashboard-overview').then(result => { if(current) { setData(result); setError(''); } }).catch(e => { if(current) setError(e.message); });
    refresh();
    const timer = setInterval(refresh, 60000);
    window.addEventListener('focus', refresh);
    return () => { current = false; clearInterval(timer); window.removeEventListener('focus', refresh); };
  }, [admin]);
  const metrics = [
    {label:'Courses',key:'courses',note:'Configured courses',icon:'book',tone:'teal'},
    {label:'Department',key:'departments',note:'Configured departments',icon:'grid',tone:'blue'},
    {label:'Faculty',key:'faculty',note:'Teaching faculty',icon:'users',tone:'violet'},
    {label:'Students',key:'students',note:'Enrolled students',icon:'users',tone:'green'},
  ];
  return <div className="overview-page">
    <MessageDialog message={error} onDismiss={() => setError('')} />
    {admin ? <>
      <div className="overview-metrics">{metrics.map(metric => <article className="overview-metric" key={metric.key}><div><span>{metric.label}</span><div className={'metric-icon '+metric.tone}><Icon name={metric.icon}/></div></div><strong>{data ? data.counts[metric.key] : '...'}</strong><small><span className={'metric-dot '+metric.tone}/>{metric.note}</small></article>)}</div>
      <div className="overview-charts">
        <NoticeUpdates notices={notices}/>
        <section className="overview-panel"><div className="panel-heading"><div><h2>Courses Name</h2><p>Configured courses</p></div><Icon name="book"/></div><ul className="dashboard-course-list">{data ? data.courses.length ? data.courses.map(course => <li key={course.course_id}><span>{course.course_name}</span>{course.course_code && <small>{course.course_code}</small>}</li>) : <li className="dashboard-empty">No courses available.</li> : <li className="dashboard-empty">Loading courses...</li>}</ul></section>
      </div>
    </> : <><NoticeUpdates notices={notices}/><section className="overview-panel personal-welcome"><Icon name="book" size={36}/><h2>Welcome, {user.full_name}</h2><p>Your {user.role_name.toLowerCase()} account is active.</p><button className="teal-button" onClick={()=>onNavigate('password')}>Manage your password</button></section></>}
    <footer className="overview-footer"><span>&copy; {new Date().getFullYear()} ABIT &middot; Academic Management System</span><span>Campus administration, connected.</span></footer>
  </div>;
}
