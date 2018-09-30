//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#include <FXMind\SettingsFile.mqh>
#include <FXMind\IUtils.mqh>
#include <FXMind\IFXMindService.mqh>


struct THRIFT_CLIENT
{
   int port;
   int Magic;
   int accountNumber;
   int Reserved;
};

#import "ThriftMQL.dll"
long ProcessStringData(string& inoutdata, string parameters, THRIFT_CLIENT &tc);
long ProcessDoubleData(double &arr[], int arr_size, string parameters, string indata, THRIFT_CLIENT &tc);
long IsServerActive(THRIFT_CLIENT &tc);
void PostStatusMessage(THRIFT_CLIENT &tc, string message);
void GetGlobalProperty(string& RetValue, string PropName, THRIFT_CLIENT &tc); // returns length of the result value. -1 - on error
long InitExpert(string& OrdersListToLoad, string ChartTimeFrame, string Symbol, string comment, THRIFT_CLIENT &tc); // Returns Magic Number, 0 or error
void SaveExpert(string ActiveOrdersList, THRIFT_CLIENT &tc);
void DeInitExpert(int Reason, THRIFT_CLIENT &tc); // DeInit for Expert Advisers only
void CloseClient(THRIFT_CLIENT &tc); // Free memory
long GetProfileString(string& RetValue, string lpSection, string lpKey, string fileName);
long WriteProfileString(string lpSection, string lpKey,string lpValue, string fileName);
#import


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class FXMindClient : public IFXMindService
{
protected:
    THRIFT_CLIENT client;

   SignalNews storeEvent;
   // Events temp vars;
   datetime storeEventTime;
   string storeParamstrEvent;   
   string storeParamstr;
   
   string oldSentstr;
   datetime prevSenttime;
   
   // News variables
   string variableNewsSignal;
   string variableNewsSignalTime;
   string variableNewsSignalName;
public:
   
   FXMindClient(short Port, string EA, int DefMagic = DEFAULT_MAGIC_NUMBER)
     :IFXMindService(Port, EA)
   {
      sep = StringGetCharacter(constant.PARAMS_SEPARATOR, 0);
      sepList = StringGetCharacter(constant.LIST_SEPARATOR, 0);
      client.port = Port;
      magic = DefMagic;
      client.Magic = (int)magic;
   }
   virtual bool Init(bool isEA);
   virtual bool CheckActive();
   virtual bool NewsFromString(string newsstring, SignalNews& news);
   
   //string prevTime;
   virtual SignalNews* GetLastNewsEvent()
   {
      double Imp = GlobalVariableGet(variableNewsSignal);
      
      datetime time = (datetime) GlobalVariableGet(variableNewsSignalTime);
      string SignalTime = TimeToString(time);
      //if (StringCompare(prevTime, SignalTime) == 0)
      //   return NULL; // Signal handled;
      datetime currentTime = Utils.CurrentTimeOnTF();
      //string CurrentTime = TimeToString(currentTime);
      //int PeriodsPassed = (int)(currentTime-time)/PeriodSeconds();
      //if ( PeriodsPassed > 1)
      //   return false; // Signal too old;
      // Utils.Info(StringFormat("Upcoming News SignalTime=%s currenttime=%s %s", SignalTime, TimeToString(currentTime), storeEvent.ToString()));
                  
      for (int i = 0; i < GlobalVariablesTotal() ; i++)
      {
         string name = GlobalVariableName(i);
         if (StringFind(name, variableNewsSignalName) >= 0) 
         {
            int startPos = StringFind(name, "|");
            if (startPos > 0)
            {
               string strName = StringSubstr(name, startPos + 1);
               if (StringLen(strName) <= 0)
                  continue;
               storeEvent.SetName(strName);
               storeEvent.Importance = (int)Imp;
               storeEvent.SetRaiseTime(time);

            }   
            break;
         }
      }
      
      return &storeEvent; 
   }

   virtual bool GetNextNewsEvent(ushort Importance, SignalNews& eventInfo);
   
   virtual int  GetTodayNews(ushort Importance, SignalNews &arr[], datetime curtime);
   virtual int  GetCurrentSentiments(double& longVal, double& shortVal); 
   virtual long GetSentimentsArray(int offset, int limit, int site, const datetime& times[], double &arr[]);   
   virtual long GetCurrencyStrengthArray(string currency, int offset, int limit, int timeframe, const datetime& times[], double &arr[]);   
   virtual void PostMessage(string message);      
   virtual void SaveAllSettings(string ActiveOrdersList);   
   virtual uint DeInit(int Reason);
   virtual string GetProfileString(string lpSection, string lpKey);
   virtual long WriteProfileString(string lpSection, string lpKey,string lpValue);
   virtual void InitNewsVariables(string strMagic);
   virtual void SetGlobalNewsSignal();

   virtual ~FXMindClient()
   {
      if (set != NULL)
      {
         delete set;
         set = NULL;
      }
   }
};

bool FXMindClient::Init(bool isEA) // Should be called after MagicNumber obtained
{
   client.accountNumber = (int)Utils.GetAccountNumer();
   string periodStr = EnumToString((ENUM_TIMEFRAMES)Period());
   sym = Symbol();
   //if (StringLen(sym) > 6)
   //   sym = StringSubstr(sym, 0, 6);
	string rawOrdersList;
	StringInit(rawOrdersList, BUFF_SIZE, 0);
	if (isEA)
	{
      long result = InitExpert(rawOrdersList, periodStr, sym, EAName, client);
      if (result <= 0)
      {
         Print(StringFormat("InitExpert(%d, %s, %s) FAILED!!!", client.accountNumber, periodStr, sym));
         return false;
      }
      magic = result;
      client.Magic = (int)magic;
      fileName = StringFormat("%d_%s_%s_%d.set", client.accountNumber, sym, periodStr, magic);
      IniFilePath = TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + fileName;
      
      set = new SettingsFile(&this, constant.GLOBAL_SECTION_NAME);
      set.SetOrdersStringList(rawOrdersList, sep);
      CheckActive();
   }
   

   storeEventTime = TimeCurrent();
   prevSenttime = storeEventTime;
   return isActive || (!isEA);
}

string FXMindClient::GetProfileString(string section, string key)
{
   string rawMessage;
   StringInit(rawMessage, BUFF_SIZE, 0);
   if (GetProfileString(rawMessage, section,key,IniFilePath) >=0)
      return rawMessage;
   return "";
}

long FXMindClient::WriteProfileString(string section, string key,string value)
{
    return (WriteProfileString(section, key, (string)value, IniFilePath));
}


bool FXMindClient::CheckActive() {   
   isActive = IsServerActive(client) > 0;
   return isActive;
}
   
   
bool FXMindClient::NewsFromString(string newsstring, SignalNews& news)
{
   string result[];
   if (StringGetCharacter(newsstring, 0) == sep)
      newsstring = StringSubstr(newsstring, 1);
   int count = StringSplit(newsstring, sep, result);
   if (count >= 4)
   {
      news.Currency = result[0];
      news.Importance = (int)StringToInteger(result[1]);
      news.SetRaiseTime(StringToTime(result[2]));
      news.SetName(result[3]);
      //Print(news.ToString());
      return true;
   }
   return false;
}

bool FXMindClient::GetNextNewsEvent(ushort Importance, SignalNews& eventInfo)
{
   datetime curtime = Utils.CurrentTimeOnTF();
   
   if (storeEventTime != curtime)
      storeEventTime = curtime;
   else
   { 
      eventInfo = storeEvent;
      return true;
   }
   string instr = StringFormat("func=NextNewsEvent|symbol=%s|importance=%d|time=%s", sym, Importance, TimeToString(curtime));
	if ( StringCompare(storeParamstrEvent, instr) == 0)
   { 
      eventInfo = storeEvent;
      return true;
   }
	storeParamstrEvent = instr;
	string rawMessage;
	StringInit(rawMessage, BUFF_SIZE, 0);
	long retval = ProcessStringData(rawMessage, instr, client);
	if ( retval > 0  )
	{
	   if (NewsFromString(rawMessage, eventInfo))
	   {
	      storeEvent = eventInfo;
         //SetGlobalNewsSignal();
	      //Print(eventInfo.ToString());
	      return true;
	   }
	}
	return false;
}

int FXMindClient::GetTodayNews(ushort Importance, SignalNews &arr[], datetime curtime)
{
	string instr = "func=GetTodayNews|symbol=" + sym + "|importance=" + IntegerToString(Importance) + "|time=" + TimeToString(curtime);
	if ( StringCompare(storeParamstr, instr) == 0)
      return 0;
	storeParamstr = instr;
	int storeRes = 0;
	string rawMessage;
	StringInit(rawMessage, MAX_NEWS_PER_DAY*BUFF_SIZE, 0);
	long retval = ProcessStringData(rawMessage, instr, client);
	if ( retval > 0 )
	{
	   //Print(rawMessage);
      string result[];
      int count = StringSplit(rawMessage, sepList, result);
      count = (int)MathMin(count, MAX_NEWS_PER_DAY);
      if (count >= 1) {
         for (int i=0; i<MAX_NEWS_PER_DAY;i++)
         { 
            arr[i].Init();
         }
         storeRes = count;
         for (int i=0; i<count;i++)
         {                
            if (NewsFromString(result[i], arr[i]))
            {
               if (i==0)
               {
                 	 storeEvent = arr[i];
                   SetGlobalNewsSignal();
               }
            }
         }
      }
	}
	return storeRes;
}

int FXMindClient::GetCurrentSentiments(double& longVal, double& shortVal) 
{
   datetime curtime = Utils.CurrentTimeOnTF();
   if (prevSenttime != curtime)
      prevSenttime = curtime;
   else
      return 0;
	string instr = "func=CurrentSentiments|symbol=" + sym + "|time=" + TimeToString(curtime);
	if ( StringCompare(oldSentstr, instr) == 0)
	   return 0;
	oldSentstr = instr;
	double resDouble[2];
	//ArrayResize(resDouble, 2);
	ArrayFill(resDouble, 0, 2, 0);
	string rawMessage = "0|0";
	long retval = ProcessDoubleData(resDouble, 2, instr, rawMessage, client);
	int res = 0;   	
	if ( retval == 0 )
	{
      longVal = resDouble[0];
      shortVal = resDouble[1];
      res = 1;
   } else 
         res = 0;
   return res;
}

long FXMindClient::GetSentimentsArray(int offset, int limit, int site, const datetime& times[], double &arr[])
{
	string parameters = "func=SentimentsArray|symbol=" + sym + "|size=" + IntegerToString(limit)
	   + "|site=" + IntegerToString(site);
	string timeArray;
	for (int i = 0; i < limit; i++)
	{
      timeArray += TimeToString(times[i]);
      if (i < (limit-1) )
         timeArray += "|";
  	}
  	double retarr[];
  	ArrayResize(retarr, limit);
   long retval = ProcessDoubleData(retarr, limit, parameters, timeArray, client);
   ArrayCopy(arr, retarr, offset, 0, limit);
   return retval;
}

long FXMindClient::GetCurrencyStrengthArray(string currency, int offset, int limit, int timeframe, const datetime& times[], double &arr[])
{
	string parameters = "func=CurrencyStrengthArray|currency=" + currency + "|timeframe=" + IntegerToString(timeframe);
	string timeArray;
	for (int i = 0; i < limit; i++)
	{
      timeArray += TimeToString(times[i]);
      if (i < (limit-1) )
         timeArray += "|";
  	}
  	double retarr[];
  	ArrayResize(retarr, limit);
   long retval = ProcessDoubleData(retarr, limit, parameters, timeArray, client);
   ArrayCopy(arr, retarr, offset, 0, limit);
   return retval;
}

void FXMindClient::PostMessage(string message)
{
   PostStatusMessage(client, message);
}
   
void FXMindClient::SaveAllSettings(string ActiveOrdersList)
{      
   SaveExpert(ActiveOrdersList, client);
}

uint FXMindClient::DeInit(int Reason)
{
   DeInitExpert(Reason, client); // DeInit for Expert Advisers only
   CloseClient(client);      
   return 0;
}

void FXMindClient::InitNewsVariables(string strMagic)
{
   variableNewsSignal = StringFormat("NewsSignal%s", strMagic);
   variableNewsSignalTime = StringFormat("NewsSignal%sTime", strMagic);
   variableNewsSignalName = StringFormat("NewsSignal%sName|", strMagic);

   GlobalVariablesDeleteAll(variableNewsSignal);

   GlobalVariableSet(variableNewsSignal, 0.0);
   GlobalVariableSet(variableNewsSignalTime, 0);
   GlobalVariableSet(variableNewsSignalName, 0.0);
}

void FXMindClient::SetGlobalNewsSignal()
{
   GlobalVariableSet(variableNewsSignal, storeEvent.Importance);
   GlobalVariableSet(variableNewsSignalTime, storeEvent.RaiseTime());
   string name = storeEvent.GetName();
   GlobalVariableSet(variableNewsSignalName + name, storeEvent.Importance);   
   //Print(StringFormat("Set Global News Event: %s", storeEvent.ToString()) );
}
