//+------------------------------------------------------------------+
//|  Expert Adviser Object                       PriceHistogramm.mq5 |
//|                                 Copyright 2013, Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"


#property description "Индикатор «Ценовая гистограмма» (Рыночный профиль)."
#property description "Индикатор показывает где рынок будет «самым удобным» для  торговли. Для его применения необходимо использование сигнальных индикаторов или осцилляторов."
#property description "The indicator «Price histogram» (Market profile)."
#property description "The indicator shows where the market will be «most convenient» for trade. For his application use of alarm indicators or oscillators is necessary."

#define TEMPLATE_NAME   "Indicators"

#include <XTrade/PH/ClassExpert.mqh>
// Блок входных парамертов / The block input parameters
input int         DayTheHistogram   = 10;          // Дней с гистограммой / Days The Histogram
input int         DaysForCalculation= 365;          // Дней для расчета(-1 вся) / Days for calculation(-1 all)
input int         RangePercent      = 70;          // Процент диапазона / Range%
input color       InnerRange        =Indigo;       // Внутренний диапазон / Inner range
input color       OuterRange        =Magenta;      // Внешний диапазон / Outer range
input color       ControlPoint      =Orange;       // Контрольная точка(POC) / Point of Control
input bool        ShowValue         =true;         // Показать значения / Show Value

// Переменная класса / Class variable
CExpert ExtExpert;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
// Проверяем синхронизацию инструмента перед началом расчетов / We check tool synchronisation before the beginning of accounts
   int err=0;
   while(!(bool)SeriesInfoInteger(Symbol(),0,SERIES_SYNCHRONIZED) && err<AMOUNT_OF_ATTEMPTS)
     {
      Sleep(500);
      err++;
     }
// Инициализация класса CExpert / Initialization of class CExpert
   ExtExpert.RangePercent=RangePercent;
   ExtExpert.InnerRange=InnerRange;
   ExtExpert.OuterRange=OuterRange;
   ExtExpert.ControlPoint=ControlPoint;
   ExtExpert.ShowValue=ShowValue;
   ExtExpert.DaysForCalculation=DaysForCalculation;
   ExtExpert.DayTheHistogram=DayTheHistogram;
   ExtExpert.Init();
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ExtExpert.Deinit(reason);
  }
//+------------------------------------------------------------------+
//| Expert Tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| Expert Event function                                            |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // идентификатор события  
                  const long& lparam,   // параметр события типа long
                  const double& dparam, // параметр события типа double
                  const string& sparam) // параметр события типа string
  {
   ExtExpert.OnEvent(id,lparam,dparam,sparam);
  }
//+------------------------------------------------------------------+
//| Expert Timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+
