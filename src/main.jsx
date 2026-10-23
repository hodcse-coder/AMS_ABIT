import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import './styles.css';
import Erp, { api } from './Erp.jsx';
import MessageDialog, { validationMessage } from './MessageDialog.jsx';

function App() {
  const [accountType, setAccountType] = useState('Faculty');
  const [showPassword, setShowPassword] = useState(false);
  const [message, setMessage] = useState('');
  const [user, setUser] = useState(null);
  const [busy, setBusy] = useState(false);
  const [checking, setChecking] = useState(true);
  useEffect(() => {
    api('/api/me').then(data => setUser(data.user)).catch(() => {}).finally(() => setChecking(false));
  }, []);

  async function signIn(event) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setBusy(true);
    setMessage('');
    try {
      const data = await api('/api/login', { method: 'POST', body: JSON.stringify({ username: form.get('username'), password: form.get('password'), role: accountType, remember: form.get('remember') === 'on' }) });
      setUser(data.user);
    } catch (error) { setMessage(error.message); } finally { setBusy(false); }
  }

  if (checking) return <div className="erp">Loading…</div>;
  if (user) return <><MessageDialog message={message} onDismiss={() => setMessage('')} /><Erp user={user} onPasswordChanged={() => { setUser(null); setMessage('Password updated. Sign in with your new password.'); }} onLogout={async () => {
    try { await api('/api/logout', { method: 'POST', body: '{}' }); setUser(null); setMessage(''); }
    catch (error) { setMessage(error.message); }
  }} /></>;

  return (
    <main>
      <section className="visual" aria-label="ABIT campus">
        <img src="/campus.png" alt="Red brick ABIT campus building with a landscaped entrance" />
        <div className="brand">
          <img className="mark" src="/Logo.png" alt="ABIT logo" width="56" height="64" />
          <div><strong>ABIT</strong><small>CAMPUS CONNECT</small></div>
        </div>
        <div className="story">
          <span className="eyebrow">ACADEMIC MANAGEMENT SYSTEM</span>
          <h1>A connected campus.<br />A brighter tomorrow.</h1>
          <p>Your everyday campus essentials, together in one place. Stay informed. Stay connected.</p>
        </div>
        <div className="photo-label">One campus. Endless possibilities.</div>
      </section>
      <section className="right">
        <div className="form-wrap">
          <h2>Welcome back</h2>
          <p className="intro">Sign in to your ABIT account to continue.</p>
          <div className="roles" role="group" aria-label="Account type">
            {['Faculty', 'Student', 'Admin'].map(role => (
              <button key={role} className="role" aria-pressed={accountType === role} type="button"
                onClick={() => { setAccountType(role); setMessage(''); }}>{role}</button>
            ))}
          </div>
          <form id="login" onSubmit={signIn} onInvalid={event => validationMessage(event, setMessage)}>
            <label htmlFor="username">User Name</label>
            <input id="username" name="username" type="text" placeholder="Enter your user name" autoComplete="username" autoCapitalize="none" spellCheck={false} required />
            <label htmlFor="password">Password</label>
            <div className="field">
              <input id="password" name="password" type={showPassword ? 'text' : 'password'} placeholder="Enter your password" autoComplete="current-password" required />
              <button className="show" type="button" aria-label={showPassword ? 'Hide password' : 'Show password'} aria-pressed={showPassword}
                onClick={() => setShowPassword(value => !value)}>{showPassword ? 'Hide' : 'Show'}</button>
            </div>
            <div className="options"><label className="remember"><input type="checkbox" name="remember" /> Remember me</label></div>
            <button className="submit" type="submit" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'} <span aria-hidden="true">→</span></button>
            <MessageDialog message={message} onDismiss={() => setMessage('')} />
          </form>
        </div>
        <footer className="footer"><span>© {new Date().getFullYear()} ABIT. All rights reserved.</span></footer>
      </section>
    </main>
  );
}

createRoot(document.getElementById('root')).render(<React.StrictMode><App /></React.StrictMode>);
