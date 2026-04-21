use serde::{Deserialize, Serialize};

#[cfg(windows)]
use windows_sys::Win32::{
    UI::WindowsAndMessaging::{GetForegroundWindow, GetWindowThreadProcessId},
    System::Threading::{OpenProcess, PROCESS_QUERY_INFORMATION, PROCESS_VM_READ},
    System::ProcessStatus::GetModuleFileNameExW,
    Foundation::CloseHandle,
};

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum UserActivityCategory {
    Work,
    SocialMedia,
    Entertainment,
    Idle,
    Unknown,
}

pub struct ProxyKernel;

impl ProxyKernel {
    pub fn get_active_window_category() -> UserActivityCategory {
        #[cfg(windows)]
        {
            unsafe {
                let hwnd = GetForegroundWindow();
                if hwnd == 0 {
                    return UserActivityCategory::Idle;
                }

                let mut pid: u32 = 0;
                GetWindowThreadProcessId(hwnd, &mut pid);
                if pid == 0 {
                    return UserActivityCategory::Unknown;
                }

                let handle = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, 0, pid);
                if handle == 0 {
                    return UserActivityCategory::Unknown;
                }

                let mut buf = [0u16; 512];
                let len = GetModuleFileNameExW(handle, 0, buf.as_mut_ptr(), 512);
                CloseHandle(handle);

                if len == 0 {
                    return UserActivityCategory::Unknown;
                }

                let path = String::from_utf16_lossy(&buf[..len as usize]);
                Self::categorize(&path)
            }
        }

        #[cfg(not(windows))]
        UserActivityCategory::Unknown
    }

    fn categorize(path: &str) -> UserActivityCategory {
        let p = path.to_lowercase();
        if p.contains("code.exe") || p.contains("texstudio") || p.contains("pycharm") {
            UserActivityCategory::Work
        } else if p.contains("discord.exe") || p.contains("twitter") {
            UserActivityCategory::SocialMedia
        } else if p.contains("vlc.exe") || p.contains("spotify.exe") || p.contains("steam.exe") {
            UserActivityCategory::Entertainment
        } else {
            UserActivityCategory::Unknown
        }
    }
}
