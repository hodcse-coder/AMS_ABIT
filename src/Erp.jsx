import AccountMenu from './AccountMenu.jsx';
import ManageAccounts from './ManageAccounts.jsx';
import HeaderMessage from './HeaderMessage.jsx';
import {obeItems,obePages} from '../shared/obe.mjs';
import DashboardConfiguration from './DashboardConfiguration.jsx';
import {dashboardConfigurationItems} from '../shared/dashboard-configuration.mjs';
import UserManagement from './UserManagement.jsx';
import {userManagementItems,userManagementPages} from '../shared/user-management.mjs';
import MentoringModule from './MentoringModule.jsx';
import {mentoringNavigation,mentoringPages} from '../shared/mentoring.mjs';
import TimetableModule from './TimetableModule.jsx';
import {timetableMenuItems,timetablePages,offlineTimetableItems} from '../shared/timetable.mjs';
import StudentModule from './StudentModule.jsx';
import {studentMenuItems} from '../shared/students.mjs';
import EmployeeModule from './EmployeeModule.jsx';
import {employeeMenuItems} from '../shared/employees.mjs';
import SubjectConfiguration,{subjectConfigurationItems} from './SubjectConfiguration.jsx';
import AcademicResources from './AcademicResources.jsx';
import {academicResources} from '../shared/academic-resources.mjs';
import React, { useEffect, useState, lazy, Suspense } from 'react';
import Configuration from './Configuration.jsx';
import CourseModules from './CourseModules.jsx';
import { configuration } from '../shared/configuration.mjs';
import DashboardOverview, { Icon } from './DashboardOverview.jsx';
import './dashboard.css';
import MessageDialog, { validationMessage } from './MessageDialog.jsx';

const ObeModule=lazy(()=>import('./ObeModule.jsx'));

export async function api(path, options = {}) {
  const response = await fetch(path, { ...options, headers: { 'Content-Type': 'application/json', ...options.headers } });
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || 'Request failed.');
  return data;
}

export default function Erp({ user, onLogout, onPasswordChanged }) {
  const [users, setUsers] = useState(null);
  const [dashboardContent,setDashboardContent]=useState({message:null,notices:[]});
  const [dashboardConfigurationOpen,setDashboardConfigurationOpen]=useState(false);
  const refreshDashboardContent=()=>api('/api/dashboard-content').then(setDashboardContent);
  useEffect(()=>{let active=true;const update=()=>api('/api/dashboard-content').then(data=>{if(active)setDashboardContent(data);}).catch(()=>{});update();const interval=setInterval(update,60000);window.addEventListener('focus',update);return()=>{active=false;clearInterval(interval);window.removeEventListener('focus',update);};},[user.user_id]);
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);
  const [page, setPage] = useState('dashboard');
  const [sidebarOpen, setSidebarOpen] = useState(() => window.innerWidth >= 1024);
  const [menuSearch, setMenuSearch] = useState('');
  const [academicsOpen,setAcademicsOpen]=useState(false);
  const [subjectConfigurationOpen,setSubjectConfigurationOpen]=useState(false);
  const [courseOpen, setCourseOpen] = useState(false);
  const [configurationOpen, setConfigurationOpen] = useState(false);
  const [employeeOpen,setEmployeeOpen]=useState(false);
  const [studentOpen,setStudentOpen]=useState(false);
  const [timetableOpen,setTimetableOpen]=useState(false);
  const [offlineOpen,setOfflineOpen]=useState(false);
  const [mentoringOpen,setMentoringOpen]=useState(false);
  const [mentoringGroups,setMentoringGroups]=useState({});
  const [accountsOpen,setAccountsOpen]=useState(false);
  const [obeOpen,setObeOpen]=useState(false);
  const [obeGroups,setObeGroups]=useState({});
  const [accessGroups,setAccessGroups]=useState({});
  const configurationItems = configuration.map(item => ({ key: 'config-' + item.key, label: item.label }));
  const isMenuOpen = key => !!menuSearch || (key==='obe'?obeOpen:obeItems.some(item=>item.key===key&&item.children)?!!obeGroups[key]:key==='dashboard-configuration'?dashboardConfigurationOpen:key==='accounts'?accountsOpen:userManagementItems.some(item=>item.key===key)?!!accessGroups[key]:key==='mentoring'?mentoringOpen:['mentoring-sessions','mentoring-allotment'].includes(key)?!!mentoringGroups[key]:key === 'timetable' ? timetableOpen : key === 'timetable-offline' ? offlineOpen : key === 'academics' ? academicsOpen : key === 'subject-configuration' ? subjectConfigurationOpen : key === 'configuration' ? configurationOpen : key === 'employees' ? employeeOpen : key === 'student-menu' ? studentOpen : courseOpen);
  function toggleMenu(key) {
    const opening = !isMenuOpen(key);
    if(obeItems.some(item=>item.key===key&&item.children)){setObeGroups(previous=>({...previous,[key]:opening}));setObeOpen(true);setMenuSearch('');if(opening)setPage(key);return;}
    setObeOpen(key==='obe'&&opening);
    if(!['mentoring-sessions','mentoring-allotment',...userManagementItems.map(item=>item.key),'timetable-offline'].includes(key))setDashboardConfigurationOpen(key==='dashboard-configuration'&&opening);
    if(userManagementItems.some(item=>item.key===key)){setAccessGroups(previous=>({...previous,[key]:opening}));setAccountsOpen(true);setMenuSearch('');if(opening)setPage(key);return;}
    setAccountsOpen(key==='accounts'&&opening);
    if(['mentoring-sessions','mentoring-allotment'].includes(key)){setMentoringGroups(previous=>({...previous,[key]:opening}));setMentoringOpen(true);setMenuSearch('');if(opening)setPage(key);return;}
    setMentoringOpen(key==='mentoring'&&opening);
    if(key==='timetable-offline'){setOfflineOpen(opening);setTimetableOpen(true);setMenuSearch('');if(opening)setPage(key);return;}
    setTimetableOpen(key==='timetable'&&opening);
    setMenuSearch('');
    setMessage('');
    if (opening) setPage(key);
    setAcademicsOpen(key === 'academics' && opening);
    setSubjectConfigurationOpen(key === 'subject-configuration' && opening);
    setConfigurationOpen(key === 'configuration' && opening);
    setCourseOpen(key === 'course-menu' && opening);
    setEmployeeOpen(key === 'employees' && opening);
    setStudentOpen(key === 'student-menu' && opening);
  }

  const courseItems = [{key:'course',label:'Course'},{key:'batch',label:'Batch'},{key:'assign-section',label:'Assign Section'},{key:'add-section',label:'Add Section'},{key:'section-master',label:'Section Master'},{key:'add-branch',label:'Add Branch'},{key:'academic-year',label:'Academic Year'},{key:'subjects',label:'Subjects'}];
  const admin = user.role_name === 'Admin';
  const canModule=module=>admin||user.access_modules?.includes(module);
  const mentoringMenu={key:'mentoring',label:'Student Mentoring',icon:'users',group:'Menu',children:mentoringNavigation(false)};
  const moduleMenu=[
    {key:'course-menu',label:'Course',module:'course',icon:'book',group:'Menu',children:courseItems},
    {key:'academics',label:'Academics',module:'academics',icon:'book',group:'Menu',children:academicResources.map(item=>({key:'academics-'+item.key,label:item.label}))},
    {key:'subject-configuration',label:'Subject Configuration',module:'subject-configuration',icon:'settings',group:'Menu',children:subjectConfigurationItems},
    {key:'timetable',label:'Timetable',module:null,icon:'book',group:'Menu',children:canModule('timetable')?timetableMenuItems:[...timetableMenuItems.filter(item=>item.key==='timetable-mine'),...offlineTimetableItems.filter(item=>item.key==='timetable-floor')]},
    {key:'configuration',label:'Configuration',module:'configuration',icon:'settings',group:'Menu',children:configurationItems},
    {key:'employees',label:'Employee',module:'employees',icon:'users',group:'Menu',children:employeeMenuItems},
    {key:'student-menu',label:'Student',module:'students',icon:'users',group:'Menu',children:studentMenuItems}
  ];
  const menu=[{key:'dashboard',label:'Dashboard',icon:'grid',group:'Menu'},...moduleMenu.filter(item=>!item.module||canModule(item.module)),...(admin||['Faculty','Employee'].includes(user.role_name)?[{...mentoringMenu,children:mentoringNavigation(admin)}]:[]),...(canModule('obe')?[{key:'obe',label:'OBE',icon:'book',group:'Menu',children:obeItems}]:[]),...(canModule('dashboard-configuration')?[{key:'dashboard-configuration',label:'Dashboard Setup',icon:'settings',group:'Menu',children:dashboardConfigurationItems}]:[]),...(admin?[{key:'accounts',label:'User Management',icon:'users',group:'Menu',children:userManagementItems}]:[])];
  function navigate(key) {
    setObeOpen(key==='obe'||key.startsWith('obe-'));
    setObeGroups(Object.fromEntries(obeItems.filter(item=>item.children).map(item=>[item.key,item.key===key||item.children.some(child=>child.key===key)])));
    setDashboardConfigurationOpen(key==='dashboard-configuration'||key.startsWith('dashboard-config-'));
    setAccountsOpen(key==='accounts'||key.startsWith('access-'));
    setAccessGroups(Object.fromEntries(userManagementItems.map(item=>[item.key,item.key===key||item.children.some(child=>child.key===key)])));
    setMentoringOpen(key==='mentoring'||key.startsWith('mentoring-'));
    setMentoringGroups({'mentoring-sessions':['mentoring-sessions','mentoring-existing'].includes(key),'mentoring-allotment':['mentoring-allotment','mentoring-allot-existing'].includes(key)});
    setTimetableOpen(key==='timetable'||key.startsWith('timetable-'));
    setOfflineOpen(key==='timetable-offline'||offlineTimetableItems.some(item=>item.key===key));
    setAcademicsOpen(key==='academics'||key.startsWith('academics-'));
    setSubjectConfigurationOpen(key==='subject-configuration'||key.startsWith('subject-config-'));
    setConfigurationOpen(key === 'configuration' || key.startsWith('config-'));
    setCourseOpen(key === 'course-menu' || courseItems.some(item => item.key === key));
    setEmployeeOpen(key==='employees'||key.startsWith('employee-'));
    setStudentOpen(key==='student-menu'||key.startsWith('student-'));
    setPage(key);
    setMessage('');
    setMenuSearch('');
    if (window.innerWidth < 1024) setSidebarOpen(false);
  }
  const refresh = () => api('/api/admin/users').then(data => setUsers(data.users));
  useEffect(() => { if (admin) refresh().catch(error => setMessage(error.message)); }, [admin]);
  async function create(event) {
    event.preventDefault();
    const form = event.currentTarget;
    setBusy(true);
    try {
      await api('/api/admin/users', { method: 'POST', body: JSON.stringify(Object.fromEntries(new FormData(form))) });
      form.reset();
      await refresh();
      setMessage('Account created successfully.');
    } catch (error) { setMessage(error.message); } finally { setBusy(false); }
  }
  async function toggle(account) {
    setBusy(true);
    try {
      await api(`/api/admin/users/${account.user_id}/status`, { method: 'POST', body: JSON.stringify({ is_active: !account.is_active }) });
      await refresh();
      setMessage('Account access updated.');
    } catch (error) { setMessage(error.message); } finally { setBusy(false); }
  }
  async function changePassword(event) {
    event.preventDefault();
    const input = Object.fromEntries(new FormData(event.currentTarget));
    if (input.new_password !== input.confirm_password) { setMessage('New Password and Confirm Password must match.'); return; }
    setBusy(true);
    try {
      await api('/api/password', { method: 'POST', body: JSON.stringify(input) });
      onPasswordChanged();
    } catch (error) { setMessage(error.message); } finally { setBusy(false); }
  }
  function matchesMenu(item){return item.label.toLowerCase().includes(menuSearch.toLowerCase())||!!item.children?.some(matchesMenu);}
  function selectedMenu(item){return item.key===page||!!item.children?.some(selectedMenu);}
  function renderMenu(item,depth=0,parentMatch=false){
    const expanded=isMenuOpen(item.key),showAll=parentMatch||item.label.toLowerCase().includes(menuSearch.toLowerCase());
    return <React.Fragment key={item.key}><button className={depth?(item.children?'workspace-submenu-item submenu-parent':'workspace-submenu-item'):`workspace-nav-item ${item.children&&selectedMenu(item)?'course-parent-active':''}`} aria-current={page===item.key?'page':undefined} aria-expanded={item.children?expanded:undefined} aria-controls={item.children?item.key+'-submenu':undefined} onClick={()=>item.children?toggleMenu(item.key):navigate(item.key)}>
      {depth?<span className="submenu-dot"/>:<Icon name={item.icon}/>}<span>{item.label}</span>{item.children&&<svg className={`submenu-chevron ${expanded?'expanded':''}`} width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" aria-hidden="true"><path d="m8 10 4 4 4-4"/></svg>}
    </button>{item.children&&<div className="workspace-submenu" id={item.key+'-submenu'} hidden={!expanded}>{item.children.filter(child=>showAll||matchesMenu(child)).map(child=>renderMenu(child,depth+1,showAll))}</div>}</React.Fragment>;
  }
  return <div className={`erp dashboard-shell ${sidebarOpen ? 'sidebar-open' : ''}`}>
    <MessageDialog message={message} onDismiss={() => setMessage('')} />
    <aside className="workspace-sidebar" id="workspace-sidebar" aria-label="Campus sidebar" inert={!sidebarOpen}>
      <button className="workspace-brand" onClick={()=>navigate('dashboard')}><img src="/Logo.png" alt="ABIT logo"/><span><strong>ABIT <span className="brand-autonomous">AUTONOMOUS</span></strong><small>Academic Management System</small></span></button>
      <nav className="workspace-navigation" aria-label="ERP navigation">{menu.filter(matchesMenu).map((item,index,items)=><React.Fragment key={item.key}>
        {(index===0||items[index-1].group!==item.group)&&<div className="nav-section-label">{item.group}</div>}{renderMenu(item)}
      </React.Fragment>)}{menuSearch&&!menu.some(matchesMenu)&&<p className="menu-no-results">No matching menus.</p>}</nav>
    </aside>
    {sidebarOpen&&<button className="sidebar-scrim" aria-label="Close navigation" onClick={()=>setSidebarOpen(false)}/>}
    <div className="workspace-main"><header className="workspace-topbar"><div className="topbar-left"><button className="icon-button" aria-label="Toggle navigation" aria-expanded={sidebarOpen} aria-controls="workspace-sidebar" onClick={()=>setSidebarOpen(value=>!value)}><Icon name="menu"/></button></div><HeaderMessage message={dashboardContent.message?.msg_details||''}/><div className="topbar-right"><span className="topbar-role">{user.role_name}</span><AccountMenu user={user} photoVersion={users?.find(account=>account.user_id===user.user_id)?.updated_at} onPassword={()=>navigate('password')} onLogout={onLogout}/></div></header>
    <div className="dashboard-content">
    {canModule('obe')&&(page==='obe'||page.startsWith('obe-'))&&<Suspense fallback={<p role="status">Loading OBE...</p>}><ObeModule key={page} page={page} onNavigate={navigate}/></Suspense>}
    {canModule('dashboard-configuration')&&(page==='dashboard-configuration'||page.startsWith('dashboard-config-'))&&<DashboardConfiguration key={page} page={page} onNavigate={navigate} onContentChanged={refreshDashboardContent}/>}
    {(page==='mentoring'||page.startsWith('mentoring-'))&&<MentoringModule key={page} page={page} user={user} onNavigate={navigate}/>}
    {(page==='timetable'||page.startsWith('timetable-'))&&<TimetableModule page={page} user={user} canManage={canModule('timetable')} onNavigate={navigate}/>}
    {page === 'dashboard' && <DashboardOverview user={user} users={users} notices={dashboardContent.notices} onNavigate={navigate} />}
    {(page === 'configuration' || page.startsWith('config-')) && canModule('configuration') && <Configuration selectedKey={page.startsWith('config-') ? page.slice(7) : null} onSelect={key => navigate(key ? 'config-' + key : 'configuration')} />}
    {canModule('course') && ['course-menu','course','batch','assign-section','add-section','section-master','add-branch','academic-year','subjects'].includes(page) && <CourseModules page={page} onNavigate={navigate} />}
    {canModule('academics') && (page==='academics'||page.startsWith('academics-')) && <AcademicResources page={page} onNavigate={navigate}/>}
    {canModule('subject-configuration') && (page==='subject-configuration'||page.startsWith('subject-config-')) && <SubjectConfiguration page={page} onNavigate={navigate}/>}
    {canModule('students')&&(page==='student-menu'||page.startsWith('student-'))&&<StudentModule key={page} page={page} onNavigate={navigate} onAccountsChanged={admin?refresh:undefined}/>}
    {canModule('employees')&&(page==='employees'||page.startsWith('employee-'))&&<EmployeeModule key={page} page={page} onNavigate={navigate} onAccountsChanged={admin?refresh:undefined}/>}
    {admin&&(page==='accounts'||page.startsWith('access-'))&&page!=='access-accounts'&&<UserManagement key={page} page={page} onNavigate={navigate}/>}
    {admin && page === 'access-accounts' && <ManageAccounts user={user} onChanged={refresh}/>}
    {page === 'password' && <>
    {page === 'password' && <section className="erp-panel"><h2>Change your password</h2><form className="erp-form" onSubmit={changePassword} onInvalid={event => validationMessage(event, setMessage)}>
      <label>Current password<input name="current_password" type="password" autoComplete="current-password" maxLength={1024} required /></label>
      <label>New Password<input name="new_password" type="password" autoComplete="new-password" minLength={8} maxLength={1024} placeholder="At least 8 characters" required /></label>
      <label>Confirm Password<input name="confirm_password" type="password" autoComplete="new-password" minLength={8} maxLength={1024} placeholder="Re-enter new password" required /></label>
      <button disabled={busy}>Update password</button>
    </form></section>}
    </>}
    </div></div>
  </div>;
}
