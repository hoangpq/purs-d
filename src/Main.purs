module Main where

import Prelude
import Data.Argonaut (encodeJson, fromString, stringify, toObject)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), Replacement(..), replace)
import Data.Tuple (Tuple(..))
import Deno as Deno
import Deno.Dotenv as Dotenv
import Deno.Http (Response, createResponse, hContentTypeHtml, hContentTypeJson, serveListener)
import Deno.Http.Request (Request)
import Deno.Http.Request as Request
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Console (log)
import Foreign.Object as Object
import Router (Router, Context, makeRouter)
import Router as Router
import Router.Method (Method)
import Router.Method as Method
import Data.Argonaut.Encode.Class (encodeJson)

type AppRouter
  = Router ()

type AppContext
  = Context ()

requestToContext :: Request -> {}
requestToContext _req = {}

requestToMethod :: Request -> Method
requestToMethod = fromMaybe Method.GET <<< Method.fromString <<< Request.method

main :: Effect Unit
main = do
  log "🍝"
  e <-
    Dotenv.configSync $ Just
      $ { export: Just true
        , allowEmptyValues: Nothing
        , defaults: Nothing
        , example: Nothing
        , path: Nothing
        , safe: Nothing
        }
  let
    baseUrl = fromMaybe "http://localhost:3456" $ (\_ -> Nothing) $ e

    routes =
      Map.fromFoldable
        [ Tuple
            ( Router.makeRoute
                { path: "/", methods: [ Method.GET ]
                }
            )
            indexRoute,
          Tuple
            ( Router.makeRoute
                { path: "/json", methods: [ Method.GET ]
                }
            )
            jsonEcho
        ]

    router =
      makeRouter
        { routes
        , fallbackResponse: (pure $ createResponse "Not Found" (Just { headers: Just $ Map.fromFoldable [ Tuple "content-type" "text/plain" ], status: Just 404, statusText: Just "Not Found" }))
        , requestToPath: \req -> replace (Pattern baseUrl) (Replacement "") $ Request.url req
        , requestToContext
        , requestToMethod
        }

    handler = Router.route router
  listener <- Deno.listen { port: 3456 }
  launchAff_ $ serveListener listener handler Nothing

indexRoute :: Request → AppContext -> Aff Response
indexRoute _req _ctx =
  let
    payload =
      """<h1 style="color:red;">Hello World!</h1>"""
    headers = Just $ Map.fromFoldable [ hContentTypeHtml ]
    status = Just 200
    statusText = Just "OK"
  in
    pure $ createResponse payload $ Just { headers, status: status, statusText: statusText }

jsonEcho :: Request → AppContext -> Aff Response
jsonEcho req { params } = do
  -- payload <- Request.json req
  -- payload <- pure $ Object.fromFoldable [Tuple "hello" "world"]
  let
    headers = Just $ Map.fromFoldable [ hContentTypeJson ]
    response_options = Just { headers, status: Nothing, statusText: Nothing }
    -- encode json, decode json
    payloadAsObject = fromMaybe Object.empty $ Just $ Object.fromFoldable [Tuple "hello" "world"]
  pure $ createResponse (stringify $ encodeJson $ payloadAsObject) response_options
