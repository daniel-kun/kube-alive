module RollingUpdate exposing (Model, Msg(StartServiceUpdate, ReceiveVersionResponse), init, update, view, subscriptions)
import Base exposing (PodInfo, CommonModel)
import String.Format exposing (format1)
import Html exposing (Html, h1, div, text, button, table, tr, td, span)
import Html.Events exposing (onClick)
import Time
import Http

-- MODEL

type alias Model = {
    originHost : String,
    version : String
}

-- MSG

type Msg =
      StartServiceUpdate
    | StartServiceResponse (Result Http.Error String)
    | ReceiveVersionResponse (Result Http.Error String)
    | VersionPollTimer Time.Time

type alias Container c = {
    c | rollingUpdate : Model
}

-- FUNCTIONS

init originHost = Model originHost ""

renderPod : PodInfo -> Html msg
renderPod pod =
    tr [] [
        td [] [ text pod.name ],
        td [] [ text pod.status ]
    ]

view : (Msg -> msg) -> CommonModel -> Model -> List (Html msg)
view makeMsg commonModel rollingUpdate =
    [
        div [] [
            h1 [] [ text "Experiment 4: Rolling Updates" ],
            div [] [
                button [ onClick (makeMsg StartServiceUpdate) ] [ text "Start update" ],
                text (format1 "Current version: {1}" rollingUpdate.version)
            ],
            table []
                (List.map renderPod (List.filter (\n -> n.app == "incver") commonModel.podList))
        ]
    ]

update : (Msg -> msg) -> Msg -> Container c -> (Container c, Cmd msg)
update makeMsg msg model =
    let
        rollingUpdate = model.rollingUpdate
    in
        case msg of
            StartServiceUpdate ->
                (model, (Http.send (\m -> (makeMsg (StartServiceResponse m))) (Http.getString (format1 "http://{1}/incver/start" rollingUpdate.originHost))))
            StartServiceResponse (Ok _) ->
                (model, Cmd.none)
            StartServiceResponse (Err _) ->
                (model, Cmd.none)
            ReceiveVersionResponse (Ok version) ->
                ({ model | rollingUpdate = { rollingUpdate | version = version }}, Cmd.none)
            ReceiveVersionResponse (Err _) ->
                (model, Cmd.none)
            VersionPollTimer _ ->
                (model, (Http.send (\m -> (makeMsg (ReceiveVersionResponse m))) (Http.getString (format1 "http://{1}/incver/version" rollingUpdate.originHost))))

subscriptions : (Msg -> msg) -> Container c -> Sub msg
subscriptions makeMsg model =
    Time.every (500 * Time.millisecond) (\t -> (makeMsg (VersionPollTimer t)))
