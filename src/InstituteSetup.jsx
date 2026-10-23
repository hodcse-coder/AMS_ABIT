import React, { useState } from 'react';
import { api } from './Erp.jsx';
import MessageDialog, { validationMessage } from './MessageDialog.jsx';
import { configuration } from '../shared/configuration.mjs';
import './institute.css';

const spec = configuration.find(item => item.key === 'organization');
const timestamp = value => value ? new Date(value).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) : 'Not Set';
function websiteLink(value) { try { const url = new URL(value); return ['http:', 'https:'].includes(url.protocol) ? url.href : null; } catch { return null; } }

export default function InstituteSetup({ rows, loading, onRefresh }) {
  const [selectedId, setSelectedId] = useState(null);
  const [mode, setMode] = useState(null);
  const [values, setValues] = useState({});
  const [busy, setBusy] = useState(false);
  const [reading, setReading] = useState(false);
  const [message, setMessage] = useState('');
  const [formVersion, setFormVersion] = useState(0);
  const current = rows.find(row => row.org_id === selectedId) || rows[0];
  function start(mode) {
    setFormVersion(value => value + 1);
    setMode(mode);
    setValues(mode === 'edit' ? Object.fromEntries(spec.fields.filter(field => field.type !== 'file').map(field => [field.name, current?.[field.name] || ''])) : {});
  }
  async function upload(event) {
    const file = event.target.files[0];
    if (!file) { setValues(previous => { const next = { ...previous }; delete next.org_logo; return next; }); return; }
    if (file.size > 1000000 || !['image/png','image/jpeg','image/webp'].includes(file.type)) { event.target.value = ''; setValues(previous => { const next = { ...previous }; delete next.org_logo; return next; }); setMessage('Choose a PNG, JPEG, or WebP logo under 1 MB.'); return; }
    setReading(true);
    const reader = new FileReader();
    reader.onload = () => { setValues(previous => ({ ...previous, org_logo: reader.result })); setReading(false); };
    reader.onerror = () => { setMessage('Unable to read the selected logo. Please choose the file again.'); setReading(false); };
    reader.readAsDataURL(file);
  }
  async function save(event) {
    event.preventDefault(); setBusy(true);
    try {
      const result = await api(`/api/admin/configuration/organization${mode === 'edit' ? `/${current.org_id}` : ''}`, { method: mode === 'edit' ? 'PATCH' : 'POST', body: JSON.stringify(values) });
      if (result.id) setSelectedId(result.id);
      await onRefresh(); setMode(null); setValues({}); setMessage('Institute setup saved successfully.');
    } catch (error) { setMessage(error.message); } finally { setBusy(false); }
  }
  return <div className="institute-setup">
    <MessageDialog message={message} onDismiss={() => setMessage('')} />
    {mode ? <>
      <h2>{mode === 'edit' ? 'Edit' : 'Add'} Institute</h2>
      <section className="institute-editor"><form key={formVersion} onSubmit={save} onInvalid={event => validationMessage(event,setMessage)}><fieldset disabled={busy || reading}>
        <div className="institute-fields">{spec.fields.map(field => <label key={field.name}>{field.label}{field.required && (field.type !== 'file' || mode === 'add') ? ' *' : ''}
          {field.type === 'file' ? <><input type="file" accept="image/png,image/jpeg,image/webp" required={mode === 'add'} onChange={upload}/>{mode === 'edit' && <small>Leave unchanged to keep the saved logo.</small>}</> : <input type={field.type} placeholder={field.label} maxLength={field.maxLength} required={field.required} value={values[field.name] || ''} onChange={event => setValues(previous => ({ ...previous, [field.name]: field.uppercase ? event.target.value.toUpperCase() : event.target.value }))}/>}
        </label>)}</div>
        <div className="institute-form-actions"><button className="institute-save" disabled={busy || reading}>{busy?'Saving…':mode === 'edit'?'Update':'Create'}</button><button type="button" className="institute-reset" onClick={() => start(mode)}>Reset</button><button type="button" className="institute-cancel" onClick={() => {setMode(null);setValues({});}}>Cancel</button></div>
      </fieldset></form></section>
    </> : <>
      <div className="institute-heading"><h2>View Institute Setup Details</h2><div>{current ? <button className="institute-edit" disabled={loading} onClick={() => start('edit')}>Edit</button> : <button className="institute-add" disabled={loading} onClick={() => start('add')}>Add Institute</button>}</div></div>
      {rows.length > 1 && <label className="institute-selector">Institute<select value={current?.org_id || ''} onChange={event => setSelectedId(Number(event.target.value))}>{rows.map(row => <option value={row.org_id} key={row.org_id}>{row.org_name}</option>)}</select></label>}
      <section className="institute-details institute-details-grid">{loading ? <p>Loading institute setup…</p> : !current ? <p>No institute setup has been saved. Click Add Institute to create it.</p> : <dl className="institute-detail-layout">
        <div className="institute-detail-item"><dt>Institute Name</dt><dd>{current.org_name || 'Not Set'}</dd></div>
        <div className="institute-detail-item"><dt>Alias</dt><dd>{current.org_alias || 'Not Set'}</dd></div>
        <div className="institute-detail-item institute-address"><dt>Address</dt><dd>{current.org_address_line1 || 'Not Set'}{current.org_address_line2 && <><br/><br/>{current.org_address_line2}</>}</dd></div>
        <div className="institute-detail-item"><dt>Phone</dt><dd>{current.org_phone || 'Not Set'}</dd></div>
        <div className="institute-detail-item"><dt>Website</dt><dd>{websiteLink(current.org_website) ? <a href={websiteLink(current.org_website)} target="_blank" rel="noreferrer">{current.org_website}</a> : current.org_website || 'Not Set'}</dd></div>
        <div className="institute-detail-item"><dt>Email</dt><dd>{current.org_email ? <a href={`mailto:${current.org_email}`}>{current.org_email}</a> : 'Not Set'}</dd></div>
        <div className="institute-detail-item institute-logo-row"><dt>Institute Logo</dt><dd>{current.logo_url ? <img className="institute-logo" src={current.logo_url} alt={`${current.org_name} logo`}/> : 'No logo saved'}</dd></div>
        <div className="institute-detail-item"><dt>Employee Login Prefix</dt><dd>{current.org_emp_prefix || 'Not Set'}</dd></div>
        <div className="institute-detail-item"><dt>Student Login Prefix</dt><dd>{current.org_stu_prefix || 'Not Set'}</dd></div>
        <div className="institute-detail-item"><dt>Created Time</dt><dd>{timestamp(current.created_at)}</dd></div>
        <div className="institute-detail-item"><dt>Created User</dt><dd>{current.created_user || 'Not Set'}</dd></div>
        <div className="institute-detail-item"><dt>Updated Time</dt><dd>{timestamp(current.updated_at)}</dd></div>
        <div className="institute-detail-item"><dt>Updated User</dt><dd>{current.updated_user || 'Not Set'}</dd></div>
      </dl>}</section>
    </>}
  </div>;
}
