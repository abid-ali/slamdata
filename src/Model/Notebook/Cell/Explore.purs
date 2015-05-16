module Model.Notebook.Cell.Explore
  ( ExploreRec()
  , initialExploreRec
  , _input
  , _table
  ) where

import Model.Notebook.Cell.FileInput (FileInput(), initialFileInput)
import Model.Notebook.Cell.JTableContent (JTableContent(), initialJTableContent)
import Optic.Core (LensP(), lens)

newtype ExploreRec =
  ExploreRec { input :: FileInput
             , table :: JTableContent
             }

initialExploreRec :: ExploreRec
initialExploreRec =
  ExploreRec { input: initialFileInput
             , table: initialJTableContent
             }

_ExploreRec :: LensP ExploreRec _
_ExploreRec = lens (\(ExploreRec obj) -> obj) (const ExploreRec)

_input :: LensP ExploreRec FileInput
_input = _ExploreRec <<< lens _.input (_ { input = _ })

_table :: LensP ExploreRec JTableContent
_table = _ExploreRec <<< lens _.table (_ { table = _ })