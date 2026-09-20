/* TanoNote landing page — a few honest enhancements, no tracking.
   The page works with this file absent: content is visible by default and the
   theme follows the system until the visitor chooses otherwise. */

(function () {
  "use strict";

  var root = document.documentElement;
  root.classList.add("js");

  /* ---------- Theme ---------- */

  // A remembered choice was already applied by the inline script in <head>.
  var STORAGE_KEY = "tano-theme";
  var toggle = document.querySelector("[data-theme-toggle]");
  var media = window.matchMedia
    ? window.matchMedia("(prefers-color-scheme: dark)")
    : null;

  function prefersDark() {
    return !!(media && media.matches);
  }

  function currentTheme() {
    var explicit = root.getAttribute("data-theme");
    if (explicit === "dark" || explicit === "light") {
      return explicit;
    }
    return prefersDark() ? "dark" : "light";
  }

  if (toggle) {
    toggle.addEventListener("click", function () {
      var next = currentTheme() === "dark" ? "light" : "dark";
      root.setAttribute("data-theme", next);
      try {
        localStorage.setItem(STORAGE_KEY, next);
      } catch (error) {
        /* private mode: the choice simply will not be remembered */
      }
    });
  }

  /* ---------- The year in the footer ---------- */

  var years = document.querySelectorAll("[data-year]");
  for (var i = 0; i < years.length; i++) {
    years[i].textContent = String(new Date().getFullYear());
  }

  /* ---------- A hairline under the masthead once the page moves ---------- */

  var masthead = document.querySelector(".masthead");
  function onScroll() {
    if (masthead) {
      masthead.classList.toggle("is-stuck", window.scrollY > 8);
    }
  }
  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });

  /* ---------- The ruled lines of the paper sheets ---------- */

  // Many identical lines, so they are grown here instead of written out.
  var lineBlocks = document.querySelectorAll("[data-lines]");
  for (var b = 0; b < lineBlocks.length; b++) {
    var block = lineBlocks[b];
    var count = parseInt(block.getAttribute("data-lines"), 10) || 0;
    for (var n = 0; n < count; n++) {
      var line = document.createElement("span");
      line.className = "ruled";
      block.appendChild(line);
    }
  }

  /* ---------- Cards arrive as they are reached ---------- */

  var targets = document.querySelectorAll("[data-reveal]");
  if (!targets.length) {
    return;
  }

  function revealAll() {
    for (var j = 0; j < targets.length; j++) {
      targets[j].classList.add("in");
    }
  }

  var reduced =
    window.matchMedia &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reduced || !("IntersectionObserver" in window)) {
    revealAll();
    return;
  }

  try {
    var observer = new IntersectionObserver(
      function (entries) {
        for (var k = 0; k < entries.length; k++) {
          if (entries[k].isIntersecting) {
            entries[k].target.classList.add("in");
            observer.unobserve(entries[k].target);
          }
        }
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0.08 }
    );
    for (var m = 0; m < targets.length; m++) {
      observer.observe(targets[m]);
    }
  } catch (error) {
    revealAll();
  }
})();
