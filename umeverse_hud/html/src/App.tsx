import { useState } from "react";
import { PlayerStatus } from "./components/PlayerStatus";
import { Minimap } from "./components/Minimap";
import { CarHUDContainer } from "./components/CarHUD";
import { Settings, type HudSettings } from "./components/Settings";
import { useNuiEvent } from "./hooks/useNuiEvent";

const defaultSettings: HudSettings = {
  showHealth: true,
  showArmor: true,
  showHunger: true,
  showThirst: true,
  showVehicle: true,
  showMinimap: true,
  speedUnit: "mph",
};

export default function App() {
  const [visible, setVisible] = useState(true);
  const [settings, setSettings] = useState<HudSettings>(defaultSettings);

  // Restore saved settings on player load
  useNuiEvent<{ settings?: HudSettings }>("init", (data) => {
    if (data.settings) {
      setSettings((prev) => ({ ...prev, ...data.settings }));
    }
  });

  // External toggle from other resources
  useNuiEvent<{ visible: boolean }>("toggleHud", (data) => {
    setVisible(data.visible);
  });

  if (!visible) return null;

  const showStatus =
    settings.showHealth ||
    settings.showArmor ||
    settings.showHunger ||
    settings.showThirst;

  return (
    <>
      {/* Status circles — bottom left, above minimap */}
      {showStatus && (
        <div className="fixed bottom-[270px] left-6 z-10">
          <PlayerStatus />
        </div>
      )}

      {/* Minimap — bottom left */}
      {settings.showMinimap && (
        <div className="fixed bottom-6 left-6 z-10">
          <Minimap />
        </div>
      )}

      {/* Vehicle cluster — bottom center */}
      {settings.showVehicle && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-10">
          <CarHUDContainer speedUnit={settings.speedUnit} />
        </div>
      )}

      {/* Settings modal */}
      <Settings settings={settings} onSettingsChange={setSettings} />
    </>
  );
}
