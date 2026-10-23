import React,{useEffect,useState} from 'react';
import {api} from '../Erp.jsx';
import MessageDialog,{validationMessage} from '../MessageDialog.jsx';
const base='/api/admin/obe';
export default function ErpLinks({faculty=false}){
 const [entities,setEntities]=useState({}),[type,setType]=useState(faculty?'faculty':'departments'),[obeId,setObeId]=useState(''),[erpId,setErpId]=useState(''),[department,setDepartment]=useState(''),[departments,setDepartments]=useState([]),[message,setMessage]=useState(''),[busy,setBusy]=useState(false);
 const selected=entities[type]||{records:[],erp:[]};
 async function refresh(){const [links,departments]=await Promise.all([api(base+'/erp-links'),api(base+'/departments')]);setEntities(links.entities);setDepartments(departments);}
 useEffect(()=>{refresh().catch(error=>setMessage(error.message));},[]);
 async function save(event){event.preventDefault();setBusy(true);try{await api(faculty?base+'/faculty-from-erp':base+'/erp-links/'+type+'/'+obeId,{method:faculty?'POST':'PATCH',body:JSON.stringify(faculty?{employee_id:erpId,department_id:department}:{erp_id:erpId||null})});await refresh();setMessage(faculty?'Faculty linked from ERP.':'ERP link saved.');}catch(error){setMessage(error.message);}finally{setBusy(false);}}
 return <><MessageDialog message={message} onDismiss={()=>setMessage('')}/><form className="employee-card" onSubmit={save} onInvalid={event=>validationMessage(event,setMessage)}><h3>{faculty?'Faculty from ERP':'Link OBE and ERP Records'}</h3><fieldset disabled={busy}><div className="employee-fields">
 {!faculty&&<><label>Record Type<select value={type} onChange={event=>{setType(event.target.value);setObeId('');setErpId('');}}>{Object.keys(entities).map(key=><option key={key} value={key}>{key}</option>)}</select></label><label>OBE Record <span>*</span><select required value={obeId} onChange={event=>{setObeId(event.target.value);setErpId(selected.records.find(row=>String(row.id)===event.target.value)?.erp_id||'');}}><option value="">Select OBE Record</option>{selected.records.map(row=><option key={row.id} value={row.id}>{row.label}</option>)}</select></label></>}
 <label>{faculty?'Employee':'ERP Record'}{faculty&&<span> *</span>}<select required={faculty} value={erpId} onChange={event=>setErpId(event.target.value)}><option value="">{faculty?'Select Employee':'Unlinked'}</option>{selected.erp.map(row=><option key={row.id} value={row.id}>{row.label}</option>)}</select></label>
 {faculty&&<label>OBE Department<select value={department} onChange={event=>setDepartment(event.target.value)}><option value="">Select Department</option>{departments.map(row=><option key={row.department_id} value={row.department_id}>{row.department_name}</option>)}</select></label>}
 </div><div className="employee-buttons"><button type="submit">{faculty?'Add / Refresh Faculty':'Save Link'}</button></div></fieldset></form><div className="employee-table"><table><thead><tr><th>OBE Record</th><th>ERP Record</th></tr></thead><tbody>{selected.records.map(row=><tr key={row.id}><td>{row.label}</td><td>{selected.erp.find(record=>String(record.id)===String(row.erp_id))?.label||'Unlinked'}</td></tr>)}</tbody></table></div></>;
}
