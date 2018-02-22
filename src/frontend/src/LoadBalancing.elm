module LoadBalancing exposing (Model, Msg(ExecLoadBalanceTest, ReceiveLoadBalanceResponse), init, update, view)
import Base exposing (PodInfo, CommonModel)
import String.Format exposing (format1)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http exposing (get, send)
import List.Extra

-- MODEL

type alias Model =
    { responses: List String,
      originHost: String
    }

-- MSG

type Msg =
      ExecLoadBalanceTest 
    | ReceiveLoadBalanceResponse (Result Http.Error String)

type alias Container c = {
    c | loadBalancing : Model
}

-- FUNCTIONS

init originHost = Model [] originHost


renderLoadBalancing : Model -> PodInfo  -> Html msg
renderLoadBalancing loadBalancing pod =
    tr [] [
        td [] [text <| pod.name ],
        td [] [text <| pod.status ],
        td [] [text <| toString (List.Extra.count (\n -> n == pod.podIP) loadBalancing.responses), text <| " responses" ]
    ]

view : (Msg -> msg) -> CommonModel -> Model -> List (Html msg)
view makeMsg commonModel loadBalancing =
    [
        h1 [] [ text "Experiment 1: Load-Balancing" ],
        button [ onClick (makeMsg ExecLoadBalanceTest) ] [text "Make 50 requests to getip"],
        table [] (List.map (renderLoadBalancing loadBalancing) (List.filter (\n -> n.app == "getip") commonModel.podList))
    ]

update : (Msg -> msg) -> Msg -> Container c -> (Container c, Cmd msg)
update makeMsg msg model =
    case msg of
        ExecLoadBalanceTest ->
            (model, Cmd.batch (List.repeat 50 (Http.send (\m -> makeMsg (ReceiveLoadBalanceResponse m)) (Http.getString (format1 "http://{1}/getip" model.loadBalancing.originHost)))))
        ReceiveLoadBalanceResponse (Ok response) ->
            let
                loadBalancing = model.loadBalancing
            in
                ({ model | loadBalancing = { loadBalancing | responses = response :: loadBalancing.responses }}, Cmd.none)
        ReceiveLoadBalanceResponse (Err _) ->
            (model, Cmd.none)

