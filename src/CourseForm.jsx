import React from 'react';
import { validationMessage } from './MessageDialog.jsx';

export default function CourseForm({values,setValues,editing,busy,onSave,onCancel,onMessage}) {
  const field=(name,label,maxLength,options={})=><label className={options.className||''}>{label}{options.required===false?'':' *'}<input name={name} type={options.type||'text'} placeholder={label} maxLength={maxLength} min={options.min} step={options.type==='number'?1:undefined} required={options.required!==false} value={values[name]??''} onChange={event=>setValues(previous=>({...previous,[name]:!options.type?event.target.value.toUpperCase():event.target.value}))}/></label>;
  return <section className="course-design-editor"><h2>{editing?'Edit':'Add'} Course</h2><form onSubmit={onSave} onInvalid={event=>validationMessage(event,onMessage)}><fieldset disabled={busy}><div className="course-design-fields">
    {field('course_name','Course Name',100,{className:'course-full'})}
    {field('course_code','Course Code',50,{className:'course-half'})}
    {field('course_alias','Course Alias',35)}
    {field('course_duration','Duration in Years',undefined,{type:'number',min:1})}
    {!editing&&<><h3>Initial Batch</h3>
      {field('batch_name','Batch Name',120,{className:'course-half'})}
      {field('batch_alias','Batch Alias',35,{className:'course-half'})}
      {field('start_date','Start Date',undefined,{className:'course-half',type:'date'})}
      {field('end_date','End Date',undefined,{className:'course-half',type:'date'})}
      <h3>Initial Section</h3>
      {field('section_name','Section Name',50,{className:'course-half',required:false})}
      {field('intake','Intake',undefined,{className:'course-half',type:'number',min:0,required:false})}
    </>}
    {editing&&<label className="course-half">Status<select value={String(values.is_active??true)} onChange={event=>setValues(previous=>({...previous,is_active:event.target.value==='true'}))}><option value="true">Active</option><option value="false">Inactive</option></select></label>}
  </div><div className="course-design-actions"><button type="submit">{busy?'Saving…':editing?'Update':'Create'}</button><button type="button" onClick={onCancel}>Cancel</button></div></fieldset></form></section>;
}
