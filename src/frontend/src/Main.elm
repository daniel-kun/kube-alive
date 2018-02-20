import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import String.Format exposing (format1, format2)
import WebSocket
import Http exposing (get, send)
import KubernetesApiModel exposing (KubernetesResultMetadata, KubernetesPodResult, KubernetesPodItem, KubernetesPodMetadata, KubernetesLabels, KubernetesPodStatus, KubernetesPodCondition, KubernetesPodUpdate)
import KubernetesApiDecoder exposing (decodeKubernetesPodResult, decodeKubernetesPodUpdate)
import Json.Decode exposing (decodeString)
import LoadBalancing
import SelfHealing
import AutoScaling

main =
  Html.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias PodInfo =
    { name: String
    , uid: String
    , app: String
    , status: String
    , podIP: String
    }

type alias Model =
  {   podList : List PodInfo
    , originHost: String
    , podListResourceVersion : String
    , debugText : String
    , loadBalancing : LoadBalancing.Model
    , selfHealing : SelfHealing.Model
    , autoScaling : AutoScaling.Model
  }

type alias Flags =
  { originHost : String
  }

init : Flags -> (Model, Cmd Msg)
init flags =
  (Model [] flags.originHost "" "(Loading)" (LoadBalancing.init flags.originHost) (SelfHealing.init flags.originHost) (AutoScaling.init flags.originHost), Http.send PodList (Http.get (format1 "http://{1}/api/v1/namespaces/kube-alive/pods" flags.originHost) decodeKubernetesPodResult))

-- UPDATE

type Msg = 
      PodList (Result Http.Error KubernetesPodResult) 
    | PodUpdate String
    | LoadBalancingMsg LoadBalancing.Msg 
    | SelfHealingMsg SelfHealing.Msg
    | AutoScalingMsg AutoScaling.Msg

makePodInfoStatus : KubernetesPodItem -> String
makePodInfoStatus item =
    case item.metadata.deletionTimestamp of 
        Just _ -> "Terminating"
        Nothing -> item.status.phase

makePodIP : KubernetesPodItem -> String
makePodIP item =
    case item.status.podIP of 
        Just ip -> ip
        Nothing -> ""

makePodInfo : KubernetesPodItem -> PodInfo
makePodInfo item =
    PodInfo item.metadata.name item.metadata.uid item.metadata.labels.app (makePodInfoStatus item) (makePodIP item)

makePodList : KubernetesPodResult -> List PodInfo
makePodList newPodList =
    List.map makePodInfo newPodList.items

updatePodInfo : KubernetesPodUpdate -> PodInfo -> PodInfo
updatePodInfo podUpdate podInfo =
    if podUpdate.object.metadata.uid == podInfo.uid then
        { podInfo | status = makePodInfoStatus podUpdate.object }
    else
        podInfo

addOrUpdatePod : List PodInfo -> KubernetesPodUpdate -> List PodInfo
addOrUpdatePod podList podUpdate =
    if (List.length (List.filter (\p -> p.uid == podUpdate.object.metadata.uid) podList) > 0) then
        List.map (updatePodInfo podUpdate) podList
    else
        (makePodInfo podUpdate.object) :: podList
        

selectAllPodsExcept : KubernetesPodUpdate -> PodInfo -> Bool
selectAllPodsExcept podUpdate podInfo =
    podUpdate.object.metadata.uid /= podInfo.uid

updatePodList : List PodInfo -> KubernetesPodUpdate -> List PodInfo
updatePodList podList podUpdate =
    case podUpdate.updateType of
        "MODIFIED" ->
            addOrUpdatePod podList podUpdate
        "DELETED" ->
            List.filter (selectAllPodsExcept podUpdate) podList
        "ADDED" ->
            addOrUpdatePod podList podUpdate
        _ ->
            podList

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    PodList (Ok newPodList) ->
        ({ model | debugText = "Loaded.", podList = makePodList newPodList, podListResourceVersion = newPodList.metadata.resourceVersion }, Cmd.none)
    PodList (Err _) ->
        ({ model | debugText = "Fetch error" }, Cmd.none)
    PodUpdate jsonResponse ->
        let
            parseResult = (decodeString decodeKubernetesPodUpdate jsonResponse)
        in 
            case parseResult of
                Ok podUpdates ->
                    ({ model | podList = (updatePodList model.podList podUpdates) }, Cmd.none)
                Err errorMessage ->
                    ({ model | debugText = errorMessage }, Cmd.none)
    LoadBalancingMsg msg ->
        LoadBalancing.update LoadBalancingMsg msg model
    SelfHealingMsg msg ->
        SelfHealing.update SelfHealingMsg msg model
    AutoScalingMsg msg ->
        AutoScaling.update AutoScalingMsg msg model

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [
        (case model.podListResourceVersion of
            "" ->
                Sub.none
            version ->
                WebSocket.listen (format2 "ws://{1}/api/v1/namespaces/kube-alive/pods?resourceVersion={2}&watch=true" (model.originHost, model.podListResourceVersion)) PodUpdate),
        (SelfHealing.subscriptions SelfHealingMsg model)
    ]

-- VIEW

view : Model -> Html Msg
view model =
    let
        podList = (List.map (\n -> { name = n.name, status = n.status, app = n.app, podIP = n.podIP }) model.podList)
    in 
        div [ style [("width", "100%")] ]
            [
                div [ style [("margin", "5px"), ("backgroundColor", "#962E2E"), ("color", "white"), ("padding", "15px")] ]
                    (LoadBalancing.view LoadBalancingMsg podList model.loadBalancing),
                div [ style [("margin", "5px"), ("backgroundColor", "#473f54"), ("color", "white"), ("padding", "15px")] ]
                    (SelfHealing.view SelfHealingMsg podList model.selfHealing),
                div [ style [("margin", "5px"), ("backgroundColor", "#294f82"), ("color", "white"), ("padding", "15px")] ]
                    (AutoScaling.view AutoScalingMsg  podList model.autoScaling)
            ]

