//+------------------------------------------------------------------+
//|                                                         OsMA.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|        Modified by Cobraforex for THV System, www.cobraforex.com |
//|                                    Copyright © 2006, Robert Hill |
//|                                    Copyright © 2008, Linuxser    |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2006, Robert Hill"
#property  copyright "Copyright © 2008, Linuxser and Forex-TSD"
#property  link      "http://www.metaquotes.net/"
//---- indicator settings
#property  indicator_separate_window
#ifdef __MQL5__
#property  indicator_buffers 7
#else
#property  indicator_buffers 2
#endif
#property  indicator_color1  LimeGreen
#property  indicator_color2  FireBrick

#property  indicator_plots    2

#property  indicator_type1   DRAW_HISTOGRAM
#property  indicator_style1  STYLE_SOLID
#property  indicator_width1  2
#property  indicator_type2   DRAW_HISTOGRAM
#property  indicator_style2  STYLE_SOLID
#property  indicator_width2  2

#include <XTrade\IUtils.mqh>
#include <MovingAverages.mqh>
   
//---- indicator parameters
//extern bool SoundON=false;
//extern bool EmailON=false;
//extern bool HistogramAlarm=false;
//extern bool ZeroLineAlarm=false;
input int FastEMA=12;
input int SlowEMA=26;
input int SignalSMA=9;

//---- indicator buffers
double     OsmaBuffer[];
double     MacdBuffer[];
double     SignalBuffer[];
double HistogramBufferUp[];
double HistogramBufferDown[];
double                   ExtFastMaBuffer[];
double                   ExtSlowMaBuffer[];
//bool HistAboveZero = false;
//bool HistBelowZero = false;
//bool MACDAboveZero = false;
//bool MACDBelowZero = false;

bool setAsSeries = false;

int ThriftPORT = Constants::MQL_PORT;
int MASlowHandle = INVALID_HANDLE;
int MAFastHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//---- 2 additional buffers are used for counting.
#ifdef __MQL4__
   IndicatorBuffers(5);
   setAsSeries = true;
#endif   
//---- drawing settings

   string name = StringFormat("OsMA(%d,%d,%d)", FastEMA, SlowEMA, SignalSMA);
   Utils = CreateUtils((short)ThriftPORT, name); 
   if (Utils == NULL)
      Print("Failed create Utils!!!");
      
   Utils.SetIndiName(name);
   
   Utils.AddBuffer(0, OsmaBuffer, setAsSeries, "Osma", SignalSMA);

   Utils.AddBuffer(1, HistogramBufferUp, setAsSeries, "Up", SignalSMA);
   //SetIndexDrawBegin(0,SignalSMA);
   //SetIndexStyle(0,DRAW_HISTOGRAM,STYLE_SOLID);
   //SetIndexBuffer(0,HistogramBufferUp);
   
   Utils.AddBuffer(2, HistogramBufferDown, setAsSeries, "Down", 0);
   //SetIndexStyle(1,DRAW_HISTOGRAM,STYLE_SOLID);
   //SetIndexBuffer(1,HistogramBufferDown);
   //IndicatorDigits(Digits+2);

//---- 3 indicator buffers mapping
   //Utils.AddBuffer(2, OsmaBuffer, setAsSeries, "Osma", INDICATOR_CALCULATIONS);
   //Utils.AddBuffer(3, MacdBuffer, setAsSeries, "MACD", INDICATOR_CALCULATIONS);
   //Utils.AddBuffer(4, SignalBuffer, setAsSeries, "Signal", INDICATOR_CALCULATIONS);
   //SetIndexBuffer(2,OsmaBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,MacdBuffer, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SignalBuffer, INDICATOR_CALCULATIONS);   
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 2); 
   
#ifdef  __MQL5__ 
   SetIndexBuffer(5,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);
  
   MASlowHandle = iMA(Symbol(),0,SlowEMA,0,MODE_EMA,PRICE_CLOSE);
   if (MASlowHandle == INVALID_HANDLE)
      Utils.Info("Failed Init iMA Slow!!!");
   MAFastHandle = iMA(Symbol(),0,FastEMA,0,MODE_EMA,PRICE_CLOSE);
   if (MAFastHandle == INVALID_HANDLE)
      Utils.Info("Failed Init iMA Fast!!!");
#else
#endif    
   
//---- initialization done
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) 
{
#ifdef __MQL5__
  IndicatorRelease(MASlowHandle);
  IndicatorRelease(MAFastHandle);
#endif 
  DELETE_PTR(Utils)
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   double current, prev = 0;
#ifdef __MQL5__   
       
   ArraySetAsSeries(time, setAsSeries);
   ArraySetAsSeries(open, setAsSeries);
   ArraySetAsSeries(close, setAsSeries);
   ArraySetAsSeries(high, setAsSeries);
   ArraySetAsSeries(low, setAsSeries);
   if(rates_total<SignalSMA)
      return(0);
//--- not all data may be calculated

   int calculated=BarsCalculated(MASlowHandle);
   if(calculated<rates_total)
   {
      Print("Not all data of ExtSlowMaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
   }
      int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
//--- get Fast EMA buffer
   if(IsStopped()) 
      return(0); //Checking for stop flag
   if(CopyBuffer(MAFastHandle,0,0,to_copy,ExtFastMaBuffer)<=0)
     {
      Print("Getting fast EMA is failed! Error",GetLastError());
      return(0);
     }
//--- get SlowSMA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(MASlowHandle,0,0,to_copy,ExtSlowMaBuffer)<=0)
     {
      Print("Getting slow SMA is failed! Error",GetLastError());
      return(0);
     }
//---
   int i,limit;
   if(prev_calculated==0)
      limit=1;
   else 
       limit=prev_calculated-1;
//--- the main loop of calculations
   for(i=limit;i<rates_total;i++)
     {
      //--- calculate MACD
      MacdBuffer[i]=ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];
     }
//--- calculate Signal
   SimpleMAOnBuffer(rates_total,prev_calculated,0,SignalSMA,MacdBuffer,SignalBuffer);
//--- calculate OsMA
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      OsmaBuffer[i]=MacdBuffer[i]-SignalBuffer[i];
     }

#else 
   int i = 0;
   int bars = Bars;
   int limit;
   int counted_bars = IndicatorCounted();
//---- last counted bar will be recounted
   if(counted_bars > 0)
      counted_bars--;
   limit = bars - counted_bars - 1;
   int sz = ArraySize(MacdBuffer);
//---- macd counted in the 1-st additional buffer

   for(i=0; i<limit; i++)
   {
      MacdBuffer[i] = iMA(NULL,0,FastEMA,0,MODE_EMA,PRICE_CLOSE,i)-iMA(NULL,0,SlowEMA,0,MODE_EMA,PRICE_CLOSE,i);
   }   
   for (i=0; i<limit; i++)
   {
      SignalBuffer[i] = iMAOnArray(MacdBuffer,bars,SignalSMA,0,MODE_SMA,i);
   }
   for(i=0; i<limit; i++)
      OsmaBuffer[i]=MacdBuffer[i]-SignalBuffer[i];
#endif      
   
//---- main loop
#ifdef __MQL5__
   //for(i=limit;i<rates_total-1 && !IsStopped();i++)
   for(i=rates_total-1;i >= (limit) && !IsStopped();i--)
#else
   for(i=0; i<limit; i++)
#endif 
   {
      HistogramBufferUp[i] = 0;
      HistogramBufferDown[i] = 0;
      current = MacdBuffer[i] - SignalBuffer[i];
#ifdef __MQL5__      
      prev = MacdBuffer[i-1] - SignalBuffer[i-1];
#else 
      prev = MacdBuffer[i+1] - SignalBuffer[i+1];
#endif      
      if (current > prev)
      {
        HistogramBufferUp[i] = current;
        HistogramBufferDown[i] = 0.0;
      }
      else
      {
        HistogramBufferDown[i] = current;
        HistogramBufferUp[i] = 0.0;
      }
      
      //if (MACDAboveZero) 
      //   Utils.Info("\nThe trend has changed to UP");
      //if (MACDBelowZero)
      //   Utils.Info("\nThe trend has changed to DOWN");
      
      //if (i == 1)
      //{
// Check for Histogram Change Color
        /*
        if  (HistogramAlarm==true)
        {
        if (HistogramBufferUp[i] > HistogramBufferDown[i + 1])
        {
// Cross up
         if (HistAboveZero == false)
         {
           HistAboveZero=true;
           HistBelowZero=false;
           //if (SoundON) Alert("OSMA is Positive","\n Time=",TimeToStr(CurTime(),TIME_DATE)," ",TimeHour(CurTime()),":",TimeMinute(CurTime()),"\n Symbol=",Symbol()," Period=",Period());
           //if (EmailON) SendMail("OSMA is Positive", "MACD Crossed up, Date="+TimeToStr(CurTime(),TIME_DATE)+" "+TimeHour(CurTime())+":"+TimeMinute(CurTime())+" Symbol="+Symbol()+" Period="+Period());
         }
        }
        else if (HistogramBufferDown[i] <  HistogramBufferUp[i + 1] > 0)
        {
// Cross down
         if (HistBelowZero == false)
         {
          HistBelowZero=true;
          HistAboveZero=false;
          //if (SoundON) Alert("OSMA is Negative","\n Date=",TimeToStr(CurTime(),TIME_DATE)," ",TimeHour(CurTime()),":",TimeMinute(CurTime()),"\n Symbol=",Symbol()," Period=",Period());
          //if (EmailON) SendMail("OSMA is Negative","MACD Crossed Down, Date="+TimeToStr(CurTime(),TIME_DATE)+" "+TimeHour(CurTime())+":"+TimeMinute(CurTime())+" Symbol="+Symbol()+" Period="+Period());
         }
        }
        */
        //}
// Check for MACD Signal line crossing 0 line
        /*if (ZeroLineAlarm==true)
        {
        if (OsmaBuffer[i] > 0 && OsmaBuffer[i + 1] < 0)
        {
// Cross up
         if (MACDAboveZero == false)
         {
           MACDAboveZero=true;
           MACDBelowZero=false;
           //if (SoundON) Alert("Histogram is Above Zero Line","\n Time=",TimeToStr(CurTime(),TIME_DATE)," ",TimeHour(CurTime()),":",TimeMinute(CurTime()),"\n Symbol=",Symbol()," Period=",Period());
           //if (EmailON) SendMail("Histogram is Above Zero Line", "OSMA Crossed up, Date="+TimeToStr(CurTime(),TIME_DATE)+" "+TimeHour(CurTime())+":"+TimeMinute(CurTime())+" Symbol="+Symbol()+" Period="+Period());
         }
        }
        else if (OsmaBuffer[i] < 0 && OsmaBuffer[i + 1] > 0)
        {
// Cross down
         if (MACDBelowZero == false)
         {
          MACDBelowZero=true;
          MACDAboveZero=false;
          //if (SoundON) Alert("Histogram is Below Zero Line","\n Date=",TimeToStr(CurTime(),TIME_DATE)," ",TimeHour(CurTime()),":",TimeMinute(CurTime()),"\n Symbol=",Symbol()," Period=",Period());
          //if (EmailON) SendMail("Histogram is Below Zero Line","OSMA Crossed Down, Date="+TimeToStr(CurTime(),TIME_DATE)+" "+TimeHour(CurTime())+":"+TimeMinute(CurTime())+" Symbol="+Symbol()+" Period="+Period());
         }
        }
        */
   }
      
//---- done
   return(rates_total);
}