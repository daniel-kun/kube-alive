module SelfHealing exposing (Model, Msg, init, update, view, subscriptions)
import Html exposing (Html, h1, div, text, button, table, tr, td, span)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (string)
import Time

-- MODEL

type alias Model = {
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

init = Model 0 True

renderPod : { name: String, app: String, status: String, podIP: String } -> Html msg
renderPod pod =
    tr [] [
        td [] [ text pod.name ],
        td [] [ text pod.status ]
    ]

view : (Msg -> msg) -> List { name: String, app: String, status: String, podIP: String } -> Model -> List (Html msg)
view makeMsg pods model =
    [ div [] [ 
        h1 [] [ text "Experiment 2: Self-Healing" ],
        button [ onClick (makeMsg InfectService) ] [ text "Infect service" ],
        button [ onClick (makeMsg KillService) ] [ text "Kill service" ],
        if (model.healthy) then (span [style [("color", "green")]][text "Service healthy"]) else (span [style [("color", "red")]][text "Service unhealthy"]),
        table [] 
            (List.map renderPod (List.filter (\n -> n.app == "healthcheck") pods))
    ] ]

update : (Msg -> msg) -> Msg -> Container c -> (Container c, Cmd msg)
update makeMsg msg model =
    let
        selfHealing = model.selfHealing
    in
        case msg of
            InfectService ->
                (model, Http.send (\m -> (makeMsg (ServiceInfectOrKillResponse m))) (Http.post "/healthcheck/infect" Http.emptyBody (string)))
            KillService ->
                (model, Http.send (\m -> (makeMsg (ServiceInfectOrKillResponse m))) (Http.post "/healthcheck/kill" Http.emptyBody (string)))
            ServiceInfectOrKillResponse _ ->
                (model, Cmd.none)
            StatusPollTimer _ ->
                ({ model | selfHealing = { selfHealing | x = selfHealing.x + 1 }}, (Http.send (\m -> (makeMsg (StatusPollResponse m))) (Http.getString "/healthcheck/")))
            StatusPollResponse (Ok response) ->
                ({ model | selfHealing = { selfHealing | healthy = True }}, Cmd.none)
            StatusPollResponse (Err _)->
                ({ model | selfHealing = { selfHealing | healthy = False }}, Cmd.none)

subscriptions : (Msg -> msg) -> Container c -> Sub msg
subscriptions makeMsg model =
    Time.every (500 * Time.millisecond) (\t -> (makeMsg (StatusPollTimer t)))

