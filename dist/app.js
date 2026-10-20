const password = document.querySelector('#password');
const toggle = document.querySelector('#toggle');
const message = document.querySelector('#message');
let accountType = 'Student';
document.querySelector('#year').textContent = new Date().getFullYear();
toggle.addEventListener('click', () => {
  const visible = password.type === 'password';
  password.type = visible ? 'text' : 'password';
  toggle.textContent = visible ? 'Hide' : 'Show';
  toggle.setAttribute('aria-label', visible ? 'Hide password' : 'Show password');
  toggle.setAttribute('aria-pressed', String(visible));
});
document.querySelectorAll('.role').forEach(button => button.addEventListener('click', () => {
  document.querySelectorAll('.role').forEach(role => role.setAttribute('aria-pressed', String(role === button)));
  accountType = button.textContent;
  message.textContent = '';
}));
document.querySelector('#login').addEventListener('submit', event => {
  event.preventDefault();
  message.textContent = `${accountType} sign-in is ready to connect to your campus authentication service. This preview does not send or store your password.`;
});
document.querySelector('#forgot').addEventListener('click', () => {
  message.textContent = 'To reset your password, contact your campus administrator using your registered campus email. Password recovery will be available when your campus account service is connected.';
});
['help', 'support'].forEach(id => document.getElementById(id).addEventListener('click', () => {
  message.textContent = 'Please contact your campus administration office for account access and sign-in support.';
  message.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}));
