import { Navigation } from "lucide-react";
import { useState } from "react";
import { useNuiEvent } from "../hooks/useNuiEvent";

interface MinimapData {
  heading: number;
  street: string;
  cross: string;
  zone: string;
  hidden?: boolean;
}

export function Minimap() {
  const [data, setData] = useState<MinimapData>({
    heading: 0,
    street: "",
    cross: "",
    zone: "",
    hidden: false,
  });

  useNuiEvent<MinimapData>("updateMinimap", (incoming) => {
    if (incoming.hidden) {
      setData((prev) => ({ ...prev, hidden: true }));
      return;
    }
    setData({
      heading: incoming.heading ?? 0,
      street: incoming.street ?? "",
      cross: incoming.cross ?? "",
      zone: incoming.zone ?? "",
      hidden: false,
    });
  });

  const streetLabel =
    data.street && data.cross
      ? `${data.street} / ${data.cross}`
      : data.street || "Unknown";

  if (data.hidden) return null;

  return (
    <div className="relative">
      {/* Street name display */}
      <div className="mb-2 text-white text-sm font-medium">
        <div className="bg-black/60 backdrop-blur-sm px-3 py-1 rounded truncate max-w-[200px]">
          {streetLabel}
        </div>
      </div>

      {/* Minimap container */}
      <div className="relative w-48 h-48 rounded-sm overflow-hidden border-2 border-white/20">
        {/* Map background - simulated with grid */}
        <div className="absolute inset-0 bg-gradient-to-br from-green-900/40 via-green-800/30 to-green-700/40">
          {/* Grid lines */}
          <svg className="w-full h-full opacity-30">
            <defs>
              <pattern
                id="grid"
                width="20"
                height="20"
                patternUnits="userSpaceOnUse"
              >
                <path
                  d="M 20 0 L 0 0 0 20"
                  fill="none"
                  stroke="white"
                  strokeWidth="0.5"
                />
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#grid)" />
          </svg>

          {/* Mock roads */}
          <div className="absolute top-1/2 left-0 right-0 h-2 bg-gray-700/60 transform -translate-y-1/2" />
          <div className="absolute left-1/2 top-0 bottom-0 w-2 bg-gray-700/60 transform -translate-x-1/2" />
        </div>

        {/* Player indicator (center) */}
        <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-10">
          <div
            className="transition-transform duration-100"
            style={{ transform: `rotate(${data.heading}deg)` }}
          >
            <Navigation className="w-6 h-6 text-blue-400 fill-blue-400" />
          </div>
        </div>

        {/* Compass directions */}
        <div className="absolute top-2 left-1/2 transform -translate-x-1/2 text-white text-xs font-bold">
          N
        </div>
      </div>

      {/* Zone name */}
      <div className="mt-2 text-white/80 text-xs text-center">
        {data.zone || "Los Santos"}
      </div>
    </div>
  );
}
