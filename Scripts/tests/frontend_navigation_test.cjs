// Run with: node --test Scripts/tests/frontend_navigation_test.cjs
// Execute the shipped handlers with controlled fetch/history rather than relying
// on a real network to reproduce out-of-order responses and Back navigation.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../../Assets/js/site.js'), 'utf8');
const navigation = source.slice(source.indexOf('// Collection URL shapes'), source.indexOf('// Back-to-top:'));
const flush = () => new Promise(resolve => setImmediate(resolve));

function surface() {
    const listeners = {};
    return {
        addEventListener(type, fn) { (listeners[type] ||= []).push(fn); },
        dispatchEvent(event) { for (const fn of listeners[event.type] || []) fn(event); }
    };
}

function harness(initial = '/apps/') {
    let address = new URL(initial, 'https://tim.dev');
    const hardNavigations = [];
    const location = {
        get href() { return address.href; },
        set href(value) { hardNavigations.push(value); },
        get origin() { return address.origin; },
        get pathname() { return address.pathname; },
        get search() { return address.search; },
        reload() { hardNavigations.push('reload'); }
    };
    const stack = [{ url: address.href, state: null }];
    let index = 0;
    const clone = value => JSON.parse(JSON.stringify(value));
    const history = {
        get state() { return clone(stack[index].state); },
        replaceState(state, _, url) { address = new URL(url, address); stack[index] = { state: clone(state), url: address.href }; },
        pushState(state, _, url) { address = new URL(url, address); stack.splice(++index); stack.push({ state: clone(state), url: address.href }); }
    };
    const heading = { setAttribute() {}, focus(options) { heading.focused = options.preventScroll; } };
    const container = {
        innerHTML: '',
        querySelector(selector) { return selector === 'h1' ? heading : { classList: { add() {} } }; }
    };
    function meta(value) {
        return { value, remove() { document.head.nodes.splice(document.head.nodes.indexOf(this), 1); }, cloneNode() { return meta(value); } };
    }
    const document = Object.assign(surface(), {
        title: 'Apps',
        querySelector: () => container,
        getElementById: () => null,
        head: {
            nodes: [meta('old-canonical')],
            querySelectorAll() { return [...this.nodes]; },
            appendChild(node) { this.nodes.push(node); }
        }
    });
    const window = Object.assign(surface(), {
        history, location, fetch: true, DOMParser: true,
        scrollX: 0, scrollY: 0,
        scrollTo({ left, top }) { this.scrollX = left; this.scrollY = top; },
        matchMedia: () => ({ matches: false })
    });
    const requests = [];
    const events = [];
    for (const type of ['collection:before-swap', 'collection:swapped']) document.addEventListener(type, () => events.push(type));
    vm.runInNewContext(navigation, {
        window, document, history, location, URL, Event, AbortController, Date,
        fetch(url, options) { return new Promise((resolve, reject) => requests.push({ url, options, resolve, reject })); },
        DOMParser: class { parseFromString(title) { return {
            title,
            querySelector: () => ({ innerHTML: title }),
            head: { querySelectorAll: () => [meta(title + '-canonical')] }
        }; } }
    });
    return {
        requests, events, document, window, heading, container, hardNavigations,
        get pathname() { return address.pathname; },
        click(pathname) {
            const a = new URL(pathname, address);
            a.getAttribute = () => pathname;
            a.hasAttribute = () => false;
            let prevented = false;
            document.dispatchEvent({ type: 'click', button: 0, target: { closest: () => a }, preventDefault() { prevented = true; } });
            return prevented;
        },
        resolve(n, title) { requests[n].resolve({ ok: true, url: requests[n].url, text: () => Promise.resolve(title) }); },
        pop(delta) { index += delta; address = new URL(stack[index].url); window.dispatchEvent({ type: 'popstate', state: history.state }); }
    };
}

test('cross-section links retain full document navigation; same-section swaps update page identity and focus', async () => {
    const h = harness();
    assert.equal(h.click('/talks/'), false);
    assert.equal(h.requests.length, 0);
    assert.equal(h.click('/apps/icomics/'), true);
    h.resolve(0, 'iComics');
    await flush();
    assert.equal(h.pathname, '/apps/icomics/');
    assert.equal(h.container.innerHTML, 'iComics');
    assert.equal(h.document.title, 'iComics');
    assert.equal(h.document.head.nodes.length, 1);
    assert.equal(h.document.head.nodes[0].value, 'iComics-canonical');
    assert.equal(h.heading.focused, true);
    assert.deepEqual(h.events, ['collection:before-swap', 'collection:swapped']);
});

test('late responses and failures cannot overwrite the latest destination', async () => {
    const h = harness();
    h.click('/apps/first/');
    h.click('/apps/second/');
    assert.equal(h.requests[0].options.signal.aborted, true);
    h.resolve(1, 'Second');
    await flush();
    h.resolve(0, 'First');
    await flush();
    assert.equal(h.pathname, '/apps/second/');
    assert.equal(h.container.innerHTML, 'Second');
    h.click('/apps/third/');
    h.click('/apps/fourth/');
    h.requests[2].reject(new Error('late failure'));
    h.resolve(3, 'Fourth');
    await flush();
    assert.deepEqual(h.hardNavigations, []);
    assert.equal(h.container.innerHTML, 'Fourth');
});

test('Back and Forward restore each entry scroll after its DOM has loaded', async () => {
    const h = harness();
    h.window.scrollY = 650;
    h.click('/apps/icomics/');
    h.resolve(0, 'iComics');
    await flush();
    assert.equal(h.window.scrollY, 0);
    h.window.scrollY = 230;
    h.pop(-1);
    h.resolve(1, 'Apps');
    await flush();
    assert.equal(h.window.scrollY, 650);
    h.pop(1);
    h.resolve(2, 'iComics');
    await flush();
    assert.equal(h.window.scrollY, 230);
});

test('a failed current request falls back to ordinary navigation', async () => {
    const h = harness();
    h.click('/apps/icomics/');
    h.requests[0].reject(new Error('offline'));
    await flush();
    assert.deepEqual(h.hardNavigations, ['https://tim.dev/apps/icomics/']);
});

test('comments root initialization shares a bounded observer when the widget is unavailable', () => {
    const script = fs.readFileSync(path.join(__dirname, '../../Assets/js/comentario-tweaks.js'), 'utf8');
    const observers = [];
    const timers = [];
    const widget = { querySelector: () => null };
    vm.runInNewContext(script, {
        document: { querySelector: selector => selector === 'comentario-comments' ? widget : null, querySelectorAll: () => [], addEventListener() {} },
        window: { open() {} },
        MutationObserver: class {
            constructor(callback) { this.callback = callback; observers.push(this); }
            observe() {}
            disconnect() { this.disconnected = true; }
        },
        setTimeout(callback, delay) { timers.push({ callback, delay }); return timers.length; },
        clearTimeout() {}
    });
    assert.equal(observers.length, 1);
    assert.equal(timers.length, 1);
    assert.equal(timers[0].delay, 20000);
    observers[0].callback();
    assert.equal(timers.length, 1);
    timers[0].callback();
    assert.equal(observers[0].disconnected, true);
});

test('newly swapped LQIP images are observed and receive responsive sources', () => {
    const script = source.slice(0, source.indexOf('\n(function() {\n    var root = document.documentElement;'));
    const makeImage = value => ({ srcset: '', dataset: { srcset: value, sizes: '90vw' } });
    let images = [makeImage('/first.webp 800w')];
    let observer;
    const document = Object.assign(surface(), { querySelectorAll: () => images });
    vm.runInNewContext(script, {
        document,
        Image: class { constructor() { this.complete = true; this.naturalWidth = 800; } },
        IntersectionObserver: class {
            constructor(callback) { this.callback = callback; this.targets = []; observer = this; }
            observe(img) { this.targets.push(img); }
            unobserve(img) { this.targets = this.targets.filter(target => target !== img); }
            disconnect() { this.targets = []; }
        }
    });
    assert.equal(observer.targets[0], images[0]);
    observer.callback([{ target: images[0], isIntersecting: true }], observer);
    assert.equal(images[0].srcset, '/first.webp 800w');
    images = [makeImage('/second.webp 800w')];
    document.dispatchEvent({ type: 'collection:swapped' });
    assert.deepEqual(observer.targets, images);
    observer.callback([{ target: images[0], isIntersecting: true }], observer);
    assert.equal(images[0].srcset, '/second.webp 800w');
    assert.equal(images[0].sizes, '90vw');
});

test('reduced-motion menu toggles without animation and hides duplicate links from focus', () => {
    const script = source.slice(source.indexOf('// Hamburger menu open/close animation'), source.indexOf('// Embla Carousel:'));
    const element = () => Object.assign(surface(), {
        style: {}, attributes: {},
        setAttribute(name, value) { this.attributes[name] = value; },
        animate() { throw new Error('Reduced-motion menu must not animate'); }
    });
    const checkbox = Object.assign(element(), { checked: false, focus() { this.focused = true; } });
    const label = element();
    const closedBar = element();
    const menu = Object.assign(element(), { querySelectorAll: () => [], querySelector: () => null });
    const capsule = Object.assign(element(), { querySelector: () => closedBar, getAnimations: () => [] });
    const document = Object.assign(surface(), {
        documentElement: {},
        getElementById: id => ({ 'menu-toggle': checkbox, 'header-content': capsule, menu })[id],
        querySelector: selector => selector.startsWith('label') ? label : element()
    });
    vm.runInNewContext(script, {
        document,
        window: { matchMedia: () => Object.assign(surface(), { matches: true }) },
        getComputedStyle: () => ({ getPropertyValue: () => '' })
    });
    checkbox.checked = true;
    checkbox.dispatchEvent({ type: 'change' });
    assert.equal(closedBar.inert, true);
    assert.equal(checkbox.attributes['aria-expanded'], 'true');
    document.dispatchEvent({ type: 'keydown', key: 'Escape' });
    assert.equal(checkbox.checked, false);
    assert.equal(checkbox.focused, true);
    assert.equal(closedBar.inert, false);
    checkbox.checked = true;
    checkbox.dispatchEvent({ type: 'change' });
    document.dispatchEvent({ type: 'collection:before-swap' });
    assert.equal(checkbox.checked, false);
    assert.equal(label.attributes['aria-expanded'], 'false');
});
