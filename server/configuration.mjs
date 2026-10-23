import { pool } from './db.mjs';
import { configuration } from '../shared/configuration.mjs';

export async function handleConfiguration(req, res, path, user, body, reply) {
  if (!path.startsWith('/api/admin/configuration')) return false;
  if (path === '/api/admin/configuration' && req.method === 'GET') {
    const counts = {};
    for (const item of configuration) {
      const result = await pool.query(`SELECT COUNT(*)::int AS count FROM ${item.key}`);
      counts[item.key] = result.rows[0].count;
    }
    reply(res, 200, { counts });
    return true;
  }
  const match = path.match(/^\/api\/admin\/configuration\/([a-z_]+)(?:\/(\d+))?$/);
  const spec = configuration.find(item => item.key === match?.[1]);
  if (!spec) { reply(res, 404, { error: 'Configuration item not found.' }); return true; }
  const id = match[2];
  const columns = [spec.id, ...spec.fields.filter(field => field.type !== 'file').map(field => field.type === 'date' ? `${field.name}::text AS ${field.name}` : field.name)];
  if (spec.key === 'organization') columns.push('created_at', 'updated_at', '(SELECT username FROM users WHERE user_id=organization.created_by) AS created_user', '(SELECT username FROM users WHERE user_id=organization.updated_by) AS updated_user', "'data:' || org_logo_type || ';base64,' || replace(encode(org_logo,'base64'),chr(10),'') AS logo_url");
  if (spec.key === 'organization') columns.push('created_at', 'updated_at', '(SELECT username FROM users WHERE user_id=organization.created_by) AS created_user', '(SELECT username FROM users WHERE user_id=organization.updated_by) AS updated_user', "'data:' || org_logo_type || ';base64,' || replace(encode(org_logo,'base64'),chr(10),'') AS logo_url");
  if (req.method === 'GET' && !id) {
    const { rows } = await pool.query(`SELECT ${columns.join(',')} FROM ${spec.key} ORDER BY ${spec.id} DESC`);
    reply(res, 200, { rows });
    return true;
  }
  if (req.method === 'DELETE' && id) {
    const result = await pool.query(`DELETE FROM ${spec.key} WHERE ${spec.id}=$1 RETURNING ${spec.id}`, [id]);
    reply(res, result.rowCount ? 200 : 404, result.rowCount ? { ok: true } : { error: 'Record not found.' });
    return true;
  }
  if ((req.method === 'POST' && !id) || (req.method === 'PATCH' && id)) {
    const input = await body(req);
    const values = [];
    const names = [];
    for (const field of spec.fields) {
      let value = input[field.name];
      if (field.type === 'file') {
        if (id && !value) continue;
        if (typeof value !== 'string' || !/^data:image\/(png|jpeg|webp);base64,[A-Za-z0-9+/=]+$/.test(value) || value.length > 1400000) { reply(res, 400, { error: 'Choose a PNG, JPEG, or WebP logo under 1 MB.' }); return true; }
        const [header, content] = value.split(',');
        names.push('org_logo_type'); values.push(header.slice(5, header.indexOf(';')));
        value = Buffer.from(content, 'base64');
      } else if (field.type === 'reference') {
        if (!Number.isSafeInteger(Number(value)) || Number(value) <= 0) { reply(res, 400, { error: `Select ${field.label}.` }); return true; }
        value = Number(value);
      } else {
        if (value != null && typeof value !== 'string') { reply(res, 400, { error: `Invalid ${field.label}.` }); return true; }
        value = value?.trim() || null;
        if (value && field.uppercase) value = value.toUpperCase();
        if (field.type === 'lookup') {
          const match = await pool.query('SELECT 1 FROM city WHERE city_name=$1 LIMIT 1', [value]);
          if (!match.rowCount) { reply(res, 400, { error: 'Select a District from the saved City/Town records.' }); return true; }
        }
        if (field.type === 'lookup') {
          const match = await pool.query('SELECT 1 FROM city WHERE city_name=$1 LIMIT 1', [value]);
          if (!match.rowCount) { reply(res, 400, { error: 'Select a District from the saved City/Town records.' }); return true; }
        }
        if ((field.required && !value) || (value && field.maxLength && value.length > field.maxLength) || (value && field.type === 'select' && !field.options.some(option => option.value === value)) || (value && field.type === 'date' && !/^\d{4}-\d{2}-\d{2}$/.test(value)) || (value && field.type === 'email' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value))) { reply(res, 400, { error: `Enter a valid ${field.label}.` }); return true; }
      }
      names.push(field.name); values.push(value);
    }
    if (id) {
      const audited = spec.key !== 'last_passout_institution';
      if (audited) values.push(user.user_id);
      values.push(id);
      const result = await pool.query(`UPDATE ${spec.key} SET ${names.map((name, index) => `${name}=$${index + 1}`).join(',')}${audited ? `,updated_at=NOW(),updated_by=$${values.length - 1}` : ''} WHERE ${spec.id}=$${values.length} RETURNING ${spec.id}`, values);
      reply(res, result.rowCount ? 200 : 404, result.rowCount ? { ok: true } : { error: 'Record not found.' });
    } else {
      const audited = spec.key !== 'last_passout_institution';
      if (audited) values.push(user.user_id);
      const result = await pool.query(`INSERT INTO ${spec.key}(${names.join(',')}${audited ? ',created_by,created_at' : ''}) VALUES(${names.map((_, index) => `$${index + 1}`).join(',')}${audited ? `,$${values.length},NOW()` : ''}) RETURNING ${spec.id}`, values);
      reply(res, 201, { ok: true, id: result.rows[0][spec.id] });
    }
    return true;
  }
  reply(res, 405, { error: 'Method not allowed.' });
  return true;
}
