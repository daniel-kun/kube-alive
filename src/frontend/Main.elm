import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import WebSocket
import Http exposing (get, send)

main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias KubernetesLabels = {
  app: String
}


type alias KubernetesMetadata = {
  name: String,
  labels: KubernetesLabels
}


type alias KubernetesPodCondition = {
  podType: String,
  status: String
}

type alias KubernetesPodStatus = {
  phase: String,
  conditions: List KubernetesPodCondition
}

type alias KubernetesPodItem = {
  metadata: KubernetesMetadata,
  status: KubernetesPodStatus,
  hostIP: String,
  podIP: String
}

type alias KubernetesPodResult = {
  items: List KubernetesPodItem
}

type alias PodInfo =
    { name: String
    , status: String
    }

type alias LoadBalancingModel =
    { pods: List PodInfo
    }

type alias Model =
  { loadBalancing: LoadBalancingModel
    , debugPodList: String
  }

init : (Model, Cmd Msg)
init =
  (Model (LoadBalancingModel []) "", Cmd.none)

-- UPDATE

type Msg
  = PodUpdate String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    PodUpdate text ->
      ({ model | debugPodList = text }, Cmd.none)

-- SUBSCRIPTIONS

buildWebSocketListener : Model -> List (Sub Msg)
buildWebSocketListener model =
    [WebSocket.listen "ws://192.168.178.80:83/api/v1/namespaces/default/pods?resourceVersion=613723&watch=true" PodUpdate]

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch (buildWebSocketListener model)

-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ text "Hello", text model.debugPodList ]

