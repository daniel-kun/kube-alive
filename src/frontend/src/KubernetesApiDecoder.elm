module KubernetesApiDecoder exposing (decodeKubernetesPodResult, decodeKubernetesPodUpdate)

import KubernetesApiModel exposing (..)
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

decodeKubernetesPodSpec : Decoder KubernetesPodSpec
decodeKubernetesPodSpec =
    (Json.Decode.map2 KubernetesPodSpec
        (field "containers" (Json.Decode.list decodeKubernetesContainerItem))
        (field "nodeName" string))

decodeKubernetesPodItem : Decoder KubernetesPodItem
decodeKubernetesPodItem =
    (Json.Decode.map3 KubernetesPodItem 
        (field "metadata" decodeKubernetesPodMetadata) 
        (field "status" decodeKubernetesPodStatus)
        (field "spec" decodeKubernetesPodSpec))

decodeKubernetesResultMetadata : Decoder KubernetesResultMetadata
decodeKubernetesResultMetadata =
    (Json.Decode.map KubernetesResultMetadata (field "resourceVersion" string))

decodeKubernetesContainerItem : Decoder KubernetesContainerItem
decodeKubernetesContainerItem =
    (Json.Decode.map2 KubernetesContainerItem (field "name" string) (field "image" string))

decodeKubernetesPodResult : Decoder KubernetesPodResult
decodeKubernetesPodResult =
    (Json.Decode.map2 KubernetesPodResult 
        (field "metadata" decodeKubernetesResultMetadata) 
        (field "items" (Json.Decode.list decodeKubernetesPodItem)))

decodeKubernetesPodUpdate : Decoder KubernetesPodUpdate
decodeKubernetesPodUpdate = 
    (Json.Decode.map2 KubernetesPodUpdate (field "type" string) (field "object" decodeKubernetesPodItem))

