import Branches from './Branches.jsx';
import React, { useEffect, useState } from 'react';
import { api } from './Erp.jsx';
import { Icon } from './DashboardOverview.jsx';
import ConfigurationIcon from './ConfigurationIcon.jsx';
import MessageDialog, { useConfirm, validationMessage } from './MessageDialog.jsx';
import './course-modules.css';
import CourseForm from './CourseForm.jsx';
import ManageCourses from './ManageCourses.jsx';
import BatchManagement from './BatchManagement.jsx';
import AssignSection from './AssignSection.jsx';
import SectionDefinitions from './SectionDefinitions.jsx';
import SectionMaster from './SectionMaster.jsx';
import AcademicYear from './AcademicYear.jsx';
import Subjects from './Subjects.jsx';
import './section-country.css';

export default function CourseModules({ page, onNavigate }) {
  const [data,setData]=useState({courses:[],batches:[],sections:[]});
  const [loading,setLoading]=useState(true);
  const [mode,setMode]=useState(page==='course'?'courses':null);
  const [values,setValues]=useState({});
  const [editing,setEditing]=useState(null);
  const [message,setMessage]=useState('');
  const [busy,setBusy]=useState(false);
  const [members,setMembers]=useState(null);
  const [courseFilter,setCourseFilter]=useState('');
  const {confirm,confirmation}=useConfirm();
  async function refresh(){setData(await api('/api/admin/course-modules'));}
  useEffect(()=>{refresh().catch(error=>setMessage(error.message)).finally(()=>setLoading(false));},[]);
  useEffect(()=>{setMode(page==='course'?'courses':page==='batch'?'batches':page==='add-section'||page==='section-master'?'sections':null);setEditing(null);setValues({});setMembers(null);},[page]);
  function start(type,course){setMode(type);setEditing(course?.course_id||null);setValues(course?{course_name:course.course_name,course_code:course.course_code,course_alias:course.course_alias,course_duration:course.course_duration,is_active:course.is_active}:{});setMembers(null);}
  async function save(event){
    event.preventDefault();setBusy(true);
    try{await api(`/api/admin/course-modules/${mode}${editing?`/${editing}`:''}`,{method:editing?'PATCH':'POST',body:JSON.stringify(values)});await refresh();setMode(page === 'course' ? 'courses' : null);setEditing(null);setValues({});setMessage('Saved successfully.');}
    catch(error){setMessage(error.message);}finally{setBusy(false);}
  }
  async function remove(course){
    if(!await confirm(`Delete ${course.course_name}? Courses with batches or students cannot be deleted.`))return;
    setBusy(true);try{await api(`/api/admin/course-modules/courses/${course.course_id}`,{method:'DELETE'});await refresh();setMessage('Course deleted.');}catch(error){setMessage(error.message);}finally{setBusy(false);}
  }
  async function showStudents(course){setBusy(true);try{const result=await api(`/api/admin/course-modules/courses/${course.course_id}/students`);setMembers({name:course.course_name,rows:result.students});setMode(null);}catch(error){setMessage(error.message);}finally{setBusy(false);}}
  function showBatches(course){setCourseFilter(course.course_id);setMode('batches');setValues({course_id:course.course_id});setEditing(null);setMembers(null);}
  const active=data.courses.filter(course=>course.is_active);
  const input=(name,value)=>setValues(previous=>({...previous,[name]:value}));
  if (page === 'assign-section') return <><MessageDialog message={message} onDismiss={()=>setMessage('')}/><AssignSection batches={data.batches} loading={loading} onRefresh={refresh} onNavigate={onNavigate}/></>;
  if (page === 'add-branch') return <Branches courses={data.courses} loadingCourses={loading}/>;
  if (page === 'academic-year') return <AcademicYear/>;
  if (page === 'subjects') return <Subjects onNavigate={onNavigate}/>;
  if (page === 'section-master') return <SectionMaster/>;
  if (page === 'add-section') return <><MessageDialog message={message} onDismiss={()=>setMessage('')}/><SectionDefinitions courses={data.courses} onNavigate={onNavigate}/></>;
  if (page === 'batch' || mode === 'batches') return <><MessageDialog message={message} onDismiss={()=>setMessage('')}/><BatchManagement courses={data.courses} batches={data.batches} loading={loading} onRefresh={refresh} initialCourseId={values.course_id} /></>;
  return <div className="course-modules">
    {confirmation}<MessageDialog message={message} onDismiss={()=>setMessage('')}/>
    {page !== 'course' && mode !== 'courses' && <section className="course-module-summary"><h2>Manage Course Modules</h2><div className="course-summary-grid">
      {[{label:'Manage Course',count:data.courses.length,type:'courses',tone:'orange'},{label:'Manage Batches',count:data.batches.length,type:'batches',tone:'aqua'},{label:'Manage Section',count:data.sections.length,type:'sections',tone:'emerald'}].map(item=><article className="course-summary-card" key={item.type}><div className={`course-summary-icon ${item.tone}`}>{item.type==='courses'?<ConfigurationIcon name="last_passout_institution"/>:item.type==='batches'?<Icon name="users" size={39}/>:<svg width="39" height="39" viewBox="0 0 32 32" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><rect x="12" y="2" width="8" height="8" rx="1"/><path d="M16 10v7M5 23v-6h22v6M16 17v6"/><rect x="1" y="23" width="8" height="7" rx="1"/><rect x="12" y="23" width="8" height="7" rx="1"/><rect x="23" y="23" width="8" height="7" rx="1"/></svg>}</div><div><button className="course-card-title" onClick={()=>start(item.type)}>{item.label}</button><strong>{loading?'—':item.count}</strong><button className="course-create-link" onClick={()=>start(item.type)}>⊞ Create New</button></div></article>)}
    </div></section>}
    {mode==='courses' && <CourseForm values={values} setValues={setValues} editing={editing} busy={busy} onSave={save} onMessage={setMessage} onCancel={()=>{setMode(null);setEditing(null);setValues({});}}/>}
    {(page==='course'||mode==='courses')&&<ManageCourses courses={data.courses} loading={loading} busy={busy} onEdit={course=>start('courses',course)} onDelete={remove} onView={course=>setMessage(`${course.course_name}\nCourse Code: ${course.course_code}\nCourse Alias: ${course.course_alias}\nDuration in Years: ${course.course_duration}\nStatus: ${course.is_active?'Active':'Inactive'}`)}/>}
    {mode&&mode!=='courses'&&<section className="course-module-editor"><div className="course-module-panel-title"><h2>{editing?'Edit': 'Add'} {mode==='courses'?'Course':mode==='batches'?'Batch':'Section'}</h2><button className="course-text-button" onClick={()=>{setMode(null);setEditing(null);setValues({});}}>Close</button></div><form onSubmit={save} onInvalid={event=>validationMessage(event,setMessage)}><fieldset disabled={busy}><div className="course-form-fields">
      {mode==='batches'?<><label>Course *<select required value={values.course_id||''} onChange={event=>input('course_id',event.target.value)}><option value="">Select Course</option>{data.courses.map(course=><option key={course.course_id} value={course.course_id}>{course.course_name}</option>)}</select></label><label>Batch Name *<input required maxLength={120} value={values.batch_name||''} onChange={event=>input('batch_name',event.target.value.toUpperCase())}/></label><label>Batch Alias *<input required maxLength={35} value={values.batch_alias||''} onChange={event=>input('batch_alias',event.target.value.toUpperCase())}/></label><label>Start Date *<input type="date" required value={values.start_date||''} onChange={event=>input('start_date',event.target.value)}/></label><label>End Date *<input type="date" required value={values.end_date||''} onChange={event=>input('end_date',event.target.value)}/></label></>:<><label>Batch *<select required value={values.batch_id||''} onChange={event=>input('batch_id',event.target.value)}><option value="">Select Batch</option>{data.batches.map(batch=><option key={batch.batch_id} value={batch.batch_id}>{batch.course_name} / {batch.batch_name}</option>)}</select></label><label>Section Name *<input required maxLength={50} value={values.section_name||''} onChange={event=>input('section_name',event.target.value.toUpperCase())}/></label></>}
    </div><div className="course-form-actions"><button type="submit">{busy?'Saving…':editing?'Update':'Create'}</button><button className="course-reset" type="button" onClick={()=>setValues({})}>Reset</button></div></fieldset></form></section>}
    {members&&<section className="course-module-list"><div className="course-module-panel-title"><h2>{members.name} — Students</h2><button className="course-text-button" onClick={()=>setMembers(null)}>Close</button></div>{members.rows.length?<div className="table-scroll"><table><thead><tr><th>Name</th><th>User Name</th><th>Batch</th></tr></thead><tbody>{members.rows.map(student=><tr key={student.user_id}><td>{student.full_name}</td><td>{student.username}</td><td>{student.batch_name||'Not assigned'}</td></tr>)}</tbody></table></div>:<p className="course-empty">No students assigned to this course.</p>}</section>}
    {['batches','sections'].includes(mode)&&<section className="course-module-list"><div className="course-module-panel-title"><h2>{mode==='batches'?'Batch':'Section'} List</h2>{mode==='batches'&&<select aria-label="Filter batches by course" value={courseFilter} onChange={event=>setCourseFilter(event.target.value)}><option value="">All courses</option>{data.courses.map(course=><option key={course.course_id} value={course.course_id}>{course.course_name}</option>)}</select>}</div><div className="table-scroll"><table><thead><tr><th>Course</th><th>Batch</th>{mode==='sections'&&<th>Section</th>}</tr></thead><tbody>{(mode==='batches'?data.batches.filter(batch=>!courseFilter||String(batch.course_id)===String(courseFilter)):data.sections).map(row=><tr key={row.batch_id+'-'+(row.section_id||'')}><td>{row.course_name}</td><td>{row.batch_name}</td>{mode==='sections'&&<td>{row.section_name}</td>}</tr>)}</tbody></table></div></section>}
    {page !== 'course' && mode !== 'courses' && [{title:'Manage Current Active Course',rows:active},{title:'Inactive Courses',rows:data.courses.filter(course=>!course.is_active)}].filter((group,index)=>index===0||group.rows.length).map(group=><section className="course-module-list" key={group.title}><h2>{group.title}</h2><div className="course-active-list">{group.rows.map((course,index)=><article className="course-active-row" key={course.course_id}><button className="course-row-name" onClick={()=>setMessage(`${course.course_name}\nCode: ${course.course_code}\nStudents: ${course.student_count}\nBatches: ${course.batch_count}\nStatus: ${course.is_active?'Active':'Inactive'}`)}>{index+1}. {course.course_name}</button><div className="course-row-actions"><button className="course-students" disabled={busy} onClick={()=>showStudents(course)}><Icon name="users" size={12}/> Students <span>{course.student_count}</span></button><button className="course-batches" onClick={()=>showBatches(course)}><Icon name="grid" size={12}/> Batches <span>{course.batch_count}</span></button><button className="course-small-action" title={`View ${course.course_name}`} aria-label={`View ${course.course_name}`} onClick={()=>setMessage(`${course.course_name}\nCode: ${course.course_code}\nStatus: ${course.is_active?'Active':'Inactive'}`)}>◉</button><button className="course-small-action" title={`Edit ${course.course_name}`} aria-label={`Edit ${course.course_name}`} onClick={()=>start('courses',course)}>✎</button><button className="course-small-action" disabled={busy} title={`Delete ${course.course_name}`} aria-label={`Delete ${course.course_name}`} onClick={()=>remove(course)}>⌫</button></div></article>)}{!group.rows.length&&<p className="course-empty">{loading?'Loading courses…':'No active courses yet. Click Create New to add a course.'}</p>}</div></section>)}
  </div>;
}
