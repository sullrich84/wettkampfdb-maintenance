import React from "react";
import ReactDOM from "react-dom";

import logo from "./logo.svg";
import "./index.css";

ReactDOM.render(
  <React.StrictMode>
    <div className="card">
      <img id="logo" src={logo} alt="Logo" />
      <div class="row">
        <h1>Wartung</h1>
        <p>
          Die WettkampfDB wird momentan aktualisiert. <br />
          Bitte schau später nochmal vorbei&#8230;
        </p>
      </div>
      <div class="row" style={{ color: "#666" }}>
        <h1>Maintenance</h1>
        <p>
          WettkampfDB is currently being updated. <br />
          Please check back later&#8230;
        </p>
      </div>
    </div>
  </React.StrictMode>,
  document.getElementById("root")
);
