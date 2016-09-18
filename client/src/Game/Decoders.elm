module Game.Decoders exposing (..)

import Json.Decode as Json exposing (..)
import Decoders exposing (..)
import Page.Game.Model exposing (..)
import Page.Game.Chat.Model as Chat
import Game.Models exposing (..)
import Game.Inputs exposing (RaceInput)


raceInputDecoder : Decoder RaceInput
raceInputDecoder =
    object8
        RaceInput
        ("serverTime" := float)
        ("startTime" := maybe float)
        ("wind" := windDecoder)
        ("opponents" := list opponentDecoder)
        ("ghosts" := list ghostDecoder)
        ("tallies" := list playerTallyDecoder)
        ("initial" := bool)
        ("clientTime" := float)


windDecoder : Decoder Wind
windDecoder =
    object4
        Wind
        ("origin" := float)
        ("speed" := float)
        ("gusts" := list gustDecoder)
        ("gustCounter" := int)


gustDecoder : Decoder Gust
gustDecoder =
    object6
        Gust
        ("position" := pointDecoder)
        ("angle" := float)
        ("speed" := float)
        ("radius" := float)
        ("maxRadius" := float)
        ("spawnedAt" := float)


ghostDecoder : Decoder Ghost
ghostDecoder =
    object5
        Ghost
        ("position" := pointDecoder)
        ("heading" := float)
        ("id" := string)
        ("handle" := maybe string)
        ("gates" := list float)


opponentDecoder : Decoder Opponent
opponentDecoder =
    object2
        Opponent
        ("player" := playerDecoder)
        ("state" := opponentStateDecoder)


opponentStateDecoder : Decoder OpponentState
opponentStateDecoder =
    object8 OpponentState
        ("time" := float)
        ("position" := pointDecoder)
        ("heading" := float)
        ("velocity" := float)
        ("windAngle" := float)
        ("windOrigin" := float)
        ("shadowDirection" := float)
        ("crossedGates" := list float)
