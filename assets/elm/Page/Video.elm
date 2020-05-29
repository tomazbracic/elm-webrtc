port module Page.Video exposing (Model, Msg, init, subscriptions, update, view)

import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes as Attrs
import Html.Events exposing (onClick)
import Html.Keyed exposing (node)
import Json.Encode as Encode exposing (Value)
import OrderedSet exposing (OrderedSet)
import Route


port enterRoom : String -> Cmd msg


port leaveRoom : Bool -> Cmd msg


port remotePeerReadyToStream : { id : String, stream : Value } -> Cmd msg


port remotePeerJoined : ({ id : String, stream : Value } -> msg) -> Sub msg


port remotePeerLeft : (String -> msg) -> Sub msg


type alias Model =
    { peers : OrderedSet String
    , navKey : Nav.Key
    }


init : String -> Nav.Key -> ( Model, Cmd Msg )
init room navKey =
    ( { peers = OrderedSet.empty
      , navKey = navKey
      }
    , enterRoom room
    )


type Msg
    = Disconnect
    | PeerJoined { id : String, stream : Value }
    | PeerLeft String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Disconnect ->
            ( { model
                | peers = OrderedSet.empty
              }
            , Cmd.batch [ leaveRoom True, Route.pushUrl Route.Search model.navKey ]
            )

        PeerJoined { id, stream } ->
            ( { model
                | peers = OrderedSet.insert id model.peers
              }
            , remotePeerReadyToStream { id = id, stream = stream }
            )

        PeerLeft peerId ->
            ( { model
                | peers = OrderedSet.remove peerId model.peers
              }
            , Cmd.none
            )


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ remotePeerJoined PeerJoined
        , remotePeerLeft PeerLeft
        ]


view : Model -> Html Msg
view model =
    div
        [ Attrs.class "room"
        ]
        [ if OrderedSet.isEmpty model.peers then
            div [ Attrs.class "empty" ]
                [ p
                    [ Attrs.class "empty__message" ]
                    [ text "There are no users in this room right now." ]
                ]

          else
            Html.Keyed.node "div" [ Attrs.class "peers" ] (peerVideos model.peers)
        , div [ Attrs.class "user" ]
            [ userVideo "local-camera"
                True
                ""
                "user__video"
            , div [ Attrs.class "chat" ] []
            ]
        , button
            [ Attrs.class "room__disconnect"
            , onClick Disconnect
            ]
            [ text "Disconnect" ]
        ]


userVideo : String -> Bool -> String -> String -> Html Msg
userVideo userId muted uuid class =
    video
        [ Attrs.id userId
        , Attrs.autoplay True
        , Attrs.loop True
        , Attrs.attribute "playsinline" "playsinline"
        , Attrs.property "muted" (Encode.bool muted)
        , Attrs.attribute "data-UUID" uuid
        , Attrs.autoplay True
        , Attrs.class class
        ]
        [ source
            [ Attrs.src ""
            , Attrs.type_ "video/mp4"
            ]
            []
        ]


generateRemoteUserId : Int -> String
generateRemoteUserId index =
    "remote-peer-" ++ String.fromInt index


peerClass : Int -> String
peerClass numberOfPeers =
    if numberOfPeers == 1 then
        "peers__video--xl"

    else if numberOfPeers == 2 then
        "peers__video--lg"

    else if numberOfPeers <= 4 then
        "peers__video--md"

    else if numberOfPeers <= 9 then
        "peers__video--sm"

    else
        "peers__video--xs"


peerVideos : OrderedSet String -> List ( String, Html Msg )
peerVideos peers =
    let
        class =
            OrderedSet.size peers |> peerClass
    in
    peers
        |> OrderedSet.toList
        |> List.indexedMap
            (\index ->
                \peer ->
                    ( peer
                    , userVideo
                        (generateRemoteUserId index)
                        False
                        peer
                        ("peers__video " ++ class)
                    )
            )