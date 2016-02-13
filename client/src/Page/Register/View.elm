module Page.Register.View where

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Form.Input as Input
import Form

import Model.Shared exposing (..)
import Model exposing (..)
import CoreExtra exposing (..)

import Page.Register.Model exposing (..)
import Page.Register.Update exposing (addr)

import View.Utils exposing (..)
import View.Layout as Layout


view : Context -> Model -> Html
view ctx model =
  Layout.layoutWithNav "register" ctx
    [ container ""
      [ h1 [] [ text "Register" ]
      , row [ col' 6 [ registerForm model ] ]
      ]
    ]

registerForm : Model -> Html
registerForm {form, loading, serverErrors} =
  let
    formAddr = Signal.forwardTo addr FormAction
    (submitClick, submitDisabled) =
      case Form.getOutput form of
        Just newPlayer ->
          (onClick addr (Submit newPlayer), not loading)
        Nothing ->
          (onClick formAddr Form.submit, Form.isSubmitted form)
    handle = Form.getFieldAsString "handle" form
    email = Form.getFieldAsString "email" form
    password = Form.getFieldAsString "password" form
    getServerErrors field =
      Dict.get field serverErrors |> Maybe.withDefault []
  in
    div [ class "form-login form-horizontal" ]

      [ fieldGroup "Handle" "Alphanumeric, at least 4 chars"
          (errList handle.liveError ++ (getServerErrors "handle") )
          [ Input.textInput handle formAddr [ class "form-control" ] ]

      , fieldGroup "Email" ""
          (errList email.liveError ++ (getServerErrors "email"))
          [ Input.textInput email formAddr [ class "form-control" ] ]

      , fieldGroup "Password" ""
          (errList password.liveError)
          [ Input.passwordInput password formAddr [ class "form-control" ] ]

      , actionGroup
        [ button
          [ class "btn btn-primary"
          , submitClick
          -- , disabled submitDisabled
          ]
          [ text "Submit" ]
        ]
      ]

