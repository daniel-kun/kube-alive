module SelfHealing exposing (Model, Msg, init, update, view, subscriptions)

import Base exposing (..)
import String.Format exposing (format1)
import Html exposing (Html, h1, div, text, button, table, tr, td, span, p)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (string)
import Time
import Material
import Material.Layout as Layout
import Material.Options as Options exposing (css)
import Material.Color as Color
import Material.Button as Button
import Material.List as Lists
import Material.Typography as Typo
import Material.Grid as Grid


-- MODEL


type alias Model =
    { mdl : Material.Model
    , originHost : String
    , x : Int
    , healthy : Bool
    }



-- MSG


type Msg
    = InfectService
    | ServiceInfectOrKillResponse (Result Http.Error String)
    | KillService
    | StatusPollTimer Time.Time
    | StatusPollResponse (Result Http.Error String)
    | Mdl (Material.Msg Msg)



-- FUNCTIONS


init originHost =
    Model Material.model originHost 0 True


renderPod : PodInfo -> Html msg
renderPod pod =
    Lists.li [ Lists.withSubtitle ]
        [ Lists.content []
            [ text (format1 "Pod {1}" pod.name)
            , Lists.subtitle [] [ text pod.status ]
            ]
        ]


renderServiceState healthy =
    if (healthy) then
        Options.styled p [ Typo.subhead, css "font-weight" "bold", css "color" "green" ] [ text "Service healthy" ]
    else
        Options.styled p [ Typo.subhead, css "font-weight" "bold", css "color" "red" ] [ text "Service unhealthy" ]

view : CommonModel -> Model -> List (Html Msg)
view commonModel model =
    [ Options.styled h1 [ Color.text Color.primary ] [ text "Experiment 2: Self-Healing" ]
    , Options.styled p
        [ Typo.body1 ]
        [ text "In this experiment, you can observe how services recover from two different kinds of failures. When you infect the service, it continues running, but returns a 500 error code. When you kill it, the server process terminates (segmentation fault). In both cases, you can see that Kubernetes recovers your service quickly." ]
    , Grid.grid [] [
          renderButtonCell 1 model Mdl InfectService "Infect service"
        , renderButtonCell 2 model Mdl KillService "Kill service"
        , Grid.cell [ Grid.size Grid.All 4 ] [ renderServiceState model.healthy ]
        ]
    , Options.styled p [ Typo.subhead ] [ text "Pod details:" ]
    , Lists.ul []
        (List.map renderPod (List.filter (\n -> n.app == "healthcheck") commonModel.podList))
    ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InfectService ->
            ( model, (Http.send ServiceInfectOrKillResponse (Http.post (format1 "http://{1}/healthcheck/infect" model.originHost) Http.emptyBody (string))) )

        KillService ->
            ( model, (Http.send ServiceInfectOrKillResponse (Http.post (format1 "http://{1}/healthcheck/kill" model.originHost) Http.emptyBody (string))) )

        ServiceInfectOrKillResponse _ ->
            ( model, Cmd.none )

        StatusPollTimer _ ->
            ( { model | x = model.x + 1 }, (Http.send StatusPollResponse (Http.getString (format1 "http://{1}/healthcheck/" model.originHost))) )

        StatusPollResponse (Ok response) ->
            ( { model | healthy = True }, Cmd.none )

        StatusPollResponse (Err _) ->
            ( { model | healthy = False }, Cmd.none )

        Mdl msg_ ->
            Material.update Mdl msg_ model


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions makeMsg model =
    Time.every (500 * Time.millisecond) (\m -> (makeMsg (StatusPollTimer m)))
