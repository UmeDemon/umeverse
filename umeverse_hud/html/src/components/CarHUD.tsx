import { useState } from "react";
import { Fuel } from "lucide-react";
import { useNuiEvent } from "../hooks/useNuiEvent";

const MPH_FACTOR = 2.23694;
const KMH_FACTOR = 3.6;
const MAX_RPM = 8000;

interface VehicleData {
  show: boolean;
  speed: number; // m/s from native
  rpm: number; // 0-1 from native
  gear: number; // 0=R, 1-7
  fuel: number; // 0-100
}

interface CarHUDProps {
  speed: number;
  rpm: number;
  gear: number;
  fuel: number;
  speedUnit: "mph" | "kmh";
}

function Speedometer({ value, unit }: { value: number; unit: "mph" | "kmh" }) {
  const size = 180;
  const centerX = size / 2;
  const centerY = size / 2;
  const radius = size / 2 - 20;

  const minAngle = -225;
  const maxAngle = 45;
  const maxSpeed = 240;

  const percentage = Math.min(value / maxSpeed, 1);
  const needleAngle = minAngle + (maxAngle - minAngle) * percentage;

  const ticks = [];
  const numbers = [0, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200, 220, 240];

  for (let i = 0; i <= 240; i += 10) {
    const angle = minAngle + ((maxAngle - minAngle) * i) / maxSpeed;
    const isMajor = i % 20 === 0;
    const tickLength = isMajor ? 12 : 6;
    const tickWidth = isMajor ? 2 : 1;

    const startRadius = radius - tickLength;
    const startX =
      centerX + startRadius * Math.cos((angle * Math.PI) / 180);
    const startY =
      centerY + startRadius * Math.sin((angle * Math.PI) / 180);
    const endX = centerX + radius * Math.cos((angle * Math.PI) / 180);
    const endY = centerY + radius * Math.sin((angle * Math.PI) / 180);

    ticks.push(
      <line
        key={`tick-${i}`}
        x1={startX}
        y1={startY}
        x2={endX}
        y2={endY}
        stroke="white"
        strokeWidth={tickWidth}
        opacity={0.8}
      />,
    );
  }

  const numberElements = numbers.map((num) => {
    const angle = minAngle + ((maxAngle - minAngle) * num) / maxSpeed;
    const numRadius = radius - 25;
    const x = centerX + numRadius * Math.cos((angle * Math.PI) / 180);
    const y = centerY + numRadius * Math.sin((angle * Math.PI) / 180);

    return (
      <text
        key={`num-${num}`}
        x={x}
        y={y}
        fill="white"
        fontSize="10"
        fontWeight="bold"
        textAnchor="middle"
        dominantBaseline="middle"
        opacity={0.9}
      >
        {num}
      </text>
    );
  });

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <div className="absolute inset-0 bg-gradient-to-br from-gray-900 to-black rounded-full border-4 border-gray-700 shadow-2xl" />

      <svg width={size} height={size} className="relative">
        <defs>
          <linearGradient
            id="speedGradient"
            x1="0%"
            y1="0%"
            x2="100%"
            y2="0%"
          >
            <stop offset="0%" stopColor="#22c55e" />
            <stop offset="70%" stopColor="#eab308" />
            <stop offset="100%" stopColor="#ef4444" />
          </linearGradient>
        </defs>

        {ticks}
        {numberElements}

        <foreignObject x={centerX - 30} y={centerY + 15} width="60" height="30">
          <div className="text-center">
            <div className="text-2xl font-bold text-white drop-shadow-lg">
              {Math.round(value)}
            </div>
            <div className="text-[8px] text-white/60">{unit === "kmh" ? "KM/H" : "MPH"}</div>
          </div>
        </foreignObject>

        <line
          x1={centerX}
          y1={centerY}
          x2={
            centerX +
            (radius - 20) * Math.cos((needleAngle * Math.PI) / 180)
          }
          y2={
            centerY +
            (radius - 20) * Math.sin((needleAngle * Math.PI) / 180)
          }
          stroke="#ef4444"
          strokeWidth="3"
          strokeLinecap="round"
          className="transition-all duration-300 drop-shadow-lg"
        />

        <circle
          cx={centerX}
          cy={centerY}
          r="8"
          fill="#1f2937"
          stroke="white"
          strokeWidth="2"
        />
        <circle cx={centerX} cy={centerY} r="4" fill="#ef4444" />
      </svg>

      <div className="absolute bottom-3 left-0 right-0 text-center text-[10px] text-white/50 font-semibold">
        SPEED
      </div>
    </div>
  );
}

function RPMGauge({ value }: { value: number }) {
  const size = 180;
  const centerX = size / 2;
  const centerY = size / 2;
  const radius = size / 2 - 20;

  const minAngle = -225;
  const maxAngle = 45;
  const maxRPM = 8000;
  const redlineRPM = 6500;

  const percentage = Math.min(value / maxRPM, 1);
  const needleAngle = minAngle + (maxAngle - minAngle) * percentage;

  const ticks = [];
  const numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8];

  for (let i = 0; i <= 8; i += 0.5) {
    const rpmValue = i * 1000;
    const angle = minAngle + ((maxAngle - minAngle) * rpmValue) / maxRPM;
    const isMajor = i % 1 === 0;
    const tickLength = isMajor ? 12 : 6;
    const tickWidth = isMajor ? 2 : 1;
    const isRedZone = rpmValue >= redlineRPM;

    const startRadius = radius - tickLength;
    const startX =
      centerX + startRadius * Math.cos((angle * Math.PI) / 180);
    const startY =
      centerY + startRadius * Math.sin((angle * Math.PI) / 180);
    const endX = centerX + radius * Math.cos((angle * Math.PI) / 180);
    const endY = centerY + radius * Math.sin((angle * Math.PI) / 180);

    ticks.push(
      <line
        key={`tick-${i}`}
        x1={startX}
        y1={startY}
        x2={endX}
        y2={endY}
        stroke={isRedZone ? "#ef4444" : "white"}
        strokeWidth={tickWidth}
        opacity={0.8}
      />,
    );
  }

  const numberElements = numbers.map((num) => {
    const rpmValue = num * 1000;
    const angle = minAngle + ((maxAngle - minAngle) * rpmValue) / maxRPM;
    const numRadius = radius - 25;
    const x = centerX + numRadius * Math.cos((angle * Math.PI) / 180);
    const y = centerY + numRadius * Math.sin((angle * Math.PI) / 180);
    const isRedZone = rpmValue >= redlineRPM;

    return (
      <text
        key={`num-${num}`}
        x={x}
        y={y}
        fill={isRedZone ? "#ef4444" : "white"}
        fontSize="11"
        fontWeight="bold"
        textAnchor="middle"
        dominantBaseline="middle"
        opacity={0.9}
      >
        {num}
      </text>
    );
  });

  const redlineAngle =
    minAngle + ((maxAngle - minAngle) * redlineRPM) / maxRPM;
  const redZoneRadius = radius + 2;

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <div className="absolute inset-0 bg-gradient-to-br from-gray-900 to-black rounded-full border-4 border-gray-700 shadow-2xl" />

      <svg width={size} height={size} className="relative">
        <path
          d={`M ${centerX + redZoneRadius * Math.cos((redlineAngle * Math.PI) / 180)} ${centerY + redZoneRadius * Math.sin((redlineAngle * Math.PI) / 180)} A ${redZoneRadius} ${redZoneRadius} 0 0 1 ${centerX + redZoneRadius * Math.cos((maxAngle * Math.PI) / 180)} ${centerY + redZoneRadius * Math.sin((maxAngle * Math.PI) / 180)}`}
          fill="none"
          stroke="#ef4444"
          strokeWidth="6"
          opacity={0.3}
        />

        {ticks}
        {numberElements}

        <foreignObject x={centerX - 30} y={centerY + 15} width="60" height="30">
          <div className="text-center">
            <div className="text-2xl font-bold text-white drop-shadow-lg">
              {Math.round(value / 100) / 10}
            </div>
            <div className="text-[8px] text-white/60">x1000</div>
          </div>
        </foreignObject>

        <line
          x1={centerX}
          y1={centerY}
          x2={
            centerX +
            (radius - 20) * Math.cos((needleAngle * Math.PI) / 180)
          }
          y2={
            centerY +
            (radius - 20) * Math.sin((needleAngle * Math.PI) / 180)
          }
          stroke={value >= redlineRPM ? "#ef4444" : "#3b82f6"}
          strokeWidth="3"
          strokeLinecap="round"
          className="transition-all duration-300 drop-shadow-lg"
        />

        <circle
          cx={centerX}
          cy={centerY}
          r="8"
          fill="#1f2937"
          stroke="white"
          strokeWidth="2"
        />
        <circle
          cx={centerX}
          cy={centerY}
          r="4"
          fill={value >= redlineRPM ? "#ef4444" : "#3b82f6"}
        />
      </svg>

      <div className="absolute bottom-3 left-0 right-0 text-center text-[10px] text-white/50 font-semibold">
        RPM
      </div>
    </div>
  );
}

function CarHUD({ speed, rpm, gear, fuel, speedUnit }: CarHUDProps) {
  return (
    <div className="flex items-end gap-4">
      <Speedometer value={speed} unit={speedUnit} />

      <div className="flex flex-col gap-2 mb-4">
        <div className="bg-black/60 backdrop-blur-sm border border-white/20 rounded-lg px-6 py-3 text-center">
          <div className="text-xs text-white/60 mb-1">GEAR</div>
          <div className="text-4xl font-bold text-white">
            {gear === 0 ? "N" : gear === -1 ? "R" : gear}
          </div>
        </div>

        <div className="bg-black/60 backdrop-blur-sm border border-white/20 rounded-lg px-4 py-2">
          <div className="flex items-center gap-2 text-white">
            <Fuel className="w-4 h-4" />
            <div className="flex-1">
              <div className="flex items-center justify-between mb-1">
                <span className="text-xs">FUEL</span>
                <span className="text-xs font-bold">{Math.round(fuel)}%</span>
              </div>
              <div className="w-24 h-2 bg-white/20 rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-yellow-500 to-yellow-400 transition-all duration-300"
                  style={{ width: `${fuel}%` }}
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <RPMGauge value={rpm} />
    </div>
  );
}

export function CarHUDContainer({ speedUnit }: { speedUnit: "mph" | "kmh" }) {
  const [visible, setVisible] = useState(false);
  const [speed, setSpeed] = useState(0);
  const [rpm, setRpm] = useState(0);
  const [gear, setGear] = useState(1);
  const [fuel, setFuel] = useState(100);

  useNuiEvent<VehicleData>("updateVehicle", (data) => {
    setVisible(data.show);
    if (!data.show) return;

    // Convert m/s using the selected speed unit
    const factor = speedUnit === "kmh" ? KMH_FACTOR : MPH_FACTOR;
    setSpeed(data.speed * factor);
    // Convert 0-1 → 0-8000
    setRpm(data.rpm * MAX_RPM);
    // Lua: 0 = reverse, 1-7 = drive.  Component: -1 = R, 0 = N
    setGear(data.gear === 0 ? -1 : data.gear);
    setFuel(data.fuel);
  });

  if (!visible) return null;

  return <CarHUD speed={speed} rpm={rpm} gear={gear} fuel={fuel} speedUnit={speedUnit} />;
}
