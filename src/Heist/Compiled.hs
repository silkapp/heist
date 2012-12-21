{-|

Compiled splices are similar to the original Heist (interpreted) splices, but
without the high performance costs of traversing a DOM at runtime.  Compiled
splices do all of their DOM processing at load time.  They are compiled to
produce a runtime computation that generates a ByteString Builder.  This
preserves the ability to write splices that access runtime information from
the HTTP request, database, etc.

If you import both this module and "Heist.Interpreted" in the same file, then
you will need to import them qualified.

-}

module Heist.Compiled
  (
  -- * High level compiled splice API
    Splice
  , renderTemplate
  , mapPromises
  , promiseChildren
  , promiseChildrenWith
  , promiseChildrenWithTrans
  , promiseChildrenWithText
  , promiseChildrenWithNodes

  -- * Constructing Chunks
  -- $yieldOverview
  , yieldPure
  , yieldRuntime
  , yieldRuntimeEffect
  , yieldPureText
  , yieldRuntimeText
  , yieldLater
  , addSplices

  -- * Lower level promise functions
  , Promise
  , newEmptyPromise

  -- * RuntimeSplice functions
  , getPromise
  , putPromise
  , adjustPromise
  , codeGen
  , consolidate

  -- * Running nodes and splices
  , runNodeList
  , runNode
  , compileNode
  , runAttributes
  , runSplice

  ) where

import Heist.Compiled.Internal

-- $yieldOverview
-- The internals of the Chunk data type are deliberately not exported because
-- we want to hide the underlying implementation as much as possible.  The
-- @yield...@ functions give you lower lever construction of Chunks and DLists
-- of Chunks.
