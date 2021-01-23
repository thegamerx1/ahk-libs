document.oncontextmenu = document.ondragstart = function () {
  return false;
};

window.onload = function () {
  function injectcss(url) {
    var element = document.createElement("link");
    element.rel = "stylesheet";
    element.href = url;
    element.type = "text/css";
    element.async = false;

    element.onload = function () {
      inject.count++;
      injectCheck();
    };

    document.body.appendChild(element);
    inject.countTo++;
  }

  function injectjs(url) {
    var element = document.createElement("script");
    element.src = url;
    element.async = false;

    element.onload = function () {
      inject.count++;
      injectCheck();
    };

    document.body.appendChild(element);
    inject.countTo++;
  }

  if (typeof inject == "undefined") {
    inject = {};
    inject.path = "file:///C:/Users/TheGamerX05/Documents/Autohotkey/Lib/EzGui/";
  }

  inject.count = 0;
  inject.countTo = 0;
  $("link").each(function () {
    var src = this.getAttribute("href");
    if (src.match(/^localhost/)) src = src.replace("localhost/", inject.path);
    this.setAttribute("href", src);
  });
  injectcss(inject.path + "minify/default.css");
  injectcss(inject.path + "libs/bootstrap-dark.min.css");
  injectjs(inject.path + "minify/funcs.js");
  injectjs(inject.path + "libs/webcomponents.js");
  injectjs(inject.path + "minify/titlebar.js");
  injectjs(inject.path + "libs/bootstrap.min.js");
  console.log("INJECTED HGARD");
};

function injectCheck() {
  if (inject.count >= inject.countTo) {
    if (!window.document.documentMode) {
      enableDebug();
    }
  }
}

function enableDebug() {
  isAHK = false;
  activate(1);
  ready();
  debug();
}

function sleep(ms) {
  return new Promise(function (resolve) {
    setTimeout(resolve, ms);
  });
}