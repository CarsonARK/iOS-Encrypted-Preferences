//
//  EncryptedPreferences.m
//  BaseMenu
//
//  Created by Carson Mobile on 4/6/23.
//

#import <Foundation/Foundation.h>
#include "EncryptedPreferences.h"
#include <cstdio>
#include <cstdint>
#include <map>
#include <unordered_map>
#include <vector>
#include <string>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <dlfcn.h>
#import "AESCrypt-ObjC/AESCrypt.h"
static NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
using namespace std;

/* Non Class Functions */
static bool equalsIgnoreCase(const std::string& str1, const std::string& str2) {
    std::string str1_lower, str2_lower;
    str1_lower.resize(str1.size());
    str2_lower.resize(str2.size());

    std::transform(str1.begin(), str1.end(), str1_lower.begin(), [](unsigned char c){ return std::tolower(c); });
    std::transform(str2.begin(), str2.end(), str2_lower.begin(), [](unsigned char c){ return std::tolower(c); });

    return str1_lower == str2_lower;
}

static bool IsValidAddress(void* addr) {
    return (long)addr > 0x100000000 && (long)addr < 0x3000000000;
}
static NSString* ToNSNoEncry(string stdString){
    return [NSString stringWithCString:stdString.c_str() encoding:[NSString defaultCStringEncoding]];
}


/* Begin Class Functions */

/* Setters */
void EncryptedPreferences::SetPreferenceNameEncryptionKey(NSString* key){
    PreferenceNameEncryptionKey = key;
}
void EncryptedPreferences::SetValueEncryptionKey(NSString* key){
    ValueEncryptionKey = key;
}
void EncryptedPreferences::SetEncryptValues(bool shouldEncrypt){
    EncryptValues = shouldEncrypt;
}
void EncryptedPreferences::SetEncryptNames(bool shouldEncrypt){
    EncryptNames = shouldEncrypt;
}

/* Getters */

bool EncryptedPreferences::isEncryptingValues(){
    return EncryptValues;
}
bool EncryptedPreferences::isEncryptingNames(){
    return EncryptNames;
}

/* Gets the name of the preferences key, encrypted or not*/
NSString* EncryptedPreferences::ToNS(string stdString){
    NSString* Conversion = [NSString stringWithCString:stdString.c_str() encoding:[NSString defaultCStringEncoding]];
    if(EncryptNames){
        return [AESCrypt encrypt:Conversion password:PreferenceNameEncryptionKey];
    } else{
        return Conversion;
    }
}

/* Gets the string at a key, encrypted or not */
NSString* EncryptedPreferences::DecryptDefaults(string defaultsName){
    NSString* EncryptedString = [defaults stringForKey:ToNS(defaultsName)];
    if(EncryptValues){
        return [AESCrypt decrypt:EncryptedString password:ValueEncryptionKey];
    } else {
        return EncryptedString;
    }
}

void EncryptedPreferences::WriteString(NSString* ValueString, string defaultsName){
    if(EncryptValues){
        NSString* EncryptedValueString = [AESCrypt encrypt:ValueString password:ValueEncryptionKey];
        [defaults setObject:EncryptedValueString forKey:ToNS(defaultsName)];
    } else {
        [defaults setObject:ValueString forKey:ToNS(defaultsName)];
    }
}

/* Set Values */
void EncryptedPreferences::SetDefaultsLong(long Value, string defaultsName){
    NSString* ValueString = [NSString stringWithFormat:@"%ld", Value];
    WriteString(ValueString, defaultsName);
}
void EncryptedPreferences::SetDefaultsInteger(int Value, string defaultsName){
    NSString* ValueString = [NSString stringWithFormat:@"%d", Value];
    WriteString(ValueString, defaultsName);
}
void EncryptedPreferences::SetDefaultsFloat(float Value, string defaultsName){
    NSString* ValueString = [NSString stringWithFormat:@"%f", Value];
    WriteString(ValueString, defaultsName);
}
void EncryptedPreferences::SetDefaultsNSString(NSString* Value, string defaultsName){
    WriteString(Value, defaultsName);
}
void EncryptedPreferences::SetDefaultsBool(bool Value, string defaultsName){
    NSString* ValueString = [NSString stringWithFormat:@"%d", Value];
    WriteString(ValueString, defaultsName);
}
void EncryptedPreferences::SetDefaultsDouble(double Value, string defaultsName){
    NSString* ValueString = [NSString stringWithFormat:@"%f", Value];
    WriteString(ValueString, defaultsName);
}



void EncryptedPreferences::LoadObject(SaveOption ToSave){
    switch(ToSave.Type){
        case Type_Long:{
            *(long*)ToSave.pointer = [DecryptDefaults(ToSave.Name) integerValue];
            return;
        }
        case Type_Float:{
            *(float*)ToSave.pointer = [DecryptDefaults(ToSave.Name) floatValue];
            return;
        }
        case Type_Int:{
            *(int*)ToSave.pointer = [DecryptDefaults(ToSave.Name) intValue];
            return;
        }
        case Type_String:{
            NSString* nString = DecryptDefaults(ToSave.Name);
            if(nString.length < 1) return;
            *(string*)ToSave.pointer = DecryptDefaults(ToSave.Name).UTF8String;
            return;
        }
        //NSString doesnt get encrypted when it is saved, or decrypted when loaded.
        case Type_NSString:{
            
            NSString* SavedVal = [defaults stringForKey:ToNS(ToSave.Name)];
            *(void**)ToSave.pointer = (__bridge void*)[SavedVal copy];
            return;
        }
        case Type_Vector:{
            Vector3* myVector = (Vector3*)ToSave.pointer;
            myVector->X = [DecryptDefaults(ToSave.Name + "X") floatValue];
            myVector->Y = [DecryptDefaults(ToSave.Name + "Y") floatValue];
            myVector->Z = [DecryptDefaults(ToSave.Name + "Z") floatValue];
            return;
        }
        case Type_FloatTwo:{
            ((float*)ToSave.pointer)[0] = [DecryptDefaults(ToSave.Name + "1") floatValue];
            ((float*)ToSave.pointer)[1] = [DecryptDefaults(ToSave.Name + "2") floatValue];
            return;
        }
        case Type_FloatThree:{
            ((float*)ToSave.pointer)[0] = [DecryptDefaults(ToSave.Name + "1") floatValue];
            ((float*)ToSave.pointer)[1] = [DecryptDefaults(ToSave.Name + "2") floatValue];
            ((float*)ToSave.pointer)[2] = [DecryptDefaults(ToSave.Name + "3") floatValue];
            return;
        }
        case Type_FloatFour:{
            ((float*)ToSave.pointer)[0] = [DecryptDefaults(ToSave.Name + "1") floatValue];
            ((float*)ToSave.pointer)[1] = [DecryptDefaults(ToSave.Name + "2") floatValue];
            ((float*)ToSave.pointer)[2] = [DecryptDefaults(ToSave.Name + "3") floatValue];
            ((float*)ToSave.pointer)[3] = [DecryptDefaults(ToSave.Name + "4") floatValue];
            return;
        }
        case Type_Bool:{
            *(BOOL*)ToSave.pointer = [DecryptDefaults(ToSave.Name) boolValue];
            return;
        }
        case Type_Double:{
            *(double*)ToSave.pointer = [DecryptDefaults(ToSave.Name) doubleValue];
            return;
        }
        default:{
            return;
        }
    }
}

bool EncryptedPreferences::SaveObject(SaveOption ToSave){
    switch(ToSave.Type){
        case Type_Long:{
            SetDefaultsLong(*(long*)ToSave.pointer, ToSave.Name);
            return true;
        }
        case Type_Float:{
            SetDefaultsFloat(*(float*)ToSave.pointer, ToSave.Name);
            return true;
        }
        case Type_Int:{
            SetDefaultsInteger(*(int*)ToSave.pointer, ToSave.Name);
            return true;
        }
        case Type_String:{
            SetDefaultsNSString(ToNSNoEncry(*(string*)ToSave.pointer), ToSave.Name);
            return true;
        }
        //NSString doesnt get encrypted when it is saved, or decrypted when loaded.
        case Type_NSString:{
            void* NSStr = *(void**)ToSave.pointer;
            NSString* String = (__bridge NSString *)NSStr;
            [defaults setObject:String forKey:ToNS(ToSave.Name)];
            return true;
        }
        case Type_Vector:{
            SetDefaultsFloat((*(Vector3*)ToSave.pointer).X, ToSave.Name + "X");
            SetDefaultsFloat((*(Vector3*)ToSave.pointer).X, ToSave.Name + "Y");
            SetDefaultsFloat((*(Vector3*)ToSave.pointer).X, ToSave.Name + "Z");
            return true;
        }
        case Type_FloatTwo:{
            SetDefaultsFloat(((float*)ToSave.pointer)[0], ToSave.Name + "1");
            SetDefaultsFloat(((float*)ToSave.pointer)[1], ToSave.Name + "2");
            return true;
        }
        case Type_FloatThree:{
            SetDefaultsFloat(((float*)ToSave.pointer)[0], ToSave.Name + "1");
            SetDefaultsFloat(((float*)ToSave.pointer)[1], ToSave.Name + "2");
            SetDefaultsFloat(((float*)ToSave.pointer)[2], ToSave.Name + "3");
            return true;
        }
        case Type_FloatFour:{
            SetDefaultsFloat(((float*)ToSave.pointer)[0], ToSave.Name + "1");
            SetDefaultsFloat(((float*)ToSave.pointer)[1], ToSave.Name + "2");
            SetDefaultsFloat(((float*)ToSave.pointer)[2], ToSave.Name + "3");
            SetDefaultsFloat(((float*)ToSave.pointer)[3], ToSave.Name + "4");
            return true;
        }
        case Type_Bool:{
            SetDefaultsBool(*(BOOL*)ToSave.pointer, ToSave.Name);
            return true;
        }
        case Type_Double:{
            SetDefaultsDouble(*(double*)ToSave.pointer, ToSave.Name);
            return true;
        }
        default:{
            return false;
        }
    }
    return false;
}

void EncryptedPreferences::AddEntry(string Name, void *pointer, VariableType Type){
    Options.push_back({Name, pointer, Type});
}

void EncryptedPreferences::SaveDefaults(){
    for (const auto& CurrentSavedValue : Options) {
        SaveObject(CurrentSavedValue);
    }
    [defaults synchronize];
}

void EncryptedPreferences::LoadDefaults(){
    for (const auto& CurrentSavedValue : Options) {
        LoadObject(CurrentSavedValue);
    }
    [defaults synchronize];
}

/*
 Get Values
*/

void* EncryptedPreferences::GetPointer(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return CurrentSavedValue.pointer;
        }
    }
    return nullptr;
}
long EncryptedPreferences::GetLong(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return *(long*)CurrentSavedValue.pointer;
        }
    }
    return 0;
}
float EncryptedPreferences::GetFloat(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return *(float*)CurrentSavedValue.pointer;
        }
    }
    return 0;
}
int EncryptedPreferences::GetInt(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return *(int*)CurrentSavedValue.pointer;
        }
    }
    return 0;
}

string EncryptedPreferences::GetString(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return *(string*)CurrentSavedValue.pointer;
        }
    }
    return "";
}

NSString* EncryptedPreferences::GetNSString(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            void* NSStr = *(void**)CurrentSavedValue.pointer;
            return (__bridge NSString *)NSStr;
        }
    }
    return @"";
}

Vector3 EncryptedPreferences::GetVector(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return *(Vector3*)CurrentSavedValue.pointer;
        }
    }
    return {0,0,0};
}

float* EncryptedPreferences::GetFloatTwo(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return (float *)CurrentSavedValue.pointer;
        }
    }
    return nullptr;
}

float* EncryptedPreferences::GetFloatThree(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return (float *)CurrentSavedValue.pointer;
        }
    }
    return nullptr;
}

float* EncryptedPreferences::GetFloatFour(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return (float *)CurrentSavedValue.pointer;
        }
    }
    return nullptr;
}

BOOL EncryptedPreferences::GetBool(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return *(BOOL *)CurrentSavedValue.pointer;
        }
    }
    return false;
}

double EncryptedPreferences::GetDouble(std::string forKey){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            return *(double*)CurrentSavedValue.pointer;
        }
    }
    return 0;
}

/*
Setting Values
*/

void EncryptedPreferences::SetValue(string forKey, long Value){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            
            if(!IsValidAddress(CurrentSavedValue.pointer)) return;
            
            *(long*)CurrentSavedValue.pointer = Value;
        }
    }
    return;
}
void EncryptedPreferences::SetValue(string forKey, float Value){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            
            if(!IsValidAddress(CurrentSavedValue.pointer)) return;
            
            *(float*)CurrentSavedValue.pointer = Value;
        }
    }
    return;
}
void EncryptedPreferences::SetValue(string forKey, int Value){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            
            if(!IsValidAddress(CurrentSavedValue.pointer)) return;
            
            *(int*)CurrentSavedValue.pointer = Value;
        }
    }
    return;
}
void EncryptedPreferences::SetValue(string forKey, string Value){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            
            if(!IsValidAddress(CurrentSavedValue.pointer)) return;
            
            *(string*)CurrentSavedValue.pointer = Value;
        }
    }
    return;
}

void EncryptedPreferences::SetValue(string forKey, NSString* Value){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            
            if(!IsValidAddress(CurrentSavedValue.pointer)) return;

            *(void**)CurrentSavedValue.pointer = (__bridge void*)[Value copy];

        }
    }
    return;
}
void EncryptedPreferences::SetValue(string forKey, Vector3 Value){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            
            if(!IsValidAddress(CurrentSavedValue.pointer)) return;
            
            *(Vector3*)CurrentSavedValue.pointer = Value;
        }
    }
    return;
}
void EncryptedPreferences::SetValue(string forKey, float* Value, int num){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            
            if(!IsValidAddress(CurrentSavedValue.pointer)) return;
            
            for(int i = 0; i<num; i++){
                ((float*)(CurrentSavedValue.pointer))[i] = Value[i];
            }
        }
    }
    return;
}
void EncryptedPreferences::SetValue(string forKey, BOOL Value){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            
            if(!IsValidAddress(CurrentSavedValue.pointer)) return;
            
            *(BOOL*)CurrentSavedValue.pointer = Value;
        }
    }
    return;
}
void EncryptedPreferences::SetValue(string forKey, double Value){
    for (const auto& CurrentSavedValue : Options) {
        if(equalsIgnoreCase(forKey, CurrentSavedValue.Name)){
            
            if(!IsValidAddress(CurrentSavedValue.pointer)) return;
            
            *(double*)CurrentSavedValue.pointer = Value;
        }
    }
    return;
}

