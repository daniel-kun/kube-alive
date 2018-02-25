module RollingUpdate exposing (Model, Msg(StartServiceUpdate, ReceiveVersionResponse), init, update, view, subscriptions)

import Base exposing (..)
import String.Format exposing (format1)
import Html exposing (Html, h1, div, text, button, table, tr, td, span, p)
import Html.Events exposing (onClick)
import List.Extra exposing (last)
import Time
import Http
import Material
import Material.Options as Options exposing (css)
import Material.Color as Color
import Material.Grid as Grid
import Material.List as Lists
import Material.Typography as Typo
import Material.Badge as Badge


-- MODEL


type alias Model =
    { mdl : Material.Model
    , originHost : String
    , version : String
    , requestPending : Bool
    , failedRequests : Int
    }



-- MSG


type Msg
    = StartServiceUpdate
    | StartServiceResponse (Result Http.Error String)
    | ReceiveVersionResponse (Result Http.Error String)
    | VersionPollTimer Time.Time
    | Mdl (Material.Msg Msg)



-- FUNCTIONS


init originHost =
    Model Material.model originHost "" False 0

getPodVersion pod =
    case pod.containers of
        c :: _->
            case last (String.split ":" c.image) of
                Just a ->
                    a
                Nothing ->
                    ""
        _ ->
            ""

renderPod : PodInfo -> Html Msg
renderPod pod =
    Lists.li [ Lists.withSubtitle ]
        [ Lists.content []
            [ Options.span [ Badge.add (getPodVersion pod) ] [ text (format1 "Pod {1}" pod.name) ]
            , Lists.subtitle [] [ text pod.status ]
            ]
        ]

failColor : Model -> List (Options.Property c m)
failColor rollingUpdate =
    if rollingUpdate.failedRequests > 0 then
        [ css "color" "red", css "font-weight" "bold" ]
    else
        []


view : CommonModel -> Model -> List (Html Msg)
view commonModel rollingUpdate =
    [ Options.styled h1 [ Color.text Color.primary ] [ text "Experiment #3: Rolling Updates" ]
    , Options.styled p
        [ Typo.body1 ]
        [ text "In this experiment, you can observe how a stateless service is updated to a new version, without interrupting the service's availability. The new and the old instance will run in parallel until the new instance is ready, then the old instance is killed. The service is polled two times per second for it's current version. At no time should these requests fail." ]
    , Grid.grid []
        [ renderButtonCell 4 rollingUpdate Mdl StartServiceUpdate "Update service"
        , Grid.cell [ Grid.size Grid.All 4 ] [ Options.styled p [ Typo.subhead ] [ text (format1 "Current version: {1}" rollingUpdate.version) ] ]
        , Grid.cell [ Grid.size Grid.All 4 ] [ Options.styled p ([ Typo.subhead ] ++ (failColor rollingUpdate)) [ text (format1 "Failed requests: {1}" (toString rollingUpdate.failedRequests)) ] ]
        ]
    , Lists.ul []
        (List.map renderPod (List.filter (\n -> n.app == "incver") commonModel.podList))
    ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartServiceUpdate ->
            if model.requestPending then
                ( model, Cmd.none )
            else
                ( 
                    { model | requestPending = True, failedRequests = 0 }, 
                    (Http.send 
                        (\m -> StartServiceResponse m) 
                        (Http.getString (format1 "http://{1}/incver/start" model.originHost))) )

        StartServiceResponse (Ok _) ->
            ( model, Cmd.none )

        StartServiceResponse (Err _) ->
            ( model, Cmd.none )

        ReceiveVersionResponse (Ok version) ->
            ( { model | requestPending = False, version = version }, Cmd.none )

        ReceiveVersionResponse (Err _) ->
            ( { model | requestPending = False, failedRequests = model.failedRequests + 1 }, Cmd.none )

        VersionPollTimer _ ->
            ( model, (Http.send (\m -> ReceiveVersionResponse m) (Http.getString (format1 "http://{1}/incver/version" model.originHost))) )

        Mdl msg_ ->
            Material.update Mdl msg_ model


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions makeMsg model =
    Time.every (500 * Time.millisecond) (\t -> (makeMsg (VersionPollTimer t)))
