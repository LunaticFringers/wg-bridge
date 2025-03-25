// main.rs
// Copyright (c) 2025 Lunatic Fringers
// This file is part of "WG-Bridge" under the AGPL-3.0-or-later license.
// See the LICENSE file in the project root or <https://www.gnu.org/licenses/> for details.


mod cli;
mod core;
mod ui;

use core::{configuration::AppConf, logger::Logger};

use chrono::Local;

use std::thread;
use std::time::Duration;


fn main() {
  // Initializing logger
  let date = Local::now().format("%Y-%m-%d").to_string();
  Logger::init(&format!("./{}.log", date));
  let log = Logger::get();

  // Initializing application
  AppConf::init();
  let app_conf: &AppConf = AppConf::get();

  // Debugging messages
  #[cfg(debug_assertions)]
  {
    log.debug("test");
    log.info("test");
    log.warn("test");
    log.error("test");
    println!("Awaiting log creation");
    log.debug(&format!("user configuration path: {}", &app_conf.user_conf));
    thread::sleep(Duration::new(2,0));
  }
}
