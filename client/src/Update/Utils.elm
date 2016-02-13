module Update.Utils where

import Effects exposing (Effects)
import TransitRouter

import Route
import Model exposing (appActionsAddress)
import Model.Shared exposing (..)


redirect : Route.Route -> Effects ()
redirect route =
  Route.toPath route
    |> Signal.send TransitRouter.pushPathAddress
    |> Effects.task

setPlayer : Player -> Effects ()
setPlayer player =
  Model.SetPlayer player
    |> Signal.send appActionsAddress
    |> Effects.task

always : action -> Effects a -> Effects action
always action effect =
  Effects.map (\_ -> action) effect

pageAddr : (action -> Model.PageAction) -> Signal.Address action
pageAddr toPageAction =
  Signal.forwardTo appActionsAddress (toPageAction >> Model.PageAction)
