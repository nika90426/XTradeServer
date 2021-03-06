#property library
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#include <XTrade\IndiBase.mqh>
#include <XTrade\Orders.mqh>
#include <XTrade\InputTypes.mqh>
#include <XTrade\SSA\CSSAParamSet.mqh>

class SSAFastTrend : public IndiBase
{
protected:
   CSSATrendParamSet Params;

public:
   SSAFastTrend();
   ~SSAFastTrend(void);
   virtual bool Init(ENUM_TIMEFRAMES timeframe);
   virtual void Process();
   virtual void Trail(Order &order, int indent) {}
   virtual void Delete();
   virtual int LoadIndicator(string pathSet);
   virtual double GetData(const int buffer_num,const int index) const;   
   virtual int       Type(void) const { return(IND_CUSTOM); }
};
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SSAFastTrend::SSAFastTrend() 
{
   m_name = "Market\\SSA Fast Trend Forecast";    
}

int SSAFastTrend::LoadIndicator(string pathSet)
{
 //int ni = Params.FileSetLoad(pathSet);
   Params.ForecastMethod=2;
   Params.SegmentLength=1024;
   Params.SW=6;
   Params.FastNoiseLevel=0.25;
   Params.SlowNoiseLevel=0.25;
   Params.FrcstConvertMethod=ConvNorm;
   Params.ForecastUpdateON=0;// ForecastSmoothON
   Params.NWindVolat=16;
   Params.RefreshPeriod=60;
   Params.ForecastPoints=12;
   Params.BackwardShift=0;
   Params.VISUAL_OPTIONS="* VISUAL OPTIONS *";
   Params.NormalColor=16711680;
   Params.PredictColor=13749760;
   Params.INTERFACE="* INTERFACE *";
   Params.MagicNumber=19661021100;
// Params.WriteFileON=0;
//Params.InpNumRecords=0;

   //Params.LengthWithPrediction = Params.SegmentLength + Params.ForecastPoints;   
  return 0;
}


bool SSAFastTrend::Init(ENUM_TIMEFRAMES timeframe)
{
   if (Initialized())
      return true;
   m_period = timeframe;
   SetSymbolPeriod(Utils.Symbol, m_period);
   MqlParam params[19];  
   
   LoadIndicator(""); 
   params[0].type = TYPE_STRING;
   params[0].string_value = m_name;
   params[1].type = TYPE_INT;
   params[1].integer_value = Params.ForecastMethod;
   params[2].type = TYPE_INT;
   params[2].integer_value = Params.SegmentLength;
   params[3].type = TYPE_INT;
   params[3].integer_value = Params.SW;
   params[4].type = TYPE_DOUBLE;
   params[4].double_value = Params.FastNoiseLevel;
   params[5].type = TYPE_DOUBLE;
   params[5].double_value = Params.SlowNoiseLevel;
   params[6].type = TYPE_INT;
   params[6].integer_value = Params.FrcstConvertMethod;
   params[7].type = TYPE_INT;
   params[7].integer_value = Params.ForecastUpdateON;
   params[8].type = TYPE_INT;
   params[8].integer_value = Params.NWindVolat;
   params[9].type = TYPE_INT;
   params[9].integer_value = Params.RefreshPeriod;
   params[10].type = TYPE_INT;
   params[10].integer_value = Params.ForecastPoints;
   params[11].type = TYPE_INT;
   params[11].integer_value = Params.BackwardShift;
   params[12].type = TYPE_STRING;
   params[12].string_value = Params.VISUAL_OPTIONS;
   params[13].type = TYPE_INT;
   params[13].integer_value = Params.NormalColor;
   params[14].type = TYPE_INT;
   params[14].integer_value = Params.PredictColor;
   params[15].type = TYPE_STRING;
   params[15].string_value = Params.INTERFACE;
   params[16].type = TYPE_INT;
   params[16].integer_value = Params.MagicNumber;
   params[17].type = TYPE_INT;
   params[17].integer_value = 0;
   params[18].type = TYPE_INT;
   params[18].integer_value = 0;
  // params[18].type = TYPE_INT;
  // params[18].integer_value = PRICE_CLOSE;
   
   m_bInited = Create(Utils.Symbol, (ENUM_TIMEFRAMES)m_period, IND_CUSTOM, ArraySize(params), params);
   if (m_bInited)
   {
      FullRelease(!Utils.IsTesting());
      AddToChart(Utils.Trade().ChartId(), Utils.Trade().SubWindow());
      return true;
   }
   Utils.Info(StringFormat("Indicator %s - failed to load!!!!!!!!!!!!!", m_name));
   return m_bInited;
}

void SSAFastTrend::Delete()
{
    if (Handle() != INVALID_HANDLE)
    {
        DeleteFromChart(Utils.Trade().ChartId(), Utils.Trade().IndiSubWindow());
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SSAFastTrend::~SSAFastTrend(void)
{
   Delete();
}

double SSAFastTrend::GetData(const int buffer_num,const int index) const
{   
#ifdef __MQL4__   
   double val = iCustom(NULL,m_period,m_name,fast_ema_period,slow_ema_period,signal_period,index);
   //Utils.Info(StringFormat("OsMA BufIndex=%d, index=%d, val=%g", buffer_num, index, val));
   return val;
#else   
   double Buff[1];
   CopyBuffer(m_handle, buffer_num, index, 1, Buff); 
   return Buff[0];
#endif    
}

void SSAFastTrend::Process()
{   
   double totalMax = 0;
   double totalMin = 0;
   TYPE_TREND totalTrend = 0;
   Utils.GetIndicatorMinMax(this, totalMin, totalMax, totalTrend, 0, 200);
   
   double OSMAValue = GetData(0, 0);          
   double OSMAValuePrev = GetData(0, 1);          
   double osmaMax = 0;
   double osmaMin = 0;
   TYPE_TREND osmaTrend = 0;
   Utils.GetIndicatorMinMax(this, osmaMin, osmaMax, osmaTrend, 0, CANDLE_PATTERN_MAXBARS);
   
   if( (MathAbs(osmaMax/totalMax) < 0.1) && (MathAbs(osmaMin/totalMin) < 0.1) )
      return;
   
   double osMABuf[CANDLE_PATTERN_MAXBARS];
   Utils.GetIndicatorData(this, 0, 0, CANDLE_PATTERN_MAXBARS, osMABuf);
            
   bool osMABUY = (osMABuf[0] > osMABuf[1]) && (osMABuf[2] > osMABuf[1]) && (OSMAValue < 0); // dip
   bool osMASELL = (osMABuf[0] < osMABuf[1]) && (osMABuf[2] < osMABuf[1]) && (OSMAValue > 0); // peak
         
   MqlRates rates[];
   ArrayResize(rates, 2);
   ArraySetAsSeries(rates, true);    
   CopyRates(Utils.Symbol, (ENUM_TIMEFRAMES)m_period, 0, 2, rates);
   
   
   double priceHigh = MathMax(rates[0].high, rates[1].high);
   double priceLow = MathMin(rates[0].low, rates[1].low);

   //bool AfterNews = (!signals.InNewsPeriod); 
   /*
   if (EnableNews)
   {
      if ( ((signals.Trend == UPPER) || (signals.Trend == LATERAL)) 
            //&& AfterNews
            && (priceLow <= bandLowMin)
            //&& (mfiTrend == UPPER)
            && osMABUY
            )
      {
         signal.Init(false);   
         signal.Value = 1;
         signal.type = SignalBUY;
         if (signals.thrift.GetLastNewsEvent() != NULL)
            signal.SetName(signals.thrift.GetLastNewsEvent().GetName());
         signals.StatusString = StringFormat("TREND(%s) Before News %s On %s ", EnumToString(signals.Trend), EnumToString(signal.type), EnumToString(OsMAIndicator));
         return true;
      }         
      if ( ((signals.Trend == DOWN) || (signals.Trend == LATERAL))
            && AfterNews
            //&& (priceHigh >= bandUpperMax)
            //&& (mfiTrend == DOWN)
            && osMASELL
             )
      {
         signal.Init(false);
         signal.Value = -1; 
         signal.type = SignalSELL;
         if (signals.thrift.GetLastNewsEvent()!= NULL)
            signal.SetName(signals.thrift.GetLastNewsEvent().GetName());
         signals.StatusString = StringFormat("TREND(%s) Before News %s On %s ", EnumToString(signals.Trend),EnumToString(signal.type), EnumToString(OsMAIndicator));
         return true;
      }  
   
   } else {
   */
      if (GET(AllowSELL) //&& ((signals.Trend == DOWN) || (signals.Trend == LATERAL))
            //&& (priceHigh >= bandUpperMax)
            && (osmaTrend == DOWN)
            //&& osMASELL
             )
      {
         RaiseMarketSignal(-1, "SELL On OsMa");
         return ;
      }

      if ( GET(AllowBUY) //&& ((signals.Trend == UPPER) || (signals.Trend == LATERAL)) 
            //&& (priceLow <= bandLowMin)
            //&& (mfiTrend == UPPER)
            && (osmaTrend == UPPER)
            //&& osMABUY
            )
      {
         RaiseMarketSignal(1, "BUY On OsMa");
         return;
      }         
      
}

