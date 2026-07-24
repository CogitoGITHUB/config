import { ColoringSettings, VisualsSettings } from '../components/config'
import { LinksByNodeId } from '../pages'
import { getLinkNodeColor } from './getLinkNodeColor'
import { getThemeColor } from './getThemeColor'

export const getLinkColor = ({
  sourceId,
  targetId,
  needsHighlighting,
  theme,
  visuals,
  highlightColors,
  opacity,
  linksByNodeId,
  coloring,
  cluster,
}: {
  sourceId: string
  targetId: string
  needsHighlighting: boolean
  theme: any
  visuals: VisualsSettings
  highlightColors: Record<string, any>
  opacity: number
  linksByNodeId: LinksByNodeId
  coloring: ColoringSettings
  cluster: any
}) => {
  if (!highlightColors[visuals.linkColorScheme]) {
    const c = getThemeColor(
      needsHighlighting ? visuals.linkHighlight || 'red' : visuals.linkColorScheme || 'red',
      theme,
    )
    return typeof c === 'string' ? c : '#cc0000'
  }

  if (!visuals.linkHighlight && !visuals.linkColorScheme && !needsHighlighting) {
    const nodeColor = getLinkNodeColor({
      sourceId,
      targetId,
      linksByNodeId,
      visuals,
      coloring,
      cluster,
    })
    return getThemeColor(nodeColor, theme)
  }

  if (!needsHighlighting && !visuals.linkColorScheme) {
    const nodeColor = getLinkNodeColor({
      sourceId,
      targetId,
      linksByNodeId,
      visuals,
      coloring,
      cluster,
    })
    return highlightColors[nodeColor][visuals.backgroundColor](visuals.highlightFade * opacity)
  }

  if (!needsHighlighting) {
    return highlightColors[visuals.linkColorScheme][visuals.backgroundColor](
      visuals.highlightFade * opacity,
    )
  }

  if (!visuals.linkHighlight && !visuals.linkColorScheme) {
    const nodeColor = getLinkNodeColor({
      sourceId,
      targetId,
      linksByNodeId,
      visuals,
      coloring,
      cluster,
    })
    return getThemeColor(nodeColor, theme)
  }

  if (!visuals.linkHighlight) {
    return getThemeColor(visuals.linkColorScheme, theme)
  }

  if (!visuals.linkColorScheme) {
    return highlightColors[
      getLinkNodeColor({ sourceId, targetId, linksByNodeId, visuals, coloring, cluster })
    ][visuals.linkHighlight](opacity)
  }

  return highlightColors[visuals.linkColorScheme][visuals.linkHighlight](opacity)
}
