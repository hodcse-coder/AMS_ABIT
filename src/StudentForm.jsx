import React,{useState} from 'react';
import {api} from './Erp.jsx';
import MessageDialog,{validationMessage} from './MessageDialog.jsx';
import {studentSections,studentDefaults} from '../shared/students.mjs';
import {courseSemesterOptions} from '../shared/course-semesters.mjs';
export function studentReferenceOptions(key,options,values){
 if(key==='course_id')return options.courses.map(row=>[row.course_id,row.course_name]);
 if(key==='batch_id')return options.batches.filter(row=>String(row.batch_course_id)===String(values.course_id)).map(row=>[row.batch_id,row.batch_name]);
 if(key==='section_id')return options.sections.filter(row=>String(row.section_batch_id)===String(values.batch_id)).map(row=>[row.s_id,row.section_name]);
 if(key==='admission_category_id')return options.categories.map(row=>[row.stu_category_id,row.stu_category_name]);
 if(key==='nationality_id')return options.nationalities.map(row=>[row.nationality_id,row.nationality_name]);
 if(key.endsWith('_country_id'))return options.countries.map(row=>[row.country_id,row.country_name]);
 const prefix=key.split('_')[0];
 if(key.endsWith('_state_id'))return options.states.filter(row=>String(row.state_country_id)===String(values[prefix+'_country_id'])).map(row=>[row.state_id,row.state_name]);
 if(key.endsWith('_city_id'))return options.cities.filter(row=>String(row.city_state_id)===String(values[prefix+'_state_id'])).map(row=>[row.city_id,row.city_name]);
 return [];
}
export function changeStudentField(previous,key,value){return {...previous,[key]:value,...(key==='course_id'?{batch_id:'',section_id:'',semester:'1'}:key==='batch_id'?{section_id:''}:key.endsWith('_country_id')?{[key.replace('_country_id','_state_id')]:'',[key.replace('_country_id','_city_id')]:''}:key.endsWith('_state_id')?{[key.replace('_state_id','_city_id')]:''}:{})};}
export default function StudentForm({options,record,onSaved,onCancel}){
 const [values,setValues]=useState(()=>({...studentDefaults(),...(record?.form||{})})),[busy,setBusy]=useState(false),[message,setMessage]=useState('');
 const readOnly=record?.readOnly,change=(key,value)=>setValues(previous=>changeStudentField(previous,key,value));
 async function save(event){event.preventDefault();setBusy(true);try{const result=await api('/api/admin/students'+(record?'/'+record.id:''),{method:record?'PATCH':'POST',body:JSON.stringify(values)});await onSaved(result);}catch(error){setMessage(error.message);}finally{setBusy(false);}}
 function renderField(field){const value=values[field.key]??'',choices=field.type==='semester'?courseSemesterOptions(options.courses.find(row=>String(row.course_id)===String(values.course_id))?.course_duration):field.options||studentReferenceOptions(field.key,options,values);
  const props={required:field.required,value,onChange:event=>change(field.key,event.target.value)};
  const disabled=field.key==='batch_id'&&!values.course_id||field.key==='section_id'&&!values.batch_id||field.type==='semester'&&!values.course_id||field.key.endsWith('_state_id')&&!values[field.key.replace('_state_id','_country_id')]||field.key.endsWith('_city_id')&&!values[field.key.replace('_city_id','_state_id')];
  return <label key={field.key} className={field.wide?'student-field-wide':''}>{field.label}{field.required&&<span> *</span>}{['select','reference','semester'].includes(field.type)?<select {...props} disabled={disabled}><option value="">--- Select {field.label} ---</option>{choices.map(([id,label])=><option key={id} value={id}>{label}</option>)}</select>:field.type==='textarea'?<textarea {...props} maxLength={field.max}/>:<input {...props} type={field.type} maxLength={field.max} min={field.min} max={field.maxValue} step={field.type==='number'?'any':undefined}/>}</label>;
 }
 return <><MessageDialog message={message} onDismiss={()=>setMessage('')}/><h2>{readOnly?'Student Details':record?'Edit Student':'Add Student'}{record?.registration_no&&` — ${record.registration_no}`}</h2><form className="employee-card student-details-form" onSubmit={save} onInvalid={event=>validationMessage(event,setMessage)}><p>Fields with <span className="employee-required">*</span> are required.</p><fieldset disabled={busy||readOnly}>{studentSections.map(section=><section key={section.title} className="student-form-section"><h3>{section.title}</h3><div className="student-fields">{section.fields.map(renderField)}</div></section>)}</fieldset><div className="employee-buttons">{!readOnly&&<button type="submit" disabled={busy}>{busy?'Saving…':record?'Update':'Create'}</button>}<button type="button" disabled={busy} onClick={onCancel}>{readOnly?'Back':'Cancel'}</button></div></form></>;
}
