//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

enum ENUM_TRAILING  
{
    TrailingDefault,
    TrailingByFractals,
    TrailingByShadows,
    TrailingRatchetB,
    TrailingByATR,
    TrailingByMA,
    TrailingUdavka,
    TrailingByTime,
    TrailingByPriceChannel,
    TrailingFiftyFifty,
    TrailingKillLoss,
    TrailingStairs,
    TrailingFilter,
    TrailingSignal,
    TrailingManual,
    TrailEachNewBar
};

#define TRAILS_COUNT  16

enum ENUM_ORDERROLE  
{
    RegularTrail, 
    GridHead, 
    GridTail,
    ShouldBeClosed,
    History,
    PendingLimit,
    PendingStop,
};

#define ROLES_COUNT  6


//+------------------------------------------------------------------+
//|   TYPE_TREND                                                     |
//+------------------------------------------------------------------+
enum TYPE_TREND
{
   LATERAL,  //Lateral
   UPPER,   //Ascending
   DOWN,    //Descending
};


/*#ifdef  __MQL4__
#define IND_BANDS    1000
#define IND_ICHIMOKU 1001
#endif 
*/

enum ENUM_INDICATORS  
{
    NoIndicator,
    //EMAWMAIndicator,
    //BillWilliamsIndicator,
    //ZigZagIndicator,
    //NewsIndicator,
    //BWZoneIndicator,
    CandleIndicator,
    //BandsIndicator,
    IshimokuIndicator,
    //IshimokuCustomIndicator,
    OsMAIndicator,
    //TMAIndicator,
    //FractalZigZagIndicator
};

enum Applied_price_ //Тип константы
{
PRICE_CLOSE_ = 1,     //Close
PRICE_OPEN_,          //Open
PRICE_HIGH_,          //High
PRICE_LOW_,           //Low
PRICE_MEDIAN_,        //Median Price (HL/2)
PRICE_TYPICAL_,       //Typical Price (HLC/3)
PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
PRICE_SIMPL_,         //Simple Price (OC/2)
PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price 
PRICE_DEMARK_         //Demark Price
};


enum CROSS_TYPE
{
   CROSS_NO = 0,
   CROSS_DOWN = 1, 
   CROSS_UP = 2,
};


enum ENUM_SIGNALWEIGHTCALC 
{
    WeightByFilter,
    WeightBySignal,
    WeightBySum,
    WeightByMultiply,
    WeightByAND
};

enum ENUM_TRADE_PANEL_SIZE  
{
    PanelNormal,
    PanelSmall,
    PanelNone
};

#define DELETE_PTR(pointer)  if (pointer != NULL) { delete pointer; pointer = NULL; }



class Constants {
public:

  static double GAP_VALUE;
  static string MTDATETIMEFORMAT;
  static string MYSQLDATETIMEFORMAT;
  static string SOLRDATETIMEFORMAT;
  static int SENTIMENTS_FETCH_PERIOD;
  static short FXMindMQL_PORT;
  static short AppService_PORT;
  static string JOBGROUP_TECHDETAIL;
  static string JOBGROUP_OPENPOSRATIO;
  static string JOBGROUP_EXECRULES;
  static string JOBGROUP_NEWS;
  static string JOBGROUP_THRIFT;
  static string CRON_MANUAL;
  static string SETTINGS_PROPERTY_BROKERSERVERTIMEZONE;
  static string SETTINGS_PROPERTY_PARSEHISTORY;
  static string SETTINGS_PROPERTY_STARTHISTORYDATE;
  static string SETTINGS_PROPERTY_USERTIMEZONE;
  static string SETTINGS_PROPERTY_NETSERVERPORT;
  static string SETTINGS_PROPERTY_ENDHISTORYDATE;
  static string SETTINGS_PROPERTY_THRIFTPORT;
  static string SETTINGS_PROPERTY_INSTALLDIR;
  static string  SETTINGS_PROPERTY_RUNTERMINALUSER;
  static string PARAMS_SEPARATOR;
  static string LIST_SEPARATOR;
  static string GLOBAL_SECTION_NAME;
};

double Constants::GAP_VALUE = -125;
string Constants::MTDATETIMEFORMAT = "yyyy.MM.dd HH:mm";
string Constants::MYSQLDATETIMEFORMAT = "yyyy-MM-dd HH:mm:ss";

string Constants::SOLRDATETIMEFORMAT = "yyyy-MM-dd'T'HH:mm:ss'Z'";

int Constants::SENTIMENTS_FETCH_PERIOD = 100;

short Constants::FXMindMQL_PORT = 2010;

short Constants::AppService_PORT = 2012;

string Constants::JOBGROUP_TECHDETAIL = "Technical Details";

string Constants::JOBGROUP_OPENPOSRATIO = "Positions Ratio";

string Constants::JOBGROUP_EXECRULES = "Run Rules";

string Constants::JOBGROUP_NEWS = "News";

string Constants::JOBGROUP_THRIFT = "ThriftServer";

string Constants::CRON_MANUAL = "0 0 0 1 1 ? 2100";

string Constants::SETTINGS_PROPERTY_BROKERSERVERTIMEZONE = "BrokerServerTimeZone";

string Constants::SETTINGS_PROPERTY_PARSEHISTORY = "NewsEvent.ParseHistory";

string Constants::SETTINGS_PROPERTY_STARTHISTORYDATE = "NewsEvent.StartHistoryDate";

string Constants::SETTINGS_PROPERTY_USERTIMEZONE = "UserTimeZone";

string Constants::SETTINGS_PROPERTY_NETSERVERPORT = "FXMind.NETServerPort";

string Constants::SETTINGS_PROPERTY_ENDHISTORYDATE = "NewsEvent.EndHistoryDate";

string Constants::SETTINGS_PROPERTY_THRIFTPORT = "FXMind.ThriftPort";

string Constants::SETTINGS_PROPERTY_INSTALLDIR = "FXMind.InstallDir";

string Constants::SETTINGS_PROPERTY_RUNTERMINALUSER = "FXMind.TerminalUser";

string Constants::PARAMS_SEPARATOR = "|";

string Constants::LIST_SEPARATOR = "~";

string Constants::GLOBAL_SECTION_NAME = "Global";

//long const Constants::DEFAULT_MAGIC_NUMBER = 1000000;



#define SLEEP_DELAY_MSEC  1000

#define RetryOnErrorNumber  5

#define ISHIMOKU_PLAIN_NOTRADE 23

#define DEFAULT_MAGIC_NUMBER 1000000

#define CANDLE_PATTERN_MAXBARS   4

#define SL_PERCENTILE  0.75
  
#define TP_PERCENTILE  0.25

//#define TP_PERCENTILEMIN  0.08

#define INPUT_VARIABLE(var_name, var_type, def_value) input var_type var_name = def_value;


#define KEY_LEFT           37
#define KEY_UP             38
#define KEY_RIGHT          39
#define KEY_DOWN           40
#define KEY_NUMLOCK_DOWN   98
#define KEY_NUMLOCK_LEFT  100
#define KEY_NUMLOCK_RIGHT 102
#define KEY_NUMLOCK_UP    104