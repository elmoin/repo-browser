module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onBlur)
import Http
import Task
import Dict exposing (Dict)
import Json.Decode as Json exposing (Decoder)
import Json.Decode.Pipeline as Json
import Native.Blorgh


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


type alias CoolHeaders =
    Dict String String


type alias Model =
    { input : String
    , repos : List Repo
    , headers : CoolHeaders
    }


type Msg
    = UpdateQuery String
    | UpdateRepos (Result Http.Error ( List Repo, CoolHeaders ))
    | SubmitQuery


initialModel : Model
initialModel =
    { input = readFromLocalStorage |> Maybe.withDefault ""
    , repos = []
    , headers = Dict.empty
    }


readFromLocalStorage : Maybe String
readFromLocalStorage =
    Native.Blorgh.readFromLocalStorage "foo" "bar"


storeInLocalStorage : String -> String
storeInLocalStorage =
    Native.Blorgh.storeInLocalStorage


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateQuery query ->
            ( { model | input = Native.Blorgh.storeInLocalStorage query }, Cmd.none )

        SubmitQuery ->
            ( model, send model )

        UpdateRepos (Ok ( repos, headers )) ->
            ( { model | repos = repos, headers = headers }, Cmd.none )

        UpdateRepos (Err error) ->
            let
                _ =
                    Debug.log "error: " error
            in
                ( model, Cmd.none )


send : Model -> Cmd Msg
send model =
    Task.attempt UpdateRepos <| repoTask model [] 1


repoTask : Model -> List Repo -> Int -> Task.Task Http.Error ( List Repo, CoolHeaders )
repoTask model prevRepos page =
    createRepoRequest model page
        |> Http.toTask
        |> Task.andThen
            (\( repos, headers ) ->
                if List.length repos == 0 then
                    Task.succeed ( prevRepos, headers )
                else
                    repoTask { model | headers = headers } (prevRepos ++ repos) (page + 1)
            )


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


createRepoRequest : Model -> Int -> Http.Request ( List Repo, CoolHeaders )
createRepoRequest model page =
    Http.request
        { method = "GET"
        , headers =
            model.headers
                |> Dict.toList
                |> List.filter
                    (\( name, _ ) -> name == "content-type")
                |> List.map
                    (\( name, content ) ->
                        Http.header name content
                    )
        , url = "https://api.github.com/users/" ++ model.input ++ "/repos?per_page=10&page=" ++ toString page
        , body = Http.emptyBody
        , expect = Http.expectStringResponse bodyDecoder
        , timeout = Nothing
        , withCredentials = False
        }


bodyDecoder : Http.Response String -> Result String ( List Repo, CoolHeaders )
bodyDecoder { headers, body } =
    Json.decodeString (Json.list coolRepoDecoder) body |> Result.map (\repos -> ( repos, headers ))


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
            , input
                [ value model.input
                , onInput UpdateQuery
                , onBlur SubmitQuery
                ]
                []
            , br [] []
            , text model.input
            , div [] (List.map repoView model.repos)
            ]
