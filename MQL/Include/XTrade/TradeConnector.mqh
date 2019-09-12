//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#include <XTrade\SettingsFile.mqh>
#include <XTrade\IUtils.mqh>
#include <XTrade\ITradeService.mqh>
#include <XTrade\Jason.mqh>
#include <XTrade\CommandsController.mqh>
#include <XTrade\Deal.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class TradeConnector : public ITradeService
{
protected:
    CJAVal client;
    string clientString;

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
   string headers;
   int timeout;
   int paramsBufSize;
   string baseURL;
   ExpertParams* expert;
public:
   TradeConnector(short Port, string EA, int DefMagic = DEFAULT_MAGIC_NUMBER)
      :ITradeService(Port, EA)
   {
      sep = StringGetCharacter(constant.PARAMS_SEPARATOR, 0);
      sepList = StringGetCharacter(constant.LIST_SEPARATOR, 0);
      client["Port"] = (int)Port;
      magic = DefMagic;
      client["Magic"] = (int)magic;
      headers = "\r\nContent-Type: application/json\r\nAccept: application/json";
      baseURL = "http://127.0.0.1:2013/api/mt";
      timeout = 20000;
      paramsBufSize = 4096;
      expert = NULL;
   }
   virtual bool Init(bool isEA);
   virtual bool CheckActive();
   virtual bool NewsFromString(string newsstring, SignalNews& news);
   void Log(string message);
   void Log(long order, string mesage);
   // string prevTime;
   virtual SignalNews* GetLastNewsEvent();
   virtual bool GetNextNewsEvent(ushort Importance, SignalNews& eventInfo);
   virtual int  GetTodayNews(ushort Importance, SignalNews &arr[], datetime curtime);
   virtual void SaveAllSettings(string strExpertData, string strDataOrders);
   virtual uint DeInit(int Reason);
   virtual void InitNewsVariables(string strMagic);
   virtual void SetGlobalNewsSignal();
   virtual Signal* ListenSignal(long flags, long ObjectId);
   void    ProcessSignals();
   virtual void PostSignal(Signal* s);
   virtual void PostSignalLocally(Signal* signal);
   virtual Signal* SendSignal(Signal* s);
   virtual bool   LoadExpertParams();
   virtual void   CallLoadParams(CJAVal* pars);
   virtual string CallStoreParamsFunc();
   virtual ~TradeConnector();
   string  SendMethod(string action, SerializableEntity* obj);
   void    PostMethod(string action, SerializableEntity* obj);
   virtual void    DealsHistory(int days); 
};

void TradeConnector::~TradeConnector()
{
   // DELETE_PTR(expert);
}

SignalNews* TradeConnector::GetLastNewsEvent()
{
   double Imp = GlobalVariableGet(variableNewsSignal);
   
   datetime time = (datetime) GlobalVariableGet(variableNewsSignalTime);
   string SignalTime = TimeToString(time);
   datetime currentTime = Utils.CurrentTimeOnTF();
               
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

void TradeConnector::CallLoadParams(CJAVal* pars) {
   if (pars != NULL)
      eset.obj.Deserialize(pars.ToStr());
   eset.Save(false);
}

string TradeConnector::CallStoreParamsFunc() {
    return eset.Save(true);
}

string TradeConnector::SendMethod(string action, SerializableEntity* obj) {
    string uri = StringFormat("%s/%s", baseURL, action);
    uchar data[];
    ArrayResize(data, paramsBufSize);
    ArrayInitialize(data, 0);
    StringToCharArray(obj.Persistent().Serialize(),data);
    uchar resdata[];
    string resultHeaders;
    int res = WebRequest("POST", uri, headers, timeout, data, resdata, resultHeaders);
    if (res == -1) 
    { 
        isActive = false;
        Utils.Info(StringFormat("Error in WebRequest SendMethod. Error code=%d. Response: %s", GetLastError(), resultHeaders)); 
    } else {
        isActive = true;
       int size = ArraySize(resdata);
       //Utils.Info(StringFormat("Array Size =%d", size)); 
       //params.Clear();
       if (size <= 0)
          return "";
       return CharArrayToString(resdata);
    }
    return "";
}

void TradeConnector::PostMethod(string action, SerializableEntity* obj) {
    string uri = StringFormat("%s/%s", baseURL, action);
    uchar data[];
    ArrayResize(data, paramsBufSize);
    ArrayInitialize(data, 0);
    StringToCharArray(obj.Persistent().Serialize(),data);
    uchar resdata[];
    string resultHeaders;
    int res = WebRequest("POST", uri, headers, 50, data, resdata, resultHeaders);
    if(res == -1)
    {
        isActive = false;
        Utils.Info(StringFormat("Error in WebRequest PostMethod. Error code=%d. Response: %s", GetLastError(), resultHeaders)); 
    } else 
        isActive = true;
}

bool TradeConnector::Init(bool isEA) // Should be called after MagicNumber obtained
{
   IsEA = isEA;
   int accountNumber = (int)Utils.GetAccountNumer();
   client["Account"] = accountNumber;
   clientString = client.Serialize();
   string periodStr = EnumToString((ENUM_TIMEFRAMES)Period());
   sym = Symbol();
	if (isEA)
	{
      expert = new ExpertParams();
      expert.Fill(Utils.GetAccountNumer(), Period(), Symbol(), this.EAName, magic, 0, this.isMaster);
      // string rawOrdersList = SendMethod("InitExpert", expert);
      Signal initsignal(SignalToServer, SIGNAL_INIT_EXPERT, 0);
      initsignal.obj["Data"] = expert.Persistent().Serialize();
      Signal* resultSignal = SendSignal(&initsignal);
      if (resultSignal == NULL)
      {
         Utils.Info(StringFormat("InitExpert(%d, %s, %s) FAILED!!! Empty result returned!!", accountNumber, periodStr, sym));
         return false;
      }
      expert.Deserialize(resultSignal.obj["Data"].ToStr());
      DELETE_PTR(resultSignal);
      CJAVal* magicValue = expert.obj.FindKey("Magic");
      if (magicValue == NULL)
      {
         Utils.Info(StringFormat("InitExpert(%d, %s, %s) FAILED!!! No Magic Number returned!!", accountNumber, periodStr, sym));
         return false;
      }
      string magicStr = magicValue.ToStr();
      long res = StringToInteger(magicStr);
      if (res <= 0)
      {
         Utils.Info(StringFormat("InitExpert(%d, %s, %s) FAILED!!! Wrong Magic Number!!", accountNumber, periodStr, sym));
         return false;
      }
      magic = res;
      client["Magic"] = (int)magic;
      clientString = client.Serialize();
      
      CJAVal* master = expert.obj.FindKey("IsMaster");
      if (master != NULL)
         isMaster = master.ToBool();
         
      string datastr = expert.obj["Data"].ToStr();
      bool shoudSave = StringLen(datastr) == 0;
      CallLoadParams(expert.obj["Data"]);
      if (shoudSave)
      {
         string savestr = CallStoreParamsFunc();
         SaveAllSettings(savestr, ""); 
      }
      isActive = true;
   } else 
   {   
      expert = new ExpertParams();
      this.magic = Utils.GetAccountNumer();
      expert.Fill(Utils.GetAccountNumer(), Period(), Symbol(), this.EAName, magic, 0, this.isMaster);
      Signal initsignal(SignalToServer, SIGNAL_INIT_TERMINAL, Utils.GetAccountNumer());
      initsignal.obj["Data"] = expert.Persistent().Serialize();
      Signal* resultSignal = SendSignal(&initsignal);
      if (resultSignal == NULL)
      {
         Utils.Info(StringFormat("InitTerminal(%d) FAILED!!! Empty result returned!!", accountNumber));
         return false;
      }
      client["Magic"] = (int)magic;
      clientString = client.Serialize();
      expert.Deserialize(resultSignal.obj["Data"].ToStr());
      DELETE_PTR(resultSignal);
   
   }
   storeEventTime = TimeCurrent();
   prevSenttime = storeEventTime;
   return isActive;
}

void TradeConnector::ProcessSignals()
{
   Signal* signal = ListenSignal(SignalToExpert, this.magic);
   if ( signal != NULL ) {
      PostSignalLocally(signal);
   }
}

bool TradeConnector::CheckActive() {
   return isActive;
}
   
bool TradeConnector::LoadExpertParams() {
   //isActive = Connector::IsServerActive(clientString) > 0;
   return false;
}

bool TradeConnector::NewsFromString(string newsstring, SignalNews& news)
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

bool TradeConnector::GetNextNewsEvent(ushort Importance, SignalNews& eventInfo)
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
	//rawMessage = Connector::ProcessStringData(instr, clientString);
   Utils.Info("TODO : GetNextNewsEvent Implement this");
   //rawMessage = SendMethod("" //Connector::ProcessStringData(instr, clientString);
	if ( StringLen(rawMessage) > 0 )
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

int TradeConnector::GetTodayNews(ushort Importance, SignalNews &arr[], datetime curtime)
{
	string instr = "func=GetTodayNews|symbol=" + sym + "|importance=" + IntegerToString(Importance) + "|time=" + TimeToString(curtime);
	if ( StringCompare(storeParamstr, instr) == 0)
      return 0;
	storeParamstr = instr;
	int storeRes = 0;
	string rawMessage;
	StringInit(rawMessage, MAX_NEWS_PER_DAY*BUFF_SIZE, 0);
	Utils.Info("TODO: GetTodayNews Implement this");
	//rawMessage = Connector::ProcessStringData(instr, clientString);
	if ( StringLen(rawMessage) > 0 )
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

   
void TradeConnector::SaveAllSettings(string strExpertData, string strDataOrders)
{      
   if (!IsEA)
      return;
   expert.Fill(Utils.GetAccountNumer(), Period(), Symbol(), this.EAName, magic, 0, this.isMaster);
   if (StringLen(strExpertData) > 0)
      expert.obj["Data"] = strExpertData;
   
   if (StringLen(strDataOrders) > 0)
      expert.obj["Orders"] = strDataOrders;

   Signal* signal = new Signal(SignalToServer, SIGNAL_SAVE_EXPERT, magic);
   
   signal.obj["Data"] = expert.Persistent().Serialize();
   PostMethod("PostSignal", signal);
   DELETE_PTR(signal);
}

uint TradeConnector::DeInit(int Reason)
{
   if (magic != FAKE_MAGICNUMBER)
   {  
      CJAVal parameters;
      expert.Fill(Utils.GetAccountNumer(), Period(), Symbol(), this.EAName, magic, 0, this.isMaster);
      // expert.FillExpertInfo(parameters);
      SignalType type = SIGNAL_DEINIT_EXPERT;
      if (!IsEA)
         type = SIGNAL_DEINIT_TERMINAL;
      Signal* signal = new Signal(SignalToServer, type, magic);
      signal.obj["Data"] = expert.Persistent().Serialize();
      PostMethod("PostSignal", signal);
      DELETE_PTR(signal);
      DELETE_PTR(expert)
   }
   return 0;
}

void TradeConnector::InitNewsVariables(string strMagic)
{
   variableNewsSignal = StringFormat("NewsSignal%s", strMagic);
   variableNewsSignalTime = StringFormat("NewsSignal%sTime", strMagic);
   variableNewsSignalName = StringFormat("NewsSignal%sName|", strMagic);

   GlobalVariablesDeleteAll(variableNewsSignal);

   GlobalVariableSet(variableNewsSignal, 0.0);
   GlobalVariableSet(variableNewsSignalTime, 0);
   GlobalVariableSet(variableNewsSignalName, 0.0);
}

void TradeConnector::SetGlobalNewsSignal()
{
   GlobalVariableSet(variableNewsSignal, storeEvent.Importance);
   GlobalVariableSet(variableNewsSignalTime, storeEvent.RaiseTime());
   string name = storeEvent.GetName();
   GlobalVariableSet(variableNewsSignalName + name, storeEvent.Importance);   
   //Print(StringFormat("Set Global News Event: %s", storeEvent.ToString()) );
}

void TradeConnector::Log(string message)
{
   CJAVal parameters;
   parameters.Deserialize(clientString);
   parameters["message"] = message;
   Signal* signal = new Signal(SignalToServer, SIGNAL_POST_LOG, MagicNumber());
   signal.obj["Data"] = parameters.Serialize();
   PostSignal(signal);
   //Connector::PostSignal(clientString, SIGNAL_POST_LOG, SignalToServer, parameters.Serialize());
}     

Signal* TradeConnector::ListenSignal(long flags, long ObjectId)
{
   Signal signal((SignalFlags)flags, (SignalType)0, ObjectId);
   string value = SendMethod("ListenSignal", &signal);
   if ((StringLen(value) > 0) && (value != NULL))
   {
       return new Signal(value);
   }
   return NULL;
}

Signal* TradeConnector::SendSignal(Signal* s)
{
   string value = SendMethod("SendSignal", s);
   if ((StringLen(value) > 0) && (value != NULL))
   {
       return new Signal(value);
   }
   return NULL;
}

void TradeConnector::PostSignal(Signal* s)
{
   if (s.flags == SignalToExpert)
   {
       // Handle signal locally.
       PostSignalLocally(s);
       return;
   }   
   PostMethod("PostSignal", s);
   DELETE_PTR(s);
}

void TradeConnector::PostSignalLocally(Signal* signal)
{
   if (IsEA)
   {
      ushort event_id = (ushort)signal.type;
      if (event_id != 0)
      {
         this.controller.HandleSignal(event_id,signal.ObjectId,signal.Value,signal.Serialize());
      }
      DELETE_PTR(signal);

      //string ss = signal.Serialize();
      //EventChartCustom(Utils.Trade().ChartId(), event_id, signal.ObjectId, signal.Value, ss);
      //DELETE_PTR(signal);
   }
}

void TradeConnector::DealsHistory(int days) 
{    
    datetime dto = TimeCurrent();
    MqlDateTime mqlDt;
    TimeToStruct(dto, mqlDt);
    mqlDt.day_of_year = mqlDt.day_of_year - days;
    mqlDt.hour = 1;
    mqlDt.min = 1;
    mqlDt.sec = 1;
    mqlDt.day = mqlDt.day - days;
    datetime from = StructToTime(mqlDt);
    if (days <= 0)
      from = 0;
    if (!HistorySelect(from, dto))
    {
         Utils.Info(StringFormat("Failed to retrieve Deals history for %d days", days));
         return;
    }
    uint total = HistoryDealsTotal(); 
    if ( total <= 0 )
       return;
    ulong ticket = 0;
    Signal* retSignal = new Signal(SignalToServer, SIGNAL_DEALS_HISTORY, MagicNumber());
    double dailyProfit = 0;
    for ( uint i = 0;i<total;i++ )
    { 
         if ((ticket = HistoryDealGetTicket(i)) > 0) 
         {
            Deal* deal = new Deal(ticket);
            if (deal.entry == DEAL_ENTRY_IN) {
               DELETE_PTR(deal)
               continue;
            }
            if ( !this.IsEA )
               retSignal.obj["Data"].Add(deal.Persistent());
            dailyProfit += deal.profit;
            Utils.SetDailyProfit(dailyProfit);
            DELETE_PTR(deal)
        }
    }    
 
    if ( this.IsEA )
       return;  // exit if not in service

    // Run this code only in service mode
    PostSignal(retSignal);
}

