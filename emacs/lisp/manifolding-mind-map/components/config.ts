import { Easing } from '@tweenjs/tween.js'
const options: string[] = []
const algorithms: { [name: string]: (percent: number) => number } = {}
for (let type in Easing) {
  for (let mode in (Easing as any)[type]) {
    let name = type + mode
    if (name === 'LinearNone') {
      name = 'Linear'
    }
    options.push(name)
    algorithms[name] = (Easing as any)[type][mode]
  }
}

export const algos = algorithms

export type PhysicsSettings = {
  enabled: boolean
  charge: number
  collision: boolean
  collisionStrength: number
  centering: boolean
  centeringStrength: number
  linkStrength: number
  linkIts: number
  alphaDecay: number
  alphaTarget: number
  alphaMin: number
  velocityDecay: number
  gravity: number
  gravityOn: boolean
  gravityLocal: boolean
}

export type FilterSettings = {
  orphans: boolean
  dailies: boolean
  parent: string
  filelessCites: boolean
  tagsBlacklist: string[]
  tagsWhitelist: string[]
  dirsBlocklist: string[]
  dirsAllowlist: string[]
  bad: boolean
  nodes: string[]
  links: string[]
  date: string[]
  noter: boolean
  textFilter: string
}

export type VisualsSettings = {
  particles: boolean
  particlesNumber: number
  particlesWidth: number
  arrows: boolean
  arrowsLength: number
  arrowsPos: number
  arrowsColor: string
  linkOpacity: number
  linkWidth: number
  nodeRel: number
  nodeOpacity: number
  nodeResolution: number
  labels: number
  labelScale: number
  labelFontSize: number
  labelLength: number
  labelWordWrap: number
  labelLineSpace: number
  labelDynamicDegree: number
  labelDynamicStrength: number
  highlight: boolean
  highlightNodeSize: number
  highlightLinkSize: number
  highlightFade: number
  highlightAnim: boolean
  animationSpeed: number
  algorithmName: string
  linkColorScheme: string
  nodeColorScheme: string[]
  nodeHighlight: string
  linkHighlight: string
  backgroundColor: string
  emacsNodeColor: string
  labelTextColor: string
  labelBackgroundColor: string
  labelBackgroundOpacity: number
  citeDashes: boolean
  citeDashLength: number
  citeGapLength: number
  citeLinkColor: string
  citeLinkHighlightColor: string
  citeNodeColor: string
  refDashes: boolean
  refDashLength: number
  refGapLength: number
  refLinkColor: string
  refLinkHighlightColor: string
  refNodeColor: string
  nodeSizeLinks: number
  nodeZoomSize: number
}

export type ColoringSettings = {
  method: string
}

export type BehaviorSettings = {
  follow: string
  localSame: string
  zoomPadding: number
  zoomSpeed: number
}

export type MouseSettings = {
  highlight: string
  local: string
  follow: string
  context: string
  preview: string
  backgroundExitsLocal: boolean
}

export type LocalSettings = {
  neighbors: number
}

export interface TagColors {
  [tag: string]: string
}

export const colorList = [
  'red', 'orange', 'yellow', 'green', 'cyan', 'blue', 'violet', 'magenta',
  'base0', 'base1', 'base2', 'base3', 'base4', 'base5', 'base6', 'base7', 'base8',
]
