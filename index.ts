import bindings from "bindings"
const addon = bindings("mac-dictionary.node")

export const lookup = (
  word: string
): {
  suggestion: string
  definition: string
}[] => {
  return addon.lookup(word)
}
