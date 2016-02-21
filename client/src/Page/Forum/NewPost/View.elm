module Page.Forum.NewPost.View where

import Signal exposing (Address)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Page.Forum.NewPost.Model exposing (..)

import View.Utils exposing (..)


view : Address Action -> Model -> Html
view addr {content} =
  div [ class "form-new-post form-vertical" ]
    [ div [ class "form-group" ]
      [ textarea
        [ class "form-control"
        , value content
        , onInput addr SetContent
        ]
        [  ]
      ]
    , div []
      [ button
        [ class "btn btn-primary"
        -- , disabled loading
        , onClick addr Submit
        ]
        [ text "Submit" ]
      ]
    ]