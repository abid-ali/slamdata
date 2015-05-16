module Controller.Notebook.Cell.JTableContent
  ( goPage
  , stepPage
  , changePageSize
  , runJTable
  ) where

import Api.Query (query, sample)
import Control.Bind ((<=<))
import Control.Monad.Aff.Class (liftAff)
import Control.Monad.Eff.Class (liftEff)
import Control.Plus (empty)
import Controller.Notebook.Common (I())
import Data.Argonaut.Core (Json(), fromArray, toObject, toNumber)
import Data.Array (head)
import Data.Date (now)
import Data.Either (Either(..))
import Data.Foreign.Class (readJSON)
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Halogen.HTML.Events.Monad (andThen)
import Input.Notebook (Input(..), CellResultContent(..))
import Model.Notebook.Cell (Cell(), _JTableContent, _content, _cellId)
import Model.Resource (Resource())
import Optic.Core ((^.), (.~), (..))
import Optic.Extended (TraversalP(), (^?))

import qualified Model.Notebook.Cell.JTableContent as JTC
import qualified Data.Int as I
import qualified Data.Maybe.Unsafe as U
import qualified Data.StrMap as SM

goPage :: forall e. I.Int -> Cell -> (Cell -> I e) -> I e
goPage page cell run =
  ((RunCell (cell ^. _cellId)) <$> liftEff now) `andThen`
    \_ -> run (cell # _content .. _JTableContent .. JTC._page .~ page)

stepPage :: forall e. I.Int -> Cell -> (Cell -> I e) -> I e
stepPage delta cell run =
  let page :: I.Int
      page = maybe (I.fromNumber 1) (delta +) (cell ^? _content .. _JTableContent .. JTC._page)
  in ((RunCell (cell ^. _cellId)) <$> liftEff now) `andThen`
    \_ -> run (cell # _content .. _JTableContent .. JTC._page .~ page)

changePageSize :: forall e. Cell -> (Cell -> I e) -> String -> I e
changePageSize cell run value = case readJSON value of
  Left _ -> empty
  Right n ->
    ((RunCell (cell ^. _cellId)) <$> liftEff now) `andThen`
      \_ -> run (cell # (_content .. _JTableContent .. JTC._perPage .~ I.fromNumber n)
                     .. (_content .. _JTableContent .. JTC._page .~ one))

runJTable :: forall e. Resource -> Cell -> I e
runJTable file cell = fromMaybe empty $ do
  table <- cell ^? _content .. _JTableContent
  return $ do
    let perPage = table ^. JTC._perPage
        pageNumber = table ^. JTC._page
        pageIndex = pageNumber - I.fromNumber 1
    -- TODO: catch aff failures?
    numItems <- liftAff $ U.fromJust <<< readTotal <$> query file "SELECT COUNT(*) AS total FROM {{path}}"
    result <- liftAff $ sample file (pageIndex * perPage) perPage
    now' <- liftEff now
    return $ CellResult (cell ^. _cellId) now' $ Right $ JTableContent $
      JTC.JTableContent { perPage: perPage
                    , page: pageNumber
                    , result: Just $ JTC.Result
                        { totalPages: I.fromNumber $ Math.ceil (numItems / I.toNumber perPage)
                        , values: Just $ fromArray result
                        }
                    }
  where
  readTotal :: [Json] -> Maybe Number
  readTotal = toNumber <=< SM.lookup "total" <=< toObject <=< head