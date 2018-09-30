//+------------------------------------------------------------------+ 
//|                                          i-IntradayFibonacci.mq5 | 
//|                         Copyright © 2007, Ким Игорь В. aka KimIV | 
//|                                              http://www.kimiv.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2007, Ким Игорь В. aka KimIV"
#property link "http://www.kimiv.ru"
//https://www.mql5.com/ru/code/1613
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window
//---- количество индикаторных буферов 8
#property indicator_buffers 8 
//---- использовано всего 8 графических построений
#property indicator_plots   8
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET 0 // Константа для возврата терминалу команды на пересчёт индикатора
#define INDICATOR_NAME "i-IntradayFibonacci" // Константа для имени индикатора
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикаторов в виде линий
#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW
#property indicator_type3   DRAW_ARROW
#property indicator_type4   DRAW_ARROW
#property indicator_type5   DRAW_ARROW
#property indicator_type6   DRAW_ARROW
#property indicator_type7   DRAW_ARROW
#property indicator_type8   DRAW_ARROW
//---- в качестве цветов индикатора использованы
#property indicator_color1 clrBlue
#property indicator_color2 clrLime
#property indicator_color3 clrOrange
#property indicator_color4 clrDeepPink
#property indicator_color5 clrDeepPink
#property indicator_color6 clrOrange
#property indicator_color7 clrLime
#property indicator_color8 clrBlue
//---- толщина линий индикаторов равна 1
#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
#property indicator_width6  1
#property indicator_width7  1
#property indicator_width8  1
//---- отображение лэйб индикатора
#property indicator_label1  INDICATOR_NAME+" +0.764"
#property indicator_label2  INDICATOR_NAME+" +0.618"
#property indicator_label3  INDICATOR_NAME+" +0.382"
#property indicator_label4  INDICATOR_NAME+" +0.236"
#property indicator_label1  INDICATOR_NAME+" -0.236"
#property indicator_label2  INDICATOR_NAME+" -0.382"
#property indicator_label3  INDICATOR_NAME+" -0.618"
#property indicator_label4  INDICATOR_NAME+" -0.764"

//+-------------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА       |
//+-------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_D1;//Период графика
input int Shift=0; // сдвиг индикатора по горизонтали в барах
input int PriceShift=0; // cдвиг индикатора по вертикали в пунктах
//+-------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer1[],IndBuffer2[],IndBuffer3[],IndBuffer4[];
double IndBuffer5[],IndBuffer6[],IndBuffer7[],IndBuffer8[];
//---- Объявление переменной для хранения результата инициализации индикатора
bool Init;
//---- Объявление стрингов
string Symbol_;
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
void IndInit(int Number,double& Arrow[],int DRAW_BEGIN_,double EMPTY_VALUE_)
  {
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(Number,Arrow,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,DRAW_BEGIN_);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,EMPTY_VALUE_);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(Arrow,true);
//----
  }
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
void OnInit()
  {
   Init=true;
//---- проверка периодов графиков на корректность
   if(TimeFrame<Period() && TimeFrame!=PERIOD_CURRENT)
     {
      Print("Период графика не может быть меньше периода текущего графика");
      Init=false;
      return;
     }

//---- Инициализация переменных 
   min_rates_total=int(PeriodSeconds(TimeFrame)/PeriodSeconds(PERIOD_CURRENT)+1);
   Symbol_=Symbol();

//----
   IndInit(0,IndBuffer1,min_rates_total,0.0);
   IndInit(1,IndBuffer2,min_rates_total,0.0);
   IndInit(2,IndBuffer3,min_rates_total,0.0);
   IndInit(3,IndBuffer4,min_rates_total,0.0);
   IndInit(4,IndBuffer5,min_rates_total,0.0);
   IndInit(5,IndBuffer6,min_rates_total,0.0);
   IndInit(6,IndBuffer7,min_rates_total,0.0);
   IndInit(7,IndBuffer8,min_rates_total,0.0);

//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,INDICATOR_NAME);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total || !Init) return(RESET);

//---- объявления локальных переменных 
   double iHigh[2],iLow[2];
   int limit,bar;
   datetime iTime[1];
   static uint LastCountBar;

//---- расчёты необходимого количества копируемых данных и
//стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчёта всех баров
      LastCountBar=rates_total;
     }
   else limit=int(LastCountBar)+rates_total-prev_calculated; // стартовый номер для расчёта новых баров 

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(time,true);

//---- основной цикл расчёта индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- копируем вновь появившиеся данные в массив iTime
      if(CopyTime(Symbol_,TimeFrame,time[bar],1,iTime)<=0) return(RESET);

      if(time[bar]>=iTime[0] && time[bar+1]<iTime[0])
        {
         LastCountBar=bar;

         //---- копируем вновь появившиеся данные в массивы
         if(CopyLow(Symbol_,TimeFrame,time[bar],2,iLow)<=0) return(RESET);
         if(CopyHigh(Symbol_,TimeFrame,time[bar],2,iHigh)<=0) return(RESET);

         double Range=iHigh[0]-iLow[0];
         IndBuffer1[bar]=iHigh[0]+Range*0.764;
         IndBuffer2[bar]=iHigh[0]+Range*0.618;
         IndBuffer3[bar]=iHigh[0]+Range*0.382;
         IndBuffer4[bar]=iHigh[0]+Range*0.236;
         IndBuffer5[bar]=iLow[0]-Range*0.236;
         IndBuffer6[bar]=iLow[0]-Range*0.382;
         IndBuffer7[bar]=iLow[0]-Range*0.618;
         IndBuffer8[bar]=iLow[0]-Range*0.764;
        }
      else
        {
         IndBuffer1[bar]=IndBuffer1[bar+1];
         IndBuffer2[bar]=IndBuffer2[bar+1];
         IndBuffer3[bar]=IndBuffer3[bar+1];
         IndBuffer4[bar]=IndBuffer4[bar+1];
         IndBuffer5[bar]=IndBuffer5[bar+1];
         IndBuffer6[bar]=IndBuffer6[bar+1];
         IndBuffer7[bar]=IndBuffer7[bar+1];
         IndBuffer8[bar]=IndBuffer8[bar+1];
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
