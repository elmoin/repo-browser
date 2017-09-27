module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import Json.Decode as Json exposing (Decoder)
import Json.Decode.Pipeline as Json


main : Program Never Model Msg



-- :  { init : (model, Cmd msg), update : msg -> model -> (model, Cmd msg), subscriptions : model -> Sub msg, view : model -> Html msg }
--    -> Program Never model msg


main =
    program
        { init = ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = \model -> Sub.none
        }


type alias Repo =
    { language : String
    , name : String
    , stargazersCount : Int
    }


type alias Model =
    { input : String
    , repos : List Repo
    }


type Msg
    = UpdateQuery String
    | UpdateRepos (Result Http.Error (List Repo))


initialModel : Model
initialModel =
    { input = ""
    , repos = []
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateQuery query ->
            ( { model | input = query }, send query )

        UpdateRepos (Ok repos) ->
            ( { model | repos = repos }, Cmd.none )

        UpdateRepos (Err error) ->
            let
                _ =
                    Debug.log "error: " error
            in
                ( model, Cmd.none )


send : String -> Cmd Msg
send user =
    Http.send UpdateRepos (createRepoRequest user)


repoDecoder : Decoder Repo
repoDecoder =
    Json.map3 Repo
        (Json.field "language" Json.string)
        (Json.field "name" Json.string)
        (Json.field "stargazers_count" Json.int)


coolRepoDecoder : Decoder Repo
coolRepoDecoder =
    Json.decode Repo
        |> Json.optional "language" Json.string "NA"
        |> Json.required "name" Json.string
        |> Json.required "stargazers_count" Json.int


createRepoRequest : String -> Http.Request (List Repo)
createRepoRequest user =
    Http.get ("https://api.github.com/users/" ++ user ++ "/repos") (Json.list coolRepoDecoder)


view : Model -> Html Msg
view model =
    let
        repoView repo =
            div []
                [ text repo.name
                , text " / "
                , text repo.language
                , text " / "
                , text <| toString repo.stargazersCount
                ]
    in
        div []
            [ text "Github User"
            , input [ value model.input, onInput UpdateQuery ] []
            , br [] []
            , text model.input
            , div [] (List.map repoView model.repos)
            ]
