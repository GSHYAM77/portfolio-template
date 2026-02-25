(async function () {
  const $ = (id) => document.getElementById(id);

  function el(tag, attrs = {}, children = []) {
    const n = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs)) {
      if (k === "class") n.className = v;
      else if (k.startsWith("on") && typeof v === "function") n.addEventListener(k.slice(2), v);
      else n.setAttribute(k, v);
    }
    for (const c of children) n.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
    return n;
  }

  async function loadJson(path) {
    const res = await fetch(path, { cache: "no-store" });
    if (!res.ok) throw new Error(`Failed to load ${path}: ${res.status}`);
    return res.json();
  }

  function setTheme(mode) {
    const root = document.documentElement;
    if (mode === "light") root.classList.remove("dark");
    else root.classList.add("dark");
    localStorage.setItem("theme", mode);
    const btn = $("modeToggle");
    if (btn) btn.textContent = mode === "light" ? "☀" : "☾";
  }

  function initTheme() {
    const saved = localStorage.getItem("theme");
    setTheme(saved || "dark");
    const btn = $("modeToggle");
    if (btn) btn.addEventListener("click", () => {
      const isDark = document.documentElement.classList.contains("dark");
      setTheme(isDark ? "light" : "dark");
    });
  }

  function renderNav(nav = []) {
    const navEl = $("navLinks");
    if (!navEl) return;
    navEl.innerHTML = "";
    nav.forEach((item) => {
      navEl.appendChild(el("a", { href: item.href || "#", class: "nav-link" }, [item.label || "Link"]));
    });
  }

  function renderHero(hero = {}) {
    if ($("brandName")) $("brandName").textContent = hero.brand || "Template";
    if ($("heroKicker")) $("heroKicker").textContent = hero.kicker || "";
    if ($("heroTitle")) $("heroTitle").textContent = hero.title || "Your Name";
    if ($("heroSubtitle")) $("heroSubtitle").textContent = hero.subtitle || "";

    const ctas = $("heroCtas");
    if (ctas) {
      ctas.innerHTML = "";
      (hero.ctas || []).forEach((c) => {
        ctas.appendChild(el("a", { href: c.href || "#", class: c.primary ? "btn primary" : "btn" }, [c.label || "CTA"]));
      });
    }

    const badges = $("heroBadges");
    if (badges) {
      badges.innerHTML = "";
      (hero.badges || []).forEach((b) => badges.appendChild(el("span", { class: "badge" }, [b])));
    }
  }

  function renderAbout(about = {}) {
    const card = $("aboutCard");
    if (!card) return;
    card.innerHTML = "";
    card.appendChild(el("p", { class: "muted" }, [about.text || "Write a short bio here."]));
    if (about.highlights?.length) {
      const ul = el("ul", { class: "bullets" }, about.highlights.map((h) => el("li", {}, [h])));
      card.appendChild(ul);
    }
  }

  function renderServices(services = []) {
    const grid = $("servicesGrid");
    if (!grid) return;
    grid.innerHTML = "";
    services.forEach((s) => {
      grid.appendChild(el("div", { class: "card service" }, [
        el("h3", {}, [s.title || "Service"]),
        el("p", { class: "muted" }, [s.description || ""]),
        s.turnaround ? el("p", { class: "meta" }, [`Turnaround: ${s.turnaround}`]) : el("span"),
      ]));
    });
  }

  function renderProjects(projects = []) {
    const grid = $("projectsGrid");
    if (!grid) return;
    grid.innerHTML = "";
    projects.forEach((p) => {
      const links = el("div", { class: "card-links" }, []);
      (p.links || []).forEach((l) => {
        links.appendChild(el("a", { href: l.href || "#", class: "link", target: "_blank", rel: "noreferrer" }, [l.label || "Link"]));
      });
      grid.appendChild(el("div", { class: "card project" }, [
        el("h3", {}, [p.title || "Project"]),
        el("p", { class: "muted" }, [p.description || ""]),
        links,
      ]));
    });
  }

  function renderTestimonials(items = []) {
    const grid = $("testimonialsGrid");
    if (!grid) return;
    grid.innerHTML = "";
    items.forEach((t) => {
      grid.appendChild(el("div", { class: "card testimonial" }, [
        el("p", {}, [`“${t.quote || ""}”`]),
        el("p", { class: "meta" }, [`— ${t.name || "Client"}`]),
      ]));
    });
  }

  function renderProcess(steps = []) {
    const wrap = $("processSteps");
    if (!wrap) return;
    wrap.innerHTML = "";
    steps.forEach((s, idx) => {
      wrap.appendChild(el("div", { class: "step" }, [
        el("div", { class: "step-num" }, [`${idx + 1}`]),
        el("div", {}, [
          el("h3", {}, [s.title || "Step"]),
          el("p", { class: "muted" }, [s.description || ""]),
        ]),
      ]));
    });
  }

  function renderFaq(items = []) {
    const wrap = $("faqItems");
    if (!wrap) return;
    wrap.innerHTML = "";
    items.forEach((f) => {
      const details = el("details", { class: "faq-item" }, [
        el("summary", { class: "faq-q" }, [f.q || "Question"]),
        el("div", { class: "faq-a muted" }, [f.a || "Answer"]),
      ]);
      wrap.appendChild(details);
    });
  }

  function renderContact(contact = {}) {
    const card = $("contactCard");
    if (!card) return;
    card.innerHTML = "";

    const title = contact.title || "Let’s talk";
    const blurb = contact.blurb || "Send a message and I’ll reply ASAP.";
    card.appendChild(el("h3", {}, [title]));
    card.appendChild(el("p", { class: "muted" }, [blurb]));

    const endpoint = contact.formspreeEndpoint || "";
    if (endpoint) {
      card.appendChild(el("form", { class: "form", method: "POST", action: endpoint }, [
        el("input", { name: "name", placeholder: "Your name", required: "true" }),
        el("input", { name: "email", placeholder: "Email", type: "email", required: "true" }),
        el("textarea", { name: "message", placeholder: "Message", rows: "5", required: "true" }),
        el("button", { class: "btn primary", type: "submit" }, ["Send"]),
      ]));
    } else {
      const email = contact.email || "";
      card.appendChild(el("p", { class: "muted" }, [email ? `Email: ${email}` : "Add contact.formspreeEndpoint in content/site.json to enable the form."]));
      if (email) {
        card.appendChild(el("a", { class: "btn primary", href: `mailto:${email}` }, ["Email me"]));
      }
    }
  }

  function renderFooter(footer = {}) {
    const left = $("footerLeft");
    const right = $("footerRight");
    if (left) left.textContent = footer.left || "© " + new Date().getFullYear();
    if (right) {
      right.innerHTML = "";
      if (footer.creditText && footer.creditHref) {
        right.appendChild(el("a", { href: footer.creditHref, class: "link", target: "_blank", rel: "noreferrer" }, [footer.creditText]));
      } else {
        right.textContent = footer.right || "";
      }
    }
  }

  try {
    initTheme();
    const data = await loadJson("./content/site.json");
    renderNav(data.nav || [
      { label: "Home", href: "#home" },
      { label: "About", href: "#about" },
      { label: "Services", href: "#services" },
      { label: "Projects", href: "#projects" },
      { label: "Contact", href: "#contact" },
    ]);
    renderHero(data.hero || {});
    renderAbout(data.about || {});
    renderServices(data.services || []);
    renderProjects(data.projects || []);
    renderTestimonials(data.testimonials || []);
    renderProcess(data.process || []);
    renderFaq(data.faq || []);
    renderContact(data.contact || {});
    renderFooter(data.footer || {});
  } catch (e) {
    console.error(e);
    if ($("heroTitle")) $("heroTitle").textContent = "Template loaded, but data failed to load.";
    if ($("heroSubtitle")) $("heroSubtitle").textContent = String(e.message || e);
  }
})();
