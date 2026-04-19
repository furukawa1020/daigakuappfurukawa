use windows_sys::Win32::UI::WindowsAndMessaging::{GetForegroundWindow, GetWindowThreadProcessId};
use windows_sys::Win32::System::Threading::{OpenProcess, PROCESS_QUERY_INFORMATION, PROCESS_VM_READ};
use windows_sys::Win32::System::ProcessStatus::GetModuleFileNameExW;
use windows_sys::Win32::Foundation::{CloseHandle};

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

            // Open process to query information
            let handle = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, 0, pid);
            if handle == 0 {
                return UserActivityCategory::Unknown;
            }

            let mut buffer = [0u16; 512];
            let length = GetModuleFileNameExW(handle, 0, buffer.as_mut_ptr(), 512);
            CloseHandle(handle);

            if length == 0 {
                return UserActivityCategory::Unknown;
            }

            let path = String::from_utf16_lossy(&buffer[..length as usize]);
            Self::categorize_path(&path)
        }

        #[cfg(not(windows))]
        {
            UserActivityCategory::Unknown
        }
    }

    fn categorize_path(path: &str) -> UserActivityCategory {
        let p = path.to_lowercase();
        // Categorize by executable name / path
        if p.contains("code.exe") || p.contains("texstudio.exe") || p.contains("cargo.exe") || p.contains("rust") {
            UserActivityCategory::Work
        } else if p.contains("chrome.exe") || p.contains("msedge.exe") || p.contains("firefox.exe") {
            // Browsers are tricky; in a "Proper" implementation we might inspect tabs, 
            // but for now we'll mark them as unknown/neutral unless we have further data.
            UserActivityCategory::Unknown
        } else if p.contains("discord.exe") || p.contains("twitter") || p.contains("x.exe") {
            UserActivityCategory::SocialMedia
        } else if p.contains("vlc.exe") || p.contains("spotify.exe") || p.contains("steam.exe") {
            UserActivityCategory::Entertainment
        } else {
            UserActivityCategory::Unknown
        }
    }
}
