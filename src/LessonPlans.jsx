import React,{useEffect,useRef,useState} from 'react';
import {api} from './Erp.jsx';
import {Icon} from './DashboardOverview.jsx';
import MessageDialog,{validationMessage} from './MessageDialog.jsx';
import './lesson-plans.css';

const endpoint='/api/admin/academics/lesson-plan';
const title=subject=>`${subject.academic_year?subject.academic_year+' - ':''}${subject.subject_name} (${subject.subject_code})`;
const selectedCOs=value=>Array.isArray(value)?value:typeof value==='string'?value.split(',').map(item=>item.trim()).filter(Boolean):[];
const safeLink=value=>{try{return ['http:','https:'].includes(new URL(value).protocol)?value:null;}catch{return null;}};

export default function LessonPlans({onNavigate}){
 const [subjects,setSubjects]=useState([]),[selected,setSelected]=useState(null),[data,setData]=useState(null);
 const [loading,setLoading]=useState(true),[busy,setBusy]=useState(false),[message,setMessage]=useState('');
 const [mode,setMode]=useState('view'),[tab,setTab]=useState('topics'),[draft,setDraft]=useState([]);
 const [search,setSearch]=useState(''),[page,setPage]=useState(1),[error,setError]=useState('');
 const sequence=useRef(0),draftId=useRef(0);
 useEffect(()=>{let active=true;api(endpoint).then(result=>{if(active)setSubjects(result.records);}).catch(error=>{if(active)setError(error.message);}).finally(()=>{if(active)setLoading(false);});return()=>{active=false;sequence.current++;};},[]);
 async function open(subject){
  const request=++sequence.current;setSelected(subject);setData(null);setMode('view');setTab('topics');setLoading(true);setError('');
  try{const result=await api(endpoint+'/subjects/'+subject.subject_id);if(request===sequence.current)setData(result);}
  catch(error){if(request===sequence.current)setError(error.message);}
  finally{if(request===sequence.current)setLoading(false);}
 }
 function back(){if(mode==='edit'){setMode('view');return;}sequence.current++;setSelected(null);setData(null);setError('');setLoading(false);}
 function organize(){setDraft(data.topics.map(row=>({...row,_key:++draftId.current,pagenumber:Number(row.pagenumber)||'',book_id:row.book_id||'',ppt_req:String(row.ppt_req),co:selectedCOs(row.co)})));setMode('edit');}
 function add(){setDraft(rows=>[...rows,{_key:++draftId.current,topics:'',co:[],book_id:'',pagenumber:'',ppt_req:'',video_url:''}]);}
 function change(key,field,value){setDraft(rows=>rows.map(row=>row._key===key?{...row,[field]:value}:row));}
 async function save(event){
  event.preventDefault();setBusy(true);
  try{await api(endpoint+'/subjects/'+selected.subject_id,{method:'PUT',body:JSON.stringify({topics:draft})});await open(selected);setSubjects(rows=>rows.map(row=>String(row.subject_id)===String(selected.subject_id)?{...row,topic_count:draft.length}:row));setMessage('Lesson plan updated successfully.');}
  catch(error){setMessage(error.message);}finally{setBusy(false);}
 }
 const field=(row,key,label,control,required=false)=><label className={'lesson-field lesson-field-'+key}>{label}{required&&<span> *</span>}{control}</label>;
 const control=(row,key,props={})=><input value={row[key]??''} onChange={event=>change(row._key,key,event.target.value)} {...props}/>;
 const select=(row,key,options)=><select required value={row[key]??''} onChange={event=>change(row._key,key,event.target.value)}><option value="">{key==='book_id'?'--- Select Book ---':'- Select -'}</option>{options.map(([value,label])=><option key={value} value={value}>{label}</option>)}</select>;
 const filtered=subjects.filter(row=>[title(row),row.branch_name,row.semester].join(' ').toLowerCase().includes(search.toLowerCase()));
 const pages=Math.max(1,Math.ceil(filtered.length/20)),currentPage=Math.min(page,pages),start=(currentPage-1)*20;
 const resources=data?.topics.filter(row=>safeLink(row.ppt)||safeLink(row.video_url))||[];
 return <section className="lesson-page"><MessageDialog message={message} onDismiss={()=>setMessage('')}/>
 {!selected?<>
  <h2 className="lesson-heading">Manage Lessonplans</h2>
  <div className="lesson-subjects"><div className="lesson-list-tools"><span>{loading?'Loading subjects…':`Showing ${filtered.length?start+1:0}–${Math.min(start+20,filtered.length)} of ${filtered.length} items.`}</span><input aria-label="Search lesson plan subjects" type="search" placeholder="Search subjects…" value={search} onChange={event=>{setSearch(event.target.value);setPage(1);}}/></div>
   {error&&<p role="alert" className="lesson-error">{error}</p>}
   <div className="table-scroll"><table><thead><tr><th>#</th><th>Subjects</th><th>Semester</th><th>Topics</th><th>Action</th></tr></thead><tbody>{filtered.slice(start,start+20).map((subject,index)=><tr key={subject.subject_id}><td>{start+index+1}</td><td>{title(subject)}{subject.branch_name&&<small>{subject.branch_name}</small>}</td><td>{subject.semester??'Not mapped'}</td><td>{subject.topic_count}</td><td><button type="button" className="lesson-view" title="View lesson plan" aria-label={'View lesson plan for '+subject.subject_name} onClick={()=>open(subject)}><Icon name="view" size={17}/></button></td></tr>)}{!filtered.length&&<tr><td colSpan="5">{loading?'Loading…':error?'Unable to load subjects.':'No subjects found.'}</td></tr>}</tbody></table></div>
   <div className="lesson-pagination"><button disabled={currentPage===1} onClick={()=>setPage(currentPage-1)}>Previous</button><span>Page {currentPage} of {pages}</span><button disabled={currentPage===pages} onClick={()=>setPage(currentPage+1)}>Next</button></div>
  </div>
 </>:<>
  <div className="lesson-title-row"><h2 className="lesson-heading">{title(selected)} / Semester {selected.semester??'Not mapped'}</h2><button className="lesson-back" disabled={busy} onClick={back}>Back</button></div>
  {loading?<p role="status">Loading lesson plan…</p>:error?<p role="alert" className="lesson-error">{error} <button onClick={()=>open(selected)}>Retry</button></p>:data&&<>
   {mode==='edit'?<form onSubmit={save} onInvalid={event=>validationMessage(event,setMessage)}><fieldset disabled={busy} className="lesson-organizer">
    <p className="lesson-organizer-title">Lesson Plan Organizer : Details of Topics to be covered</p>
    {!draft.length&&<p className="lesson-empty">No topics yet. Add a new topic to get started.</p>}
    {draft.map((row,index)=><div className="lesson-topic-editor" key={row._key}><div className="lesson-topic-number">{index+1}<button type="button" className="lesson-remove" aria-label={`Remove topic ${index+1}`} onClick={()=>setDraft(rows=>rows.filter(item=>item._key!==row._key))}>×</button></div><div className="lesson-topic-fields">
     {field(row,'topics','Topic Description',control(row,'topics',{required:true,maxLength:5000}),true)}
     {field(row,'co','COs',<><select multiple required size={5} value={selectedCOs(row.co)} onChange={event=>change(row._key,'co',Array.from(event.target.selectedOptions,option=>option.value))}>{[1,2,3,4,5].map(number=>{const value='CO-'+number;const outcome=data.outcomes.find(item=>item.cotype===value);return <option key={value} value={value} title={outcome?.codescription}>{value}</option>;})}</select><small>Ctrl/Cmd + click to select multiple COs.</small></>,true)}
     {field(row,'book_id','Choose Book',select(row,'book_id',data.books.map(book=>[book.book_id,book.book_name])),true)}
     {field(row,'pagenumber','Page',control(row,'pagenumber',{type:'number',min:0,max:1000000,step:1}))}
     {field(row,'ppt_req','PPT Requirement',select(row,'ppt_req',[['1','Required'],['0','Not Required']]),true)}
     {field(row,'video_url','Video URL',control(row,'video_url',{type:'url',maxLength:2000,placeholder:'https://'}))}
    </div></div>)}
    <div className="lesson-editor-actions"><button className="lesson-primary" type="button" disabled={draft.length>=100} onClick={add}>Add a New Topic</button><button className="lesson-update" type="submit">{busy?'Updating…':'Update'}</button></div>
   </fieldset></form>:<div className="lesson-layout">
    <aside className="lesson-books"><div className="lesson-book-content"><h3>Books</h3>{data.books.length?<ol>{data.books.map(book=><li key={book.book_id}>{book.book_name}{book.author&&<small>{book.author}</small>}</li>)}</ol>:<p className="lesson-book-warning">No information available. To add topics you must enter at least one book name.</p>}<button className="lesson-book-link" onClick={()=>onNavigate('academics-preferred-books')}>{data.books.length?'Manage Books':'Add a Book'}</button></div></aside>
    <div className="lesson-detail"><div className="lesson-tabs" role="tablist" aria-label="Lesson plan sections"><button id="lesson-topics-tab" role="tab" aria-controls="lesson-topics-panel" aria-selected={tab==='topics'} onClick={()=>setTab('topics')}>Topics to be covered</button><button id="lesson-resources-tab" role="tab" aria-controls="lesson-resources-panel" aria-selected={tab==='resources'} onClick={()=>setTab('resources')}>Related PPT and Videos</button></div>
     <div role="tabpanel" id={tab==='topics'?'lesson-topics-panel':'lesson-resources-panel'} aria-labelledby={tab==='topics'?'lesson-topics-tab':'lesson-resources-tab'}>
      <h3 className="lesson-section-title">{tab==='topics'?'Lesson Plan':'Related PPT and Videos'}</h3>
      <div className="table-scroll"><table><thead><tr>{(tab==='topics'?['Lesson No.','Topics','CO','Book','Page','PPTs']:['Lesson No.','Topics','PPT','Video']).map(label=><th key={label}>{label}</th>)}</tr></thead><tbody>
       {(tab==='topics'?data.topics:resources).map(row=><tr key={row.lessonplan_id}><td>{row.module}</td><td className="lesson-topic-text">{row.topics}</td>{tab==='topics'?<><td>{selectedCOs(row.co).join(', ')}</td><td>{row.current_book_name||row.bookname}</td><td>{Number(row.pagenumber)||'—'}</td><td>{row.ppt_req==='1'?'Required':'Not required'}</td></>:<><td>{safeLink(row.ppt)?<a href={safeLink(row.ppt)} target="_blank" rel="noreferrer">View PPT</a>:'Not available'}</td><td>{safeLink(row.video_url)?<a href={safeLink(row.video_url)} target="_blank" rel="noreferrer">Watch video</a>:'Not available'}</td></>}</tr>)}
       {!(tab==='topics'?data.topics:resources).length&&<tr><td colSpan={tab==='topics'?6:4}>{tab==='topics'?'No topics added yet.':'No related PPT or videos available.'}</td></tr>}
      </tbody></table></div>
      {tab==='topics'&&data.books.length>0&&<div className="lesson-detail-actions"><button className="lesson-update" onClick={organize}><Icon name="edit" size={14}/> Add or Update Topics</button></div>}
     </div>
    </div>
   </div>}
  </>}
 </>}
 </section>;
}
