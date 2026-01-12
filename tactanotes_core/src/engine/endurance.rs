// Feature v5.3: Endurance Controller
// Governs system behavior based on Thermal/Battery state.

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum EnduranceMode {
    HighPerformance,   // Normal operation (Streaming ASR, Animations enabled)
    Endurance,         // Low Battery/High Heat (Batch ASR, Stealth UI)
}

pub struct EnduranceController {
    // Real state
    battery_temp_celsius: f32, // From Flutter/Android API
    cpu_temp_celsius: f32,     // From /sys/class/thermal
    
    // Mocks for testing (preserved)
    simulated_mode: bool,
    
    // State
    pub current_mode: EnduranceMode,
}

impl EnduranceController {
    pub fn new() -> Self {
        Self {
            current_mode: EnduranceMode::HighPerformance,
            battery_temp_celsius: 0.0,
            cpu_temp_celsius: 0.0,
            simulated_mode: false,
        }
    }

    pub fn update_battery_temp(&mut self, temp: f32) {
        self.battery_temp_celsius = temp;
    }

    fn read_cpu_temp(&mut self) {
        // Gap 5: Fallback 2 - Try reading system file (often blocked, but worth trying)
        if let Ok(content) = std::fs::read_to_string("/sys/class/thermal/thermal_zone0/temp") {
            if let Ok(temp_millis) = content.trim().parse::<f32>() {
                self.cpu_temp_celsius = temp_millis / 1000.0;
            }
        }
    }

    pub fn check_status(&mut self) -> EnduranceMode {
        if self.simulated_mode { return self.current_mode; }

        self.read_cpu_temp();
        
        // Gap 5: "Hybrid Vitals Fallback" logic
        // Rule: If CPU > 75C OR Battery > 42C -> Panic/Endurance
        
        let high_cpu = self.cpu_temp_celsius > 75.0;
        let high_battery = self.battery_temp_celsius > 42.0;

        if high_cpu || high_battery {
            if self.current_mode != EnduranceMode::Endurance {
                println!("Endurance: 🔥 HEAT WARNING (CPU: {}C, BAT: {}C). Engaging throttle.", 
                    self.cpu_temp_celsius, self.battery_temp_celsius);
            }
            self.current_mode = EnduranceMode::Endurance;
        } else {
            // Hysteresis: cooldown to 65 / 38
             if self.current_mode == EnduranceMode::Endurance {
                 if self.cpu_temp_celsius < 65.0 && self.battery_temp_celsius < 38.0 {
                     println!("Endurance: ❄️ System cooled. Resuming High Performance.");
                     self.current_mode = EnduranceMode::HighPerformance;
                 }
             } else {
                 self.current_mode = EnduranceMode::HighPerformance;
             }
        }
        
        self.current_mode
    }
    
    pub fn simulate_environment(&mut self, _battery: f32, temp: f32) {
        self.battery_temp_celsius = temp; // Map sim temp to battery for test
        self.simulated_mode = true;
    }
}
