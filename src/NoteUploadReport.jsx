import React,{useEffect,useState} from 'react';
import {api} from './Erp.jsx';
import MessageDialog from './MessageDialog.jsx';
import './note-upload-report.css';

export default function NoteUploadReport(){
 const [rows,setRows]=useState([]),[loading,setLoading]=useState(true),[error,setError]=useState(''),[message,setMessage]=useState(''),[downloading,setDownloading]=useState(null);
 async function refresh(){setLoading(true);setError('');try{const data=await api('/api/admin/academics/note-upload-report');setRows(data.records);}catch(error){setError(error.message);}finally{setLoading(false);}}
 useEffect(()=>{let active=true;api('/api/admin/academics/note-upload-report').then(data=>{if(active)setRows(data.records);}).catch(error=>{if(active)setError(error.message);}).finally(()=>{if(active)setLoading(false);});return()=>{active=false;};},[]);
 async function download(row){
  setDownloading(row.id);
  try{
   const response=await fetch('/api/admin/academics/lecture-notes/'+row.id+'/download');
   if(!response.ok){const result=await response.json();throw new Error(result.error||'Unable to download this file.');}
   const url=URL.createObjectURL(await response.blob()),link=document.createElement('a');link.href=url;link.download=row.file_name||'lecture-note';document.body.appendChild(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),30000);
  }catch(error){setMessage(error.message);}finally{setDownloading(null);}
 }
 return <section className="note-report-page"><MessageDialog message={message} onDismiss={()=>setMessage('')}/>
  <div className="note-report-heading"><h2>Lecture Notes Upload Report</h2><button type="button" disabled={loading} onClick={refresh}>{loading?'Loading…':'Refresh'}</button></div>
  {error&&<p className="note-report-error" role="alert">{error}</p>}
  <div className="note-report-table table-scroll"><table aria-label="Lecture Notes Upload Report"><thead><tr>{['Sl.','Faculty Name','Subject','Semester','Lecture Note Description','File Name','Action','Status'].map(label=><th scope="col" key={label}>{label}</th>)}</tr></thead><tbody>
   {rows.map((row,index)=><tr key={row.id}><td>{index+1}</td><td>{row.faculty_name||'Not mapped'}</td><td>{row.subject_name||'Not mapped'}</td><td>{row.sem}</td><td className="note-report-description">{row.description||'—'}</td><td>{row.file_name||'Not available'}</td><td>{row.downloadable&&<button type="button" className="note-report-download" disabled={downloading!==null} aria-label={'Download '+row.file_name} onClick={()=>download(row)}>{downloading===row.id?'Downloading…':'Download'}</button>}</td><td><span className={row.downloadable?'note-report-available':'note-report-missing'}>{row.file_status}</span></td></tr>)}
   {!rows.length&&<tr><td colSpan="8">{loading?'Loading upload report…':error?'Unable to load upload report.':'No lecture notes uploaded yet.'}</td></tr>}
  </tbody></table></div>
 </section>;
}
