module KubernetesApiModel exposing (KubernetesResultMetadata, KubernetesPodResult, KubernetesPodItem, KubernetesPodSpec, KubernetesPodMetadata, KubernetesLabels, KubernetesPodStatus, KubernetesPodCondition, KubernetesPodUpdate, KubernetesContainerItem)

type alias KubernetesResultMetadata = {
    resourceVersion: String
}

type alias KubernetesPodUpdate = {
    updateType: String,
    object: KubernetesPodItem
}

type alias KubernetesPodResult = {
    metadata: KubernetesResultMetadata,
    items: List KubernetesPodItem
}

type alias KubernetesPodSpec = {
    containers: List KubernetesContainerItem,
    nodeName: String
}

type alias KubernetesPodItem = {
  metadata: KubernetesPodMetadata,
  status: KubernetesPodStatus,
  spec: KubernetesPodSpec
}

type alias KubernetesPodMetadata = {
  name: String,
  uid: String,
  labels: KubernetesLabels,
  deletionTimestamp: Maybe String
}

type alias KubernetesLabels = {
  app: String
}

type alias KubernetesPodStatus = {
  phase: String,
  conditions: Maybe (List KubernetesPodCondition),
  hostIP: Maybe String,
  podIP: Maybe String
}

type alias KubernetesPodCondition = {
  conditionType: String,
  status: String
}

type alias KubernetesContainerItem = {
    name: String,
    image: String
}

