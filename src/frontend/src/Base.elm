module Base exposing (PodInfo, CommonModel)

import Material

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
    , mdl : Material.Model
}

-- INIT


