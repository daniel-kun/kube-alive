module Base exposing (PodInfo, CommonModel, renderButtonCell)

import Material
import Material.Grid as Grid
import Material.Button as Button
import Material.Options as Options exposing (css)
import Html exposing (..)

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

-- FUNCTIONS


renderButtonCell index model makeMdl msg actionText =
    Grid.cell [ Grid.size Grid.All 4 ] [ 
        Button.render makeMdl [ index ] model.mdl [ Button.raised, Button.colored, Button.ripple, Options.onClick msg ] [ text actionText ]
    ]

