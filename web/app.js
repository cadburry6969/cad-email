const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'cad-email';
const $ = (id) => document.getElementById(id);

const HINTS = {
    dms_off: 'Ask them to join the Discord server and turn on "Allow direct messages from server members" in its Privacy Settings.',
    no_discord: 'They need Discord open on their PC when joining FiveM so it can be linked. You can add their Discord ID instead.',
    unknown_user: 'In Discord, turn on Developer Mode, then right click their name and pick "Copy User ID".',
    invalid_id: 'In Discord, turn on Developer Mode, then right click their name and pick "Copy User ID".',
    invalid_citizenid: 'Ask them for the Citizen ID shown at the top of their Mail list tab.',
    not_in_list: 'Open the Mail list tab to add them.',
};

const ADD_MODES = {
    discord: { placeholder: 'Discord ID, e.g. 482449059194470410', inputmode: 'numeric' },
    citizenid: { placeholder: 'Citizen ID, e.g. ABC12345', inputmode: 'text' },
    player: { placeholder: 'Server ID of an online player, e.g. 12', inputmode: 'numeric' },
};

const state = {
    addMode: 'discord',
    sending: false,
    limits: { subject: 120, body: 2000, contacts: 50 },
    features: { citizenid: false },
    contacts: [],
    history: [],
};

async function post(name, data = {}) {
    try {
        const res = await fetch(`https://${resource}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        });
        return await res.json();
    } catch {
        return { ok: false, message: 'Could not reach the game. Try again.' };
    }
}

function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
}

let statusTimer;
function showStatus(ok, message, code) {
    const box = $('status');
    box.replaceChildren(el('span', null, message));
    if (!ok && HINTS[code]) box.append(el('span', 'hint', HINTS[code]));
    box.className = `status ${ok ? 'ok' : 'bad'}`;
    clearTimeout(statusTimer);
    statusTimer = setTimeout(() => box.classList.add('hidden'), ok ? 4000 : 12000);
}

function hideStatus() {
    $('status').classList.add('hidden');
}

function applyData(data) {
    if (!data) return;
    if (data.limits) state.limits = data.limits;
    if (data.features) state.features = data.features;

    if (data.sender) {
        $('sender').textContent = `From: ${data.sender.name} <${data.sender.email}>`;
        const myId = $('my-id');
        myId.classList.toggle('hidden', !data.sender.citizenid);
        if (data.sender.citizenid) {
            myId.replaceChildren('Your Citizen ID: ', el('strong', null, data.sender.citizenid), ' (share it so others can add you)');
        }
    }

    // Citizen ID options only show on servers that use them
    document.querySelectorAll('.citizen-only').forEach((b) => b.classList.toggle('hidden', !state.features.citizenid));
    if (!state.features.citizenid && state.addMode !== 'discord') setAddMode('discord');

    state.contacts = data.contacts || [];
    state.history = data.history || [];
    renderContacts();
    renderHistory();
    updateCounters();
}

function openTab(name) {
    document.querySelectorAll('.tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === name));
    document.querySelectorAll('.panel').forEach((p) => p.classList.toggle('hidden', p.id !== `tab-${name}`));
}

function setAddMode(mode) {
    state.addMode = mode;
    document.querySelectorAll('#add-modes .mode').forEach((m) => m.classList.toggle('active', m.dataset.mode === mode));
    const input = $('contact-value');
    input.placeholder = ADD_MODES[mode].placeholder;
    input.inputMode = ADD_MODES[mode].inputmode;
    input.value = '';
}

function updateCounters() {
    const pairs = [['subject', 'subject-count', state.limits.subject], ['body', 'body-count', state.limits.body]];
    for (const [input, counter, max] of pairs) {
        const length = $(input).value.length;
        $(counter).textContent = `${length} / ${max}`;
        $(counter).classList.toggle('over', length > max);
    }
}

function clearCompose() {
    $('pick').value = '';
    $('subject').value = '';
    $('body').value = '';
    updateCounters();
}

async function sendMail() {
    if (state.sending) return;

    const payload = {
        contactId: Number($('pick').value),
        subject: $('subject').value.trim(),
        body: $('body').value.trim(),
    };

    if (!payload.contactId) return showStatus(false, 'Pick who to send to from your mail list.', state.contacts.length ? null : 'not_in_list');
    if (!payload.subject) return showStatus(false, 'Add a subject.');
    if (!payload.body) return showStatus(false, 'Write a message.');
    if (payload.subject.length > state.limits.subject || payload.body.length > state.limits.body) {
        return showStatus(false, 'Your mail is too long.');
    }

    state.sending = true;
    $('send').disabled = true;
    $('send').textContent = 'Sending...';

    const result = await post('send', payload);

    state.sending = false;
    $('send').disabled = false;
    $('send').textContent = 'Send';

    applyData(result.data);
    showStatus(result.ok, result.message, result.code);
    if (result.ok) clearCompose();
}

function renderContacts() {
    const list = $('contacts');
    const pick = $('pick');
    const picked = pick.value;

    list.replaceChildren();
    pick.replaceChildren(el('option', null, 'Choose from your mail list'));
    pick.firstChild.value = '';

    const hasContacts = state.contacts.length > 0;
    $('contact-count').textContent = state.contacts.length;
    $('contacts-empty').classList.toggle('hidden', hasContacts);
    $('compose-empty').classList.toggle('hidden', hasContacts);
    pick.disabled = !hasContacts;

    for (const contact of state.contacts) {
        const isCitizen = contact.kind === 'citizenid';

        const option = el('option', null, contact.label);
        option.value = contact.id;
        pick.append(option);

        const item = el('li', 'item');
        const head = el('div', 'item-head');
        const info = el('div');
        const sub = el('div', 'item-sub');
        sub.append(el('span', 'tag', isCitizen ? 'Citizen ID' : 'Discord'), contact.target);
        info.append(el('div', 'item-title', contact.label), sub);

        const buttons = el('div', 'item-buttons');
        const mailBtn = el('button', 'btn primary small', 'Mail');
        mailBtn.onclick = () => {
            pick.value = contact.id;
            openTab('compose');
            $('subject').focus();
        };
        const removeBtn = el('button', 'btn danger small', 'Remove');
        removeBtn.onclick = async () => {
            if (removeBtn.dataset.confirm !== '1') {
                removeBtn.dataset.confirm = '1';
                removeBtn.textContent = 'Sure?';
                return;
            }
            const result = await post('deleteContact', { id: contact.id });
            applyData(result.data);
            showStatus(result.ok, result.message);
        };

        buttons.append(mailBtn, removeBtn);
        head.append(info, buttons);
        item.append(head);
        list.append(item);
    }

    // Keep the chosen recipient after a refresh, if they are still in the list
    if (state.contacts.some((c) => String(c.id) === picked)) pick.value = picked;
}

async function addContact(event) {
    event.preventDefault();
    const label = $('contact-label').value.trim();
    const value = $('contact-value').value.trim();
    if (!label || !value) return showStatus(false, 'Enter a name and who to add.');

    const result = await post('saveContact', { mode: state.addMode, label, value });
    applyData(result.data);
    showStatus(result.ok, result.message, result.code);
    if (result.ok) {
        $('contact-label').value = '';
        $('contact-value').value = '';
    }
}

function formatTime(seconds) {
    const date = new Date(seconds * 1000);
    return date.toLocaleString([], { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
}

function renderHistory() {
    const list = $('history');
    list.replaceChildren();
    $('history-empty').classList.toggle('hidden', state.history.length > 0);

    for (const mail of state.history) {
        const item = el('li', 'item mail');
        const head = el('div', 'item-head');
        const info = el('div');
        info.append(
            el('div', 'item-title', mail.subject),
            el('div', 'item-sub', `To ${mail.recipient}  |  ${formatTime(mail.sent_at)}`),
        );
        const badge = el('span', `badge ${mail.status}`, mail.status === 'sent' ? 'Delivered' : 'Failed');
        head.append(info, badge);
        item.append(head);

        if (mail.status === 'failed' && mail.error) item.append(el('div', 'reason', mail.error));

        const body = el('div', 'body hidden', mail.body);
        item.append(body);
        item.onclick = () => body.classList.toggle('hidden');

        list.append(item);
    }
}

function closeApp() {
    $('app').classList.add('hidden');
    hideStatus();
    post('close');
}

window.addEventListener('message', ({ data }) => {
    if (data.action === 'load') applyData(data.data);
    if (data.action === 'open') {
        $('app').classList.remove('hidden');
        openTab('compose');
    }
    if (data.action === 'close') $('app').classList.add('hidden');
});

document.addEventListener('keyup', (event) => {
    if (event.key === 'Escape') closeApp();
});

document.querySelectorAll('.tab').forEach((tab) => (tab.onclick = () => openTab(tab.dataset.tab)));
document.querySelectorAll('#add-modes .mode').forEach((mode) => (mode.onclick = () => setAddMode(mode.dataset.mode)));
$('close').onclick = closeApp;
$('send').onclick = sendMail;
$('clear').onclick = clearCompose;
$('go-contacts').onclick = () => openTab('contacts');
$('contact-form').onsubmit = addContact;
$('subject').oninput = updateCounters;
$('body').oninput = updateCounters;
