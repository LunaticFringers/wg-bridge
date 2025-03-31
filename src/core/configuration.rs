// configuration.rs
// Copyright (c) 2025 Lunatic Fringers
// This file is part of "WG-Bridge" under the AGPL-3.0-or-later license.
// See the LICENSE file in the project root or <https://www.gnu.org/licenses/> for details.

use serde::{Deserialize, Serialize};
use std::{error::Error, sync::OnceLock, fs, env, process};
use toml;

use crate::core::logger::Logger;

/// Define a struct for application-level configuration.
#[derive(Serialize, Deserialize, Debug)]
pub struct Config {
  #[serde(rename = "path")]
  pub filepath: String,
  pub token: bool,
  pub uri: String,

  #[serde(rename = "connected")]
  pub active: bool,
}

/// Define a struct to represent the collection of configurations for Wgbc.
#[derive(Serialize, Deserialize, Debug)]
pub struct Wgbc {
  pub confs: Vec<Config>,
}

/// Define the main application configuration structure.
#[derive(Serialize, Deserialize, Debug)]
pub struct AppConf {
  pub version: String,
  pub log_path: String,
  pub user_conf: String,
}

/// A static OnceLock that holds the application configuration as a singleton.
static CONFIG: OnceLock<AppConf> = OnceLock::new();

impl AppConf {
  /// Loads the application configuration from the TOML file.
  ///
  /// This function reads the configuration file, parses it into an `AppConf` struct,
  /// and processes any environment variables (such as replacing "$HOME" with the actual home directory).
  ///
  /// # Returns
  /// * `Ok(AppConf)`: The loaded configuration if successful.
  /// * `Err(Box<dyn Error>)`: If any error occurs during reading or parsing the file.
  pub fn load_app_conf() -> Result<Self, Box<dyn Error>> {
    let log: &Logger = Logger::get();
    let path: String = "/etc/wg-bridge/app.toml".to_string();

    // Read configuration file
    let config_content = fs::read_to_string(&path).map_err(|err| {
      log.error(&format!("Failed to read config file {}: {}", path, err));
      err
    })?;

    // Parse configuration file into AppConf struct
    let mut config: AppConf = toml::from_str(&config_content).map_err(|err| {
      log.error(&format!("Failed to parse the config file {}: {}", path, err));
      err
    })?;

    // Replace "$HOME" with the actual home directory if found in user_conf
    if config.user_conf.contains("$HOME") {
      let home = env::var("HOME")?;
      config.user_conf = config.user_conf.replace("$HOME", &home);
    }

    Ok(config)
  }

  /// Initializes the application configuration by loading the TOML file and setting the static `CONFIG`.
  ///
  /// This function attempts to load the application configuration. If successful, it sets the `CONFIG`
  /// static variable and logs the success. If it fails, it logs the error and exits the process with code 1.
  pub fn init() {
    let log: &Logger = Logger::get();
    match Self::load_app_conf() {
      Ok(config) => {
        CONFIG.set(config).expect("Failed to set configuration"); // Handle potential error
        log.debug("Configuration loaded successfully");
      }
      Err(err) => {
        log.error(&format!("Failed to load configuration: {}", err));
        process::exit(1);
      }
    }
  }

  /// Retrieves the application configuration after it has been initialized.
  ///
  /// This function provides access to the singleton instance of the `AppConf` struct.
  /// If the configuration has not been initialized, it panics with the message "Configuration not initialized".
  ///
  /// # Returns
  /// * `&'static AppConf`: A reference to the initialized configuration.
  pub fn get() -> &'static AppConf {
    CONFIG.get().expect("Configuration not initialized")
  }
}

impl Wgbc {
    // pub fn load_user_conf() -> Result<Self, Box<dyn Error>> {
    // let user_conf_path: String = AppConf::get().user_conf_path.clone(); // Access AppConf's user_conf_path
    // //
    // let user_conf = fs::read_to_string(&user_conf_path).map_err(|err| {
    //     Logger::get().error(&format!(
    //         "Failed to read config file {}: {}",
    //         user_conf_path, err
    //     ));
    //     err
    // })?;
    // let conf: WGBC = toml::from_str(&user_conf).map_err(|err| {
    // Logger::get().error(&format!(
    // "Failed to parse config file {}: {}",
    // user_conf_path, err
    // ));
    // err
    // })?;
    //
    // Ok(conf) // Return the parsed configuration
    // }
}
