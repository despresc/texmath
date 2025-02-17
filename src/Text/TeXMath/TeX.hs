module Text.TeXMath.TeX (TeX(..),
                         renderTeX,
                         isControlSeq,
                         escapeLaTeX)
where
import Data.List (isPrefixOf)
import Data.Char (isLetter, isAlphaNum, isAscii)

-- | An intermediate representation of TeX math, to be used in rendering.
data TeX = ControlSeq String
         | Token Char
         | Literal String
         | Grouped [TeX]
         | Space
         deriving (Show, Eq)

-- | Render a 'TeX' to a string, appending to the front of the given string.
renderTeX :: TeX -> String -> String
renderTeX (Token c) cs     = c:cs
renderTeX (Literal s) cs
  | startsWith (not . isLetter)
               (reverse s) = s ++ cs
  | startsWith isLetter cs = s ++ (' ':cs)
  | otherwise              = s ++ cs
renderTeX (ControlSeq s) cs
  | s == "\\ "               = s ++ cs
  | startsWith (\c -> isAlphaNum c || not (isAscii c)) cs
                             = s ++ (' ':cs)
  | otherwise                = s ++ cs
renderTeX (Grouped [Grouped xs]) cs  = renderTeX (Grouped xs) cs
renderTeX (Grouped xs) cs     =
  '{' : foldr renderTeX "" (trimSpaces xs) ++ "}" ++ cs
renderTeX Space ""             = "" -- no need to end with space
renderTeX Space ('^':cs)       = '^':cs  -- no space before ^
renderTeX Space ('_':cs)       = '_':cs  -- no space before _
renderTeX Space (' ':cs)       = ' ':cs  -- no doubled up spaces
renderTeX Space cs
  | "\\limits" `isPrefixOf` cs = cs      -- no space before \limits
  | otherwise                  = ' ':cs

trimSpaces :: [TeX] -> [TeX]
trimSpaces = reverse . go . reverse . go
  where go = dropWhile (== Space)

startsWith :: (Char -> Bool) -> String -> Bool
startsWith p (c:_) = p c
startsWith _ []    = False

isControlSeq :: String -> Bool
isControlSeq ['\\',c] = c /= ' '
isControlSeq ('\\':xs) = all isLetter xs
isControlSeq _ = False

escapeLaTeX :: Char -> TeX
escapeLaTeX c =
  case c of
       '~'   -> ControlSeq "\\textasciitilde"
       '^'   -> Literal "\\textasciicircum"
       '\\'  -> ControlSeq "\\textbackslash"
       '\x200B' -> Literal "\\!"
       '\x200A' -> Literal "\\,"
       '\x2006' -> Literal "\\,"
       '\xA0'   -> Literal "~"
       '\x2005' -> Literal "\\:"
       '\x2004' -> Literal "\\;"
       '\x2001' -> ControlSeq "\\quad"
       '\x2003' -> ControlSeq "\\quad"
       '\x2032' -> Literal "'"
       '\x2033' -> Literal "''"
       '\x2034' -> Literal "'''"
       _ | c `elem` "#$%&_{} " -> Literal ("\\" ++ [c])
         | otherwise -> Token c
