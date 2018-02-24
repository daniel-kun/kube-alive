module LoadBalancing exposing (Model, Msg(ExecLoadBalanceTest, ReceiveLoadBalanceResponse), init, update, view)

import Base exposing (..)
import String.Format exposing (format1)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http exposing (get, send)
import List.Extra
import Material
import Material.Layout as Layout
import Material.Options as Options
import Material.Color as Color
import Material.Button as Button
import Material.List as Lists
import Material.Badge as Badge
import Material.Typography as Typo
import Material.Grid as Grid


-- MODEL


type alias Model =
    { mdl : Material.Model
    , responses : List String
    , originHost : String
    }



-- MSG


type Msg
    = ExecLoadBalanceTest
    | ReceiveLoadBalanceResponse (Result Http.Error String)
    | Mdl (Material.Msg Msg)



-- FUNCTIONS


init originHost =
    Model Material.model [] originHost


renderLoadBalancing : Model -> PodInfo -> Html msg
renderLoadBalancing loadBalancing pod =
    Lists.li [ Lists.withSubtitle ]
        [ Lists.content [] [ text (format1 "Pod {1}" pod.name), Lists.subtitle [] [ text pod.status ] ]
        , Lists.content2 [] [ Options.span [ Badge.add (toString (List.Extra.count (\n -> n == pod.podIP) loadBalancing.responses)) ] [ text "Responses" ] ]
        ]


view : CommonModel -> Model -> List (Html Msg)
view commonModel loadBalancing =
    [ Options.styled h1 [ Color.text Color.primary ] [ text "Experiment #1: Load-Balancing" ]
    , Options.styled p
        [ Typo.body1 ]
        [ text "In this experiment, you can make requests to a load-balanced service backed by multiple, stateless instances. Press the button below and observe how the requests are balanced between the Pods." ]
    , Grid.grid [] [
            renderButtonCell 0 loadBalancing Mdl ExecLoadBalanceTest "Make 50 requests"
        ]
    , Options.styled p [ Typo.subhead ] [ text "Pod details:" ]
    , Lists.ul [] (List.map (renderLoadBalancing loadBalancing) (List.filter (\n -> n.app == "getip") commonModel.podList))
    ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ExecLoadBalanceTest ->
            ( model, Cmd.batch (List.repeat 50 (Http.send ReceiveLoadBalanceResponse (Http.getString (format1 "http://{1}/getip" model.originHost)))) )

        ReceiveLoadBalanceResponse (Ok response) ->
            ( { model | responses = response :: model.responses }, Cmd.none )

        ReceiveLoadBalanceResponse (Err _) ->
            ( model, Cmd.none )

        Mdl msg_ ->
            Material.update Mdl msg_ model
