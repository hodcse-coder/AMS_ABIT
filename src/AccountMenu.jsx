import React,{useEffect,useRef,useState} from 'react';
import {Icon} from './DashboardOverview.jsx';

export default function AccountMenu({user,onPassword,onLogout,photoVersion}){
  const menu=useRef(null);
  const [photoFailed,setPhotoFailed]=useState(false);
  useEffect(()=>setPhotoFailed(false),[user.user_id,photoVersion]);
  useEffect(()=>{
    const outside=e=>{if(menu.current&&!menu.current.contains(e.target))menu.current.open=false;};
    const escape=e=>{if(e.key==='Escape'&&menu.current?.open){menu.current.open=false;menu.current.querySelector('summary')?.focus();}};
    document.addEventListener('pointerdown',outside);document.addEventListener('keydown',escape);
    return()=>{document.removeEventListener('pointerdown',outside);document.removeEventListener('keydown',escape);};
  },[]);
  function choose(action){menu.current.open=false;action();}
  return <details ref={menu} className="account-menu"><summary className="topbar-avatar" aria-label="Account options" title="Account options">{photoFailed?user.full_name.slice(0,1):<img src={'/api/me/photo?v='+encodeURIComponent(photoVersion||user.user_id)} alt={user.full_name+' photo'} onError={()=>setPhotoFailed(true)}/>}</summary><div className="account-menu-dropdown"><strong>{user.full_name}</strong><button type="button" onClick={()=>choose(onPassword)}><Icon name="lock" size={16}/>Change Password</button><button type="button" onClick={()=>choose(onLogout)}><Icon name="logout" size={16}/>Sign Out</button></div></details>;
}
