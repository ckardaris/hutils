{-# LANGUAGE OverloadedStrings #-}

import qualified Data.ByteString.Lazy as BL
import Data.ByteString.Lazy.Char8 as C8
import Data.Char
import Options.Applicative
import System.IO

data Options
  = Options
      Bool -- show-all
      Bool -- number-nonblank
      Bool -- e
      Bool -- show-ends
      Bool -- number
      Bool -- squeeze-blank
      Bool -- t
      Bool -- show-tabs
      Bool -- u
      Bool -- show-nonprinting
      [String] -- input-files

options :: Parser Options
options =
  Options
    <$> switch
      ( long "show-all"
          <> short 'A'
          <> help "equivalent to -vET"
      )
    <*> switch
      ( long "number-nonblank"
          <> short 'b'
          <> help "number nonempty output lines, overrides -n"
      )
    <*> switch
      ( short 'e'
          <> help "equivalent to -vE"
      )
    <*> switch
      ( long "show-ends"
          <> short 'E'
          <> help "display $ at end of each line"
      )
    <*> switch
      ( long "number"
          <> short 'n'
          <> help "number all output lines"
      )
    <*> switch
      ( long "squeeze-blank"
          <> short 's'
          <> help "suppress repeated empty output lines"
      )
    <*> switch
      ( short 't'
          <> help "equivalent to -vT"
      )
    <*> switch
      ( long "show-tabs"
          <> short 'T'
          <> help "display TAB characters as ^I"
      )
    <*> switch
      ( short 'u'
          <> help "(ignored)"
      )
    <*> switch
      ( long "show-nonprinting"
          <> short 'v'
          <> help "use ^ and M- notation, except for LFD and TAB"
      )
    <*> many
      ( argument
          str
          (metavar "FILE")
      )

main :: IO ()
main = hcat =<< execParser opts
  where
    opts =
      info
        (options <**> helper)
        ( fullDesc
            <> progDesc
              "Concatenate FILE(s) to standard output. \
              \With no FILE, or when FILE is -, read standard input."
            <> header "hcat"
        )

-- show-ends
addDollar :: Bool -> BL.ByteString -> BL.ByteString
addDollar b string = if b then BL.snoc string (toEnum $ ord '$') else string

-- number
minNumberWidth :: Int
minNumberWidth = 6

rightAlign :: Int -> BL.ByteString
rightAlign n = C8.pack $ Prelude.replicate (minNumberWidth - Prelude.length (show n)) ' ' ++ show n ++ "\t"

addNumber :: Bool -> Bool -> Bool -> Int -> [BL.ByteString] -> [BL.ByteString]
addNumber False _ _ _ strings = strings
addNumber _ _ _ _ [] = []
addNumber True b ends n (x : xs) =
  if not b || not (isBlank x)
    then BL.append (rightAlign n) x : addNumber True b ends (n + 1) xs
    else x : addNumber True b ends n xs
  where
    isBlank :: ByteString -> Bool
    isBlank string = BL.null string || (ends && BL.length x == 1)

-- squeeze-blank
squeeze :: Bool -> [ByteString] -> [BL.ByteString]
squeeze False strings = strings
squeeze True [] = []
squeeze True [x] = [x]
squeeze True (x : xs) = if BL.null x && BL.null (Prelude.head xs) then squeeze True xs else x : squeeze True xs

---- show-tabs
tabstituteC :: Char -> BL.ByteString
tabstituteC '\t' = C8.pack "^I"
tabstituteC c = C8.pack [c]

tabstituteS :: BL.ByteString -> BL.ByteString
tabstituteS = C8.concatMap tabstituteC

tab :: Bool -> [BL.ByteString] -> [BL.ByteString]
tab bool strings = if bool then Prelude.map tabstituteS strings else strings

-- show-nonprinting
escapeC :: Char -> BL.ByteString
escapeC c
  | c == '\n' || c == '\t' = C8.pack [c]
  | ord c < 32 = C8.pack $ "^" ++ [chr $ ord c + 64]
  | ord c < 127 = C8.pack [c]
  | ord c == 127 = C8.pack "^?"
  | ord c < 160 = C8.pack $ "M-^" ++ [chr $ ord c - 128 + 64]
  | ord c < 255 = C8.pack $ "M-" ++ [chr $ ord c - 128]
  | otherwise = C8.pack "M-^?"

nonPrint :: Bool -> [BL.ByteString] -> [BL.ByteString]
nonPrint False = id
nonPrint True = Prelude.map $ C8.concatMap escapeC

-- concatenate input files
readFile :: String -> IO BL.ByteString
readFile s
  | s == "-" = BL.hGetContents stdin
  | otherwise = BL.readFile s

catFiles :: [String] -> IO BL.ByteString
catFiles [] = BL.hGetContents stdin
catFiles list = do
  files <- mapM Main.readFile list
  return (BL.concat files)

-- main
hcat :: Options -> IO ()
hcat (Options aCaps b e eCaps n s t tCaps _ v files) = do
  content <- catFiles files
  let lines_ = C8.lines content
  let squeezed = squeeze s lines_
  let tabbed = tab (aCaps || t || tCaps) squeezed
  let nonprinted = nonPrint (aCaps || e || t || v) tabbed
  let dollared = Prelude.map (addDollar (aCaps || e || eCaps)) nonprinted
  let numbered = addNumber (b || n) b (aCaps || e || eCaps) 1 dollared
  BL.putStr $ C8.unlines numbered
