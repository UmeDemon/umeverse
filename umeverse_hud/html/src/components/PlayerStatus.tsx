import { Heart, Shield, Zap, Droplet, Activity } from "lucide-react";
import { useState } from "react";
import { useNuiEvent } from "../hooks/useNuiEvent";

interface StatusCircleProps {
  icon: React.ReactNode;
  value: number;
  max: number;
  color: string;
}

function StatusCircle({ icon, value, max, color }: StatusCircleProps) {
  const percentage = value / max;
  const size = 70;
  const radius = size / 2 - 5;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - percentage * circumference;

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="transform -rotate-90">
        {/* Background circle */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="rgba(255,255,255,0.1)"
          strokeWidth="4"
        />
        {/* Progress circle */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth="4"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          className="transition-all duration-300"
          strokeLinecap="round"
        />
      </svg>

      {/* Center content */}
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <div className="text-white drop-shadow-lg">{icon}</div>
        <div className="text-xs font-bold text-white mt-0.5">
          {Math.round(value)}
        </div>
      </div>
    </div>
  );
}

interface StatusData {
  health: number;
  armor: number;
  stamina: number;
  hunger: number;
  thirst: number;
}

export function PlayerStatus() {
  const [status, setStatus] = useState<StatusData>({
    health: 100,
    armor: 0,
    stamina: 100,
    hunger: 100,
    thirst: 100,
  });

  useNuiEvent<StatusData>("updateStatus", (data) => {
    setStatus((prev) => ({
      health: data.health ?? prev.health,
      armor: data.armor ?? prev.armor,
      stamina: data.stamina ?? prev.stamina,
      hunger: data.hunger ?? prev.hunger,
      thirst: data.thirst ?? prev.thirst,
    }));
  });

  return (
    <div className="space-y-3">
      <div className="bg-black/60 backdrop-blur-sm border border-white/20 rounded-lg p-3">
        <div className="flex gap-3 justify-center flex-wrap">
          <StatusCircle
            icon={<Heart className="w-5 h-5" />}
            value={status.health}
            max={100}
            color="#ef4444"
          />

          <StatusCircle
            icon={<Shield className="w-5 h-5" />}
            value={status.armor}
            max={100}
            color="#3b82f6"
          />

          <StatusCircle
            icon={<Activity className="w-5 h-5" />}
            value={status.stamina}
            max={100}
            color="#22c55e"
          />

          <StatusCircle
            icon={<Zap className="w-5 h-5" />}
            value={status.hunger}
            max={100}
            color="#f97316"
          />

          <StatusCircle
            icon={<Droplet className="w-5 h-5" />}
            value={status.thirst}
            max={100}
            color="#06b6d4"
          />
        </div>
      </div>
    </div>
  );
}
