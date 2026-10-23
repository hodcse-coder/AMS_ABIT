import React,{useEffect,useState} from 'react';
import * as Pages from './obe/ReferencePages.jsx';
import {api} from './Erp.jsx';
import {obeItems,obePages} from '../shared/obe.mjs';
import ErpLinks from './obe/ErpLinks.jsx';
import MessageDialog,{validationMessage} from './MessageDialog.jsx';
import './employees.css';
import './obe/obe.css';
const base='/api/admin/obe';
const components={'obe-departments':Pages.DepartmentsPage,'obe-programmes':Pages.ProgrammesPage,'obe-batches':Pages.AdmissionBatchManagementPage,'obe-semesters':Pages.SemestersPage,'obe-courses':Pages.CoursesPage,'obe-outcomes':Pages.CourseOutcomesPage,'obe-programme-outcomes':Pages.ProgrammeOutcomesPage,'obe-department-vision':Pages.DepartmentVisionMissionPage,'obe-target':Pages.AssessmentsPage,'obe-mapping':Pages.CoPoMappingPage,'obe-university-mapping':Pages.UniversityMappingQuestionPage,'obe-students':Pages.StudentMasterPage,'obe-enrolments':Pages.StudentCourseFacultyMappingPage,'obe-articulation':Pages.ArticulationMatrixPage,'obe-mark-attainment':Pages.MarkAttainmentPage,'obe-co-attainment':Pages.CoAttainmentCalculationPage,'obe-po-attainment':Pages.CoPoAttainmentPage,'obe-pso-attainment':Pages.CoPsoAttainmentPage,'obe-external-marks':Pages.ExternalMarkUploadPage,'obe-internal-marks':Pages.InternalMarkUploadPage};
export default function ObeModule({page,onNavigate}){
 if(page==='obe')return <section className="employee-image-page"><img src="/obe.png" alt="OBE"/></section>;
 const group=obeItems.find(item=>item.key===page),Component=components[page];
 // This source presentation flag shows the editors; ERP APIs enforce permissions.
 const presentation={role:'Admin'};
 return <section className="employee-page obe-workspace">{!Component&&<h2>{page==='obe'?'OBE':obePages.find(item=>item.key===page)?.label}</h2>}{page==='obe'||group?.children?<nav className="employee-overview">{(group?.children||obeItems).map(item=><button key={item.key} onClick={()=>onNavigate(item.key)}>{item.label}</button>)}</nav>:Component?<Component user={presentation}/>:page==='obe-institute-vision'?<InstituteVision/>:page==='obe-erp-links'||page==='obe-faculty'?<ErpLinks faculty={page==='obe-faculty'}/>:page==='obe-course-report'||page==='obe-department-report'?<Pages.SubjectWiseReportPage user={presentation} reportName={page==='obe-course-report'?'Course Wise':'Department Wise'}/>:<ObeOverview onNavigate={onNavigate}/>}</section>;
}
function ObeOverview({onNavigate}){
 const [counts,setCounts]=useState(null),[error,setError]=useState('');
 useEffect(()=>{Promise.all(['departments','programmes','courses','course-outcomes','students'].map(key=>api(base+'/'+key))).then(([departments,programmes,courses,outcomes,students])=>setCounts({Departments:departments.length,Programmes:programmes.length,Courses:courses.length,'Course Outcomes':outcomes.length,Students:students.length})).catch(error=>setError(error.message));},[]);
 return <><p className="employee-error" hidden={!error}>{error}</p><div className="obe-metrics">{counts?Object.entries(counts).map(([label,count])=><article key={label}><strong>{count}</strong><span>{label}</span></article>):<p>Loading OBE overview…</p>}</div><div className="employee-overview">{obeItems.filter(item=>item.children).map(item=><button key={item.key} onClick={()=>onNavigate(item.key)}>{item.label}</button>)}</div></>;
}
function InstituteVision(){
 const [records,setRecords]=useState([]),[message,setMessage]=useState(''),[busy,setBusy]=useState(false);
 useEffect(()=>{api(base+'/dashboard-content').then(setRecords).catch(error=>setMessage(error.message));},[]);
 async function save(event,row){event.preventDefault();setBusy(true);try{await api(base+'/dashboard-content/'+row.content_type,{method:'POST',body:JSON.stringify(row)});setMessage(row.content_label+' saved.');}catch(error){setMessage(error.message);}finally{setBusy(false);}}
 return <><MessageDialog message={message} onDismiss={()=>setMessage('')}/>{records.map(row=><form className="employee-card" key={row.content_type} onSubmit={event=>save(event,row)} onInvalid={event=>validationMessage(event,setMessage)}><h3>{row.content_label}</h3><label>Statement <span>*</span><textarea required rows={5} value={row.content_statement} onChange={event=>setRecords(previous=>previous.map(item=>item.content_type===row.content_type?{...item,content_statement:event.target.value}:item))}/></label><div className="employee-buttons"><button disabled={busy} type="submit">Save</button></div></form>)}</>;
}
