module Main exposing (..)

import Html exposing (..)
import Base exposing (PodInfo, CommonModel)
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
import RollingUpdate
import Material
import Material.Scheme
import Material.Layout as Layout
import Material.Options as Options exposing (css)


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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        commonModel =
            model.commonModel
    in
        case msg of
            PodList (Ok newPodList) ->
                ( { model | debugText = "Loaded.", commonModel = { commonModel | podList = makePodList newPodList }, podListResourceVersion = newPodList.metadata.resourceVersion }, Cmd.none )

            PodList (Err _) ->
                ( { model | debugText = "Fetch error" }, Cmd.none )

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

            LoadBalancingMsg msg ->
                LoadBalancing.update LoadBalancingMsg msg model

            SelfHealingMsg msg ->
                SelfHealing.update SelfHealingMsg msg model

            AutoScalingMsg msg ->
                AutoScaling.update AutoScalingMsg msg model

            RollingUpdateMsg msg ->
                RollingUpdate.update RollingUpdateMsg msg model

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
        , (SelfHealing.subscriptions SelfHealingMsg model)
        , (RollingUpdate.subscriptions RollingUpdateMsg model)
        ]



-- VIEW


type alias Mdl =
    Material.Model


renderMain : Model -> Html Msg
renderMain model =
    case model.activeTab of
        LoadBalancingTab ->
            div [ style [ ( "margin", "20px" ), ( "backgroundColor", "#53d88a" ), ( "padding", "15px" ) ] ]
                (LoadBalancing.view LoadBalancingMsg model.commonModel model.loadBalancing)

        SelfHealingTab ->
            div [ style [ ( "margin", "20px" ), ( "backgroundColor", "#fbdb54" ), ( "padding", "15px" ) ] ]
                (SelfHealing.view SelfHealingMsg model.commonModel model.selfHealing)

        AutoScalingTab ->
            div [ style [ ( "margin", "20px" ), ( "backgroundColor", "#999fc7" ), ( "padding", "15px" ) ] ]
                (AutoScaling.view AutoScalingMsg model.commonModel model.autoScaling)

        RollingUpdateTab ->
            div [ style [ ( "margin", "20px" ), ( "backgroundColor", "#fa695b" ), ( "padding", "15px" ) ] ]
                (RollingUpdate.view RollingUpdateMsg model.commonModel model.rollingUpdate)


renderDrawer : Model -> List (Html Msg)
renderDrawer model =
    [ Layout.title [] [ text "Experiments:" ]
    , Layout.navigation [] [ Layout.link [ Options.onClick ToggleTabLoadBalancing ] [ text "Experiment #1" ] ]
    , Layout.navigation [] [ Layout.link [ Options.onClick ToggleTabSelfHealing ] [ text "Experiment #2" ] ]
    , Layout.navigation [] [ Layout.link [ Options.onClick ToggleTabAutoScaling ] [ text "Experiment #3" ] ]
    , Layout.navigation [] [ Layout.link [ Options.onClick ToggleTabRollingUpdates ] [ text "Experiment #4" ] ]
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
