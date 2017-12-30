module AutoScaling exposing (Model, Msg, init, view, update)
import Html exposing (Html, h1, text)

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

view : (Msg -> msg) -> Model -> List (Html msg)
view makeMsg model =
    [
        h1 [] [ text "Experiment 3: Auto-Scaling" ]
    ]

update : (Msg -> msg) -> Msg -> Container c -> (Container c, Cmd msg)
update makeMsg msg model =
    (model, Cmd.none)


