module SelfHealing exposing (Model, Msg, init, update, view)
import Html exposing (Html, h1, div, text)

-- MODEL

type alias Model = {
    x: Int
}

type alias Container c = {
    c |
    selfHealing : Model
}

-- MSG

type Msg =
    Unused

-- FUNCTIONS

init = Model 0

view : (Msg -> msg) -> Model -> List (Html msg)
view makeMsg model =
    [ div [] [ h1 [] [ text "Example 2: Self-Healing" ] ] ]

update : (Msg -> msg) -> Msg -> Container c -> (Container c, Cmd msg)
update makeMsg msg model =
    (model, Cmd.none)

