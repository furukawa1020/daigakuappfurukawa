use daigakuos-core::security::SovereignVault;
use daigakuos-core::tutor::TutorEngine;

#[derive(Serialize, Deserialize)]
#[serde(tag = "command", rename_all = "snake_case")]
enum BridgeCommand {
    Simulate { 
        encrypted_state: String, 
        dt_hours: f32, 
        velocity: f32 
    },
    ProcessDamage { 
        encrypted_state: String, 
        damage: f32 
    },
    Rebirth { 
        encrypted_state: String 
    },
    Bootstrap {
        state: BioState
    },
}

#[derive(Serialize, Deserialize)]
struct BridgeResponse {
    encrypted_state: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    result: Option<serde_json::Value>,
    message: String,
}

fn main() -> anyhow::Result<()> {
    let stdin = io::stdin();
    let mut lines = stdin.lock().lines();

    if let Some(Ok(line)) = lines.next() {
        let cmd: BridgeCommand = serde_json::from_str(&line)?;
        
        match cmd {
            BridgeCommand::Simulate { encrypted_state, dt_hours, velocity } => {
                let decrypted = match SovereignVault::unseal(&encrypted_state) {
                    Ok(s) => s,
                    Err(_) => {
                        // 🔐 Security Breach: Invalid signature
                        unsafe { windows_sys::Win32::System::SystemServices::LockWorkStation(); }
                        return Err(anyhow::anyhow!("SECURITY_BREACH: Authentication failed"));
                    }
                };
                let mut state: BioState = serde_json::from_str(&decrypted)?;
                
                state.last_activity = ProxyKernel::get_active_window_category();
                BioKernel::tick(&mut state, dt_hours, velocity);
                
                let re_encrypted = SovereignVault::seal(&serde_json::to_string(&state)?);
                let response = BridgeResponse {
                    encrypted_state: re_encrypted,
                    result: None,
                    message: "Simulation tick successful 🦀".to_string(),
                };
                println!("{}", serde_json::to_string(&response)?);
            },
            BridgeCommand::ProcessDamage { encrypted_state, damage } => {
                let decrypted = SovereignVault::unseal(&encrypted_state)?;
                let mut state: BioState = serde_json::from_str(&decrypted)?;
                
                let res = BioKernel::process_damage(&mut state, damage);
                
                let re_encrypted = SovereignVault::seal(&serde_json::to_string(&state)?);
                let response = BridgeResponse {
                    encrypted_state: re_encrypted,
                    result: Some(serde_json::to_value(res)?),
                    message: "Damage processed natively 🦀".to_string(),
                };
                println!("{}", serde_json::to_string(&response)?);
            },
            BridgeCommand::Rebirth { encrypted_state } => {
                let decrypted = SovereignVault::unseal(&encrypted_state)?;
                let state: BioState = serde_json::from_str(&decrypted)?;
                
                let next_state = BioKernel::rebirth(&state);
                
                let re_encrypted = SovereignVault::seal(&serde_json::to_string(&next_state)?);
                let response = BridgeResponse {
                    encrypted_state: re_encrypted,
                    result: None,
                    message: "Genetically recombined natively 🧬".to_string(),
                };
                println!("{}", serde_json::to_string(&response)?);
            }
        }
    }

    Ok(())
}
