module LoadBalancing exposing (Model, Msg(ExecLoadBalanceTest, ReceiveLoadBalanceResponse), init, update, view)
import Base exposing (PodInfo, CommonModel)
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

-- MODEL

type alias Model =
    { responses: List String,
      originHost: String,
      mdl : Material.Model
    }

-- MSG

type Msg =
      ExecLoadBalanceTest 
    | ReceiveLoadBalanceResponse (Result Http.Error String)
    | Mdl (Material.Msg Msg)

-- FUNCTIONS

init originHost = Model [] originHost Material.model


renderLoadBalancing : Model -> PodInfo  -> Html msg
renderLoadBalancing loadBalancing pod =
    Lists.li [] [
        Lists.content [] [ text pod.name, Lists.subtitle [] [ text pod.status ] ],
        Lists.content2 [] [ Options.span [ Badge.add (toString (List.Extra.count (\n -> n == pod.podIP) loadBalancing.responses)) ] [ text "Responses" ] ]
    ]

view : CommonModel -> Model -> List (Html Msg)
view commonModel loadBalancing =
    [
        Options.styled h1 [Color.text Color.primary] [ text "Experiment 1: Load-Balancing" ],
        Button.render Mdl [0] commonModel.mdl [ Button.raised, Button.colored, Button.ripple, Options.onClick ExecLoadBalanceTest ] [text "Make 50 requests to getip"],
        Lists.ul [] (List.map (renderLoadBalancing loadBalancing) (List.filter (\n -> n.app == "getip") commonModel.podList))
    ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        ExecLoadBalanceTest ->
            (model, Cmd.batch (List.repeat 50 (Http.send ReceiveLoadBalanceResponse (Http.getString (format1 "http://{1}/getip" model.originHost)))))
        ReceiveLoadBalanceResponse (Ok response) ->
            ({ model | responses = response :: model.responses }, Cmd.none)
        ReceiveLoadBalanceResponse (Err _) ->
            (model, Cmd.none)
        Mdl msg_ ->
            Material.update Mdl msg_ model

