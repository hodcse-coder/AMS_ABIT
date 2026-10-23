import React,{useEffect,useRef,useState} from 'react';
import {api} from './Erp.jsx';
import {Icon} from './DashboardOverview.jsx';
import MessageDialog,{useConfirm,validationMessage} from './MessageDialog.jsx';
import './video-lectures.css';
const base='/api/admin/academics/video-lecture';
const safeUrl=value=>{try{return ['http:','https:'].includes(new URL(value).protocol)?value:null;}catch{return null;}};
const encode=file=>new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(String(reader.result).split(',')[1]);reader.onerror=()=>reject(new Error('Unable to read this video.'));reader.readAsDataURL(file);});

export default function VideoLectures(){
 const [subjects,setSubjects]=useState([]),[rows,setRows]=useState([]),[values,setValues]=useState({}),[file,setFile]=useState(null),[filters,setFilters]=useState({});
 const [loading,setLoading]=useState(true),[busy,setBusy]=useState(false),[message,setMessage]=useState(''),[error,setError]=useState('');
 const fileInput=useRef(null);const {confirm,confirmation}=useConfirm();
 useEffect(()=>{let active=true;Promise.all([api('/api/admin/course-modules/subjects'),api(base)]).then(([a,b])=>{if(active){setSubjects(a.subjects);setRows(b.records);}}).catch(error=>{if(active)setError(error.message);}).finally(()=>{if(active)setLoading(false);});return()=>{active=false;};},[]);
 const change=(key,value)=>setValues(previous=>({...previous,[key]:value}));
 function reset(){setValues({});setFile(null);if(fileInput.current)fileInput.current.value='';}
 async function save(event){event.preventDefault();if(!values.video_url?.trim()&&!file){setMessage('Enter a Video URL or choose a video file.');return;}if(file&&(!file.size||file.size>26214400)){setMessage('Choose a nonempty MP4, WebM or OGV video up to 25 MB.');return;}setBusy(true);try{const input={...values,...(file?{file_name:file.name,file_base64:await encode(file)}:{})};await api(base,{method:'POST',body:JSON.stringify(input)});setRows((await api(base)).records);reset();setMessage('Video lecture created successfully.');}catch(error){setMessage(error.message);}finally{setBusy(false);}}
 async function remove(row){if(!await confirm('Delete this video lecture?'))return;setBusy(true);try{await api(base+'/'+row.l_id,{method:'DELETE'});setRows((await api(base)).records);setMessage('Video lecture deleted.');}catch(error){setMessage(error.message);}finally{setBusy(false);}}
 const visible=rows.filter(row=>(!filters.subject||String(row.related_subject)===filters.subject)&&(!filters.description||row.brief_description.toLowerCase().includes(filters.description.trim().toLowerCase()))&&(!filters.uploader||String(row.created_by)===filters.uploader));
 const uploaders=[...new Map(rows.map(row=>[String(row.created_by),row.uploaded_by||'Not mapped'])).entries()];
 return <section className="video-lecture-page">{confirmation}<MessageDialog message={message} onDismiss={()=>setMessage('')}/>
  <h2>Upload Video</h2>{error&&<p className="video-error" role="alert">{error}</p>}
  <form className="video-form" onSubmit={save} onInvalid={event=>validationMessage(event,setMessage)}><fieldset disabled={loading||busy}><div className="video-fields">
   <label className="video-subject"><span className="video-field-label">Subject</span><select required value={values.related_subject||''} onChange={event=>change('related_subject',event.target.value)}><option value="">--- Select Subject ---</option>{subjects.map(row=><option key={row.subject_id} value={row.subject_id}>{row.subject_name} ({row.subject_code})</option>)}</select></label>
   <label className="video-description"><span className="video-field-label">Video Description</span><input required maxLength={2000} placeholder="Video Description in brief" value={values.brief_description||''} onChange={event=>change('brief_description',event.target.value)}/></label>
   <label className="video-url"><span className="video-field-label">Video URL</span><input type="url" maxLength={2000} placeholder="Video URL" value={values.video_url||''} onChange={event=>{change('video_url',event.target.value);setFile(null);if(fileInput.current)fileInput.current.value='';}}/></label>
   <span className="video-or">or</span><label className="video-file">Upload<input ref={fileInput} type="file" accept=".mp4,.webm,.ogv,video/mp4,video/webm,video/ogg" onChange={event=>{setFile(event.target.files?.[0]||null);change('video_url','');}}/><small>MP4, WebM or OGV, up to 25 MB.</small></label>
  </div><div className="video-actions"><button type="submit">{busy?'Saving…':'Create'}</button><button type="button" onClick={reset}>Reset</button></div></fieldset></form>
  <h2 className="video-list-heading">Video Lectures</h2><div className="video-table table-scroll"><table><thead><tr><th>#</th><th>Videos</th><th>Related Subject</th><th>Video Description</th><th>Uploaded by</th><th>Action</th></tr><tr><th/><th/><th><select aria-label="Filter Related Subject" value={filters.subject||''} onChange={event=>setFilters(previous=>({...previous,subject:event.target.value}))}><option value="">All subjects</option>{subjects.map(row=><option key={row.subject_id} value={row.subject_id}>{row.subject_name} ({row.subject_code})</option>)}</select></th><th><input aria-label="Filter Video Description" value={filters.description||''} onChange={event=>setFilters(previous=>({...previous,description:event.target.value}))}/></th><th><select aria-label="Filter Uploaded by" value={filters.uploader||''} onChange={event=>setFilters(previous=>({...previous,uploader:event.target.value}))}><option value="">All uploaders</option>{uploaders.map(([id,name])=><option key={id} value={id}>{name}</option>)}</select></th><th><button className="video-clear" onClick={()=>setFilters({})}>Clear</button></th></tr></thead><tbody>
   {visible.map((row,index)=><tr key={row.l_id}><td>{index+1}</td><td>{row.uploaded?<video controls preload="none" src={base+'/'+row.l_id+'/media'} aria-label={'Play '+row.brief_description}/>:safeUrl(row.video_url)?<a href={safeUrl(row.video_url)} target="_blank" rel="noreferrer">Watch Video</a>:<span>Unavailable</span>}</td><td>{row.subject_name||'Not mapped'} {row.subject_code&&`(${row.subject_code})`}</td><td>{row.brief_description}</td><td>{row.uploaded_by||'Not mapped'}</td><td><button className="video-delete" title="Delete" aria-label={'Delete '+row.brief_description} disabled={busy} onClick={()=>remove(row)}><Icon name="delete" size={16}/></button></td></tr>)}
   {!visible.length&&<tr><td colSpan="6">{loading?'Loading videos…':error?'Unable to load videos.':'No results found.'}</td></tr>}
  </tbody></table></div>
 </section>;
}
