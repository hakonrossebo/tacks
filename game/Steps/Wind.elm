module Steps.Wind where

import Game (..)
import Geo (..)
import Core (..)

import Maybe as M
import List as L


type alias GustEffect =
  { origin: Float
  , speed: Float
  , factor: Float
  }


shadowImpact = -5 -- knots
shadowArc = 30 -- degrees


windStep : GameState -> PlayerState -> PlayerState
windStep ({wind,course,opponents} as gameState) state =
  let
    shadowDirection = ensure360 (state.windOrigin + 180 + (state.windAngle / 3))

    gustsOnPlayer = L.filter (\g -> (distance state.position g.position) < g.radius) wind.gusts
    gustsEffects = L.map (gustEffect state wind) gustsOnPlayer
    windShadow =
      L.filter (isShadowedBy state course.windShadowLength) opponents
      |> L.map (\_ -> shadowImpact)
      |> L.sum

    origin =
      if L.isEmpty gustsEffects then
        wind.origin
      else
        let totalEffect = L.map (\g -> g.origin * g.factor) gustsEffects |> L.sum
        in  ensure360 (wind.origin + totalEffect)

    speed = wind.speed + (L.map (\g -> g.speed * g.factor) gustsEffects |> L.sum) + windShadow
  in
    { state
      | windOrigin <- origin
      , windSpeed <- speed
      , shadowDirection <- shadowDirection
    }


gustEffect : PlayerState -> Wind -> Gust -> GustEffect
gustEffect state wind gust =
  let
    d = distance state.position gust.position
    fromEdge = gust.radius - d
    factor = L.minimum [fromEdge / (gust.radius * 0.2), 1]

    originEffect = angleDelta gust.angle wind.origin
    speedEffect = gust.speed
  in
    { origin = originEffect
    , speed = speedEffect
    , factor = factor
    }


isShadowedBy : PlayerState -> Float -> PlayerState -> Bool
isShadowedBy state shadowLength opponent =
  (distance opponent.position state.position) <= shadowLength &&
    let
      angle = angleBetween opponent.position state.position
      (min, max) = windShadowSector opponent
    in
      inSector min max angle


windShadowSector : PlayerState -> (Float,Float)
windShadowSector state =
  let
    d = state.windOrigin + 180 + (state.windAngle / 3)
  in
    (ensure360 (d - shadowArc/2), ensure360 (d + shadowArc/2))
