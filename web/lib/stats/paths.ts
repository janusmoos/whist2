export function gameTypeSlug(type: string): string {
  return encodeURIComponent(type);
}

export function decodeGameTypeSlug(slug: string): string {
  return decodeURIComponent(slug);
}

export function playerPath(id: string): string {
  return `/statistik/spillere/${encodeURIComponent(id)}`;
}

export function sessionPath(sessionIndex: number): string {
  return `/statistik/spilledage/${sessionIndex}`;
}

export function gamePath(gameId: string): string {
  return `/statistik/spil/${encodeURIComponent(gameId)}`;
}

export function gameTypePath(type: string): string {
  return `/statistik/spiltyper/${gameTypeSlug(type)}`;
}
