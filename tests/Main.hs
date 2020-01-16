{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP               #-}

import Control.Monad (forM_)

import Data.Text (unpack, Text)

import Test.Tasty
import Test.Tasty.HUnit

import Common
import Text.Pandoc.Filter.Plot.Internal

main :: IO ()
main = do
    available <- availableToolkits
    unavailable <- unavailableToolkits
    forM_ unavailable $ \tk -> do
        putStrLn $ show tk <> " is not availble. Its tests will be skipped."

    defaultMain $
        testGroup
            "General tests"
            (toolkitSuite <$> available)

-- | Suite of tests that every renderer should pass
toolkitSuite :: Toolkit -> TestTree
toolkitSuite tk = 
    testGroup (show tk) $ 
        [ testFileCreation
        , testFileInclusion
        ] <*> [tk]
