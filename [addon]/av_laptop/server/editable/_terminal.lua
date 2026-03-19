allCommands = {
    ['atm-crack'] = { -- command used, should be unique and also a string
        allowed = function(playerId, laptopSerial)
            return true
        end,
        canProcess = function(playerId, laptopSerial, args)
            return true
        end,
        onSuccess = function(playerId, laptopSerial, args)

        end,
        actions = {
            {type = "text", input = "Initializing ATM bypass...", delay = 500},
            {type = "progressbar", input = "Sniffing Card Reader", delay = 5000},
            {type = "text", input = "Vulnerability found in firmware v4.2", style = "output", delay = 800},
            {type = "progressbar", input = "Infecting dispense-buffer", delay = 5000},
            {type = "minigame", input = "sniffer", label = "ATM_FIRMWARE_FILTER"}
        },
        output = {
            message = ">>> ATM CRACKED: ENCRYPTION BYPASSED. YOU CAN NOW INSTALL THE SKIMMER.",
            color = "teal"
        }
    },
    ['jailbreak'] = { -- command used, should be unique and also a string
        allowed = function(playerId, laptopSerial)
            return true
        end,
        canProcess = function(playerId, laptopSerial, args)
            return true
        end,
        onSuccess = function(playerId, laptopSerial, args)

        end,
        actions = {
            {type = "text", input = "Accessing local kernel bootloader...", delay = 600},
            {type = "progressbar", input = "Corrupting security signed-boot", delay = 4000},
            {type = "text", input = "Warning: Integrity check bypassed. System unstable.", style = "error", delay = 1000},
            {type = "progressbar", input = "Mounting read-write partition", delay = 3500},
            {type = "text", input = "Injecting unsigned binary signature...", delay = 500},
            {type = "minigame", input = "grid", label = "KERNEL_VULN_MAPPER"}
        },
        output = {
            message = ">>> SYSTEM JAILBROKEN: RESTRICTIONS REMOVED. THIRD-PARTY APPS ENABLED.",
            color = "teal"
        }
    },
    ['wifi-crack'] = { -- command used, should be unique and also a string
        allowed = function(playerId, laptopSerial)
            return true
        end,
        canProcess = function(playerId, laptopSerial, args)
            if not args or string.len(args) <= 1 then
                return false
            end
            return true
        end,
        onSuccess = function(playerId, laptopSerial, args)

        end,
        onError = function(playerId, laptopSerial, args)
            return {
                message = "ERROR: SSID_SPEC_REQUIRED. USE: wifi-crack [target_ssid]"
            }
        end,
        actions = {
            {type = "text", input = "Scanning wireless spectrum...", delay = 800},
            {type = "progressbar", input = "Capturing WPA3 Handshake", delay = 6000},
            {type = "text", input = "Beacon frames captured. Starting deauthentication attack...", style = "output", delay = 1000},
            {type = "progressbar", input = "Injecting malicious packets", delay = 4500},
            {type = "text", input = "Handshake data buffer full. Ready for manual bypass.", delay = 500},
            {type = "minigame", input = "hacking", label = "WIFI_PROTOCOL_BREACH"}
        },
        output = {
            message = ">>> NETWORK COMPROMISED: WPA3 KEY DECRYPTED. CONNECTION ESTABLISHED.",
            color = "teal"
        }
    },
    ['cam-crack'] = { -- command used, should be unique and also a string
        allowed = function(playerId, laptopSerial)
            return true
        end,
        canProcess = function(playerId, laptopSerial, args)
            if not args or string.len(args) <= 1 then
                return false
            end
            return true
        end,
        onSuccess = function(playerId, laptopSerial, args)

        end,
        onError = function(playerId, laptopSerial, args)
            return {
                message = "ERROR: CAMERA_ID_REQUIRED. USAGE: cam-crack [id]"
            }
        end,
        actions = {
            {type = "text", input = "Establishing remote uplink to CCTV network...", delay = 500},
            {type = "progressbar", input = "Scanning for open RTSP ports", delay = 4000},
            {type = "text", input = "Port 554 active. Intercepting encrypted stream...", style = "output", delay = 800},
            {type = "progressbar", input = "Bypassing admin authentication", delay = 6000},
            {type = "text", input = "Credential handshake detected. Initiating bruteforce...", delay = 500},
            {type = "minigame", input = "cracker", label = "CCTV_AUTH_BYPASS"}
        },
        output = {
            message = ">>> CAMERA FEED ACCESSED. ENCRYPTION OVERRIDDEN. REMOTE MONITORING ENABLED.",
            color = "teal"
        }
    },
}