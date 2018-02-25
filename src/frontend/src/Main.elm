module Main exposing (..)

import Html exposing (..)
import Base exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import String.Format exposing (format1, format2)
import String exposing (toInt)
import Maybe exposing (withDefault)
import WebSocket
import Http exposing (get, send)
import KubernetesApiModel exposing (..)
import KubernetesApiDecoder exposing (decodeKubernetesPodResult, decodeKubernetesPodUpdate)
import Json.Decode exposing (decodeString)
import List.Extra exposing (last)
import LoadBalancing
import SelfHealing
import AutoScaling
import RollingUpdate
import Material
import Material.Layout as Layout
import Material.Options as Options exposing (css)
import Material.Helpers exposing (lift)


main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type ActiveTab
    = LoadBalancingTab
    | SelfHealingTab
    | AutoScalingTab
    | RollingUpdateTab


type alias Model =
    { commonModel : CommonModel
    , originHost : String
    , activeTab : ActiveTab
    , podListResourceVersion : String
    , debugText : String
    , loadBalancing : LoadBalancing.Model
    , selfHealing : SelfHealing.Model
    , autoScaling : AutoScaling.Model
    , rollingUpdate : RollingUpdate.Model
    , mdl : Material.Model
    }


type alias Flags =
    { originHost : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model (CommonModel []) flags.originHost LoadBalancingTab "" "(Loading)" (LoadBalancing.init flags.originHost) (SelfHealing.init flags.originHost) (AutoScaling.init flags.originHost) (RollingUpdate.init flags.originHost) Material.model, Http.send PodList (Http.get (format1 "http://{1}/api/v1/namespaces/kube-alive/pods" flags.originHost) decodeKubernetesPodResult) )



-- UPDATE


type Msg
    = PodList (Result Http.Error KubernetesPodResult)
    | PodUpdate String
    | LoadBalancingMsg LoadBalancing.Msg
    | SelfHealingMsg SelfHealing.Msg
    | AutoScalingMsg AutoScaling.Msg
    | RollingUpdateMsg RollingUpdate.Msg
    | Mdl (Material.Msg Msg)
    | ToggleTabLoadBalancing
    | ToggleTabSelfHealing
    | ToggleTabAutoScaling
    | ToggleTabRollingUpdates


makePodInfoStatus : KubernetesPodItem -> String
makePodInfoStatus item =
    case item.metadata.deletionTimestamp of
        Just _ ->
            "Terminating"

        Nothing ->
            item.status.phase


makePodIP : KubernetesPodItem -> String
makePodIP item =
    case item.status.podIP of
        Just ip ->
            ip

        Nothing ->
            ""

makeContainerInfo container =
    ContainerInfo container.name container.image

makeContainerState : KubernetesContainerStateItem -> ContainerState
makeContainerState state =
    case state.running of
        Just details ->
            Running (withDefault "" details.startedAt)
        Nothing ->
            case state.terminating of
                Just details ->
                    Failed (withDefault "" details.startedAt) (withDefault "" details.reason) (withDefault "" details.message)
                Nothing ->
                    case state.waiting of
                        Just details ->
                            Failed (withDefault "" details.startedAt) (withDefault "" details.reason) (withDefault "" details.message)
                        Nothing ->
                            Failed "" "" ""

makeContainerStatus : List KubernetesContainerStatusItem -> ContainerStatusInfo
makeContainerStatus statuses =
    case statuses of
        a :: _ ->
            (ContainerStatusInfo 
                 a.restartCount
                 a.ready
                 (makeContainerState a.state))
        [] ->
            (ContainerStatusInfo 0 False (Failed "" "Pending" "Pod starting..."))

makePodInfo : KubernetesPodItem -> PodInfo
makePodInfo item =
    PodInfo item.metadata.name item.metadata.uid item.metadata.labels.app (makePodInfoStatus item) (makePodIP item) (List.map makeContainerInfo item.spec.containers) (makeContainerStatus (withDefault [] item.status.containerStatuses))


makePodList : KubernetesPodResult -> List PodInfo
makePodList newPodList =
    List.map makePodInfo newPodList.items


updatePodInfo : KubernetesPodUpdate -> PodInfo -> PodInfo
updatePodInfo podUpdate podInfo =
    if podUpdate.object.metadata.uid == podInfo.uid then
        makePodInfo podUpdate.object
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        commonModel =
            model.commonModel
    in
        case msg of
            PodList (Ok newPodList) ->
                ( { model | debugText = "Loaded.", commonModel = { commonModel | podList = makePodList newPodList }, podListResourceVersion = newPodList.metadata.resourceVersion }, Cmd.none )

            PodList (Err err) ->
                ( { model | debugText = (format1 "Fetch error: {1}" err) }, Cmd.none )

            PodUpdate jsonResponse ->
                let
                    parseResult =
                        (decodeString decodeKubernetesPodUpdate jsonResponse)
                in
                    case parseResult of
                        Ok podUpdates ->
                            ( { model | commonModel = { commonModel | podList = (updatePodList commonModel.podList podUpdates) } }, Cmd.none )

                        Err errorMessage ->
                            ( { model | debugText = errorMessage }, Cmd.none )

            LoadBalancingMsg a ->
                lift .loadBalancing (\m x -> { m | loadBalancing = x }) LoadBalancingMsg LoadBalancing.update a model

            SelfHealingMsg a ->
                lift .selfHealing (\m x -> { m | selfHealing = x }) SelfHealingMsg SelfHealing.update a model

            AutoScalingMsg a ->
                lift .autoScaling (\m x -> { m | autoScaling = x }) AutoScalingMsg AutoScaling.update a model

            RollingUpdateMsg a ->
                lift .rollingUpdate (\m x -> { m | rollingUpdate = x }) RollingUpdateMsg RollingUpdate.update a model

            Mdl msg ->
                Material.update Mdl msg model

            ToggleTabLoadBalancing ->
                ( { model | activeTab = LoadBalancingTab }, Cmd.none )

            ToggleTabSelfHealing ->
                ( { model | activeTab = SelfHealingTab }, Cmd.none )

            ToggleTabAutoScaling ->
                ( { model | activeTab = AutoScalingTab }, Cmd.none )

            ToggleTabRollingUpdates ->
                ( { model | activeTab = RollingUpdateTab }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ (case model.podListResourceVersion of
            "" ->
                Sub.none

            version ->
                WebSocket.listen (format2 "ws://{1}/api/v1/namespaces/kube-alive/pods?resourceVersion={2}&watch=true" ( model.originHost, model.podListResourceVersion )) PodUpdate
          )
        , SelfHealing.subscriptions SelfHealingMsg model.selfHealing
        , RollingUpdate.subscriptions RollingUpdateMsg model.rollingUpdate
        , Material.subscriptions Mdl model
        ]



-- VIEW


type alias Mdl =
    Material.Model


renderMain : Model -> Html Msg
renderMain model =
    case model.activeTab of
        LoadBalancingTab ->
            div [ style [ ( "margin", "20px" ), ("padding", "15px" ) ] ] 
                (List.map (Html.map LoadBalancingMsg) (LoadBalancing.view model.commonModel model.loadBalancing))

        SelfHealingTab ->
            div [ style [ ( "margin", "20px" ), ( "padding", "15px" ) ] ]
                ([ text model.debugText ] ++
                (List.map (Html.map SelfHealingMsg) (SelfHealing.view model.commonModel model.selfHealing)))

        AutoScalingTab ->
            div [ style [ ( "margin", "20px" ), ( "padding", "15px" ) ] ]
                (List.map (Html.map AutoScalingMsg) (AutoScaling.view model.commonModel model.autoScaling))

        RollingUpdateTab ->
            div [ style [ ( "margin", "20px" ), ( "padding", "15px" ) ] ]
                (List.map (Html.map RollingUpdateMsg) (RollingUpdate.view model.commonModel model.rollingUpdate))


renderTabHeader : String -> String -> List (Html Msg)
renderTabHeader title description =
    [ div [] [ text title ], div [ style [("font-weight", "bold")] ] [ text description ] ]

renderDrawer : Model -> List (Html Msg)
renderDrawer model =
    [ Layout.navigation [] [ Layout.link [ Options.onClick ToggleTabLoadBalancing ] (renderTabHeader "Experiment #1" "Load-Balancing") ]
    , Layout.navigation [] [ Layout.link [ Options.onClick ToggleTabSelfHealing ] (renderTabHeader "Experiment #2" "Self-Healing") ]
    , Layout.navigation [] [ Layout.link [ Options.onClick ToggleTabRollingUpdates ] (renderTabHeader "Experiment #3" "Rolling Updates") ]
    , Layout.navigation [] [ Layout.link [ Options.onClick ToggleTabAutoScaling ] (renderTabHeader "Experiment #4" "Auto-Scaling") ]
    ]


view : Model -> Html Msg
view model =
    Layout.render Mdl
        model.mdl
        [ Layout.fixedHeader
        , Layout.fixedDrawer
        ]
        { header = [ Layout.row [] [ Layout.title [] [ text "Kubernetes: I's alive!" ], Layout.spacer, Layout.navigation [] [ Layout.link [ Layout.href "https://github.com/daniel-kun/kube-alive" ] [ text "github" ] ] ] ]
        , drawer = renderDrawer model
        , tabs = ( [], [] )
        , main = [ renderMain model ]
        }
