import React,{useEffect,useState} from 'react';
import {api} from './Erp.jsx';
import MessageDialog,{validationMessage} from './MessageDialog.jsx';
import './lecture-notes.css';

const base='/api/admin/academics/lecture-notes';
const emptyOptions={courses:[],batches:[],sections:[],houses:[],subjects:[],faculty:[]};
const readFile=file=>new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(String(reader.result).split(',')[1]);reader.onerror=()=>reject(new Error('Unable to read the selected file.'));reader.readAsDataURL(file);});

export default function LectureNotes({onNavigate}){
 const [rows,setRows]=useState([]),[options,setOptions]=useState(emptyOptions),[filters,setFilters]=useState({});
 const [loading,setLoading]=useState(true),[busy,setBusy]=useState(false),[message,setMessage]=useState(''),[error,setError]=useState('');
 const [upload,setUpload]=useState(null),[title,setTitle]=useState(''),[file,setFile]=useState(null),[assigning,setAssigning]=useState(false),[values,setValues]=useState({section_type:'S',student_group:'ALL',teacher_type:'M'});
 async function refresh(){const result=await api(base);setRows(result.records);}
 useEffect(()=>{let active=true;Promise.all([api(base),api(base+'/options')]).then(([data,choices])=>{if(active){setRows(data.records);setOptions(choices);}}).catch(error=>{if(active)setError(error.message);}).finally(()=>{if(active)setLoading(false);});return()=>{active=false;};},[]);
 function filter(key,value){setFilters(previous=>({...previous,[key]:value,...(key==='shst_course_id'?{batch_id:''}:{})}));}
 const visible=rows.filter(row=>Object.entries(filters).every(([key,value])=>!value||(['shst_semester','teacher_type'].includes(key)?String(row[key]??'').toLowerCase().includes(value.toLowerCase()):String(row[key])===String(value))));
 const choices=key=>[...new Map(rows.filter(row=>row[key]!=null).map(row=>[String(row[key]),row])).values()];
 const dropdown=(key,label,text,source=choices(key))=><select aria-label={'Filter '+label} value={filters[key]||''} onChange={event=>filter(key,event.target.value)}><option value="">All</option>{source.map(row=><option key={row[key]} value={row[key]}>{text(row)}</option>)}</select>;
 function startUpload(row){setUpload(row);setTitle('');setFile(null);setAssigning(false);}
 async function saveNote(event){
  event.preventDefault();if(!file){setMessage('Choose a document to upload.');return;}
  if(file.size>10485760||!file.size){setMessage('Choose a nonempty document up to 10 MB.');return;}
  setBusy(true);try{const encoded=await readFile(file);await api(base+'/assignments/'+upload.shst_id,{method:'POST',body:JSON.stringify({description:title,file_name:file.name,file_base64:encoded})});await refresh();setUpload(null);setFile(null);setMessage('Lecture note uploaded successfully.');}catch(error){setMessage(error.message);}finally{setBusy(false);}
 }
 async function download(note){
  setBusy(true);try{const response=await fetch(base+'/'+note.id+'/download');if(!response.ok){const data=await response.json();throw new Error(data.error||'Unable to download this note.');}const url=URL.createObjectURL(await response.blob());const link=document.createElement('a');link.href=url;link.download=note.file_name||'lecture-note';document.body.appendChild(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),30000);}catch(error){setMessage(error.message);}finally{setBusy(false);}
 }
 function change(key,value){setValues(previous=>({...previous,[key]:value,...(key==='course_id'?{batch_id:'',section_id:''}:key==='batch_id'||key==='section_type'?{section_id:''}:{})}));}
 const select=(key,label,items,disabled=false)=><label>{label} <span>*</span><select required disabled={disabled} value={values[key]??''} onChange={event=>change(key,event.target.value)}><option value="">Select {label}</option>{items.map(([value,text])=><option key={value} value={value}>{text}</option>)}</select></label>;
 async function assign(event){event.preventDefault();setBusy(true);try{await api(base+'/assignments',{method:'POST',body:JSON.stringify(values)});await refresh();setAssigning(false);setMessage('Faculty assigned successfully.');}catch(error){setMessage(error.message);}finally{setBusy(false);}}
 return <section className="lecture-notes-page"><MessageDialog message={message} onDismiss={()=>setMessage('')}/>
  <div className="lecture-notes-heading"><h2>Lecture Notes</h2><div><button type="button" className="lecture-clear" disabled={busy} onClick={()=>setFilters({})}>Clear Filters</button><button type="button" className="lecture-assign" disabled={busy||loading} onClick={()=>{setAssigning(value=>!value);setUpload(null);}}>Assign Faculty</button></div></div>
  {error&&<p className="lecture-error" role="alert">{error}</p>}
  {assigning&&<form className="lecture-editor" onSubmit={assign} onInvalid={event=>validationMessage(event,setMessage)}><h3>Assign Faculty</h3><fieldset disabled={busy}><div className="lecture-assignment-fields">
   {select('course_id','Course',options.courses.map(row=>[row.course_id,row.course_name]))}
   {select('batch_id','Batch',options.batches.filter(row=>String(row.batch_course_id)===String(values.course_id)).map(row=>[row.batch_id,row.batch_name]),!values.course_id)}
   {select('semester','Semester',Array.from({length:12},(_,index)=>[index+1,index+1]))}
   {select('section_type','Section Type',[['S','Section'],['H','House']])}
   {select('section_id','Section',values.section_type==='H'?options.houses.map(row=>[row.section_master_id,row.section_master_name]):options.sections.filter(row=>String(row.section_batch_id)===String(values.batch_id)).map(row=>[row.s_id,row.section_name]),values.section_type==='S'&&!values.batch_id)}
   <label>Student Group <span>*</span><input required pattern="[A-Z0-9]{1,3}" maxLength={3} value={values.student_group} onChange={event=>change('student_group',event.target.value.toUpperCase())}/></label>
   {select('subject_id','Subject',options.subjects.map(row=>[row.subject_id,`${row.subject_name} (${row.subject_code})`]))}
   {select('teacher_id','Faculty',options.faculty.map(row=>[row.user_id,row.full_name]))}
   {select('teacher_type','Teacher Type',[['M','M — Main'],['A','A — Assistant']])}
  </div><div className="lecture-actions"><button className="lecture-assign" type="submit">{busy?'Saving…':'Create Assignment'}</button><button type="button" onClick={()=>setAssigning(false)}>Cancel</button></div></fieldset>
  {(!options.courses.length||!options.sections.length||!options.faculty.length)&&<p className="lecture-setup">Set up <button type="button" onClick={()=>onNavigate('course')}>Courses and Batches</button>, <button type="button" onClick={()=>onNavigate('assign-section')}>Sections</button> and <button type="button" onClick={()=>onNavigate('accounts')}>Faculty accounts</button> before assigning faculty.</p>}
  </form>}
  {upload&&<form className="lecture-editor" onSubmit={saveNote} onInvalid={event=>validationMessage(event,setMessage)}><h3>Upload Lecture Note</h3><p>{upload.subject_name} ({upload.subject_code}) · {upload.faculty_name} · {upload.batch_name||upload.shst_batch_id} · Semester {upload.shst_semester}</p><fieldset disabled={busy}><div className="lecture-upload-fields"><label>Note Title <span>*</span><input required maxLength={500} value={title} onChange={event=>setTitle(event.target.value)}/></label><label>Attachment <span>*</span><input required type="file" accept=".pdf,.doc,.docx,.ppt,.pptx" onChange={event=>setFile(event.target.files?.[0]||null)}/><small>PDF, DOC, DOCX, PPT or PPTX, up to 10 MB.</small></label></div><div className="lecture-actions"><button className="lecture-upload" type="submit">{busy?'Uploading…':'Upload'}</button><button type="button" onClick={()=>setUpload(null)}>Cancel</button></div></fieldset></form>}
  <div className="lecture-table table-scroll"><table><thead><tr>{['#','Course','Batch','Semester','Section','Student Group','Subject','Faculty','Teacher Type','Existing Lecture Notes',''].map((label,index)=><th key={index}>{label}</th>)}</tr><tr className="lecture-filters"><th/><th>{dropdown('shst_course_id','Course',row=>row.course_code||row.course_name||row.shst_course_id)}</th><th>{dropdown('batch_id','Batch',row=>row.batch_name,choices('batch_id').filter(row=>!filters.shst_course_id||String(row.shst_course_id)===String(filters.shst_course_id)))}</th><th><input aria-label="Filter Semester" value={filters.shst_semester||''} onChange={event=>filter('shst_semester',event.target.value)}/></th><th/><th/><th>{dropdown('shst_subject_id','Subject',row=>`${row.subject_name} (${row.subject_code})`)}</th><th>{dropdown('shst_teacher_id','Faculty',row=>row.faculty_name||row.shst_teacher_id)}</th><th><input aria-label="Filter Teacher Type" value={filters.teacher_type||''} onChange={event=>filter('teacher_type',event.target.value)}/></th><th/><th/></tr></thead><tbody>
   {visible.map((row,index)=><tr key={row.shst_id}><td>{index+1}</td><td>{row.course_code||row.course_name||'Not mapped'}</td><td>{row.batch_name||row.shst_batch_id}</td><td>{row.shst_semester}</td><td>{row.section_name||'Not mapped'}</td><td>{row.student_group}</td><td>{row.subject_name||'Not mapped'} {row.subject_code&&`(${row.subject_code})`}</td><td>{row.faculty_name||'Not mapped'}</td><td>{row.teacher_type}</td><td className="lecture-existing">{row.notes.map(note=><button key={note.id} className="lecture-note-link" disabled={busy||!note.downloadable} title={note.downloadable?note.file_name:'Attachment unavailable; upload the note again.'} onClick={()=>download(note)}><span aria-hidden="true">↗ </span>{note.description||note.file_name||'Lecture Note'}</button>)}</td><td><button className="lecture-upload" disabled={busy||!row.subject_name||!row.faculty_name} onClick={()=>startUpload(row)}><span aria-hidden="true">↑ </span>Upload</button></td></tr>)}
   {!visible.length&&<tr><td colSpan="11">{loading?'Loading lecture notes…':error?'Unable to load lecture notes.':rows.length?'No matching teaching assignments.':'No teaching assignments yet. Use Assign Faculty to add one.'}</td></tr>}
  </tbody></table></div>
 </section>;
}
