module AutoScaling exposing (Model, Msg, init, view, update)

import Base exposing (..)
import Html exposing (Html, h1, text, table, tr, td, button, div, p)
import Html.Events exposing (onClick)
import Http
import String.Format exposing (format1)
import Material
import Material.List as Lists
import Material.Grid as Grid
import Material.Color as Color
import Material.Options as Options
import Material.Typography as Typo


-- MODEL

type alias Model = {
    mdl : Material.Model,
    originHost: String,
    isRunning: Bool,
    finishedRequests: Int
}

-- MSG

type Msg =
      StartLoadGenerator
    | StopLoadGenerator
    | ContinueLoadGenerator (Result Http.Error String)
    | Mdl (Material.Msg Msg)

-- FUNCTIONS

init originHost = Model Material.model originHost False 0


renderPod : Model -> CommonModel -> PodInfo -> Html Msg
renderPod model commonModel pod =
    Lists.li [ Lists.withSubtitle ] [
        Lists.content [] [
            text (format1 "Pod {1}" pod.name),
            Lists.subtitle [] [ text (getPodState pod commonModel) ]
            ]
        ]

renderButtons : Model -> List (Grid.Cell Msg)
renderButtons model =
    if (model.isRunning) then
    [
        renderButtonCell 5 model Mdl StopLoadGenerator "Stop load generator",
        Grid.cell [ Grid.size Grid.All 4 ] [ text (String.Format.format1 "{1} requests finished" model.finishedRequests) ]
    ]
    else
    [
        renderButtonCell 6 model Mdl StartLoadGenerator "Start load generator"
    ]

view : CommonModel -> Model -> List (Html Msg)
view commonModel model =
    [ Options.styled h1 [ Color.text Color.primary ] [ text "Experiment #4: Auto-Scaling" ]
    , Options.styled p
        [ Typo.body1 ]
        [ text "In this experiment, you can hammer requests to the service and see how Kubernetes allocates new Pods, potentially on different nodes, to serve the requests faster." ]
    , Grid.grid [] 
          (renderButtons model)
        , (Lists.ul [] (List.map (renderPod model commonModel) (List.filter (\n -> n.app == "cpuhog") commonModel.podList)))
    ]

makeLoadGeneratorRequest originHost = 
        Http.send (\n -> ContinueLoadGenerator n) (Http.getString (format1 "http://{1}/cpuhog" originHost))

-- The load generator fires two requests at once, because a single request would only occupy two nodes
makeLoadGeneratorRequests originHost = 
    Cmd.batch [
        makeLoadGeneratorRequest originHost,
        makeLoadGeneratorRequest originHost 
    ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        StartLoadGenerator ->
            ({ model | isRunning = True }, makeLoadGeneratorRequests model.originHost)
        StopLoadGenerator ->
            ({ model | isRunning = False, finishedRequests = 0 }, Cmd.none)
        ContinueLoadGenerator _ ->
            if (model.isRunning) then
                ({ model | finishedRequests = model.finishedRequests + 1 }, makeLoadGeneratorRequests model.originHost)
            else
                (model, Cmd.none)
        Mdl msg_ ->
            Material.update Mdl msg_ model

