module SelfHealing exposing (Model, Msg, init, update, view, subscriptions)
import Base exposing (PodInfo, CommonModel)
import String.Format exposing (format1)
import Html exposing (Html, h1, div, text, button, table, tr, td, span)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (string)
import Time

-- MODEL

type alias Model = {
    originHost: String,
    x: Int,
    healthy: Bool
}

type alias Container c = {
    c |
    selfHealing : Model
}

-- MSG

type Msg =
      InfectService
    | ServiceInfectOrKillResponse (Result Http.Error String)
    | KillService
    | StatusPollTimer Time.Time
    | StatusPollResponse  (Result Http.Error String)

-- FUNCTIONS

init originHost = Model originHost 0 True

renderPod : PodInfo -> Html msg
renderPod pod =
    tr [] [
        td [] [ text pod.name ],
        td [] [ text pod.status ]
    ]

view : (Msg -> msg) -> CommonModel -> Model -> List (Html msg)
view makeMsg commonModel model =
    [ div [] [ 
        h1 [] [ text "Experiment 2: Self-Healing" ],
        button [ onClick (makeMsg InfectService) ] [ text "Infect service" ],
        button [ onClick (makeMsg KillService) ] [ text "Kill service" ],
        if (model.healthy) then (span [style [("font-weight", "bold"), ("color", "green")]][text "Service healthy"]) else (span [style [("font-weight", "bold"), ("color", "red")]][text "Service unhealthy"]),
        table [] 
            (List.map renderPod (List.filter (\n -> n.app == "healthcheck") commonModel.podList))
    ] ]

update : (Msg -> msg) -> Msg -> Container c -> (Container c, Cmd msg)
update makeMsg msg model =
    let
        selfHealing = model.selfHealing
    in
        case msg of
            InfectService ->
                (model, Http.send (\m -> (makeMsg (ServiceInfectOrKillResponse m))) (Http.post (format1 "http://{1}/healthcheck/infect" selfHealing.originHost) Http.emptyBody (string)))
            KillService ->
                (model, Http.send (\m -> (makeMsg (ServiceInfectOrKillResponse m))) (Http.post (format1 "http://{1}/healthcheck/kill" selfHealing.originHost) Http.emptyBody (string)))
            ServiceInfectOrKillResponse _ ->
                (model, Cmd.none)
            StatusPollTimer _ ->
                ({ model | selfHealing = { selfHealing | x = selfHealing.x + 1 }}, (Http.send (\m -> (makeMsg (StatusPollResponse m))) (Http.getString (format1 "http://{1}/healthcheck/" selfHealing.originHost))))
            StatusPollResponse (Ok response) ->
                ({ model | selfHealing = { selfHealing | healthy = True }}, Cmd.none)
            StatusPollResponse (Err _)->
                ({ model | selfHealing = { selfHealing | healthy = False }}, Cmd.none)

subscriptions : (Msg -> msg) -> Container c -> Sub msg
subscriptions makeMsg model =
    Time.every (500 * Time.millisecond) (\t -> (makeMsg (StatusPollTimer t)))

