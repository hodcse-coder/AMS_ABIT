import React, { useCallback, useEffect, useId, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import './message-dialog.css';

export default function MessageDialog({ message, title = 'ABIT', onDismiss, onConfirm, confirmText = 'OK' }) {
  const dialog = useRef(null);
  const titleId = useId();
  const messageId = useId();
  useEffect(() => {
    const element = dialog.current;
    if (!message || !element) return;
    element.showModal();
    return () => { if (element.open) element.close(); };
  }, [message]);
  if (!message || typeof document === 'undefined') return null;
  return createPortal(<dialog className="message-dialog" ref={dialog} aria-labelledby={titleId} aria-describedby={messageId} onCancel={event => { event.preventDefault(); onDismiss(); }}>
    <div className="message-dialog-logo"><img src="/Logo.png" alt="ABIT logo"/></div>
    <h2 id={titleId}>{title}</h2><p id={messageId}>{message}</p>
    <div className="message-dialog-actions">{onConfirm && <button type="button" autoFocus className="message-cancel" onClick={onDismiss}>Cancel</button>}<button type="button" autoFocus={!onConfirm} className={onConfirm ? 'message-delete' : 'message-ok'} onClick={onConfirm || onDismiss}>{confirmText}</button></div>
  </dialog>, document.body);
}

export function useConfirm() {
  const [message, setMessage] = useState('');
  const resolver = useRef(null);
  const confirm = useCallback(text => {
    if (resolver.current) return Promise.resolve(false);
    return new Promise(resolve => { resolver.current = resolve; setMessage(text); });
  }, []);
  const finish = useCallback(value => {
    const resolve = resolver.current;
    resolver.current = null;
    setMessage('');
    resolve?.(value);
  }, []);
  useEffect(() => () => { resolver.current?.(false); resolver.current = null; }, []);
  return { confirm, confirmation: <MessageDialog title="Confirm deletion" message={message} confirmText="Delete" onConfirm={() => finish(true)} onDismiss={() => finish(false)} /> };
}

export function validationMessage(event, setMessage) {
  event.preventDefault();
  const field = event.target;
  if (field.form?.querySelector(':invalid') !== field) return;
  const label = field.labels?.[0]?.textContent?.trim().replace(/\s*\*$/, '');
  setMessage(`${label ? `${label}: ` : ''}${field.validationMessage}`);
}
