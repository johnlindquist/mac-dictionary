import bindings from "bindings";
const addon = bindings("mac-dictionary.node");
export const lookup = (word) => {
    return addon.lookup(word);
};
