import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import String.Format exposing (format1)
import WebSocket
import Http exposing (get, send)
import KubernetesApiModel exposing (KubernetesResultMetadata, KubernetesPodResult, KubernetesPodItem, KubernetesPodMetadata, KubernetesLabels, KubernetesPodStatus, KubernetesPodCondition, KubernetesPodUpdate)
import KubernetesApiDecoder exposing (decodeKubernetesPodResult, decodeKubernetesPodUpdate)
import Json.Decode exposing (decodeString)
import LoadBalancing
import SelfHealing

main =
  Html.program
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
  {   lastMsg : Msg
    , podList : List PodInfo
    , podListResourceVersion : String
    , debugText : String
    , loadBalancing : LoadBalancing.Model
    , selfHealing : SelfHealing.Model
  }

init : (Model, Cmd Msg)
init =
  (Model Idle [] "" "(Loading)" LoadBalancing.init SelfHealing.init, Http.send PodList (Http.get "http://192.168.178.80:83/api/v1/namespaces/default/pods" decodeKubernetesPodResult))

-- UPDATE

type Msg = 
      Idle
    | PodList (Result Http.Error KubernetesPodResult) 
    | PodUpdate String
    | LoadBalancingMsg LoadBalancing.Msg 
    | SelfHealingMsg SelfHealing.Msg

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

selectAllPodsExcept : KubernetesPodUpdate -> PodInfo -> Bool
selectAllPodsExcept podUpdate podInfo =
    podUpdate.object.metadata.uid /= podInfo.uid

updatePodList : List PodInfo -> KubernetesPodUpdate -> List PodInfo
updatePodList podList podUpdate =
    case podUpdate.updateType of
        "MODIFIED" ->
            List.map (updatePodInfo podUpdate) podList
        "DELETED" ->
            List.filter (selectAllPodsExcept podUpdate) podList
        "ADDED" ->
            (makePodInfo podUpdate.object) :: podList
        _ ->
            podList

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Idle ->
        (model, Cmd.none)
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

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [
        (case model.podListResourceVersion of
            "" ->
                Sub.none
            version ->
                WebSocket.listen (format1 "ws://192.168.178.80:83/api/v1/namespaces/default/pods?resourceVersion={1}&watch=true" model.podListResourceVersion) PodUpdate),
        (SelfHealing.subscriptions SelfHealingMsg model)
    ]

-- VIEW

view : Model -> Html Msg
view model =
    div [] [
        text model.debugText,
        div [ style [("width", "100%")] ]
            [
                div [ style [("margin", "5px"), ("backgroundColor", "#962E2E"), ("color", "white"), ("padding", "15px")] ]
                    (LoadBalancing.view LoadBalancingMsg (List.map (\n -> { name = n.name, status = n.status, app = n.app, podIP = n.podIP }) model.podList) model.loadBalancing),
                div [ style [("margin", "5px"), ("backgroundColor", "#473f54"), ("color", "white"), ("padding", "15px")] ]
                    (SelfHealing.view SelfHealingMsg (List.map (\n -> { name = n.name, status = n.status, app = n.app }) model.podList) model.selfHealing)
            ]
    ]

