# DaigakuOS v2.0: Sovereignty Edition 🐾🛡️

> **"The compiled manifestation of biological sovereignty and behavioral discipline."**

DaigakuOS has evolved from a simple hobbyist app into a high-performance, cryptographically-hardened **Native Bio-Kernel**. This project represents the extreme union of biological simulation, memory-safe system programming, and cognitive behavioral enforcement.

---

## 🏛️ Architecture: The Sovereign Core

DaigakuOS v2.0 transitions the simulation's "Source of Truth" from Ruby to a specialized **Rust Kernel**. 

- **Simulation Sovereignty**: All critical logic—spatial ecological diffusion, deterministic combat, and genetic recombination—is executed natively in Rust for absolute performance and memory safety.
- **The Sovereign Vault**: World states are no longer stored in plain JSON. Every vital is protected by **AES-256-GCM authenticated encryption** and **SHA-256 HMAC integrity signatures**.
- **The Enforcement Sentinel**: A Win32-native interaction proxy that monitors system behavior at the PID level. It correlates real-world activity with biological stress to enforce discipline via `LockWorkStation`.

---

## 🧬 Key Features

### 1. High-Fidelity Bio-Simulation (Rust)
- **Spatial Grid Ecology**: 64x64 grid-based modeling of oxygen, toxification, and rot diffusion.
- **Genetic Lineage Engine**: Native DNA recombination and epigenetic transfer across generations.
- **Deterministic Combat**: Precision damage resolution factoring in organ stress and hormonal surges.

### 2. Native Security & Integrity (Vault)
- **Zero-Tamper State**: If the world state is manually edited, the kernel detects the signature mismatch and initiates a security lockdown.
- **Hardware-Bound Integrity**: (Planned) State signing tied to Windows Machine GUID.

### 3. Gachi-Gachi Enforcement (Proxy/Tutor)
- **Deep Process Inspection**: Monitors foreground executables by path validation (not just window titles).
- **Cognitive Tutoring**: Real-time diagnostic advice based on the interaction between user focus and the monster's neural stress.
- **Sovereign Execution**: Native authority to lock the workstation or terminate distracting processes.

---

## 🛠️ Quick Start (Developer Setup)

DaigakuOS v2.0 requires a **Rust** and **Ruby** environment.

### 1. Build & Bootstrap
This script will compile the Rust core into optimized release bytecode and perform the initial cryptographic 'sealing' of your simulation state.

```powershell
ruby bin/setup.rb
```

### 2. Launch the Engine
Run the Native Engine CLI to communicate with the kernel via JSON-RPC.

```powershell
ruby bin/run.rb
```

### 3. Run Self-Diagnostics
Verify the integrity of the Native Bridge and the Simulation Vault.

```powershell
ruby test_bio_engine.rb
```

---

## 🏗️ Project Structure

```text
daigakuos-v2/
├── bin/                       # Standardized Entry Points (Setup, Run)
├── rust_core/                 # 🦀 Sovereign Bio-Kernel (The Source of Truth)
│   ├── src/
│   │   ├── ecology.rs         # Spatial Diffusion Grid
│   │   ├── security.rs        # AES-GCM/HMAC Vault
│   │   ├── proxy.rs           # Win32 Process Monitoring
│   │   └── tutor.rs           # Diagnostic Feedback
├── ruby_native/               # 💎 Orchestration & Storage Layer
│   ├── core/
│   │   └── rust_bridge.rb     # Native Payload Bridge
│   └── moko_engine.rb         # Main Engine Loop
└── test_bio_engine.rb         # Modern Diagnostic Suite
```

---

## ⚖️ License & Philosophy

DaigakuOS is a platform for **continuous evolution**. It assumes a Gachi-Gachi (Strict) philosophy—if the system detects a breach of discipline or a threat to biological integrity, it will take sovereign action to restore order.

**"Life is deterministic. Code is absolute. Sovereignty is maintained."** 🐾⚓

---
*Version: 2.0.0 (Sovereignty Edition)*  
*Core Engineer: furukawa*
