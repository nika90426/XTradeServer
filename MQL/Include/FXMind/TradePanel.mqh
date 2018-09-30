//+------------------------------------------------------------------+
//|                                                 ThriftClient.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

//--- Подключаем файлы классов
#include <FXMind\IUtils.mqh>

#include <FXMind\PanelBase.mqh>
#include <FXMind\ClassRow.mqh>
#include <FXMind\IFXMindService.mqh>
#include <FXMind\ITrade.mqh>
#include <FXMind\OrderPanel.mqh>
#include <FXMind\InputTypes.mqh>

class OrderPanel;  // forward declaration
//+------------------------------------------------------------------+
//| класс TradePanel (Главный модуль)                                |
//+------------------------------------------------------------------+
class TradePanel : public PanelBase
{
protected:
   IFXMindService*     thrift;
   //TradeMethods*     methods;
   void              OpenOrderPanel(string UIName);

public:
   OrderPanel*       orderPanel;
   string            EAString;
   string            MarketInfoString;   
   string            TrendString;
   string            SentiString;
   string            OrdersString;
   bool              bHideAll, bHideOrders; // bHideNews

   //---
   CRowType1         str1EA;       // объявление строки класса
   CRowType2         str2Spread;       // объявление строки класса
   CRowType2         str3Trend;       // объявление строки класса
   CRowType2         str4Senti;       // объявление строки класса
   CRowType1         str6Orders;       // объявление строки класса
   CRowTypeOrder*    strOrders[];
   SignalNews        news_arr[MAX_NEWS_PER_DAY];
   
   double SentiLongPos;
   double SentiShortPos;
   
   TradePanel() 
    :PanelBase(ChartID(), 0)
    ,str1EA(GetPointer(this))
    ,str2Spread(GetPointer(this))
    ,str3Trend(GetPointer(this))
    ,str4Senti(GetPointer(this))
    ,str6Orders(GetPointer(this))
   {
      thrift = Utils.Service();
      //methods = metod;
      EAString = StringFormat("%s %d", thrift.Name(), thrift.MagicNumber());
            
      MarketInfoString = "Initial Market Info";
      TrendString = "Initial Trend";
      //NewsString = "Initial News";
      SentiString = "Initial Sentiments";
      //NewsStatString = "News";
      OrdersString = "Orders";
      
      bHideAll = false;
      //bHideNews = true;
      bHideOrders = false;
      
      SentiLongPos = -1;
      SentiShortPos = -1;
      
   }
   
   static Order* OrderFromUIString(string name);

   void ~TradePanel() 
   {
      if (orderPanel != NULL)
      {
         delete orderPanel;
         orderPanel = NULL;
      }
      
      for (int i = 0; i < ArraySize(strOrders);i++) 
      {
         strOrders[i].Delete();
         DELETE_PTR(strOrders[i]);
      }      
      
      //--- деинициализация главного модуля (удаляем весь мусор)
      // delete all UI data
      ObjectsDeleteAll(chartID,subWin,-1); 
      
   }

   void              Init();           // метод запуска главного модуля
   virtual void      OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
   virtual void              Draw();
   
   
   
   //--------------------------------------------------------------------
   void UpdateShowGlobalSentiments()  
   {
      string symbolName = Symbol();
      double longVal = -1;
      double shortVal = -1;
      if (thrift.GetCurrentSentiments(longVal, shortVal) != 0)
      {
         SentiLongPos = NormalizeDouble(longVal, 2);
         SentiShortPos = NormalizeDouble(shortVal, 2);
      }   
      SentiString = StringFormat("%s : Buying (%s) Selling (%s)", symbolName, DoubleToString(SentiLongPos, 2), DoubleToString(SentiShortPos, 2));
   }
   
   //+------------------------------------------------------------------+
   void UpdateShowMarketInfo()
   {
      double spread = Utils.Spread();
      if (Digits() == 5 || Digits() == 3)
      {
         spread = spread / 10;
      }
      MarketInfoString = StringFormat("DIG=%d SPR=%s D1ATR=%d PT=%f LOTSELL=%g LOTBUY=%g MULT=%d", Digits(), DoubleToString(spread, 2), 
      Utils.Trade().GetGridStepValue(), Point() , Utils.Trade().CalculateLotSize(OP_SELL), Utils.Trade().CalculateLotSize(OP_BUY), Utils.Trade().GetMartinMultiplier());
   }

   /*string labelEventString;
   void CreateTextLabel(string msg, int Importance, datetime raisetime) 
   {
      if (StringCompare(labelEventString, msg) ==0)
            return;
      labelEventString = msg;
      Print( " Upcoming: " + msg );
      if (!Utils.IsTesting() || Utils.IsVisualMode()) {
         string name = StringFormat("newsevent%d", MathRand());
         ObjectCreate(name,OBJ_TEXT,0,raisetime,High[0]);
         ObjectSetString(0, name,OBJPROP_TEXT,msg);
         ObjectSet(name,OBJPROP_ANGLE,90);
         color clr = clrNONE;
         switch(Importance) {
             case -1:
             case 1:
             clr = clrOrange;
             break;
             case -2:
             case 2:
             clr = clrRed;
             break;
             default:
                clr = clrGray;
             break;
         }
         ObjectSet(name,OBJPROP_COLOR,clr);
      }
   }*/

};

//+------------------------------------------------------------------+
//| Метод Run класса TradePanel                                      |
//+------------------------------------------------------------------+
void TradePanel::Init()
{
   ObjectsDeleteAll(chartID,subWin,-1);
   // Comment("Программный код сгенерирован TradePanel ");
   //--- создаём главное окно и запускаем исполняемый модуль
   if (PanelSize == PanelNormal)
   {
      Property.H = 28; // height of fonts
      SetWin(5,25,1000,CORNER_LEFT_UPPER);
   } else if (PanelSize == PanelSmall)
            {
               Property.H = 26; // height of fonts
               // X, Y positions of the Panel on the chart
               SetWin(5,20,700,CORNER_LEFT_UPPER);
            }
   str1EA.Property=Property; 
   str2Spread.Property=Property;
   str3Trend.Property=Property;
   str4Senti.Property=Property;
   str6Orders.Property=Property;
         
   ArrayResize(strOrders, MaxOpenedTrades);
   for (int i = 0; i < ArraySize(strOrders);i++) 
   {
      strOrders[i] = new CRowTypeOrder(GetPointer(this));
   }      
         
   //UpdateShowGlobalSentiments();
   //UpdateShowMarketInfo();
   bForceRedraw = true;
   

   Draw();
}

//+------------------------------------------------------------------+
//| Метод Draw                                            
//+------------------------------------------------------------------+
void TradePanel::Draw()
{
   if (!bForceRedraw)
   {
      if (!AllowRedrawByEvenMinutesTimer(Symbol(), RefreshTimeFrame))
         return;
   }
   bForceRedraw = false;
      
   UpdateShowGlobalSentiments();
   UpdateShowMarketInfo();
   
   int X,Y,B;
   X=w_xpos;
   Y=w_ypos;
   B=w_bsize;
   
   str1EA.Draw("Expert", X, Y, B, 0, EAString);
   Y=Y+Property.H+DELTA;
   if (bHideAll == false)
   {
      str2Spread.Edit.SetText(MarketInfoString);
      str2Spread.Draw("MarketInfo0", X, Y, B, 150, "Market Info");
      Y=Y+Property.H+DELTA;
      str3Trend.Edit.SetText(TrendString);
      str3Trend.Draw("Trend0", X, Y, B, 100, "Trend");
      Y=Y+Property.H+DELTA;
      str4Senti.Edit.SetText(SentiString);      
      str4Senti.Draw("Sentiments0", X, Y, B, 150, "Sentiments");
      Y=Y+Property.H+DELTA;
      /*str5News.Draw("NewsStat0", X, Y, B, 0, NewsStatString);
      if (bHideNews == false)
      {
         //for (int i = 0; i < ArraySize(strNews);i++) 
         //{
         //   strNews[i].Delete();
         //}

         string newsName = "News";
         thrift.GetTodayNews((ushort)MinImportance, news_arr, Utils.CurrentTimeOnTF());
         for (int i = 0; i < MAX_NEWS_PER_DAY;i++ ) 
         {
            strNews[i].Property = Property;
            newsName = StringFormat("News%d", i);
            Y=Y+Property.H+DELTA;
            strNews[i].Edit.SetText(news_arr[i].ToString());
            strNews[i].Draw(newsName, X, Y, B, 0, "");
         }
      }
      
      Y=Y+Property.H+DELTA; */
      str6Orders.Draw("Orders0", X, Y, B, 0, OrdersString);
      if (bHideOrders == false)
      {
         OrderSelection* orders = Utils.Trade().Orders();
         
         for (int i = 0; i < ArraySize(strOrders);i++) 
         {
            strOrders[i].Delete();
         }

         string ordersName = "";
         int i = 0;
         FOREACH_ORDER(orders)
         {
            strOrders[i].Property = Property;
            ordersName = StringFormat("Order_%d", order.Id());
            Y=Y+Property.H+DELTA;
            string orderStr = order.ToString();
            strOrders[i].Text.SetText(orderStr);
            strOrders[i].Draw(ordersName, X, Y, B, orderStr);
            i++;
         }
      }
   }   
   ChartRedraw(chartID);
   on_event=true;   // разрешаем обработку событий
}

Order* TradePanel::OrderFromUIString(string name) {
   ushort u_sep = StringGetCharacter("_",0);
   string result[];
   StringSplit(name, u_sep, result);
   Order* order = NULL;
   if (ArraySize(result) >= 2)
   {
      int ticket = (int)StringToInteger(result[1]);
      return order = Utils.Trade().Orders().SearchOrder(ticket);
   }
   return NULL;
}

void TradePanel::OpenOrderPanel(string UIName)
{
   ushort u_sep = StringGetCharacter("_",0);
   string result[];
   StringSplit(UIName, u_sep, result);
   Order* order = NULL;
   if (ArraySize(result) >= 2)
   {
      int ticket = (int)StringToInteger(result[1]);
      order = Utils.Trade().Orders().SearchOrder(ticket);
   }
   
   if (orderPanel == NULL)
   {
      orderPanel = new OrderPanel(order, &this);
      orderPanel.Init();
   }
   orderPanel.Draw();   
}

//+------------------------------------------------------------------+
//| Метод обработки события OnChartEvent класса TradePanel           |
//+------------------------------------------------------------------+
void TradePanel::OnEvent(const int id,
                           const long &lparam,
                           const double &dparam,
                           const string &sparam)
{

   if(on_event)
     {         
      
      if(id==CHARTEVENT_CHART_CHANGE)
      {
         SetForceRedraw();
      }
      //--- трансляция событий OnChartEvent
      str1EA.OnEvent(id,lparam,dparam,sparam);
      if (bHideAll == false)
      {
         str2Spread.OnEvent(id,lparam,dparam,sparam);
         str3Trend.OnEvent(id,lparam,dparam,sparam);
         str4Senti.OnEvent(id,lparam,dparam,sparam);
         /*str5News.OnEvent(id,lparam,dparam,sparam);
         if (bHideNews == false)
         {
            for (int i=0; i < ArraySize(strNews);i++) 
            {
               strNews[i].OnEvent(id,lparam,dparam,sparam);
            }
         }*/
         str6Orders.OnEvent(id,lparam,dparam,sparam);
         if ( bHideOrders == false)
         {
            for (int i = 0; i < ArraySize(strOrders); i++ ) 
            {
               strOrders[i].OnEvent(id,lparam,dparam,sparam);
            }
         }
      }
              
      //--- нажатие кнопки Close в главном окне
      if((ENUM_CHART_EVENT)id==CHARTEVENT_OBJECT_CLICK
         && StringFind(sparam,".Button1",0)>0)
        {
         //--- реакция на планируемое событие
         //ExpertRemove();
        }
      //--- нажатие кнопки Hide в главном окне
      if((ENUM_CHART_EVENT)id==CHARTEVENT_OBJECT_CLICK
         && StringFind(sparam,".Button0",0)>0)
        {
           if (StringFind(sparam, str1EA.name) >= 0)
           {
              bHideAll = !bHideAll;
              if (bHideAll)
              {
                 str2Spread.Delete();
                 str3Trend.Delete();
                 str4Senti.Delete();
                 /*str5News.Delete();
                  for (int i=0; i < ArraySize(strNews);i++) 
                  {
                     strNews[i].Delete();
                  }*/
                  str6Orders.Delete();
                  for (int i=0; i < ArraySize(strOrders);i++) 
                  {
                     strOrders[i].Delete();
                  }
              }
           }
            
               
           if (StringFind(sparam, str6Orders.name)>=0)
           {
               bHideOrders = !bHideOrders;
               if (bHideOrders)
               {
                  for (int i=0; i < ArraySize(strOrders);i++) 
                  {
                     strOrders[i].Delete();
                  }
               }
           }
           SetForceRedraw();    
           Draw();           
           return;
            //--- реакция на планируемое событие
        }
        
        //--- редактирование переменных [NEW3] : кнопка Plus STR3
        if ((ENUM_CHART_EVENT)id==CHARTEVENT_OBJECT_CLICK)
        {
            if (StringFind(sparam, str6Orders.name) >= 0)
            {
                  OpenOrderPanel(sparam);
                  return;
            }
            if ((StringFind(sparam, "Order_") >= 0))
            {
               string plus = ".RowType3.Button3";
               string minus = ".RowType3.Button4";
               if (StringFind(sparam, plus) >= 0)
               {
                  OpenOrderPanel(sparam);
                  return;
               }
               if (StringFind(sparam, minus) >= 0)
               {
                  Order * order = OrderFromUIString(sparam);
                  if (order != NULL)
                  {
                     order.doSelect(true);
                     ChartRedraw(chartID);
                  }
                  return;
               }
            }
        }
        
        if (orderPanel != NULL)
           orderPanel.OnEvent(id, lparam, dparam, sparam);

     }          
}

