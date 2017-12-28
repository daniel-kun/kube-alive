module KubernetesApiDecoder exposing (decodeKubernetesPodResult, decodeKubernetesPodUpdate)

import KubernetesApiModel exposing (KubernetesResultMetadata, KubernetesPodResult, KubernetesPodItem, KubernetesPodMetadata, KubernetesLabels, KubernetesPodStatus, KubernetesPodCondition, KubernetesPodUpdate)
import Json.Decode exposing (Decoder, string, list, field, maybe)

decodeKubernetesLabels : Decoder KubernetesLabels
decodeKubernetesLabels =
    (Json.Decode.map KubernetesLabels (field "app" string))

decodeKubernetesPodMetadata : Decoder KubernetesPodMetadata
decodeKubernetesPodMetadata = 
    (Json.Decode.map4 KubernetesPodMetadata (field "name" string) (field "uid" string) (field "labels" decodeKubernetesLabels) (maybe (field "deletionTimestamp" string)))

decodeKubernetesPodStatusCondition : Decoder KubernetesPodCondition 
decodeKubernetesPodStatusCondition =
    (Json.Decode.map2 KubernetesPodCondition (field "type" string) (field "status" string))

decodeKubernetesPodStatus : Decoder KubernetesPodStatus
decodeKubernetesPodStatus =
    (Json.Decode.map4 KubernetesPodStatus (field "phase" string) (maybe (field "conditions" (Json.Decode.list decodeKubernetesPodStatusCondition))) (maybe (field "hostIP" string)) (maybe (field "podIP" string)))

decodeKubernetesPodItem : Decoder KubernetesPodItem
decodeKubernetesPodItem =
    (Json.Decode.map2 KubernetesPodItem (field "metadata" decodeKubernetesPodMetadata) (field "status" decodeKubernetesPodStatus))

decodeKubernetesResultMetadata : Decoder KubernetesResultMetadata
decodeKubernetesResultMetadata =
    (Json.Decode.map KubernetesResultMetadata (field "resourceVersion" string))

decodeKubernetesPodResult : Decoder KubernetesPodResult
decodeKubernetesPodResult =
    (Json.Decode.map2 KubernetesPodResult (field "metadata" decodeKubernetesResultMetadata) (field "items" (Json.Decode.list decodeKubernetesPodItem)))

decodeKubernetesPodUpdate : Decoder KubernetesPodUpdate
decodeKubernetesPodUpdate = 
    (Json.Decode.map2 KubernetesPodUpdate (field "type" string) (field "object" decodeKubernetesPodItem))

