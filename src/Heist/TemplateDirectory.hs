{-# LANGUAGE FlexibleContexts #-}
{-|

This module defines a TemplateDirectory data structure for convenient
interaction with templates within web apps.

-}

module Heist.TemplateDirectory
    ( TemplateDirectory
    , newTemplateDirectory
    , newTemplateDirectory'

    , getDirectoryHS
    , getDirectoryCTS
    , reloadTemplateDirectory
    ) where

------------------------------------------------------------------------------
import           Control.Concurrent
import           Control.Error
import           Control.Monad
import           Control.Monad.Trans
import           Control.Monad.Trans.Control
import           Heist
import           Heist.Splices.Cache


------------------------------------------------------------------------------
-- | Structure representing a template directory.
data TemplateDirectory n
    = TemplateDirectory
        FilePath
        (HeistConfig n)
        (MVar (HeistState n))
        (MVar CacheTagState)


------------------------------------------------------------------------------
-- | Creates and returns a new 'TemplateDirectory' wrapped in an Either for
-- error handling.
newTemplateDirectory :: (MonadIO n, MonadBaseControl IO n)
                     => FilePath
                     -> HeistConfig n
                     -> EitherT [String] IO (TemplateDirectory n)
newTemplateDirectory dir hc = do
    templates <- loadTemplates dir
    let hc' = hc { hcTemplates = templates }
    (hs,cts) <- initHeistWithCacheTag hc'
    tsMVar <- liftIO $ newMVar hs
    ctsMVar <- liftIO $ newMVar cts
    return $ TemplateDirectory dir hc' tsMVar ctsMVar


------------------------------------------------------------------------------
-- | Creates and returns a new 'TemplateDirectory', using the monad's fail
-- function on error.
newTemplateDirectory' :: (MonadIO n, MonadBaseControl IO n)
                      => FilePath
                      -> HeistConfig n
                      -> IO (TemplateDirectory n)
newTemplateDirectory' dir hc = do
    res <- runEitherT $ newTemplateDirectory dir hc
    either (error . concat) return res


------------------------------------------------------------------------------
-- | Gets the 'HeistState' from a TemplateDirectory.
getDirectoryHS :: (MonadIO n)
               => TemplateDirectory n
               -> IO (HeistState n)
getDirectoryHS (TemplateDirectory _ _ tsMVar _) =
    liftIO $ readMVar $ tsMVar


------------------------------------------------------------------------------
-- | Clears the TemplateDirectory's cache tag state.
getDirectoryCTS :: TemplateDirectory n -> IO CacheTagState
getDirectoryCTS (TemplateDirectory _ _ _ ctsMVar) = readMVar ctsMVar


------------------------------------------------------------------------------
-- | Clears cached content and reloads templates from disk.
reloadTemplateDirectory :: (MonadIO n, MonadBaseControl IO n)
                        => TemplateDirectory n
                        -> IO (Either String ())
reloadTemplateDirectory (TemplateDirectory p hc tsMVar ctsMVar) = do
    ehs <- runEitherT $ do
        templates <- loadTemplates p
        initHeistWithCacheTag (hc { hcTemplates = templates })
    leftPass ehs $ \(hs,cts) -> do
        modifyMVar_ tsMVar (const $ return hs)
        modifyMVar_ ctsMVar (const $ return cts)


------------------------------------------------------------------------------
-- | Prepends an error onto a Left.
leftPass :: Monad m => Either [String] b -> (b -> m c) -> m (Either String c)
leftPass e m = either (return . Left . loadError . concat)
                      (liftM Right . m) e
  where
    loadError = (++) "Error loading templates: "
