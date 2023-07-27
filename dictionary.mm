// dictionary.mm

// Include headers required for the module
#include <napi.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

// N-API namespace usage for convenience
using namespace Napi;

// The method performing the main logic of the module
Value Method(const CallbackInfo& info) {
    // Get the execution environment
    Env env = info.Env();

    // Check for correct number of arguments
    if (info.Length() < 1) {
        // Throw a JavaScript TypeError
        TypeError::New(env, "Wrong number of arguments").ThrowAsJavaScriptException();
        return env.Null();
    }

    // Check for correct argument type
    if (!info[0].IsString()) {
        // Throw a JavaScript TypeError
        TypeError::New(env, "Argument must be a string").ThrowAsJavaScriptException();
        return env.Null();
    }

    // Extract the string from the arguments
    String utf8_value = info[0].As<String>();
    // Convert it to NSString for further processing
    NSString *inputWord = [NSString stringWithUTF8String:utf8_value.Utf8Value().c_str()];

    // Create an instance of NSSpellChecker
    NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];

    // Get suggestions for the word
    NSArray *suggestions = [spellChecker guessesForWordRange:NSMakeRange(0, [inputWord length]) 
                                                   inString:inputWord 
                                                   language:@"en_US" 
                                                     inSpellDocumentWithTag:0];
    
    // Initialize the result array
    Array results = Array::New(env);
    int i = 0;
    
    // Iterate over the suggestions
    for (NSString *suggestedWord in suggestions) {
        // Get the definition of the suggested word
        NSString *definition = (__bridge_transfer NSString*)DCSCopyTextDefinition(NULL, (__bridge CFStringRef)suggestedWord, CFRangeMake(0, [suggestedWord length]));
        
        // Create a JavaScript object for the entry
        Object entry = Object::New(env);
        entry.Set("suggestion", String::New(env, [suggestedWord UTF8String]));
        entry.Set("definition", String::New(env, [definition UTF8String]));

        // Add the entry to the results array
        results[i] = entry;
        i++;
    }

    // Check if the original word is spelled correctly
    if ([spellChecker checkSpellingOfString:inputWord startingAt:0].length == [inputWord length]) {
        // Get the definition of the word
        NSString *definition = (__bridge_transfer NSString*)DCSCopyTextDefinition(NULL, (__bridge CFStringRef)inputWord, CFRangeMake(0, [inputWord length]));

        // Create a JavaScript object for the entry
        Object entry = Object::New(env);
        entry.Set("suggestion", String::New(env, [inputWord UTF8String]));
        entry.Set("definition", String::New(env, [definition UTF8String]));

        // Add the entry to the results array
        results[i] = entry;
    }

    // Return the results array
    return results;
}

// Function for initializing the module
Object Init(Env env, Object exports) {
    // Add the method to the exports object
    exports.Set(String::New(env, "lookup"), Function::New(env, Method));

    // Return the modified exports object
    return exports;
}

// Use the NODE_API_MODULE macro to register the module
NODE_API_MODULE(addon, Init)
