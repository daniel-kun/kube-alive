module AutoScaling exposing (Model, Msg, init, view, update)
import Html exposing (Html, h1, text, table, tr, td)

-- MODEL

type alias Model = {
    x: Int
}

type alias Container c = {
    c
    | autoScaling : Model
}

-- MSG

type Msg =
    None

-- FUNCTIONS

init = Model 0


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
        table [] (List.map (renderAutoScaling model) (List.filter (\n -> n.app == "cpuhog") podList))
    ]

update : (Msg -> msg) -> Msg -> Container c -> (Container c, Cmd msg)
update makeMsg msg model =
    (model, Cmd.none)


