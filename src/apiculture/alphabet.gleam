//// Alphabet representation and validation.
////
//// An alphabet is a validated set of graphemes for direct random character
//// sampling. It is deliberately separate from an encoding, which transforms
//// arbitrary bytes into text.

import apiculture/error.{type Error}
import gleam/list
import gleam/string

/// An alphabet is a character repertoire used for direct sampling.
/// This is distinct from an encoding, which transforms bytes to text.
pub type Alphabet {
  Alphabet(chars: String)
}

/// Creates a new alphabet from a string of characters.
///
/// Returns an error if the alphabet is empty, has only one character,
/// or contains duplicate characters.
pub fn new_alphabet(chars: String) -> Result(Alphabet, Error) {
  let char_list = string.to_graphemes(chars)

  case list.is_empty(char_list) {
    True -> Error(error.EmptyAlphabet)
    False -> {
      case list.length(char_list) {
        1 -> Error(error.SingleCharacterAlphabet)
        _ -> {
          case has_duplicates(char_list) {
            True -> Error(error.DuplicateCharacters)
            False -> Ok(Alphabet(chars: chars))
          }
        }
      }
    }
  }
}

/// Returns the characters in the alphabet as a list of graphemes.
pub fn characters(alphabet: Alphabet) -> List(String) {
  string.to_graphemes(alphabet.chars)
}

/// Returns the size (number of characters) in the alphabet.
pub fn size(alphabet: Alphabet) -> Int {
  string.length(alphabet.chars)
}

fn has_duplicates(items: List(String)) -> Bool {
  case items {
    [] -> False
    [first, ..rest] -> {
      case list.contains(rest, first) {
        True -> True
        False -> has_duplicates(rest)
      }
    }
  }
}
