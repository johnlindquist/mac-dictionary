// dictionary.mm

#include <napi.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

using namespace Napi;

Value Method(const CallbackInfo& info) {
    Env env = info.Env();

    if (info.Length() < 1) {
        TypeError::New(env, "Wrong number of arguments").ThrowAsJavaScriptException();
        return env.Null();
    }

    if (!info[0].IsString()) {
        TypeError::New(env, "Argument must be a string").ThrowAsJavaScriptException();
        return env.Null();
    }

    String utf8_value = info[0].As<String>();
    NSString *inputWord = [NSString stringWithUTF8String:utf8_value.Utf8Value().c_str()];
    NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];

    // Initialize a JavaScript array
    Array results = Array::New(env);
    int i = 0;

    // Fetch the definition for the original word and insert it into the results array
    NSString *definition = (__bridge_transfer NSString*)DCSCopyTextDefinition(NULL, (__bridge CFStringRef)inputWord, CFRangeMake(0, [inputWord length]));

    if (definition) {
        Object entry = Object::New(env);
        entry.Set(String::New(env, "suggestion"), String::New(env, [inputWord UTF8String]));
        entry.Set(String::New(env, "definition"), String::New(env, [definition UTF8String]));

        results[i] = entry;
        i++;
    }

    NSArray *suggestions = [spellChecker guessesForWordRange:NSMakeRange(0, [inputWord length]) 
                                                   inString:inputWord 
                                                   language:@"en_US" 
                                                     inSpellDocumentWithTag:0];

    for (NSString *suggestedWord in suggestions) {
        NSString *suggestedDefinition = (__bridge_transfer NSString*)DCSCopyTextDefinition(NULL, (__bridge CFStringRef)suggestedWord, CFRangeMake(0, [suggestedWord length]));

        // Check if definition exists, if not, set to a default value
        if (!suggestedDefinition) {
            suggestedDefinition = @"Definition not found.";
        }

        // Create a JavaScript object directly
        Object entry = Object::New(env);
        entry.Set(String::New(env, "suggestion"), String::New(env, [suggestedWord UTF8String]));
        entry.Set(String::New(env, "definition"), String::New(env, [suggestedDefinition UTF8String]));

        results[i] = entry;
        i++;
    }

    return results; // Return the JavaScript array directly
}

Object Init(Env env, Object exports) {
    exports.Set(String::New(env, "lookup"), Function::New(env, Method));
    return exports;
}

NODE_API_MODULE(addon, Init)
