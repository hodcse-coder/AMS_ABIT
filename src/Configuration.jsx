import React, { useEffect, useState } from 'react';
import { configuration } from '../shared/configuration.mjs';
import { api } from './Erp.jsx';
import MessageDialog, { useConfirm, validationMessage } from './MessageDialog.jsx';
import ConfigurationIcon from './ConfigurationIcon.jsx';
import { Icon } from './DashboardOverview.jsx';
import InstituteSetup from './InstituteSetup.jsx';

export default function Configuration({ selectedKey = null, onSelect }) {
  const [selected, setSelected] = useState(selectedKey);
  useEffect(() => { setSelected(selectedKey); }, [selectedKey]);
  function select(key) { setSelected(key); onSelect?.(key); }
  const [counts, setCounts] = useState({});
  const [rows, setRows] = useState([]);
  const [references, setReferences] = useState({});
  const [values, setValues] = useState({});
  const [editing, setEditing] = useState(null);
  const [search, setSearch] = useState('');
  const [filters, setFilters] = useState({});
  const [viewing, setViewing] = useState(null);
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);
  const [loading, setLoading] = useState(false);
  const { confirm, confirmation } = useConfirm();
  const spec = configuration.find(item => item.key === selected);
  const refreshCounts = () => api('/api/admin/configuration').then(data => setCounts(data.counts));
  useEffect(() => { refreshCounts().catch(error => setMessage(error.message)); }, []);
  useEffect(() => {
    let active = true;
    setRows([]); setReferences({}); setValues({}); setEditing(null); setMessage(''); setSearch(''); setFilters({}); setViewing(null);
    if (spec) {
      setLoading(true);
      Promise.all([api(`/api/admin/configuration/${spec.key}`), ...spec.fields.filter(field => field.type === 'reference' || field.type === 'lookup').map(async field => [field.reference, (await api(`/api/admin/configuration/${field.reference}`)).rows])])
        .then(([data, ...lookups]) => { if (active) { setRows(data.rows); setReferences(Object.fromEntries(lookups)); } })
        .catch(error => { if (active) setMessage(error.message); })
        .finally(() => { if (active) setLoading(false); });
    }
    return () => { active = false; };
  }, [selected]);
  async function refresh() {
    setRows((await api(`/api/admin/configuration/${spec.key}`)).rows);
    await refreshCounts();
  }
  function reset() { setValues({}); setEditing(null); }
  async function save(event) {
    event.preventDefault(); setBusy(true); setMessage('');
    try {
      await api(`/api/admin/configuration/${spec.key}${editing ? `/${editing}` : ''}`, { method: editing ? 'PATCH' : 'POST', body: JSON.stringify(values) });
      reset(); event.target.reset(); await refresh(); setMessage(editing ? 'Record updated.' : 'Record created.');
    } catch (error) { setMessage(error.message); } finally { setBusy(false); }
  }
  async function remove(row) {
    if (!await confirm(`Delete this ${spec.singular || spec.label} record?`)) return;
    setBusy(true);
    try {
      await api(`/api/admin/configuration/${spec.key}/${row[spec.id]}`, { method: 'DELETE' });
      if (editing === row[spec.id]) reset();
      await refresh(); setMessage('Record deleted.');
    } catch (error) { setMessage(error.message); } finally { setBusy(false); }
  }
  async function upload(event) {
    const file = event.target.files[0];
    if (!file) return;
    if (file.size > 1000000 || !['image/png', 'image/jpeg', 'image/webp'].includes(file.type)) { event.target.value = ''; setMessage('Choose a PNG, JPEG, or WebP logo under 1 MB.'); return; }
    const reader = new FileReader();
    reader.onload = () => setValues(previous => ({ ...previous, org_logo: reader.result }));
    reader.readAsDataURL(file);
  }
  const displayValue = (row, field) => {
    if (field.type === 'reference') {
      const target = configuration.find(item => item.key === field.reference);
      return references[field.reference]?.find(item => item[target.id] === row[field.name])?.[target.fields[0].name] || row[field.name];
    }
    if (field.type === 'select') return field.options.find(option => option.value === row[field.name])?.label || row[field.name];
    return field.type === 'date' ? row[field.name]?.slice(0, 10) : row[field.name];
  };
  const arrange = order => order ? order.map(name => spec.fields.find(field => field.name === name)) : spec.fields;
  const formFields = spec ? arrange(spec.formOrder) : [];
  const visibleFields = spec ? arrange(spec.listOrder).filter(field => field.type !== 'file') : [];
  const cardOrder = ['country','state','city','organization','languages','national_holidays','document_category','nationality','last_passout_institution','hobbies'];
  const cards = cardOrder.map(key => configuration.find(item => item.key === key)).filter(Boolean);
  const filteredRows = rows.filter(row => visibleFields.some(field => String(displayValue(row, field) ?? '').toLowerCase().includes(search.toLowerCase())) && visibleFields.every(field => !filters[field.name] || String(displayValue(row, field) ?? '').toLowerCase().includes(filters[field.name].toLowerCase())));
  if (spec?.key === 'organization') return <><MessageDialog message={message} onDismiss={() => setMessage('')} /><InstituteSetup rows={rows} loading={loading} onRefresh={refresh} /></>;
  return <div className="configuration" data-config={selected || 'overview'}>
    {confirmation}<MessageDialog message={message} onDismiss={() => setMessage('')} />
    {!spec ? <section className="config-overview"><h2>Master Configuration</h2><div className="config-grid">
      {cards.map(item => <article className="config-card" key={item.key}>
        <div className="config-icon" aria-hidden="true"><ConfigurationIcon name={item.key} /></div>
        <div className="config-card-body"><button className="config-name" onClick={() => select(item.key)}>{item.label}</button><strong>{counts[item.key] ?? '—'}</strong>{item.note && <small>{item.note}</small>}
          <button className="config-create" onClick={() => select(item.key)}>{item.key === 'organization' ? '✎ Edit' : '⊞ Create New'}</button>
        </div>
      </article>)}
    </div></section> : <>
      <h2>{editing ? 'Edit' : 'Add'} {spec.singular || spec.label}</h2>
      <section className="config-editor"><form key={`${selected}-${editing || 'new'}`} onSubmit={save} onReset={reset} onInvalid={event => validationMessage(event, setMessage)}>
        <fieldset disabled={busy || loading}><div className={`config-fields config-fields-${spec.key}`}>{formFields.map(field => <label className={field.wide ? 'config-wide-field' : ''} key={field.name}>{field.label}{field.required && !(field.type === 'file' && editing) ? ' *' : ''}
          {field.type === 'reference' ? <select value={values[field.name] ?? ''} required onChange={event => setValues(previous => ({ ...previous, [field.name]: event.target.value, ...(field.name === 'city_country_id' ? { city_state_id: '' } : {}) }))}>
            <option value="">Select {field.label}</option>{(references[field.reference] || []).filter(row => field.name !== 'city_state_id' || String(row.state_country_id) === String(values.city_country_id)).map(row => { const lookup = configuration.find(item => item.key === field.reference); return <option key={row[lookup.id]} value={row[lookup.id]}>{row[lookup.fields[0].name]}</option>; })}
          </select> : field.type === 'select' ? <select required={field.required} value={values[field.name] ?? ''} onChange={event => setValues(previous => ({ ...previous, [field.name]: event.target.value }))}><option value="">Select {field.label}</option>{field.options.map(option => <option key={option.value} value={option.value}>{option.label}</option>)}</select>
            : field.type === 'file' ? <input type="file" accept="image/png,image/jpeg,image/webp" required={!editing} onChange={upload} />
              : field.type === 'lookup' ? <select required={field.required} value={values[field.name] ?? ''} onChange={event => setValues(previous => ({ ...previous, [field.name]: event.target.value }))}><option value="">Select District</option>{[...new Set((references[field.reference] || []).map(row => row[field.valueField]))].sort().map(name => <option key={name} value={name}>{name}</option>)}{values[field.name] && !(references[field.reference] || []).some(row => row[field.valueField] === values[field.name]) && <option value={values[field.name]} disabled>{values[field.name]} (not in City/Town)</option>}</select>
              : <input type={field.type} placeholder={field.label} maxLength={field.maxLength} required={field.required} value={values[field.name] ?? ''} onChange={event => setValues(previous => ({ ...previous, [field.name]: field.uppercase ? event.target.value.toUpperCase() : event.target.value }))} />}
        </label>)}</div><div className="config-actions"><button className="config-save" type="submit">{busy ? 'Saving…' : editing ? 'Update' : 'Create'}</button><button className="config-reset" type="reset">{editing ? 'Cancel' : 'Reset'}</button></div></fieldset>
      </form></section>
      <div className="config-list-heading"><h2>{spec.singular || spec.label} List</h2>{!['country', 'state', 'city', 'last_passout_institution', 'document_category', 'languages', 'hobbies', 'national_holidays', 'nationality'].includes(spec.key) && <input aria-label={`Search ${spec.label}`} placeholder="Search…" value={search} onChange={event => setSearch(event.target.value)} />}</div>
      <section className="config-list"><div className="table-scroll"><table><thead><tr><th>#</th>{visibleFields.map(field => <th key={field.name}>{field.label}</th>)}<th>Actions</th></tr>
        <tr className="config-filter-row"><th></th>{visibleFields.map(field => <th key={field.name}>{field.type === 'reference' || field.type === 'select' || field.type === 'lookup' ? <select aria-label={`Filter ${field.label}`} value={filters[field.name] || ''} onChange={event => setFilters(previous => ({ ...previous, [field.name]: event.target.value }))}><option value="">All</option>{[...new Set(rows.map(row => displayValue(row, field)).filter(Boolean))].sort().map(value => <option key={value} value={value}>{value}</option>)}</select> : <input aria-label={`Filter ${field.label}`} value={filters[field.name] || ''} onChange={event => setFilters(previous => ({ ...previous, [field.name]: event.target.value }))} />}</th>)}<th><button className="filter-clear" onClick={() => { setFilters({}); setSearch(''); }}>Clear</button></th></tr></thead><tbody>
        {loading ? <tr><td colSpan={visibleFields.length + 2}>Loading…</td></tr> : filteredRows.map((row, index) => <tr key={row[spec.id]}><td>{index + 1}</td>{visibleFields.map(field => <td key={field.name}>{displayValue(row, field) || '—'}</td>)}<td className="record-actions"><button type="button" className="record-icon action-view" title="View" aria-label="View record" disabled={busy} onClick={() => setViewing(row)}><Icon name="view" size={16}/></button><button type="button" className="record-icon action-edit" title="Edit" aria-label="Edit record" disabled={busy} onClick={() => { setEditing(row[spec.id]); setValues(Object.fromEntries(visibleFields.map(field => [field.name, field.type === 'date' ? row[field.name]?.slice(0, 10) || '' : row[field.name] ?? '']))); setMessage(''); document.querySelector('.config-editor')?.scrollIntoView({ behavior: 'smooth', block: 'start' }); }}><Icon name="edit" size={16}/></button><button type="button" className="record-icon action-delete" title="Delete" aria-label="Delete record" disabled={busy} onClick={() => remove(row)}><Icon name="delete" size={16}/></button></td></tr>)}
        {!loading && !filteredRows.length && <tr><td colSpan={visibleFields.length + 2}>{rows.length ? 'No matching records.' : 'No records yet.'}</td></tr>}
      </tbody></table></div></section>
      {viewing && <dialog ref={node => { if (node && !node.open) node.showModal(); }} className="config-details" onCancel={() => setViewing(null)}><h2>{spec.singular || spec.label} Details</h2><dl>{visibleFields.map(field => <React.Fragment key={field.name}><dt>{field.label}</dt><dd>{displayValue(viewing, field) || '—'}</dd></React.Fragment>)}</dl><button autoFocus onClick={() => setViewing(null)}>Close</button></dialog>}
    </>}
  </div>;
}
