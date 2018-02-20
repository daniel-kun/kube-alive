module KubernetesApiModel exposing (KubernetesResultMetadata, KubernetesPodResult, KubernetesPodItem, KubernetesPodMetadata, KubernetesLabels, KubernetesPodStatus, KubernetesPodCondition, KubernetesPodUpdate)

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

type alias KubernetesPodItem = {
  metadata: KubernetesPodMetadata,
  status: KubernetesPodStatus
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

