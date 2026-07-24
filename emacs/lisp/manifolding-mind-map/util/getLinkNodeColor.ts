import { ColoringSettings, VisualsSettings } from '../components/config'
import { LinksByNodeId } from '../pages'
import { getNodeColorById } from './getNodeColorById'

export const getLinkNodeColor = ({
  sourceId,
  targetId,
  linksByNodeId,
  visuals,
  coloring,
  cluster,
}: {
  sourceId: string
  targetId: string
  linksByNodeId: LinksByNodeId
  visuals: VisualsSettings
  coloring: ColoringSettings
  cluster: any
}) => {
  return linksByNodeId[sourceId]!.length > linksByNodeId[targetId]!.length
    ? getNodeColorById({ id: sourceId, linksByNodeId, visuals, cluster, coloring })
    : getNodeColorById({ id: targetId, visuals, linksByNodeId, cluster, coloring })
}
