use std::io::{self, BufRead};
use std::collections::HashMap;

use serde::{Deserialize, Serialize};

// Crate's own modules (crate name is daigakuos_core with underscores)
use daigakuos_core::{
    BioKernel,
    state::BioState,
    security::SovereignVault,
    proxy::ProxyKernel,
};

#[derive(Serialize, Deserialize)]
#[serde(tag = "command", rename_all = "snake_case")]
enum BridgeCommand {
    Bootstrap { state: BioState },
    Simulate   { encrypted_state: String, dt_hours: f32, velocity: f32 },
    ProcessDamage { encrypted_state: String, damage: f32 },
    Rebirth    { encrypted_state: String },
}

#[derive(Serialize, Deserialize)]
struct BridgeResponse {
    encrypted_state: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    state: Option<BioState>,
    #[serde(skip_serializing_if = "Option::is_none")]
    result: Option<serde_json::Value>,
    message: String,
}

fn main() -> anyhow::Result<()> {
    let stdin   = io::stdin();
    let mut lines = stdin.lock().lines();

    let line = match lines.next() {
        Some(Ok(l)) => l,
        _ => return Err(anyhow::anyhow!("No input received")),
    };

    let cmd: BridgeCommand = serde_json::from_str(&line)
        .map_err(|e| anyhow::anyhow!("JSON parse error: {}", e))?;

    let response = match cmd {
        // ── Bootstrap: seal a raw state for the first time ──────────
        BridgeCommand::Bootstrap { state } => {
            let json    = serde_json::to_string(&state)?;
            let sealed  = SovereignVault::seal(&json);
            BridgeResponse {
                encrypted_state: sealed,
                state: Some(state),
                result: None,
                message: "Vault bootstrap successful 🔐".to_string(),
            }
        }

        // ── Simulate: unseal → tick → reseal ────────────────────────
        BridgeCommand::Simulate { encrypted_state, dt_hours, velocity } => {
            let plain = SovereignVault::unseal(&encrypted_state)
                .map_err(|_| {
                    // Hard enforcement: lock workstation on tamper
                    #[cfg(windows)]
                    unsafe { windows_sys::Win32::System::SystemServices::LockWorkStation(); }
                    anyhow::anyhow!("SECURITY_BREACH: tampered state rejected")
                })?;

            let mut state: BioState = serde_json::from_str(&plain)?;
            state.last_activity = ProxyKernel::get_active_window_category();
            BioKernel::tick(&mut state, dt_hours, velocity);

            let sealed = SovereignVault::seal(&serde_json::to_string(&state)?);
            BridgeResponse {
                encrypted_state: sealed,
                state: Some(state),
                result: None,
                message: "Simulation tick complete 🦀".to_string(),
            }
        }

        // ── ProcessDamage ────────────────────────────────────────────
        BridgeCommand::ProcessDamage { encrypted_state, damage } => {
            let plain = SovereignVault::unseal(&encrypted_state)?;
            let mut state: BioState = serde_json::from_str(&plain)?;

            let result = BioKernel::process_damage(&mut state, damage);

            let sealed = SovereignVault::seal(&serde_json::to_string(&state)?);
            BridgeResponse {
                encrypted_state: sealed,
                state: Some(state),
                result: Some(serde_json::to_value(result)?),
                message: "Damage resolved natively 🦀".to_string(),
            }
        }

        // ── Rebirth ──────────────────────────────────────────────────
        BridgeCommand::Rebirth { encrypted_state } => {
            let plain = SovereignVault::unseal(&encrypted_state)?;
            let parent: BioState = serde_json::from_str(&plain)?;

            let child = BioKernel::rebirth(&parent);
            let sealed = SovereignVault::seal(&serde_json::to_string(&child)?);
            BridgeResponse {
                encrypted_state: sealed,
                state: Some(child),
                result: None,
                message: "Genetically recombined 🧬".to_string(),
            }
        }
    };

    println!("{}", serde_json::to_string(&response)?);
    Ok(())
}
