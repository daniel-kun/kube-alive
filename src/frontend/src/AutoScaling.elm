module AutoScaling exposing (Model, Msg, init, view, update)
import Html exposing (Html, h1, text, table, tr, td, button, div)
import Html.Events exposing (onClick)
import Http
import String.Format exposing (format1)

-- MODEL

type alias Model = {
    isRunning: Bool,
    finishedRequests: Int
}

type alias Container c = {
    c
    | autoScaling : Model
}

-- MSG

type Msg =
      StartLoadGenerator
    | StopLoadGenerator
    | ContinueLoadGenerator (Result Http.Error String)

-- FUNCTIONS

init = Model False 0


renderAutoScaling : Model -> { name: String, status: String, app: String, podIP: String } -> Html msg
renderAutoScaling model pod =
    tr [] [
        td [] [text <| pod.name ],
        td [] [text <| pod.status ]
    ]

view : (Msg -> msg) -> List { name: String, status: String, app: String, podIP: String } -> Model -> List (Html msg)
view makeMsg podList model =
    [
        h1 [] [ text "Experiment 3: Auto-Scaling" ],
        if (model.isRunning) then
            div [] [
                button [ onClick (makeMsg StopLoadGenerator)] [ text "Stop load generator" ],
                text (String.Format.format1 "{1} requests finished" model.finishedRequests)
            ]
        else
            button [ onClick (makeMsg StartLoadGenerator)] [ text "Start load generator" ],
        table [] (List.map (renderAutoScaling model) (List.filter (\n -> n.app == "cpuhog") podList))
    ]

makeLoadGeneratorRequest makeMsg = 
        Http.send (\n -> (makeMsg (ContinueLoadGenerator n))) (Http.getString "/cpuhog")

-- The load generator fires two requests at once, because a single request would only occupy two nodes
makeLoadGeneratorRequests makeMsg = 
    Cmd.batch [
        makeLoadGeneratorRequest makeMsg,
        makeLoadGeneratorRequest makeMsg
    ]

update : (Msg -> msg) -> Msg -> Container c -> (Container c, Cmd msg)
update makeMsg msg model =
    let
        autoScaling = model.autoScaling
    in
        case msg of
            StartLoadGenerator ->
                ({ model | autoScaling = { autoScaling | isRunning = True } }, makeLoadGeneratorRequests makeMsg)
            StopLoadGenerator ->
                ({ model | autoScaling = { autoScaling | isRunning = False, finishedRequests = 0 } }, Cmd.none)
            ContinueLoadGenerator _ ->
                if (autoScaling.isRunning) then
                    ({ model | autoScaling = { autoScaling | finishedRequests = autoScaling.finishedRequests + 1 } }, makeLoadGeneratorRequests makeMsg)
                else
                    (model, Cmd.none)

