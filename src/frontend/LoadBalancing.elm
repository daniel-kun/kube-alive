module LoadBalancing exposing (LoadBalancingModel, view, init, Msg(ExecLoadBalanceTest, ReceiveLoadBalanceResponse))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http exposing (get, send)
import List.Extra

-- MSG

type Msg =
      ExecLoadBalanceTest 
    | ReceiveLoadBalanceResponse (Result Http.Error String)

-- MODEL

type alias LoadBalancingModel =
    { responses: List String
    }

-- FUNCTIONS

init = LoadBalancingModel []

renderLoadBalancingResponse : (String, Int) -> Html msg
renderLoadBalancingResponse response =
    tr [] [
        td [] [text <| Tuple.first response],
        td [] [text <| (Tuple.second response |> toString)]
    ]

responsesWithCount : List String -> List (String, Int)
responsesWithCount responses =
    List.map (\n -> (,) n (List.Extra.count ((==) n) responses)) (List.sort (List.Extra.unique responses))

view : (Msg -> m) -> List { name: String, uid: String, app: String, status: String } -> LoadBalancingModel -> Html m
view makeMsg podList loadBalancing =
    div [] [
        button [ onClick (makeMsg ExecLoadBalanceTest) ] [text "Make 50 requests to getmac"]
--        table [] (List.map renderPodRow ),
--        table [] (List.map renderLoadBalancingResponse (responsesWithCount loadBalancing.responses))
    ]

