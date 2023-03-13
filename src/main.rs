use clap::Command;
use colored::*;
use flexi_logger::{detailed_format, Duplicate, FileSpec, Logger};
use indicatif::{HumanDuration, MultiProgress, ProgressBar, ProgressStyle};
use log::error;

use std::{
    error::Error,
    fs, io,
    path::{Path, PathBuf},
    process,
    sync::Arc,
    thread,
    time::{Duration, Instant},
};

// struct Package {
//     name: String,
//     url: String,
//     alias: String,
// }

fn main() {
    // handle Ctrl+C
    ctrlc::set_handler(move || {
        println!(
            "{} {} {}",
            "🤬",
            "Received Ctrl-C! => Exit program!".bold(),
            "☠",
        );
        process::exit(0)
    })
    .expect("Error setting Ctrl-C handler");

    // get config dir
    let config_dir = check_create_config_dir().unwrap_or_else(|err| {
        error!("Unable to find or create a config directory: {err}");
        process::exit(1);
    });

    // initialize the logger
    let _logger = Logger::try_with_str("info") // log warn and error
        .unwrap()
        .format_for_files(detailed_format) // use timestamp for every log
        .log_to_file(
            FileSpec::default()
                .directory(&config_dir)
                .suppress_timestamp(),
        ) // change directory for logs, no timestamps in the filename
        .append() // use only one logfile
        .duplicate_to_stderr(Duplicate::Info) // print infos, warnings and errors also to the console
        .start()
        .unwrap();

    // handle arguments
    let matches = leann_core().get_matches();

    match matches.subcommand() {
        Some(("log", _)) => {
            if let Ok(logs) = show_log_file(&config_dir) {
                println!("{}", "Available logs:".bold().yellow());
                println!("{}", logs);
            } else {
                error!("Unable to read logs");
                process::exit(1);
            }
        }
        _ => {
            if let Err(err) = get_lc() {
                error!("Unable to get leann-core utils: {err}");
                process::exit(1);
            }
        }
    }
}

fn leann_core() -> Command {
    Command::new("lc")
        .bin_name("lc")
        .before_help(format!(
            "{}\n{}",
            "LEANN CORE".bold().truecolor(250, 0, 104),
            "Leann Phydon <leann.phydon@gmail.com>".italic().dimmed()
        ))
        .about("Get leann core utils")
        .before_long_help(format!(
            "{}\n{}",
            "LEANN CORE".bold().truecolor(250, 0, 104),
            "Leann Phydon <leann.phydon@gmail.com>".italic().dimmed()
        ))
        .long_about(format!("{}", "Get leann core utils",))
        // TODO update version
        .version("1.0.0")
        .author("Leann Phydon <leann.phydon@gmail.com>")
        .subcommand(
            Command::new("log")
                .short_flag('L')
                .long_flag("log")
                .about("Show content of the log file"),
        )
}

fn get_lc() -> io::Result<()> {
    let packages = vec!["wasd".to_string(), "test".to_string(), "stuff".to_string()];

    if let Err(err) = download(packages) {
        error!("Unable to get packages: {err}");
    }

    add_to_path();

    Ok(())
}

fn download(packages: Vec<String>) -> Result<Arc<MultiProgress>, Box<dyn Error>> {
    let started = Instant::now();
    let spinner_style =
        ProgressStyle::with_template("{prefix} {spinner:.blue} {wide_msg}").unwrap();

    let m = Arc::new(MultiProgress::new());
    let sty = ProgressStyle::with_template(
        "{spinner:.red} [{elapsed_precise}] {bar:40.blue/white} {pos:>5}/{len:5} {eta:5} {msg}",
    )
    .unwrap()
    .progress_chars("->..");
    // .progress_chars("=>-");

    let pb = m.add(ProgressBar::new(packages.len() as u64));
    pb.set_style(sty);

    pb.tick();
    let handles: Vec<_> = packages
        .into_iter()
        .map(|pkg| {
            let pkg = pkg.clone();
            let pb = pb.clone();
            let spinner = m.add(ProgressBar::new_spinner());
            spinner.enable_steady_tick(Duration::from_millis(200));
            spinner.set_style(spinner_style.clone());
            spinner.set_prefix(format!("{} {}", "[...]".dimmed(), pkg));
            thread::spawn(move || {
                spinner.set_message(format!("{}", "updating".truecolor(250, 0, 104),));
                spinner.tick();
                if let Err(err) = get_pkg(pkg) {
                    error!("Unable to process pkgs: {err}");
                }
                spinner.finish_with_message(format!("{}", "done".truecolor(59, 179, 140)));
                pb.inc(1);
            })
        })
        .collect();

    for h in handles {
        let _ = h.join();
    }

    pb.finish_with_message(format!("{}", "done".bold().truecolor(59, 179, 140)));

    // m.clear().unwrap();

    println!(
        "{} {} {}",
        "✔",
        "ALL DONE IN ".bold().truecolor(59, 179, 140),
        HumanDuration(started.elapsed())
            .to_string()
            .to_uppercase()
            .bold()
            .truecolor(59, 179, 140)
    );

    Ok(m)
}

fn get_pkg(name: String) -> Result<(), Box<dyn Error>> {
    thread::sleep(Duration::from_millis(3000));

    // Invoke-WebRequest -Uri <source> -OutFile <destination>
    // curl.exe -LO https://github.com/Phydon/<REPO>/releases/latest/download/<FILE>

    // let cmd = String::from("update ");
    // cmd.push_str(&name);

    // if cfg!(target_os = "windows") {
    //     process::Command::new("powershell")
    //         .args(["-c", "echo Hello"])
    //         // .args(["-c", &cmd])
    //         .status()?
    // } else {
    //     unimplemented!();
    // };

    Ok(())
}

fn add_to_path() {
    println!("Adding to path ...");
}

fn check_create_config_dir() -> io::Result<PathBuf> {
    let mut new_dir = PathBuf::new();
    match dirs::config_dir() {
        Some(config_dir) => {
            new_dir.push(config_dir);
            new_dir.push("leann_core");
            if !new_dir.as_path().exists() {
                fs::create_dir(&new_dir)?;
            }
        }
        None => {
            error!("Unable to find config directory");
        }
    }

    Ok(new_dir)
}

fn show_log_file(config_dir: &PathBuf) -> io::Result<String> {
    let log_path = Path::new(&config_dir).join("leann_core.log");
    match log_path.try_exists()? {
        true => {
            return Ok(format!(
                "{} {}\n{}",
                "Log location:".italic().dimmed(),
                &log_path.display(),
                fs::read_to_string(&log_path)?
            ));
        }
        false => {
            return Ok(format!(
                "{} {}",
                "No log file found:"
                    .truecolor(250, 0, 104)
                    .bold()
                    .to_string(),
                log_path.display()
            ))
        }
    }
}
