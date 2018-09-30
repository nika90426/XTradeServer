//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_type1   DRAW_ARROW 
#property indicator_color1 Blue
#property indicator_style1 STYLE_DOT
#property indicator_width1 1
#property indicator_type2   DRAW_ARROW 
#property indicator_color2 Red
#property indicator_style2 STYLE_DOT
#property indicator_width2 1

#include <FXMind\IUtils.mqh>

int ZZBack   =      1;

//-------------------------------
// Input parameters
//-------------------------------
input int  ZZDepth                = 12;
input int  ZZDev                  = 5;

bool CalculateOnBarClose    = true;

//-------------------------------
// Buffers
//-------------------------------
double ExtMapBuffer1[];
double ExtMapBuffer2[];

//-------------------------------
// Internal variables
//-------------------------------

// Fractals value -mine-
double fr_resistance       = 0;
double fr_support          = EMPTY_VALUE;
bool fr_resistance_change  = EMPTY_VALUE;
bool fr_support_change     = EMPTY_VALUE;

// zzvalues
double zzhigh = 0;
double zzlow = 0;

// Offset in chart
int    nShift;   
bool setAsSeries = true;
int ThriftPORT = Constants::FXMindMQL_PORT;
int ZigZagHandle = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   string name = "Fractal Zig Zag";
   Utils = CreateUtils((short)ThriftPORT, name); 
   if (Utils == NULL)
      Print("Failed create Utils!!!");
      
    Utils.SetIndiName(name);
    
    Utils.AddBuffer(0, ExtMapBuffer1, setAsSeries, "Fractal Up", 0);
    Utils.AddBuffer(1, ExtMapBuffer2, setAsSeries, "Fractal Down", 0);

#ifdef  __MQL5__    
    PlotIndexSetInteger(0, PLOT_ARROW, 233);
    PlotIndexSetInteger(1, PLOT_ARROW, 234);
#else     
    SetIndexArrow(0, 233);
    SetIndexArrow(1, 234);
#endif       
    
    PlotIndexSetDouble(0,PLOT_EMPTY_VALUE, 0);
    PlotIndexSetDouble(1,PLOT_EMPTY_VALUE, 0);
    
   PlotIndexSetString(0,PLOT_LABEL,"Fractal Up");
   PlotIndexSetString(1,PLOT_LABEL,"Fractal Down");

    // Chart offset calculation
    switch(Period())
    {
        case     PERIOD_M1: nShift = 1;   break;    
        case     PERIOD_M5: nShift = 3;   break; 
        case    PERIOD_M15: nShift = 5;   break; 
        case    PERIOD_M30: nShift = 10;  break; 
        case    PERIOD_H1: nShift = 15;  break; 
        case   PERIOD_H4: nShift = 20;  break; 
        case  PERIOD_D1: nShift = 80;  break; 
        case PERIOD_W1: nShift = 100; break; 
        case PERIOD_MN1: nShift = 200; break;               
    }
    nShift = nShift * 2;
    
#ifdef __MQL5__
    ZigZagHandle = iCustom(Symbol(), 0, "Examples\\ZigZag", ZZDepth, ZZDev, ZZBack);//, 1, i);
    if (ZigZagHandle == INVALID_HANDLE)
    {
       Utils.Info("Failed to load ZigZag Indicator!");
       return INIT_FAILED;  
    }
#endif     
 
//bool v = ArrayGetAsSeries(ExtMapBuffer1);
   Utils.Info(StringFormat("%s Init: %d, %d",name, ZZDepth, ZZDev));


    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) 
{
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

#ifdef __MQL5__     
   ArraySetAsSeries(time, setAsSeries);
   ArraySetAsSeries(open, setAsSeries);
   ArraySetAsSeries(close, setAsSeries);
   ArraySetAsSeries(high, setAsSeries);
   ArraySetAsSeries(low, setAsSeries);
   int calculated=BarsCalculated(ZigZagHandle);
   if(calculated<rates_total)
   {
      Utils.Info(StringFormat("Not all data of ZigZag is calculated (%d bars ). Error %d", calculated, GetLastError()));
      return(0);
   }
#endif
    // Start, limit, etc..
    int start = 0;
    int limit;
    int counted_bars = prev_calculated;//IndicatorCounted();

    // nothing else to do?
    if(counted_bars < 0) 
    {  
        Utils.Info(StringFormat("CountedBars=%d", counted_bars));
        return(-1);
    }

    // do not check repeated bars
    limit = Utils.Bars() - 1;// - counted_bars;
    
    // Check if ignore bar 0
    if(CalculateOnBarClose == true)
        start = 1;
    
    int i = 0;
     double UpperBuf[1];
     double DownBuf[1];
    // Check the signal foreach bar from past to present
    for(i = limit; i >= start; i--)
    {
        ExtMapBuffer1[i] = 0;
        ExtMapBuffer1[2] = 0;
        
        // Zig Zag high
#ifdef __MQL5__        
        if (CopyBuffer(ZigZagHandle, 1, i, 1, UpperBuf) <= 0)
            Utils.Info("Failed CopyBuffer in ZigZag");
          
        double zzhighn = UpperBuf[0]; 
#else         
        double zzhighn = iCustom(Symbol(), 0, "ZigZag", ZZDepth, ZZDev, ZZBack, 1, i);
#endif         
        if(zzhighn != 0) zzhigh = zzhighn;
        
        // Zig Zag low
#ifdef __MQL5__        
        if (CopyBuffer(ZigZagHandle, 2, i, 1, DownBuf) <= 0)
            Utils.Info("Failed CopyBuffer in ZigZag");

        double zzlown  = DownBuf[0];//iCustom(Symbol(), 0, "ZigZag", ZZDepth, ZZDev, ZZBack, 2, i);
#else         
        double zzlown  = iCustom(Symbol(), 0, "ZigZag", ZZDepth, ZZDev, ZZBack, 2, i);
#endif         
        if(zzlown != 0) zzlow = zzlown;
     
        // Last fractals
        double resistance = upper_fractal(i);
        double support = lower_fractal(i);
        
        //--------------------------------------------------------
        // Show signals
        //--------------------------------------------------------
        
        // Show signal if it is a fractal and matches last zigzag high value
        if(fr_support_change == true && fr_support == zzlow)
        {
            // Show arrow on fractal and pricetag
            ExtMapBuffer1[i+2] = fr_support - nShift*Point();
            //Utils.Info(StringFormat("BUY Signal FractalZigZag %g",  ExtMapBuffer1[i+2]));
            
        } else 
       
        // Show signal if it is a fractal and matches last zigzag low value
        if(fr_resistance_change == true && fr_resistance == zzhigh)
        {
            // Show arrow on fractal and pricetag
            ExtMapBuffer2[i+2] = fr_resistance + nShift*Point();
            //Utils.Info(StringFormat("SELL Signal FractalZigZag %g",  ExtMapBuffer2[i+2]));
        }
    }
    return(rates_total);
}

//+------------------------------------------------------------------+
//| Custom code ahead
//+------------------------------------------------------------------+

/**
* Returns fractal resistance
* @param int shift
*/
double upper_fractal(int shift = 1)
{
   double middle = iHigh(Symbol(), 0, shift + 2);
   double v1 = iHigh(Symbol(), 0, shift);
   double v2 = iHigh(Symbol(), 0, shift+1);
   double v3 = iHigh(Symbol(), 0, shift + 3);
   double v4 = iHigh(Symbol(), 0, shift + 4);
   if(middle > v1 && middle > v2 && middle > v3 && middle > v4/* && v2 > v1 && v3 > v4*/)
   {
      fr_resistance = middle;
      fr_resistance_change = true;
   } else {
      fr_resistance_change = false;
   }
   return(fr_resistance);
}

/**
* Returns fractal support and stores wether it has changed or not
* @param int shift
*/

double lower_fractal(int shift = 1)
{
   double middle = iLow(Symbol(), 0, shift + 2);
   double v1 = iLow(Symbol(), 0, shift);
   double v2 = iLow(Symbol(), 0, shift+1);
   double v3 = iLow(Symbol(), 0, shift + 3);
   double v4 = iLow(Symbol(), 0, shift + 4);
   if(middle < v1 && middle < v2 && middle < v3 && middle < v4/* && v2 < v1 && v3 < v4*/)
   {
      fr_support = middle;
      fr_support_change = true;
   } else {
      fr_support_change = false;
   }
   return(fr_support);
}

//+------------------------------------------------------------------+

