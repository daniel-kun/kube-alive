module LoadBalancing exposing (Model, Msg(ExecLoadBalanceTest, ReceiveLoadBalanceResponse), init, update, view)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http exposing (get, send)
import List.Extra

-- MODEL

type alias Model =
    { responses: List String
    }

-- MSG

type Msg =
      ExecLoadBalanceTest 
    | ReceiveLoadBalanceResponse (Result Http.Error String)

type alias Container c = {
    c | loadBalancing : Model
}

-- FUNCTIONS

init = Model []


renderLoadBalancing : Model -> { name: String, status: String, app: String, podIP: String } -> Html msg
renderLoadBalancing loadBalancing pod =
    tr [] [
        td [] [text <| pod.name ],
        td [] [text <| pod.status ],
        td [] [text <| toString (List.Extra.count (\n -> n == pod.podIP) loadBalancing.responses), text <| " responses" ]
    ]

view : (Msg -> m) -> List { name: String, status: String, app: String, podIP: String } -> Model -> List (Html m)
view makeMsg podList loadBalancing =
    [
        h1 [] [ text "Example 1: Load-Balancing" ],
        button [ onClick (makeMsg ExecLoadBalanceTest) ] [text "Make 50 requests to getmac"],
        table [] (List.map (renderLoadBalancing loadBalancing) (List.filter (\n -> n.app == "getmac") podList))
    ]

update : (Msg -> msg) -> Msg -> Container c -> (Container c, Cmd msg)
update makeMsg msg model =
    case msg of
        ExecLoadBalanceTest ->
            (model, Cmd.batch (List.repeat 50 (Http.send (\m -> makeMsg (ReceiveLoadBalanceResponse m)) (Http.getString "http://192.168.178.80:83/getmac"))))
        ReceiveLoadBalanceResponse (Ok response) ->
            let
                loadBalancing = model.loadBalancing
            in
                ({ model | loadBalancing = { loadBalancing | responses = response :: loadBalancing.responses }}, Cmd.none)
        ReceiveLoadBalanceResponse (Err _) ->
            (model, Cmd.none)
