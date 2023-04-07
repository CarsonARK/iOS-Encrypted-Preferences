//
//  Preferences.h
//  LegitServer
//
//  Created by Carson Mobile on 4/6/23.
//
#pragma once

#include <cstdio>
#include <cstdint>
#include <map>
#include <unordered_map>
#include <vector>
#include <string>
using namespace std;

struct Vector3{
    float X,Y,Z;
};
enum VariableType : uint8_t{
    Type_Long = 0,
    Type_Float = 1,
    Type_Int = 2,
    Type_String = 3,
    Type_NSString = 4,
    Type_Vector = 5,
    Type_FloatTwo = 6,
    Type_FloatThree = 7,
    Type_FloatFour = 8,
    Type_Bool = 9,
    Type_Double = 10
};
struct SaveOption{
    std::string Name;
    void* pointer;
    VariableType Type;
    
};


class EncryptedPreferences
{
    vector<SaveOption> Options;
    
    bool EncryptValues = true;
    bool EncryptNames = true;
    
    NSString* PreferenceNameEncryptionKey = @"NameDefault";
    NSString* ValueEncryptionKey = @"ValueDefault";
    
    NSString* ToNS(string stdString);
    NSString* DecryptDefaults(string defaultsName);
    void WriteString(NSString* ValueString, string defaultsName);
    
    
    void SetDefaultsLong(long Value, string defaultsName);
    void SetDefaultsInteger(int Value, string defaultsName);
    void SetDefaultsFloat(float Value, string defaultsName);
    void SetDefaultsNSString(NSString* Value, string defaultsName);
    void SetDefaultsBool(bool Value, string defaultsName);
    void SetDefaultsDouble(double Value, string defaultsName);
    void LoadObject(SaveOption ToSave);
    bool SaveObject(SaveOption ToSave);
    
public:
    
    
    static EncryptedPreferences& getInstance() {
        static EncryptedPreferences instance; // The single instance
        return instance;
    }
    
    void SetPreferenceNameEncryptionKey(NSString* key);
    void SetValueEncryptionKey(NSString* key);
    void SetEncryptValues(bool shouldEncrypt);
    void SetEncryptNames(bool shouldEncrypt);
    
    bool isEncryptingValues();
    bool isEncryptingNames();
    
    void AddEntry(string Name, void* pointer, VariableType Type);
    void LoadDefaults();
    void SaveDefaults();

    void* GetPointer(std::string forKey);
    long GetLong(std::string forKey);
    float GetFloat(std::string forKey);
    int GetInt(std::string forKey);
    string GetString(std::string forKey);
    NSString* GetNSString(std::string forKey);
    Vector3 GetVector(std::string forKey);
    float* GetFloatTwo(std::string forKey);
    float* GetFloatThree(std::string forKey);
    float* GetFloatFour(std::string forKey);
    BOOL GetBool(std::string forKey);
    double GetDouble(std::string forKey);
    
    void SetValue(string forKey, long Value);
    void SetValue(string forKey, float Value);
    void SetValue(string forKey, int Value);
    void SetValue(string forKey, string Value);
    void SetValue(string forKey, NSString* Value);
    void SetValue(string forKey, Vector3 Value);
    void SetValue(string forKey, float* Value, int num);
    void SetValue(string forKey, BOOL Value);
    void SetValue(string forKey, double Value);
};

