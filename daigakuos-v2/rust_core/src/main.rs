use serde::{Deserialize, Serialize};
use std::io::{self, BufRead};
use daigakuos-core::state::BioState;
use daigakuos-core::BioKernel;

#[derive(Serialize, Deserialize)]
#[serde(tag = "command", rename_all = "snake_case")]
enum BridgeCommand {
    Simulate { 
        state: BioState, 
        dt_hours: f32, 
        velocity: f32 
    },
    ProcessDamage { 
        state: BioState, 
        damage: f32 
    },
    Rebirth { 
        state: BioState 
    },
}

#[derive(Serialize, Deserialize)]
struct BridgeResponse {
    state: BioState,
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
            BridgeCommand::Simulate { mut state, dt_hours, velocity } => {
                BioKernel::tick(&mut state, dt_hours, velocity);
                let response = BridgeResponse {
                    state,
                    result: None,
                    message: "Simulation tick successful 🦀".to_string(),
                };
                println!("{}", serde_json::to_string(&response)?);
            },
            BridgeCommand::ProcessDamage { mut state, damage } => {
                let res = BioKernel::process_damage(&mut state, damage);
                let response = BridgeResponse {
                    state,
                    result: Some(serde_json::to_value(res)?),
                    message: "Damage processed natively 🦀".to_string(),
                };
                println!("{}", serde_json::to_string(&response)?);
            },
            BridgeCommand::Rebirth { state } => {
                let next_state = BioKernel::rebirth(&state);
                let response = BridgeResponse {
                    state: next_state,
                    result: None,
                    message: "Genetically recombined for succession 🧬".to_string(),
                };
                println!("{}", serde_json::to_string(&response)?);
            }
        }
    }

    Ok(())
}
