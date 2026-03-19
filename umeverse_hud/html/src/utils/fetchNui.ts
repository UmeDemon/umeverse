/**
 * Post a NUI callback to the Lua client via fetch.
 * Matches the FiveM RegisterNUICallback pattern.
 */
export async function fetchNui<T = unknown>(
  eventName: string,
  data: Record<string, unknown> = {},
): Promise<T> {
  const resourceName =
    (window as unknown as { GetParentResourceName?: () => string })
      .GetParentResourceName?.() ?? "nui-frame-app";

  const resp = await fetch(`https://${resourceName}/${eventName}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  const text = await resp.text();
  try {
    return JSON.parse(text) as T;
  } catch {
    return text as unknown as T;
  }
}
