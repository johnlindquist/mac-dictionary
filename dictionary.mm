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
    NSArray *suggestions = [spellChecker guessesForWordRange:NSMakeRange(0, [inputWord length]) 
                                                   inString:inputWord 
                                                   language:@"en_US" 
                                                     inSpellDocumentWithTag:0];

    NSMutableArray *results = [NSMutableArray array];
    for (NSString *suggestedWord in suggestions) {
        NSString *definition = (__bridge_transfer NSString*)DCSCopyTextDefinition(NULL, (__bridge CFStringRef)suggestedWord, CFRangeMake(0, [suggestedWord length]));
        NSDictionary *entry = @{
            @"suggestion": suggestedWord,
            @"definition": definition ? definition : @""
        };
        [results addObject:entry];
    }

    // Include the original word if it's spelled correctly
    if ([spellChecker checkSpellingOfString:inputWord startingAt:0].length == [inputWord length]) {
        NSString *definition = (__bridge_transfer NSString*)DCSCopyTextDefinition(NULL, (__bridge CFStringRef)inputWord, CFRangeMake(0, [inputWord length]));
        NSDictionary *entry = @{
            @"suggestion": inputWord,
            @"definition": definition ? definition : @""
        };
        [results addObject:entry];
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:results options:0 error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return String::New(env, jsonString.UTF8String);
}

Object Init(Env env, Object exports) {
    exports.Set(String::New(env, "lookup"), Function::New(env, Method));
    return exports;
}

NODE_API_MODULE(addon, Init)
