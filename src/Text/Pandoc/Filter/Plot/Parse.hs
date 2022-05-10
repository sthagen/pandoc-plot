{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

-- |
-- Module      : $header$
-- Copyright   : (c) Laurent P René de Cotret, 2019 - present
-- License     : GNU GPL, version 2 or above
-- Maintainer  : laurent.decotret@outlook.com
-- Stability   : internal
-- Portability : portable
--
-- This module defines types and functions that help
-- with keeping track of figure specifications
module Text.Pandoc.Filter.Plot.Parse
  ( plotToolkit,
    parseFigureSpec,
    ParseFigureResult (..),
    captionReader,
  )
where

import Control.Monad (join, unless, when)
import Data.Char (isSpace)
import Data.Default (def)
import Data.List (find, intersperse)
import qualified Data.Map.Strict as Map
import Data.Maybe (fromJust, fromMaybe, isJust)
import Data.String (fromString)
import Data.Text (Text, pack, unpack)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.Version (showVersion)
import Paths_pandoc_plot (version)
import System.FilePath (makeValid, normalise)
import Text.Pandoc.Class (runPure)
import Text.Pandoc.Definition
  ( Block (..),
    Format (..),
    Inline,
    Pandoc (..),
  )
import Text.Pandoc.Filter.Plot.Monad
import Text.Pandoc.Filter.Plot.Renderers
import Text.Pandoc.Options (ReaderOptions (..))
import Text.Pandoc.Readers (Reader (..), getReader)

tshow :: Show a => a -> Text
tshow = pack . show

data ParseFigureResult
  -- | The block is not meant to become a figure
  = NotAFigure
  -- | The block is meant to become a figure
  | Figure FigureSpec
  -- | The block is meant to become a figure, but the plotting toolkit is missing
  | MissingToolkit Toolkit
  -- | The block is meant to become a figure, but the figure format is incompatible 
  --   with the plotting toolkit
  | UnsupportedSaveFormat Toolkit SaveFormat

-- | Determine inclusion specifications from @Block@ attributes.
-- If an environment is detected, but the save format is incompatible,
-- an error will be thrown.
parseFigureSpec :: Block -> PlotM ParseFigureResult
parseFigureSpec block@(CodeBlock (id', classes, attrs) _) = do
  -- The following would be a good case for the use of MaybeT
  -- but I don't want to bring in another dependency
  let mtk = plotToolkit block
  case mtk of
    Nothing -> return NotAFigure
    Just tk -> do
      r <- renderer tk
      case r of
        Nothing -> do
          err $ mconcat ["Renderer for ", tshow tk, " needed but is not installed"]
          return $ MissingToolkit tk
        Just r' -> figureSpec r'
  where
    attrs' = Map.fromList attrs
    preamblePath = unpack <$> Map.lookup (tshow PreambleK) attrs'

    figureSpec :: Renderer -> PlotM ParseFigureResult
    figureSpec renderer_@Renderer {..} = do
      conf <- asks envConfig
      let toolkit = rendererToolkit
          saveFormat = maybe (defaultSaveFormat conf) (fromString . unpack) (Map.lookup (tshow SaveFormatK) attrs')

      -- Check if the saveformat is compatible with the toolkit
      if not (saveFormat `elem` rendererSupportedSaveFormats) 
        then do
          err $ pack $ mconcat ["Save format ", show saveFormat, " not supported by ", show toolkit]
          return $ UnsupportedSaveFormat toolkit saveFormat
        else do
          let extraAttrs' = parseExtraAttrs toolkit attrs'
              header = rendererComment $ "Generated by pandoc-plot " <> (pack . showVersion) version
              defaultPreamble = preambleSelector toolkit conf

          includeScript <-
            maybe
              (return defaultPreamble)
              (liftIO . TIO.readFile)
              preamblePath
          let -- Filter attributes that are not relevant to pandoc-plot
              -- This presumes that inclusionKeys includes ALL possible keys, for all toolkits
              filteredAttrs = filter (\(k, _) -> k `notElem` (tshow <$> inclusionKeys)) attrs
              defWithSource = defaultWithSource conf
              defDPI = defaultDPI conf

          -- Decide between reading from file or using document content
          content <- parseContent block
          
          defaultExe <- fromJust <$> (executable rendererToolkit)

          let caption = Map.findWithDefault mempty (tshow CaptionK) attrs'
              fsExecutable = maybe defaultExe (exeFromPath . unpack) $ Map.lookup (tshow ExecutableK) attrs'
              withSource = maybe defWithSource readBool (Map.lookup (tshow WithSourceK) attrs')
              script = mconcat $ intersperse "\n" [header, includeScript, content]
              directory = makeValid $ unpack $ Map.findWithDefault (pack $ defaultDirectory conf) (tshow DirectoryK) attrs'
              dpi = maybe defDPI (read . unpack) (Map.lookup (tshow DpiK) attrs')
              extraAttrs = Map.toList extraAttrs'
              blockAttrs = (id', filter (/= cls toolkit) classes, filteredAttrs)

          let blockDependencies = parseFileDependencies $ fromMaybe mempty $ Map.lookup (tshow DependenciesK) attrs'
              dependencies = defaultDependencies conf <> blockDependencies

          -- This is the first opportunity to check save format compatibility
          _' <-
            unless (saveFormat `elem` rendererSupportedSaveFormats) $
              let msg = pack $ mconcat ["Save format ", show saveFormat, " not supported by ", show toolkit]
              in err msg
          
          -- Ensure that the save format makes sense given the final conversion format, if known
          return $ Figure (FigureSpec {..})
-- Base case: block is not a CodeBlock
parseFigureSpec _ = return NotAFigure

-- | Parse script content from a block, if possible.
-- The script content can either come from a file
-- or from the code block itself. If both are present,
-- the file is preferred.
parseContent :: Block -> PlotM Script
parseContent (CodeBlock (_, _, attrs) content) = do
  let attrs' = Map.fromList attrs
      mfile = normalise . unpack <$> Map.lookup (tshow FileK) attrs'
  when (content /= mempty && isJust mfile) $ do
    warning $
      mconcat
        [ "Figure refers to a file (",
          pack $ fromJust mfile,
          ") but also has content in the document.\nThe file content will be preferred."
        ]
  let loadFromFile fp = do
        info $ "Loading figure content from " <> pack fp
        liftIO $ TIO.readFile fp
  maybe (return content) loadFromFile mfile
parseContent _ = return mempty

-- | Determine which toolkit should be used to render the plot
-- from a code block, if any.
plotToolkit :: Block -> Maybe Toolkit
plotToolkit (CodeBlock (_, classes, _) _) =
  find (\tk -> cls tk `elem` classes) toolkits
plotToolkit _ = Nothing

-- | Reader a caption, based on input document format
captionReader :: Format -> Text -> Maybe [Inline]
captionReader (Format f) t = either (const Nothing) (Just . extractFromBlocks) $
  runPure $ do
    (reader, exts) <- getReader f
    let readerOpts = def {readerExtensions = exts}
    -- Assuming no ByteString readers...
    case reader of
      TextReader fct -> fct readerOpts t
      _ -> return mempty
  where
    extractFromBlocks (Pandoc _ blocks) = mconcat $ extractInlines <$> blocks

    extractInlines (Plain inlines) = inlines
    extractInlines (Para inlines) = inlines
    extractInlines (LineBlock multiinlines) = join multiinlines
    extractInlines _ = []

-- | Flexible boolean parsing
readBool :: Text -> Bool
readBool s
  | s `elem` ["True", "true", "'True'", "'true'", "1"] = True
  | s `elem` ["False", "false", "'False'", "'false'", "0"] = False
  | otherwise = errorWithoutStackTrace $ unpack $ mconcat ["Could not parse '", s, "' into a boolean. Please use 'True' or 'False'"]

-- | Parse a list of file dependencies such as /[foo.bar, hello.txt]/.
parseFileDependencies :: Text -> [FilePath]
parseFileDependencies t
  | t == mempty = mempty
  | otherwise =
    fmap (normalise . unpack . T.dropAround isSpace)
      . T.splitOn ","
      . T.dropAround (\c -> c `elem` ['[', ']'])
      $ t
