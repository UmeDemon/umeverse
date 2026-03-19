import { useState, useEffect } from "react";
import { X, Eye, EyeOff, RotateCcw } from "lucide-react";
import { fetchNui } from "../utils/fetchNui";
import { useNuiEvent } from "../hooks/useNuiEvent";

export interface HudSettings {
  showHealth: boolean;
  showArmor: boolean;
  showHunger: boolean;
  showThirst: boolean;
  showVehicle: boolean;
  showMinimap: boolean;
  speedUnit: "mph" | "kmh";
}

const defaultSettings: HudSettings = {
  showHealth: true,
  showArmor: true,
  showHunger: true,
  showThirst: true,
  showVehicle: true,
  showMinimap: true,
  speedUnit: "mph",
};

interface SettingsProps {
  settings: HudSettings;
  onSettingsChange: (settings: HudSettings) => void;
}

export function Settings({ settings, onSettingsChange }: SettingsProps) {
  const [open, setOpen] = useState(false);

  useNuiEvent("openSettings", () => setOpen(true));

  function close() {
    setOpen(false);
    fetchNui("closeSettings");
  }

  // Global Escape key listener — FiveM NUI won't capture Escape via React onKeyDown alone
  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape" && open) {
        close();
      }
    }
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open]);

  function toggle(key: keyof HudSettings) {
    const next = { ...settings, [key]: !settings[key] };
    onSettingsChange(next);
    fetchNui("saveSettings", { settings: next });
    if (key === "showMinimap") {
      fetchNui("setMinimap", { show: next.showMinimap });
    }
  }

  function setUnit(unit: "mph" | "kmh") {
    const next = { ...settings, speedUnit: unit };
    onSettingsChange(next);
    fetchNui("saveSettings", { settings: next });
  }

  function reset() {
    onSettingsChange({ ...defaultSettings });
    fetchNui("saveSettings", { settings: defaultSettings });
    fetchNui("setMinimap", { show: true });
  }

  if (!open) return null;

  const toggleItems: { key: keyof HudSettings; label: string }[] = [
    { key: "showHealth", label: "Health" },
    { key: "showArmor", label: "Armor" },
    { key: "showHunger", label: "Hunger" },
    { key: "showThirst", label: "Thirst" },
    { key: "showVehicle", label: "Vehicle Cluster" },
    { key: "showMinimap", label: "Minimap" },
  ];

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center"
    >
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/50" onClick={close} />

      {/* Panel */}
      <div className="relative bg-[rgba(10,10,28,0.95)] border border-white/10 rounded-2xl p-8 w-[420px] shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-bold text-white">HUD Settings</h2>
          <button
            onClick={close}
            className="text-white/40 hover:text-white transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Speed unit toggle */}
        <div className="mb-6">
          <label className="text-xs text-white/50 uppercase tracking-wider mb-2 block">
            Speed Unit
          </label>
          <div className="flex gap-2">
            <button
              onClick={() => setUnit("mph")}
              className={`flex-1 py-2 px-4 rounded-lg text-sm font-medium transition-colors ${
                settings.speedUnit === "mph"
                  ? "bg-blue-600/30 text-blue-400 border border-blue-500/40"
                  : "bg-white/5 text-white/40 border border-white/10 hover:text-white/60"
              }`}
            >
              MPH
            </button>
            <button
              onClick={() => setUnit("kmh")}
              className={`flex-1 py-2 px-4 rounded-lg text-sm font-medium transition-colors ${
                settings.speedUnit === "kmh"
                  ? "bg-blue-600/30 text-blue-400 border border-blue-500/40"
                  : "bg-white/5 text-white/40 border border-white/10 hover:text-white/60"
              }`}
            >
              KM/H
            </button>
          </div>
        </div>

        {/* Visibility toggles */}
        <div className="mb-6">
          <label className="text-xs text-white/50 uppercase tracking-wider mb-3 block">
            Visible Elements
          </label>
          <div className="space-y-2">
            {toggleItems.map(({ key, label }) => (
              <button
                key={key}
                onClick={() => toggle(key)}
                className="w-full flex items-center justify-between py-2 px-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
              >
                <span className="text-sm text-white/80">{label}</span>
                {settings[key] ? (
                  <Eye className="w-4 h-4 text-green-400" />
                ) : (
                  <EyeOff className="w-4 h-4 text-white/30" />
                )}
              </button>
            ))}
          </div>
        </div>

        {/* Reset */}
        <button
          onClick={reset}
          className="w-full flex items-center justify-center gap-2 py-2 px-4 rounded-lg bg-red-500/10 text-red-400 hover:bg-red-500/20 transition-colors text-sm font-medium"
        >
          <RotateCcw className="w-4 h-4" />
          Reset All
        </button>
      </div>
    </div>
  );
}
