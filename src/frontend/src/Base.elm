module Base exposing (PodInfo, CommonModel)

-- MODEL

type alias PodInfo =
    { name: String
    , uid: String
    , app: String
    , status: String
    , podIP: String
    }

type alias CommonModel = {
    podList: List PodInfo
}

-- INIT


