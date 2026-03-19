import { useEffect, useRef } from "react";

/**
 * Subscribe to NUI messages (window.postMessage from Lua SendNUIMessage).
 * Calls `handler` whenever a message with the matching `action` arrives.
 */
export function useNuiEvent<T = unknown>(
  action: string,
  handler: (data: T) => void,
) {
  const savedHandler = useRef(handler);
  savedHandler.current = handler;

  useEffect(() => {
    function onMessage(event: MessageEvent) {
      const { action: incomingAction, ...rest } = event.data;
      if (incomingAction === action) {
        savedHandler.current(rest as T);
      }
    }
    window.addEventListener("message", onMessage);
    return () => window.removeEventListener("message", onMessage);
  }, [action]);
}
