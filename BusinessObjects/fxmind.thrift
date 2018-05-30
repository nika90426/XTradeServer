/**
 * The first thing to know about are types. The available types in Thrift are:
 *
 *  bool        Boolean, one byte
 *  byte        Signed byte
 *  i16         Signed 16-bit integer
 *  i32         Signed 32-bit integer
 *  i64         Signed 64-bit integer
 *  double      64-bit floating point value
 *  string      String
 *  binary      Blob (byte array)
 *  map<t1,t2>  Map from one type to another
 *  list<t1>    Ordered list of one type
 *  set<t1>     Set of unique elements of one type
 *
 * Did you also notice that Thrift supports C style comments?
 */

// to compile:  ./thrift -r -out ../java --gen java fxmind.thrift
// thrift -r -out . --gen csharp fxmind.thrift
/**
 * Thrift files can namespace, package, or prefix their output in various
 * target languages.
 */
namespace csharp BusinessObjects
namespace java com.fxmind.global

/**
 * Thrift also lets you define constants for use across languages. Complex
 * types and structs are specified using JSON notation.
 */
const double GAP_VALUE = -125.0
const string MTDATETIMEFORMAT = "yyyy.MM.dd HH:mm"
const string MYSQLDATETIMEFORMAT = "yyyy-MM-dd HH:mm:ss"
const string SOLRDATETIMEFORMAT = "yyyy-MM-dd'T'HH:mm:ss'Z'"
const i32 SENTIMENTS_FETCH_PERIOD = 100
const i16 FXMindMQL_PORT = 2010
const i16 AppService_PORT = 2012

const string JOBGROUP_TECHDETAIL = "Technical Details"
const string JOBGROUP_OPENPOSRATIO = "Positions Ratio"
const string JOBGROUP_EXECRULES = "Run Rules"
const string JOBGROUP_NEWS = "News"
const string JOBGROUP_THRIFT = "ThriftServer"

const string CRON_MANUAL = "0 0 0 1 1 ? 2100"

const string PARAMS_SEPARATOR = "|"
const string LIST_SEPARATOR = "~"

const string SETTINGS_PROPERTY_BROKERSERVERTIMEZONE = "BrokerServerTimeZone"
const string SETTINGS_PROPERTY_PARSEHISTORY = "NewsEvent.ParseHistory"
const string SETTINGS_PROPERTY_STARTHISTORYDATE = "NewsEvent.StartHistoryDate"
const string SETTINGS_PROPERTY_USERTIMEZONE = "UserTimeZone"
const string SETTINGS_PROPERTY_NETSERVERPORT = "FXMind.NETServerPort"
const string SETTINGS_PROPERTY_ENDHISTORYDATE = "NewsEvent.EndHistoryDate"
const string SETTINGS_PROPERTY_THRIFTPORT = "FXMind.ThriftPort"
const string SETTINGS_PROPERTY_INSTALLDIR = "FXMind.InstallDir"
const string SETTINGS_PROPERTY_RUNTERMINALUSER = "FXMind.TerminalUser"
const string SETTINGS_PROPERTY_MTCOMMONFILES = "Metatrader.CommonFiles"
//const string SETTINGS_APPREGKEY = "SOFTWARE\\FXMind"

//const i32 INT32CONSTANT = 9853
//const map<string,string> MAPCONSTANT = {'hello':'world', 'goodnight':'moon'}

/**
 * You can define enums, which are just 32 bit integers. Values are optional
 * and start at 1 if not supplied, C style again.
 */
enum EnumExpertValueType {   
    ValueUndefined = 0,
    ValueInteger = 1,
    ValueShort = 2
    ValueDouble  = 3,
    ValueString = 4,
    ValueBool = 5
}

enum EnumExpertValueScope {   
    GlobalScope = 0,
    ExpertScope = 1,
    OrderScope = 3 
}

/**
 * Structs are the basic complex data structures. They are comprised of fields
 * which each have an integer identifier, a type, a symbolic name, and an
 * optional default value.
 *
 * Fields can be declared "optional", which ensures they will not be included
 * in the serialized output if they aren't set.  Note that this requires some
 * manual management in some languages.
 */
struct ScheduledJob {
  1: bool isRunning,
  2: string Group,
  3: string Name,
  4: string Log,
  5: string Schedule,
  6: i64 PrevTime,
  7: i64 NextTime
}

struct CurrencyStrengthSummary
{
  1:string Currency,
  2:double Min1,     
  3:double Min5,
  4:double Min15,
  5:double Min30,
  6:double Hourly,
  7:double Hourly5,
  8:double Daily,
  9:double Monthly
}

struct Currency
{
  1:i16 ID,
  2:string Name,     
  3:bool Enabled
}

struct TechIndicator
{
  1:i16 ID,
  2:string IndicatorName,     
  3:bool Enabled
}

struct  NewsEventInfo
{
  1:string Currency,
  2:string Name,
  3:i8     Importance,
  4:string RaiseDateTime // date returned in MTFormat
}

struct ExpertParameter
{
   1:EnumExpertValueType ValueType,
   2:EnumExpertValueScope Scope,
   3:i64 ScopeID,
   4:string Name
}

struct Order 
{
   1:i64 ticket,
   2:i8  type,
   3:i64 magic,
   4:double   lots,
   5:double   openPrice,
   6:double   closePrice,
   7:string openTime,
   8:string closeTime,
   9:double   profit,
   10:double   swapValue,
   11:double   commission,
   12:double   stopLoss,
   13:double   takeProfit,
   14:string   expiration,
   15:string   comment,
   16:string   symbol,
   17:list<ExpertParameter> parameters
}   

/**
 * Structs can also be exceptions, if they are nasty.
 */
//exception InvalidOperation {
//  1: i32 what,
//  2: string why
//}

/**
 * Ahh, now onto the cool part, defining a service. Services just need a name
 * and can optionally inherit from another service using the extends keyword.
 */
service FXMindMQL {
   
   list<string> ProcessStringData(1:map<string,string> paramsList, 2:list<string> inputData),

   list<double> ProcessDoubleData(1:map<string,string> paramsList, 2:list<string> inputData),

   i64 IsServerActive(1:map<string,string> paramsList),
   
   oneway void PostStatusMessage(1:map<string,string> paramsList),
   
   string GetGlobalProperty(1:string propName),

   //returns MagicNumber
   i64 InitExpert(1:i64 Account, 2:string ChartTimeFrame, 3:string Symbol, 4:string EAName),

   oneway void SaveExpert(1:i64 MagicNumber),

   oneway void DeInitExpert(1:i32 Reason, 2:i64 MagicNumber)

   // Load Active Orders (if exist ) from DB. Should be called after InitExpert where AdviserDBID can be obtained from result parameters list
//   map<string, Order> LoadOrders(1:i64 AdviserDBID),      

   // To Store Expert Adviser State both methods StoreOrders and StoreExpertParameters should be called 
  // oneway void StoreOrders(1:i64 AdviserDBID, 2:map<string, Order> orders),

   //oneway void StoreExpertParameters(1:i64 AdviserDBID, 2:list<ExpertParameter> parameters)
}  

service AppService {

   string GetGlobalProp(1:string name),

   oneway void SetGlobalProp(1:string name, 2:string value),

   bool InitScheduler(1:bool serverMode),

   oneway void RunJobNow(1:string group, 2:string name),

   string GetJobProp(1:string group, 2:string name, 3:string prop),

   oneway void SetJobCronSchedule(1:string group, 2:string name, 3:string cron),

   list<ScheduledJob> GetAllJobsList(),

   map<string, ScheduledJob> GetRunningJobs(),

   i64 GetJobNextTime(1:string group, 2:string name),

   i64 GetJobPrevTime(1:string group, 2:string name),

   oneway void PauseScheduler(),

   oneway void ResumeScheduler(),

   list<CurrencyStrengthSummary> GetCurrencyStrengthSummary(1:bool recalc, 2:bool bUseLast, 3:i64 startInterval, 4:i64 endInterval),

   list<Currency> GetCurrencies(),

   list<TechIndicator> GetIndicators(),

   bool IsDebug(),

   oneway void SaveCurrency(1:Currency c),

   oneway void SaveIndicator(1:TechIndicator i)
	
}

