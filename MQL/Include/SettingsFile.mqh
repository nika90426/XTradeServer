//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict


/* Library Functions:

  //--- If the key is not found, the returned value is NULL.
  bool  GetIniKey        (string fileName, string section, string key, T &ReturnedValue)

  //---add new or update an existing key.
  bool  SetIniKey        (string fileName, string section, string key, T value)

  bool  DeleteIniKey     (string fileName, string section, string key);
  bool  DeleteIniSection (string fileName, string section);
*/

#import "kernel32.dll"
int  GetPrivateProfileStringW(string lpSection,string lpKey,string lpDefault,ushort &lpReturnedString[],int nSize,string lpFileName);
bool WritePrivateProfileStringW(string lpSection,string lpKey,string lpValue,string lpFileName);
#import

class SettingsFile
{
protected:
   string IniFileName;
   string IniFilePath;
public:
   string globalSection;
   SettingsFile(string globalName, string fileName)
   {
      globalSection = globalName;
      IniFileName = fileName; 
      IniFilePath = TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + IniFileName;
      
   }
   
   bool FileExists()
   {
      //int fileN = FileOpen(IniFilePath, FILE_READ);
      long fileN = FileIsExist(IniFileName,  FILE_COMMON);
      //fileN = FileFindFirst("/Files", IniFileName);
      if (fileN == INVALID_HANDLE)
      {
         int err = GetLastError();
         Print(StringFormat("File not exist error(%d): %s", err,IniFilePath));
         return false;
      }
      return true;
   }

//+------------------------------------------------------------------+
//| GetIniKey                                                        |
//+------------------------------------------------------------------+
/**
 * If the key is not found, the returned value is NULL.
 */
// string overload
bool GetIniKey(string section,string key,string &ReturnedValue)
  {
    
   string result=GetRawIniString(IniFilePath,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=result;
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }
  
// int overload
bool GetIniKey(string section,string key,int &ReturnedValue)
  {
   string result=GetRawIniString(IniFilePath,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=(int) StringToInteger(result);
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }
  
// long overload
bool GetIniKey(string section,string key,long &ReturnedValue)
  {
   string result=GetRawIniString(IniFilePath,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=(long) StringToInteger(result);
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }
  
// double overload
bool GetIniKey(string section,string key,double &ReturnedValue)
  {
   string result=GetRawIniString(IniFilePath,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=(double) StringToDouble(result);
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }
  
// datetime overload
bool GetIniKey(string section,string key,datetime &ReturnedValue)
  {
   string result=GetRawIniString(IniFilePath,section,key);

   if(StringLen(result)>0)
     {
      ReturnedValue=(datetime) StringToTime(result);
      return (true);
     }
   else
     {
      ReturnedValue=NULL;
      return (false);
     }
  }
  
  // bool overload
bool GetIniKey(string section,string key,bool &ReturnedValue)
  {
   string result=GetRawIniString(IniFilePath,section,key);
   if ( StringLen(result) == 0)
      return false;
   if(StringCompare(result, "true", false))
     { 
        ReturnedValue=true;
        return (true);
     }
   else
     {
        ReturnedValue=false;
        return (true);
     }
  }


  template<typename T>
  bool SetParam(string section,string key,T value)
  {
     return _setIniKey(section, key, value);
     //return (WritePrivateProfileStringW(section, key, value, IniFilePath));
  }
    
  template<typename T>
  bool SetGlobalParam(string key,T value)
  {
   return _setIniKey(globalSection, key, value);
  }
  
  bool DeleteSection(string section)
  {
   return DeleteIniSection(IniFileName, section);
  }

protected:
/**
 * add new or update an existing key.
 */
  template<typename T>
  bool _setIniKey(string section,string key,T value)
  {
   return (WritePrivateProfileStringW(section, key, (string)value, IniFilePath));
  }


//+------------------------------------------------------------------+
//| Internal function                                                |
//+------------------------------------------------------------------+
string GetRawIniString(string fileName,string section,string key)
  {
   ushort buffer[255];

   ArrayInitialize(buffer,0);
   string defaultValue="";
   GetPrivateProfileStringW(section,key,defaultValue,buffer,sizeof(buffer),fileName);
 
   return ShortArrayToString(buffer);
  }
  
  
//+------------------------------------------------------------------+
//| DeleteIniKey                                                     |
//+------------------------------------------------------------------+
bool DeleteIniKey(string fileName,string section,string key)
  {
   return (WritePrivateProfileStringW(section, key, NULL, fileName));
  }
  
//+------------------------------------------------------------------+
//| DeleteIniSection                                                 |
//+------------------------------------------------------------------+
bool DeleteIniSection(string fileName,string section)
  {
   return (WritePrivateProfileStringW(section, NULL, NULL, fileName));
  }

};