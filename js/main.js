(async function () {
  const $ = (id) => document.getElementById(id);

  function el(tag, attrs = {}, children = []) {
    const n = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs)) {
      if (k === "class") n.className = v;
      else if (k === "html") n.innerHTML = v;
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

  async function applyStylePack(meta) {
    const pack = (meta && meta.stylePack) ? meta.stylePack : "modern-saas";

    try {
      const data = await loadJson(`/styles/packs/${pack}.json`);
      const vars = (data && data.vars) || {};
      for (const [k, v] of Object.entries(vars)) {
        document.documentElement.style.setProperty(k, v);
      }
    } catch (e) {
      // If pack missing, fall back silently
      console.warn("Style pack load failed:", pack);
    }
  }


  function applyPageFilter() {
    const page = document.body.getAttribute("data-page") || "home";
    const all = ["about","services","projects","testimonials","process","faq","contact"];
    const keepMap = {
      home: all,
      about: ["about","contact"],
      services: ["services","testimonials","faq","contact"],
      inventory: ["projects","testimonials","faq","contact"],
      contact: ["contact"]
    };
    const keep = new Set(keepMap[page] || all);
    all.forEach((id) => {
      const node = document.getElementById(id);
      if (node && !keep.has(id)) node.style.display = "none";
    });
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

  function nl2br(s = "") {
    return (s || "").split("\n").map((line) => line.trim()).filter(Boolean).join("<br/>");
  }

  function ensureHashLinks(names = []) {
    // Maps ["About","Services"] -> [{label:"About", href:"#about"}, ...]
    return names.map((label) => ({
      label,
      href: "#" + String(label).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "")
    }));
  }

  function applyMeta(meta = {}) {
    if (meta.title) document.title = meta.title;
    const desc = document.querySelector('meta[name="description"]');
    if (desc && meta.description) desc.setAttribute("content", meta.description);

    // favicon
    const ico = document.querySelector('link[rel="icon"]');
    if (ico && meta.favicon) ico.setAttribute("href", "./" + meta.favicon.replace(/^\//, ""));

    // brand color as CSS var
    if (meta.brandColor) {
      document.documentElement.style.setProperty("--accent", meta.brandColor);
    }
  }

  function renderNav(nav = {}) {
    if ($("navLogo")) $("navLogo").textContent = nav.logo || "YN";

    const navEl = $("navLinks");
    if (!navEl) return;
    navEl.innerHTML = "";

    const links = Array.isArray(nav.links) ? ensureHashLinks(nav.links) : [];
    links.forEach((item) => {
      navEl.appendChild(el("a", { href: item.href, class: "nav-link" }, [item.label]));
    });
  }

  function renderHero(hero = {}) {
    if ($("heroBadge")) $("heroBadge").textContent = hero.badge || "";
    if ($("heroHeadline")) $("heroHeadline").innerHTML = nl2br(hero.headline || "Your Name");
    if ($("heroSubheadline")) $("heroSubheadline").textContent = hero.subheadline || "";

    const ctaRow = $("heroCtaRow");
    if (ctaRow) {
      ctaRow.innerHTML = "";
      if (hero.cta?.text) {
        ctaRow.appendChild(el("a", { href: hero.cta.href || "#contact", class: "btn primary" }, [hero.cta.text]));
      }
    }

    const stats = $("heroStats");
    if (stats) {
      stats.innerHTML = "";
      (hero.stats || []).forEach((s) => {
        stats.appendChild(el("div", { class: "stat" }, [
          el("div", { class: "stat-val" }, [String(s.value ?? "")]),
          el("div", { class: "stat-lbl muted" }, [String(s.label ?? "")]),
        ]));
      });
    }
  }

  function renderAbout(about = {}) {
    if ($("aboutLabel")) $("aboutLabel").textContent = about.sectionLabel || "About";
    if ($("aboutHeading")) $("aboutHeading").innerHTML = nl2br(about.heading || "");

    const body = $("aboutBody");
    if (body) {
      body.innerHTML = "";
      (about.paragraphs || []).forEach((p) => body.appendChild(el("p", { class: "muted" }, [p])));

      if (Array.isArray(about.highlights) && about.highlights.length) {
        const grid = el("div", { class: "grid two" }, []);
        about.highlights.forEach((h) => {
          grid.appendChild(el("div", { class: "card mini" }, [
            el("div", { class: "mini-title" }, [h.label || ""]),
            el("div", { class: "muted" }, [h.detail || ""]),
          ]));
        });
        body.appendChild(grid);
      }

      if (about.linkedin) {
        body.appendChild(el("a", { class: "link", href: about.linkedin, target: "_blank", rel: "noreferrer" }, ["LinkedIn →"]));
      }
    }
  }

  function renderServices(services = {}) {
    if ($("servicesLabel")) $("servicesLabel").textContent = services.sectionLabel || "Services";
    if ($("servicesHeading")) $("servicesHeading").innerHTML = nl2br(services.heading || "");
    if ($("servicesIntro")) $("servicesIntro").textContent = services.intro || "";

    const grid = $("servicesGrid");
    if (grid) {
      grid.innerHTML = "";
      (services.items || []).forEach((s) => {
        const feats = el("ul", { class: "bullets" }, (s.features || []).map((f) => el("li", {}, [f])));
        grid.appendChild(el("div", { class: "card service" }, [
          el("h3", {}, [s.title || "Service"]),
          el("p", { class: "muted" }, [s.description || ""]),
          feats,
          el("div", { class: "meta-row" }, [
            s.bestFor ? el("span", { class: "chip" }, [s.bestFor]) : el("span"),
            s.turnaround ? el("span", { class: "chip" }, [`Turnaround: ${s.turnaround}`]) : el("span"),
          ]),
        ]));
      });
    }

    const ctaRow = $("servicesCtaRow");
    if (ctaRow) {
      ctaRow.innerHTML = "";
      if (services.cta?.text) {
        ctaRow.appendChild(el("a", { href: services.cta.href || "#contact", class: "btn" }, [services.cta.text]));
      }
    }
  }

  function renderProjects(projects = {}) {
    if ($("projectsLabel")) $("projectsLabel").textContent = projects.sectionLabel || "Projects";
    if ($("projectsHeading")) $("projectsHeading").innerHTML = nl2br(projects.heading || "");
    if ($("projectsIntro")) $("projectsIntro").textContent = projects.intro || "";

    const grid = $("projectsGrid");
    if (grid) {
      grid.innerHTML = "";
      (projects.items || []).forEach((p) => {
        const tags = el("div", { class: "tags" }, (p.tags || []).map((t) => el("span", { class: "tag" }, [t])));
        const url = p.url && p.url !== "#" ? p.url : "";
        grid.appendChild(el("div", { class: "card project" }, [
          el("div", { class: "meta" }, [`${p.type || ""}${p.year ? " · " + p.year : ""}`].filter(Boolean).join("")),
          el("h3", {}, [p.title || "Project"]),
          el("p", { class: "muted" }, [p.description || ""]),
          p.role ? el("p", { class: "muted" }, [`Role: ${p.role}`]) : el("span"),
          tags,
          url ? el("a", { class: "link", href: url, target: "_blank", rel: "noreferrer" }, ["View →"]) : el("span"),
        ]));
      });
    }
  }

  function renderTestimonials(t = {}) {
    if ($("testimonialsLabel")) $("testimonialsLabel").textContent = t.sectionLabel || "Testimonials";
    if ($("testimonialsHeading")) $("testimonialsHeading").innerHTML = nl2br(t.heading || "");

    const grid = $("testimonialsGrid");
    if (grid) {
      grid.innerHTML = "";
      (t.items || []).forEach((x) => {
        grid.appendChild(el("div", { class: "card testimonial" }, [
          el("p", {}, [`“${x.quote || ""}”`]),
          el("p", { class: "meta" }, [`— ${x.author || "Client"}${x.role ? ", " + x.role : ""}`]),
        ]));
      });
    }
  }

  function renderProcess(proc = {}) {
    if ($("processLabel")) $("processLabel").textContent = proc.sectionLabel || "Process";
    if ($("processHeading")) $("processHeading").innerHTML = nl2br(proc.heading || "");

    const wrap = $("processSteps");
    if (wrap) {
      wrap.innerHTML = "";
      (proc.steps || []).forEach((s) => {
        wrap.appendChild(el("div", { class: "step" }, [
          el("div", { class: "step-num" }, [s.number || ""]),
          el("div", {}, [
            el("h3", {}, [s.title || "Step"]),
            el("p", { class: "muted" }, [s.description || ""]),
          ]),
        ]));
      });
    }
  }

  function renderFaq(faq = {}) {
    if ($("faqLabel")) $("faqLabel").textContent = faq.sectionLabel || "FAQ";
    if ($("faqHeading")) $("faqHeading").innerHTML = nl2br(faq.heading || "");

    const wrap = $("faqItems");
    if (wrap) {
      wrap.innerHTML = "";
      (faq.items || []).forEach((f) => {
        wrap.appendChild(el("details", { class: "faq-item" }, [
          el("summary", { class: "faq-q" }, [f.question || "Question"]),
          el("div", { class: "faq-a muted" }, [f.answer || "Answer"]),
        ]));
      });
    }
  }

  function renderContact(c = {}) {
    if ($("contactLabel")) $("contactLabel").textContent = c.sectionLabel || "Contact";
    if ($("contactHeading")) $("contactHeading").innerHTML = nl2br(c.heading || "");
    if ($("contactIntro")) $("contactIntro").textContent = c.intro || "";

    const card = $("contactCard");
    if (!card) return;
    card.innerHTML = "";

    const email = c.email || "";
    const formspreeAction = c.formspreeAction || "";

    if (formspreeAction) {
      card.appendChild(el("form", { class: "form", method: "POST", action: formspreeAction }, [
        el("input", { name: "name", placeholder: "Your name", required: "true" }),
        el("input", { name: "email", placeholder: "Email", type: "email", required: "true" }),
        el("textarea", { name: "message", placeholder: "Message", rows: "5", required: "true" }),
        el("button", { class: "btn primary", type: "submit" }, ["Send"]),
      ]));
      if (email) card.appendChild(el("p", { class: "muted" }, [`Or email: ${email}`]));
    } else {
      card.appendChild(el("p", { class: "muted" }, [
        email ? `Email: ${email}` : "Add contact.formspreeAction in content/site.json to enable the form."
      ]));
      if (email) card.appendChild(el("a", { class: "btn primary", href: `mailto:${email}` }, ["Email me"]));
    }
  }

  function renderFooter(f = {}) {
    const left = $("footerLeft");
    const right = $("footerRight");
    if (left) left.textContent = `© ${new Date().getFullYear()}`;

    if (right) {
      right.innerHTML = "";
      const credit = [f.credit, f.creditName].filter(Boolean).join(" ");
      if (f.creditLink && credit) {
        right.appendChild(el("span", {}, [credit + " "]));
        right.appendChild(el("a", { class: "link", href: f.creditLink, target: "_blank", rel: "noreferrer" }, [f.creditLink.replace(/^https?:\/\//, "")]));
      } else if (credit) {
        right.textContent = credit;
      }
    }
  }

  try {
    initTheme();
    const data = await loadJson("/content/site.json");
    await applyStylePack(data.meta || {});
    applyMeta(data.meta || {});
    if (typeof applyPageFilter === 'function') applyPageFilter();
    renderNav(data.nav || {});
    renderHero(data.hero || {});
    renderAbout(data.about || {});
    renderServices(data.services || {});
    renderProjects(data.projects || {});
    renderTestimonials(data.testimonials || {});
    renderProcess(data.process || {});
    renderFaq(data.faq || {});
    renderContact(data.contact || {});
    renderFooter(data.footer || {});
  } catch (e) {
    console.error(e);
    if ($("heroHeadline")) $("heroHeadline").textContent = "Template loaded, but content failed to load.";
    if ($("heroSubheadline")) $("heroSubheadline").textContent = String(e.message || e);
  }
})();
