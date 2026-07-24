export const getThemeColor = (name: string, theme: any) => {
  if (!name || name.startsWith('#')) return name

  // Check palette sub-object first (holds Emacs theme palette keys)
  if (theme.colors.palette?.[name]) return theme.colors.palette[name]

  // Chakra-style resolution (e.g. "gray.500", "red.500")
  try {
    const result = name.split('.').reduce((o: any, i: string) => o[i], theme.colors)
    if (typeof result === 'string') return result
  } catch {
    // fall through
  }

  // Try palette as last resort (catches any missed palette keys)
  return name
}
