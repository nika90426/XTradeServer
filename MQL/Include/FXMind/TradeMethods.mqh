#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#include <stdliberr.mqh>
#include <FXMind\Orders.mqh>
#include <FXMind\SettingsFile.mqh>
#include <FXMind\IFXMindService.mqh>
#include <FXMind\PendingOrders.mqh>

class TradeSignals;

#include <FXMind\TradeSignals.mqh>

class TradeMethods : public ITrade 
{
protected:
    datetime sdtPrevtime;
    string   EANameString;
            
   //+------------------------------------------------------------------+
   bool CloseOrder(long ticket, double lots, double price, color arrow_color)
   {
      price = NormalizeDouble(price, Digits());
      int err = ::GetLastError();
      err = 0;
      bool result = false;
      bool exit_loop = false;
      int cnt = 0;
      while (!exit_loop)
      {
         if (Utils.SelectOrder(ticket))
         {
            lots = NormalizeDouble(lots, 2);
            price = NormalizeDouble(price, Digits());
            if (Utils.OrderLots() > lots)
               result = Utils.OrderClosePartially(ticket, lots, price, Slippage);
            else
               result = Utils.OrderClose(ticket, lots, price, Slippage, arrow_color);
            if (result == true) 
            {  
            
               if (!Utils.IsTesting())
               {
                  Sleep(100);
               }
               return true;        
            } 
            err = ::GetLastError();
            switch (err)
            {
               case ERR_NO_ERROR:
                  exit_loop = true;
               break;
               case ERR_SERVER_BUSY:
               case ERR_BROKER_BUSY:
               case ERR_TRADE_CONTEXT_BUSY:
               case ERR_TRADE_SEND_FAILED:
                  cnt++;
               break;
               case ERR_INVALID_PRICE:
               case ERR_PRICE_CHANGED:
               case ERR_OFF_QUOTES:
               case ERR_REQUOTE:
                  Utils.RefreshRates();
                  continue;
               break;
               default:
                exit_loop = true;
            }
            if (cnt > RetryOnErrorNumber )
               exit_loop = true;
            
            if ( !exit_loop )
            {
               if (!Utils.IsTesting())
                  Sleep(SLEEP_DELAY_MSEC);
               Utils.RefreshRates();
            }
            else 
            {
               if (err != ERR_NO_ERROR) 
               {
                  LogError(StringFormat("^^^^^^^^^^Error Close Order ticket: %d, error#: %d", ticket ,err));
               }
            }
         }
      }
      return result;
   }
   //+------------------------------------------------------------------+
 
public:
   OrderSelection globalOrders;

   IFXMindService *thrift;
   TradeSignals* signals;
   string Symbol;
   double Point;
   int Digits;
   ENUM_TIMEFRAMES Period;
   color    TrailingColor;
   double StopLevelPoints;
   int MartinMultiplier;

   TradeMethods() 
      :globalOrders(MaxOpenedTrades)
   {
       thrift = Utils.Service();
       sdtPrevtime = 0;
       
       TrailingColor = Yellow;  
       Symbol = Symbol();
       Point = Point();
       Digits = Digits();
       Period = Period();
       StopLevelPoints = StopLevelPoints;
       MartinMultiplier = 1;
       lastDealTicket = 0;
   }
      
   ~TradeMethods()
   {
      globalOrders.Clear();
   }
      
   OrderSelection* Orders() 
   {
      return &globalOrders;
   }

   void SetSignalsProcessor(TradeSignals* sig)
   {
       signals = sig;
   }
   
   int GetMartinMultiplier() {
      return MartinMultiplier;
   }
   
   ulong lastDealTicket;
   double CalculateLotSize(int op_type, bool GridLot = false)
   {
      if (GridLot && actualAllowGRIDBUY && (op_type == OP_BUY))
          return NormalizeDouble(LotsBUY * GridMultiplier, 2);     
      if (GridLot && actualAllowGRIDSELL && (op_type == OP_SELL))
          return NormalizeDouble(LotsSELL * GridMultiplier, 2);     

      /*if (MartingaleFlat)
      {      
         ulong curDealTicket = 0;
         double lastProfit = LastDealProfit(curDealTicket);
         if (lastProfit < 0)
         {
            if (lastDealTicket != curDealTicket)
            {  
               lastDealTicket = curDealTicket;
               
               MartinMultiplier += (int)MathCeil(GridMultiplier);
               if (MartinMultiplier > 12)
                 MartinMultiplier = 12;
            } else {
               lastDealTicket = curDealTicket;
            }
         } else {
            MartinMultiplier = 1; // Reset martingale
         }
         if ((signals.Trend == LATERAL) || (MartinMultiplier > 1))
         {   
            if (op_type == OP_BUY)
               return LotsMIN * MartinMultiplier;
            if (op_type == OP_SELL)
               return LotsMIN * MartinMultiplier;
         }
      } else */ {
         if ((signals.Trend == LATERAL) )
         {
            if ((op_type == OP_BUY) || (op_type == OP_SELL))
               return LotsMIN;
         }
      }
      if (op_type == OP_BUY)
      {
         if (signals.Trend == DOWN)
            return LotsMIN;
         return LotsBUY;
      }
      if (op_type == OP_SELL)
      {
         if (signals.Trend == UPPER)
            return LotsMIN;
         return LotsSELL;
      }
      return LotsSELL;   
   }
   
   double StopLoss(double price, int op_type)
   {
      if (!actualAllowGRIDSELL) 
      {
          double actualStopLossLevel = DefaultStopLoss();
          if (op_type == OP_BUY)
          {
             return price - actualStopLossLevel * Point();
          }
          if (op_type == OP_SELL)
          {
             return price + actualStopLossLevel * Point();
          }
      }
      return 0;
   }
   
   double TakeProfit(double price, int op_type)
   {
      double actualTakeProfitLevel = DefaultTakeProfit();
      if (op_type == OP_BUY)
      {
         return price + actualTakeProfitLevel* Point(); 
      }
      if (op_type == OP_SELL)
      {
         return price - actualTakeProfitLevel* Point(); 
      }
      return 0;
   }

/*   
#ifdef  __MQL5__   
   double LastDealProfit(ulong& deal_ticket)
   {
      double deal_profit = 0;
      // --- time interval of the trade history needed
      datetime end=TimeCurrent();                 // current server time
      datetime start = end - 30*PeriodSeconds(PERIOD_D1);// decrease 1 day
      //--- request of trade history needed into the cache of MQL5 program
      HistorySelect(start,end);
      //--- get total number of deals in the history
      int deals = HistoryDealsTotal();
      //--- get ticket of the deal with the last index in the list
      deal_ticket=HistoryDealGetTicket(deals-1);
      if (deal_ticket > 0) // deal has been selected, let's proceed ot
        {
            //--- ticket of the order, opened the deal
            ulong order=HistoryDealGetInteger(deal_ticket,DEAL_ORDER);
            long order_magic=HistoryDealGetInteger(deal_ticket,DEAL_MAGIC);
            if (order_magic == thrift.MagicNumber())
            {
               long pos_ID=HistoryDealGetInteger(deal_ticket,DEAL_POSITION_ID);
               deal_profit=HistoryDealGetDouble(deal_ticket,DEAL_PROFIT);
               double deal_volume=HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
            //Utils.Info(StringFormat("Deal: #%d opened by order: #%d with ORDER_MAGIC: %d was in position: #%d price: #%d volume:",
             //           deals-1,order,order_magic,pos_ID,deal_price,deal_volume));
            }
        }
      else              // error in selecting of the deal
        {
         //Utils.Info(StringFormat("Total number of deals %d, error in selection of the deal"+
          //           " with index %d. Error %d",deals,deals-1,GetLastError()));
        }
      return(deal_profit);
   }
#else 
   double LastDealProfit(ulong& deal_ticket)
   {
      return 0;
   }
   
#endif
*/
   void SaveOrders()
   {
      OrderSelection* orders = GetOpenOrders();
      string orderSection = "";
      string ActiveOrdersList = "";
      SettingsFile *set = thrift.Settings();
      FOREACH_ORDER(orders)
      {
         orderSection = order.OrderSection();
         if (set != NULL)
         {
            //Print("Save Order: "+ orderSection);
            set.SetParam(orderSection, "ticket", order.Id());
            set.SetParam(orderSection, "openPrice", order.openPrice);
            set.SetParam(orderSection, "role", order.Role());
            set.SetParam(orderSection, "TrailingType", order.TrailingType);
            set.SetParam(orderSection, "stopLoss", order.StopLoss(false));
            set.SetParam(orderSection, "takeProfit", order.TakeProfit(false));
            set.SetParam(orderSection, "lots", order.lots);
            set.SetParam(orderSection, "profit", order.Profit());
            if (StringLen(order.signalName) > 0)
               set.SetParam(orderSection, "signalName", order.signalName);
         }
         //set.SetParam(orderSection, "comment", order.comment);
         ActiveOrdersList += orderSection;
         //if (i++ < (size - 1 ))
         ActiveOrdersList += "|"; 
      }
      ActiveOrdersList += Constants::GLOBAL_SECTION_NAME;
      thrift.SaveAllSettings(ActiveOrdersList);
   }
   
   void LoadOrders()
   {
      OrderSelection* orders = GetOpenOrders();
      
      FOREACH_ORDER(orders)
      {
         LoadOrder(order);
      }
   }   
   
   void LoadOrder(Order* order)
   {
      string orderSection = order.OrderSection();
      SettingsFile* set = thrift.Settings();
      if (set != NULL)
      {
         long t = order.Id();
         set.GetIniKey(orderSection, "ticket", t);
         order.SetId(t);
         set.GetIniKey(orderSection, "openPrice", order.openPrice);
         set.GetIniKey(orderSection, "lots", order.lots);
         int role = 0;
         set.GetIniKey(orderSection, "role", role);
         order.SetRole((ENUM_ORDERROLE)role);
         int tt = 0;
         set.GetIniKey(orderSection, "TrailingType", tt);
         order.TrailingType = (ENUM_TRAILING)tt;
         double sl = 0;
         set.GetIniKey(orderSection, "stopLoss", sl);
         order.setStopLoss(sl);
         double tp = 0;
         set.GetIniKey(orderSection, "takeProfit", tp);
         order.setTakeProfit(tp);
      } 
      if (!Utils.IsTesting())
         Print(StringFormat("Order %d restored successfully ", order.Id()));
   }
      
   void LogError(string message)
   {
       Comment(message);
   }
   
   double RiskAmount(double percent)
   {
      return Utils.AccountBalance()*percent;
   }
   
   OrderSelection* GetOpenOrders()
   {
      //if (IsTesting())
      //   Print("GetOpenOrders start");
      SettingsFile* set = thrift.Settings();
      globalOrders.MarkOrdersAsDirty();
      long ticket = 0;
      string _symbol = Symbol();
      for (int i = Utils.OrdersTotal() - 1; i >= 0; i-- )
      {     
         if (Utils.SelectOrderByPos(i))
         {
            ticket = Utils.OrderTicket();
            if ((thrift.MagicNumber() == Utils.OrderMagicNumber()) && (_symbol == Utils.OrderSymbol()))
            {
               globalOrders.AddUpdateByTicket(ticket);
            } else {
                      if (set != NULL)
                      {
                         if (set.IsTicketExistToLoad(ticket))
                         {
                            globalOrders.AddUpdateByTicket(ticket);
                         }
                      }
                   }
    
         }
      }
      
      globalOrders.RemoveDirtyObsoleteOrders();
      /*
      FOREACH_ORDER(globalOrders)
      {
         if (order.bDirty)
         {         
            set.DeleteSection(order.OrderSection());
            globalOrders.DeleteCurrent();
         }
      }    
      globalOrders.Sort();  
      */
      //if (IsTesting())
      //   Print(StringFormat("GetOpenOrders end: return %d orders", globalOrders.Total()));

      return &globalOrders;
   }
        
   //+------------------------------------------------------------------+
   int CountOrdersByType(int op_type, OrderSelection& orders) 
   {
      int count = 0;
      FOREACH_ORDER(orders)
      {
         if (order.type == op_type)
             count++;
      }
      return(count);
   }
   
   //+------------------------------------------------------------------+
   int CountOrdersByRole(ENUM_ORDERROLE role, OrderSelection& orders) 
   {
      int count = 0;
      FOREACH_ORDER(orders)
      {
         if (order.Role() == role)
             count++;
      }
      return(count);
   }
   
   Order* FindGridHead(OrderSelection& orders, int& count) 
   {
      Order* head = NULL;
      count = 0;
      FOREACH_ORDER(orders)
      {
         if (order.Role() == GridHead)
             head = order;
         if (order.isGridOrder())
             count++;
      }
      return head;
   }
         
   int GetGridStepValue()
   {
      int realGridStep = (int) double(signals.GetATR(1)/Point);
      return realGridStep;
   }
   
   int ATROnIndicator(double rank)
   {
      double percentilePt = Utils.PercentileATR(Symbol, Period, rank, NumBarsToAnalyze, 0)/Point;
      return (int)percentilePt;
   }
   
   int DefaultStopLoss()
   {
      double sl = ATROnIndicator(SL_PERCENTILE)*CoeffSL;
      // Adjust stop level
      int slp = Utils.StopLevel();
      if (slp > 0)
      {
         if (sl < slp)
            sl = MathMax( slp, slp*CoeffSL);
         //else 
         //   sl = sl - int (sl) % slp;
      }
      return (int)MathCeil(sl); 
   }

   int DefaultTakeProfit()
   {
      double tp = ATROnIndicator(SL_PERCENTILE)*CoeffTP;
      // Adjust stop level
      int slp = Utils.StopLevel();
      if (slp > 0)
      {
         if (tp < slp)
            tp = MathMax( slp, slp*CoeffSL);
         //else 
         //   tp = tp - int (tp) % slp;
      }
      return (int)MathCeil(tp); 
   }   

   /*
   int DefaultTakeProfitBUYPercentile()
   {
      double buyPerc, sellPerc;
      signals.ZigZagPercentile(buyPerc, sellPerc);
      return (int)buyPerc; 
   }   

   int DefaultTakeProfitSELLPercentile()
   {
      double buyPerc, sellPerc;
      signals.ZigZagPercentile(buyPerc, sellPerc);
      return (int)sellPerc; 
   } 
   */  

   //+------------------------------------------------------------------+
   double GetGridProfit(OrderSelection& orders) 
   {
      int count = 0;
      double gridprofit = 0;
      FOREACH_ORDER(orders)
      {
         if (order.isGridOrder() && order.Select())
             gridprofit += order.RealProfit();
      }
      return gridprofit;
   }
   //+------------------------------------------------------------------+
   double GetProfit(OrderSelection& orders) 
   {
      int count = 0;
      double profit = 0;
      FOREACH_ORDER(orders)
      {
          profit += order.RealProfit();
      }
      return profit;
   }
   
   //+------------------------------------------------------------------+
   void CloseGrid() 
   {
      // CLOSE ALL GRID ORDERS
      Print(StringFormat("++++++++++Close Grid(%d):++++++++++", globalOrders.Total()));
      FOREACH_ORDER(globalOrders)
      {
         if (order.isGridOrder())
         {
            if (CloseOrder(order, clrMediumSpringGreen))
            {
               Print(StringFormat("CLOSED GRID item: %s", order.ToString()));
               globalOrders.DeleteCurrent();
            }
         }
      }
      globalOrders.Sort();
   }
   
   void CloseTrailingPositions(int op_type) 
   {
      datetime current = TimeCurrent();
      // CLOSE ALL GRID ORDERS
      int count = globalOrders.Total();
      if (count > 0)
         Print(StringFormat("++++++++++Close Trailing Positions(%d):++++++++++", count));
      FOREACH_ORDER(globalOrders)
      {
         //if (order.Select())
         //{
         //   order.openTime = Utils.OrderOpenTime();
         //}
         if ((order.Role() == RegularTrail) && (order.type == op_type) )// && (Utils.TimeMinute(order.openTime) > 120))
         {
            //if (order.Select())
            //{
            //   if (order.RealProfit() < 1)
                  order.SetRole(ShouldBeClosed);
            //}
            /*if (CloseOrder(order, clrMediumSpringGreen))
            {
               Print(StringFormat("CLOSED Trailing item: %s", order.ToString()));
               globalOrders.DeleteCurrent();
            }*/
         }
      }
      //globalOrders.Sort();
   }

   //+------------------------------------------------------------------+
   int CountAllTrades() // OrderSelection* orders
   {
       return globalOrders.Total();
   }
   
   //+------------------------------------------------------------------+
   Order* OpenOrder(Order& order) 
   {
       if (CountAllTrades() >= MaxOpenedTrades)
       {
          Utils.Info(StringFormat("Reached maximum of orders! %d. No new orders!", MaxOpenedTrades));
          delete &order;
          return NULL;
       }
       if ((AllowBUY == false)&& (order.type==OP_BUY))
       {
          delete &order;
          Utils.Info("BUY Orders are not allowed");
          return NULL; 
       }
       if ((AllowSELL == false) && (order.type==OP_SELL))
       {
          delete &order;
          Utils.Info("SELL Orders are not allowed");
          return NULL; 
       }       
       order.comment = EANameString;        
       order.magic   = thrift.MagicNumber();  
       order.symbol  = Symbol;
       if (Utils.OpenOrder(order, Slippage))
       {
          if (order.Select())
          {
             globalOrders.Fill(order);
             globalOrders.Add(&order);
             if (!Utils.IsTesting())
                SaveOrders();
             return &order;
          }
      }
      return NULL;
   }

   //+------------------------------------------------------------------+
   bool ChangeOrder(Order& order, double stoploss, double takeprofit, datetime expiration, color arrow_color)
   {
      stoploss = NormalizeDouble(stoploss, Digits);
      takeprofit = NormalizeDouble(takeprofit, Digits);
      
      if (!order.NeedChanges(stoploss, takeprofit, expiration, TrailingIndent))
      {
         //if (!Utils.IsTesting())
         //   LogInfo(StringFormat("ChangeOrder: No need changes", order.ticket));
         return false;
      }
      bool result = false;
      //int err = ::GetLastError();
      //err = 0;
      //bool exit_loop = false;
      //int cnt = 0;
      //while (!exit_loop)
      //{
         if (order.Select())
         {
            order.setStopLoss(stoploss);
            order.setTakeProfit(takeprofit);
            order.expiration = expiration;            
            //order.PrintIfWrong("ChangeOrder");
            
            result = Utils.OrderModify(order.Id(), order.openPrice, order.StopLoss(true), order.TakeProfit(true), order.expiration, arrow_color);
            if (result == true)
               return true;
            int err = ::GetLastError();
            switch (err)
            {
               case ERR_NO_ERROR:
                 // exit_loop = true;
               break;
               case ERR_NO_RESULT:
                  return true;
               case ERR_SERVER_BUSY:
               case ERR_BROKER_BUSY:
               case ERR_TRADE_CONTEXT_BUSY:
               case ERR_TRADE_SEND_FAILED:
                  //cnt++;
               //break;
               case ERR_INVALID_PRICE:
               case ERR_PRICE_CHANGED:
               case ERR_OFF_QUOTES:
               case ERR_REQUOTE:
                  //Sleep(SLEEP_DELAY_MSEC);
                  //Utils.RefreshRates();
                  //continue;
#ifdef __MQL4__                  
                  Utils.Info(StringFormat("^^^^^^^^^^Error OrderModify ticket: %d, error#: %d ", order.ticket, err));
#endif                  
               break;
               default:
               ;
                //exit_loop = true;
            }
            //if (cnt > RetryOnErrorNumber )
            //   exit_loop = true;
            
            //if ( !exit_loop )
            //{
            //   if (!Utils.IsTesting())
            //      Sleep(SLEEP_DELAY_MSEC);
            //   Utils.RefreshRates();
            //}
            //else 
            //{
              // if (err != ERR_NO_ERROR) 
              // {
              //    LogError(StringFormat("^^^^^^^^^^Error OrderModify ticket: %d, error#: %d ", order.ticket, err));
              // }
            //}
         }
      //}

       //if (result)
       //{
       //   globalOrders.Fill(order);
          //order.openPrice = price;
          //order.stopLoss = stoploss;
          //order.takeProfit = takeprofit;
          //order.expiration = expiration;
       //}
       return result;
   }

   bool CloseOrder(Order& order, color cor) 
   {
      order.MarkToClose();
      if (OP_BUY == order.type)
         order.closePrice = Utils.Bid();
      else 
         order.closePrice = Utils.Ask();
      bool result = CloseOrder(order.Id(), order.lots, order.closePrice, cor); 
      //if (result && bRemoveOrder) {
      //    LogInfo(StringFormat("****CLOSED Order", order.ticket));
      //    globalOrders.DeleteByTicket(order.ticket);
      //}
      return result;
   }
   
   long CloseOrderPartially(Order& order, double newLotSize)
   {
      double lots = order.lots;
      double partLot = NormalizeDouble(newLotSize, 2);
      if (lots > partLot)
         partLot = NormalizeDouble(lots/2.0,2);
      double closePrice = 0;
      if (OP_BUY == order.type)
      {
         closePrice = Utils.Bid();
      }
      else
      {
         closePrice = Utils.Ask();
      }
      if (CloseOrder(order.Id(), partLot, closePrice, Yellow))
      {
         long newticket = searchNewTicket(order.Id());
         order.SetId(newticket);
         return newticket;
      } else
        return -1;
   }
   
   long searchNewTicket(long oldTicket)
   {
      for(int i=Utils.OrdersTotal()-1; i>=0; i--)
         if(Utils.SelectOrderByPos(i) &&
            StringToInteger(StringSubstr(Utils.OrderComment(),StringFind(Utils.OrderComment(),"#")+1)) == oldTicket )
            return (Utils.OrderTicket());
      return (-1);
   }


   
//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО ФРАКТАЛАМ                                            |
//| Функции передаётся тикет позиции, количество баров в фрактале,   |
//| и отступ (пунктов) - расстояние от макс. (мин.) свечи, на        |
//| которое переносится стоплосс (от 0), trlinloss - тралить ли в    |
//| зоне убытков                                                     |
//+------------------------------------------------------------------+
void TrailingByFractals(Order& order, ENUM_TIMEFRAMES tmfrm,int frktl_bars,int indent,bool trlinloss)
   {
   int i, z; // counters
   int extr_n; // номер ближайшего экстремума frktl_bars-барного фрактала 
   double temp; // служебная переменная
   int after_x, be4_x; // свечей после и до пика соответственно
   int ok_be4, ok_after; // флаги соответствия условию (1 - неправильно, 0 - правильно)
   int sell_peak_n = 0, buy_peak_n = 0; // номера экстремумов ближайших фракталов на продажу (для поджатия дл.поз.) и покупку соответсвенно   
   
   // проверяем переданные значения
   if ((frktl_bars<=3) || (indent<0) || (!order.Valid()) || (!order.Select()))
   {
      Print("Трейлинг функцией TrailingByFractals() невозможен из-за некорректности значений переданных ей аргументов.");
      return ;
   } 
   
   temp = frktl_bars;
      
   if (MathMod(frktl_bars,2)==0)
   extr_n = (int)temp/2;
   else                
   extr_n = (int)MathRound(temp/2);
      
   // баров до и после экстремума фрактала
   after_x = frktl_bars - extr_n;
   if (MathMod(frktl_bars,2)!=0)
   be4_x = frktl_bars - extr_n;
   else
   be4_x = frktl_bars - extr_n - 1;    
   
   // если длинная позиция (OP_BUY), находим ближайший фрактал на продажу (т.е. экстремум "вниз")
   if (Utils.OrderType()==OP_BUY)
      {
      // находим последний фрактал на продажу
      for (i=extr_n;i<iBars(Symbol(),tmfrm);i++)
         {
         ok_be4 = 0; ok_after = 0;
         
         for (z=1;z<=be4_x;z++)
            {
            if (iLow(Symbol(),tmfrm,i)>=iLow(Symbol(),tmfrm,i-z)) 
               {
               ok_be4 = 1;
               break;
               }
            }
            
         for (z=1;z<=after_x;z++)
            {
            if (iLow(Symbol(),tmfrm,i)>iLow(Symbol(),tmfrm,i+z)) 
               {
               ok_after = 1;
               break;
               }
            }            
         
         if ((ok_be4==0) && (ok_after==0))                
            {
            sell_peak_n = i; 
            break;
            }
         }
     
      // если тралить в убытке
      if (trlinloss==true)
         {
         // если новый стоплосс лучше имеющегося (в т.ч. если стоплосс == 0, не выставлен)
         // а также если курс не слишком близко, ну и если стоплосс уже не был перемещен на рассматриваемый уровень         
         if ((iLow(Symbol(),tmfrm,sell_peak_n)-indent*Point()>Utils.OrderStopLoss()) && (iLow(Symbol(),tmfrm,sell_peak_n)-indent*Point()<Utils.Bid() - StopLevelPoints))
            {
               ChangeOrder(order,iLow(Symbol(),tmfrm,sell_peak_n)-indent*Point(),Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            //if (!OrderModify(ticket,Utils.OrderOpenPrice(),iLow(Symbol(),tmfrm,sell_peak_n)-indent*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration()))
            //Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      // если тралить только в профите, то
      else
         {
            // если новый стоплосс лучше имеющегося И курса открытия, а также не слишком близко к текущему курсу
            if ((iLow(Symbol(),tmfrm,sell_peak_n)-indent*Point()>Utils.OrderStopLoss()) && (iLow(Symbol(),tmfrm,sell_peak_n)-indent*Point()>Utils.OrderOpenPrice()) && (iLow(Symbol(),tmfrm,sell_peak_n)-indent*Point()<Utils.Bid()-StopLevelPoints))
            {
               ChangeOrder(order,iLow(Symbol(),tmfrm,sell_peak_n)-indent*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
               //if (!OrderModify(ticket,Utils.OrderOpenPrice(),iLow(Symbol(),tmfrm,sell_peak_n)-indent*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration()))
               //Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      }
      
   // если короткая позиция (OP_SELL), находим ближайший фрактал на покупку (т.е. экстремум "вверх")
   if (Utils.OrderType()==OP_SELL)
      {
      // находим последний фрактал на продажу
      for (i=extr_n;i<iBars(Symbol(),tmfrm);i++)
         {
         ok_be4 = 0; ok_after = 0;
         
         for (z=1;z<=be4_x;z++)
            {
            if (iHigh(Symbol(),tmfrm,i)<=iHigh(Symbol(),tmfrm,i-z)) 
               {
               ok_be4 = 1;
               break;
               }
            }
            
         for (z=1;z<=after_x;z++)
            {
            if (iHigh(Symbol(),tmfrm,i)<iHigh(Symbol(),tmfrm,i+z)) 
               {
               ok_after = 1;
               break;
               }
            }            
         
         if ((ok_be4==0) && (ok_after==0))                
            {
            buy_peak_n = i;
            break;
            }
         }        
      
      // если тралить в убытке
      if (trlinloss==true)
         {
         if (((iHigh(Symbol(),tmfrm,buy_peak_n)+(indent+Utils.Spread())*Point()<Utils.OrderStopLoss()) || (Utils.OrderStopLoss()==0)) && (iHigh(Symbol(),tmfrm,buy_peak_n)+(indent+Utils.Spread())*Point()>Utils.Ask()+StopLevelPoints))
            {
               ChangeOrder(order,iHigh(Symbol(),tmfrm,buy_peak_n)+(indent+Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            }
         }      
      // если тралить только в профите, то
      else
         {
         // если новый стоплосс лучше имеющегося И курса открытия
         if ((((iHigh(Symbol(),tmfrm,buy_peak_n)+(indent+Utils.Spread())*Point<Utils.OrderStopLoss()) || (Utils.OrderStopLoss()==0))) && (iHigh(Symbol(),tmfrm,buy_peak_n)+(indent+Utils.Spread())*Point<Utils.OrderOpenPrice()) && (iHigh(Symbol(),tmfrm,buy_peak_n)+(indent+Utils.Spread())*Point>Utils.Ask()+StopLevelPoints))
            {
                ChangeOrder(order,iHigh(Symbol(),tmfrm,buy_peak_n)+(indent+Utils.Spread())*Point(),Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            }
         }
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО ТЕНЯМ N СВЕЧЕЙ                                       |
//| Функции передаётся тикет позиции, количество баров, по теням     |
//| которых необходимо трейлинговать (от 1 и больше) и отступ        |
//| (пунктов) - расстояние от макс. (мин.) свечи, на которое         |
//| переносится стоплосс (от 0), trlinloss - тралить ли в лоссе      | 
//+------------------------------------------------------------------+
void TrailingByShadows(Order& order,ENUM_TIMEFRAMES tmfrm,int bars_n, int indent,bool trlinloss)
   {  
   
   int i; // counter
   double new_extremum = 0;
   
   // проверяем переданные значения
   if ((bars_n<1) || (indent<0) || (!order.Valid()) || ((tmfrm!=1) && (tmfrm!=5) && (tmfrm!=15) && (tmfrm!=30) && (tmfrm!=60) && (tmfrm!=240) && (tmfrm!=1440) && (tmfrm!=10080) && (tmfrm!=43200)) || (!order.Select()))
      {
      Print("Трейлинг функцией TrailingByShadows() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      } 
   
   // если длинная позиция (OP_BUY), находим минимум bars_n свечей
   if (Utils.OrderType()==OP_BUY)
      {
      for(i=1;i<=bars_n;i++)
         {
         if (i==1) new_extremum = iLow(Symbol(),tmfrm,i);
         else 
         if (new_extremum>iLow(Symbol(),tmfrm,i)) new_extremum = iLow(Symbol(),tmfrm,i);
         }         
      
      // если тралим и в зоне убытков
      if (trlinloss == true)
         {
           // если найденное значение "лучше" текущего стоплосса позиции, переносим 
           if ((((new_extremum - indent*Point)>Utils.OrderStopLoss()) || (Utils.OrderStopLoss()==0)) && (new_extremum - indent*Point<Utils.Bid()-StopLevelPoints))
              ChangeOrder(order, new_extremum - indent*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      else
         {
           // если новый стоплосс не только лучше предыдущего, но и курса открытия позиции
           if ((((new_extremum - indent*Point)>Utils.OrderStopLoss()) || (Utils.OrderStopLoss()==0)) && ((new_extremum - indent*Point)>Utils.OrderOpenPrice()) && (new_extremum - indent*Point<Utils.Bid()-StopLevelPoints))
              ChangeOrder(order, new_extremum-indent*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      }
      
   // если короткая позиция (OP_SELL), находим минимум bars_n свечей
   if (Utils.OrderType()==OP_SELL)
      {
      for(i=1;i<=bars_n;i++)
         {
         if (i==1) new_extremum = iHigh(Symbol(),tmfrm,i);
         else 
         if (new_extremum<iHigh(Symbol(),tmfrm,i)) new_extremum = iHigh(Symbol(),tmfrm,i);
         }         
           
      // если тралим и в зоне убытков
      if (trlinloss==true)
         {
         // если найденное значение "лучше" текущего стоплосса позиции, переносим 
            if ((((new_extremum + (indent + Utils.Spread())*Point)<Utils.OrderStopLoss()) || (Utils.OrderStopLoss()==0)) && (new_extremum + (indent + Utils.Spread())*Point>Utils.Ask()+StopLevelPoints))
                ChangeOrder(order, new_extremum + (indent + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      else
         {
         // если новый стоплосс не только лучше предыдущего, но и курса открытия позиции
             if ((((new_extremum + (indent + Utils.Spread())*Point)<Utils.OrderStopLoss()) || (Utils.OrderStopLoss()==0)) && ((new_extremum + (indent + Utils.Spread())*Point)<Utils.OrderOpenPrice()) && (new_extremum + (indent +  Utils.Spread())*Point>Utils.Ask()+StopLevelPoints))
                ChangeOrder(order, new_extremum + (indent + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }      
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ СТАНДАРТНЫЙ-СТУПЕНЧАСТЫЙ                                |
//| Функции передаётся тикет позиции, расстояние от курса открытия,  |
//| на котором трейлинг запускается (пунктов) и "шаг", с которым он  |
//| переносится (пунктов)                                            |
//| Пример: при +30 стоп на +10, при +40 - стоп на +20 и т.д.        |
//+------------------------------------------------------------------+
void TrailingStairs(Order& order,int trldistance,int trlstep)
{ 
   double nextstair; // ближайшее значение курса, при котором будем менять стоплосс

   // проверяем переданные значения
   if ((trldistance<Utils.StopLevel()) || (trlstep<1) || (trldistance<trlstep) || (!order.Valid()) || (!order.Select()))
   {
      //Print("Трейлинг функцией TrailingStairs() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
   } 
   
   // если длинная позиция (OP_BUY)
   if (Utils.OrderType()==OP_BUY)
   {
      double bid = Utils.Bid();
      double startLevel = Utils.OrderOpenPrice() + (trldistance + Utils.Spread())*Point;
      if ( bid  >  startLevel )
      {
         if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss() < Utils.OrderOpenPrice()))
         {
            nextstair = Utils.OrderOpenPrice() + Utils.Spread()*Point; // breakeven level
            ChangeOrder(order,nextstair,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            return;
         }     
         double distance = (trldistance + trlstep)*Point;
         if ((bid - Utils.OrderStopLoss() ) > distance)
         {
            nextstair = Utils.OrderStopLoss() + (2*trlstep + Utils.Spread())*Point;
            ChangeOrder(order,nextstair,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }                    
      } 
         
   }
      
   // если короткая позиция (OP_SELL)
   if (Utils.OrderType()==OP_SELL)
   { 
      double ask = Utils.Ask();
      double startLevel = Utils.OrderOpenPrice() - (trldistance + Utils.Spread())*Point;
      if ( ask  <  startLevel )
      {
         // расчитываем, при каком значении курса следует скорректировать стоплосс
         // если стоплосс ниже открытия или равен 0 (не выставлен), то ближайший уровень = курс открытия + trldistance + спрэд
         if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss() > Utils.OrderOpenPrice()))
         {
            nextstair = Utils.OrderOpenPrice() - Utils.Spread()*Point; // breakeven level
            ChangeOrder(order,nextstair,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            return;
         }
         double distance = (trldistance + trlstep)*Point;
         if (( Utils.OrderStopLoss() - ask) > distance)
         {
            nextstair = Utils.OrderStopLoss() - (2*trlstep + Utils.Spread())*Point;
            ChangeOrder(order,nextstair,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      }
   }      
}

/*void TrailingStairs(Order& order,int trldistance,int trlstep)
{ 
   double nextstair; // ближайшее значение курса, при котором будем менять стоплосс

   // проверяем переданные значения
   if ((Utils.OrderStopLoss()==0) || (trldistance<Utils.StopLevel()) || (trlstep<1) || (trldistance<trlstep) || (!order.Valid()) || (!order.Select()))
   {
      //Print("Трейлинг функцией TrailingStairs() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
   } 
   
   // если длинная позиция (OP_BUY)
   if (Utils.OrderType()==OP_BUY)
   {
      double bid = Utils.Bid();
      double dist = MathAbs(Utils.OrderStopLoss() - Utils.OrderOpenPrice())/Point;
      double spread = Utils.Spread();
      double startLevel = Utils.OrderOpenPrice() + (dist + spread)*Point;
      if ( bid  >  startLevel )
      {
         if (Utils.OrderStopLoss() < Utils.OrderOpenPrice())
         {
            nextstair = Utils.OrderOpenPrice() + Utils.Spread()*Point; // breakeven level
            ChangeOrder(order,nextstair,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            return;
         }     
         double distance = (trldistance + trlstep)*Point;
         if ((bid - Utils.OrderStopLoss() ) > distance)
         {
            nextstair = Utils.OrderStopLoss() + (2*trlstep + Utils.Spread())*Point;
            ChangeOrder(order,nextstair,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }                    
      } 
         
   }
      
   // если короткая позиция (OP_SELL)
   if (Utils.OrderType()==OP_SELL)
   { 
      double ask = Utils.Ask();
      double dist = MathAbs(Utils.OrderStopLoss() - Utils.OrderOpenPrice())/Point;
      double spread = Utils.Spread();
      double startLevel = Utils.OrderOpenPrice() - (dist + spread)*Point;
      if ( ask  <  startLevel )
      {
         // расчитываем, при каком значении курса следует скорректировать стоплосс
         // если стоплосс ниже открытия или равен 0 (не выставлен), то ближайший уровень = курс открытия + trldistance + спрэд
         if (Utils.OrderStopLoss() > Utils.OrderOpenPrice())
         {
            nextstair = Utils.OrderOpenPrice() - Utils.Spread()*Point; // breakeven level
            ChangeOrder(order,nextstair,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            return;
         }
         double distance = (trldistance + trlstep)*Point;
         if (( Utils.OrderStopLoss() - ask) > distance)
         {
            nextstair = Utils.OrderStopLoss() - (2*trlstep + Utils.Spread())*Point;
            ChangeOrder(order,nextstair,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      }
   }      
}*/

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ СТАНДАРТНЫЙ-ЗАТЯГИВАЮЩИЙСЯ                              |
//| Функции передаётся тикет позиции, исходный трейлинг (пунктов) и  |
//| 2 "уровня" (значения профита, пунктов), при которых трейлинг     |
//| сокращаем, и соответствующие значения трейлинга (пунктов)        |
//| Пример: исходный трейлинг 30 п., при +50 - 20 п., +80 и больше - |
//| на расстоянии в 10 пунктов.                                      |
//+------------------------------------------------------------------+

void TrailingUdavka(Order& order,int trl_dist_1,int level_1,int trl_dist_2,int level_2,int trl_dist_3)
   {  
   
   double newstop = 0; // новый стоплосс
   double trldist = 0; // расстояние трейлинга (в зависимости от "пройденного" может = trl_dist_1, trl_dist_2 или trl_dist_3)

   // проверяем переданные значения
   if ((trl_dist_1<Utils.StopLevel()) || (trl_dist_2<Utils.StopLevel()) || (trl_dist_3<Utils.StopLevel()) || 
   (level_1<=trl_dist_1) || (level_2<=trl_dist_1) || (level_2<=level_1) || (!order.Valid()) || (!order.Select()))
      {
      Print("Трейлинг функцией TrailingUdavka() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      } 
   
   // если длинная позиция (OP_BUY)
   if (Utils.OrderType()==OP_BUY)
      {
        double bid = Utils.Bid();
      // если профит <=trl_dist_1, то trldist=trl_dist_1, если профит>trl_dist_1 && профит<=level_1*Point ...
      if ((bid-Utils.OrderOpenPrice())<=level_1*Point) trldist = trl_dist_1;
      if (((bid-Utils.OrderOpenPrice())>level_1*Point) && ((Utils.Bid()-Utils.OrderOpenPrice())<=level_2*Point)) trldist = trl_dist_2;
      if ((bid-Utils.OrderOpenPrice())>level_2*Point) trldist = trl_dist_3; 
            
      // если стоплосс = 0 или меньше курса открытия, то если тек.цена (Bid) больше/равна дистанции курс_открытия+расст.трейлинга
      if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()<Utils.OrderOpenPrice()))
         {
         if (bid>(Utils.OrderOpenPrice() + trldist*Point))
         newstop = bid -  trldist*Point;
         }

      // иначе: если текущая цена (Bid) больше/равна дистанции текущий_стоплосс+расстояние трейлинга, 
      else
         {
         if (bid>(Utils.OrderStopLoss() + trldist*Point))
         newstop = bid -  trldist*Point;
         }
      
      // модифицируем стоплосс
      if ((newstop>Utils.OrderStopLoss()) && (newstop<bid-StopLevelPoints))
         {
            ChangeOrder(order,newstop,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      }
      
   // если короткая позиция (OP_SELL)
   if (Utils.OrderType()==OP_SELL)
      { 
         double ask = Utils.Ask();

      // если профит <=trl_dist_1, то trldist=trl_dist_1, если профит>trl_dist_1 && профит<=level_1*Point ...
      if ((Utils.OrderOpenPrice()-(ask + Utils.Spread()*Point))<=level_1*Point) trldist = trl_dist_1;
      if (((Utils.OrderOpenPrice()-(ask + Utils.Spread()*Point))>level_1*Point) && ((Utils.OrderOpenPrice()-(ask + Utils.Spread()*Point))<=level_2*Point)) trldist = trl_dist_2;
      if ((Utils.OrderOpenPrice()-(ask + Utils.Spread()*Point))>level_2*Point) trldist = trl_dist_3; 
            
      // если стоплосс = 0 или меньше курса открытия, то если тек.цена (Ask) больше/равна дистанции курс_открытия+расст.трейлинга
      if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()>Utils.OrderOpenPrice()))
         {
         if (ask<(Utils.OrderOpenPrice() - (trldist + Utils.Spread())*Point))
         newstop = ask + trldist*Point;
         }

      // иначе: если текущая цена (Bid) больше/равна дистанции текущий_стоплосс+расстояние трейлинга, 
      else
         {
         if (ask<(Utils.OrderStopLoss() - (trldist + Utils.Spread())*Point))
         newstop = ask +  trldist*Point;
         }
            
       // модифицируем стоплосс
      if (newstop>0)
         {
         if (((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()>Utils.OrderOpenPrice())) && (newstop>ask+StopLevelPoints))
            {
               ChangeOrder(order,newstop,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            }
         else
            {
            if ((newstop<Utils.OrderStopLoss()) && (newstop>Utils.Ask()+StopLevelPoints))  
               {
                  ChangeOrder(order,newstop,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
               }
            }
         }
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО ВРЕМЕНИ                                              |
//| Функции передаётся тикет позиции, интервал (минут), с которым,   |
//| передвигается стоплосс и шаг трейлинга (на сколько пунктов       |
//| перемещается стоплосс, trlinloss - тралим ли в убытке            |
//| (т.е. с определённым интервалом подтягиваем стоп до курса        |
//| открытия, а потом и в профите, либо только в профите)            |
//+------------------------------------------------------------------+
void TrailingByTime(Order &order,int interval,int trlstep,bool trlinloss)
   {
      
   // проверяем переданные значения
   if ((!order.Valid()) || (interval<1) || (trlstep<1) || (!order.Select()))
      {
      Print("Трейлинг функцией TrailingByTime() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      }
      
   double minpast; // кол-во полных минут от открытия позиции до текущего момента 
   double times2change; // кол-во интервалов interval с момента открытия позиции (т.е. сколько раз должен был быть перемещен стоплосс) 
   double newstop; // новое значение стоплосса (учитывая кол-во переносов, которые должны были иметь место)
   
   // определяем, сколько времени прошло с момента открытия позиции
   minpast = (double)(TimeCurrent() - Utils.OrderOpenTime()) / 60;
      
   // сколько раз нужно было передвинуть стоплосс
   times2change = MathFloor(minpast / interval);
         
   // если длинная позиция (OP_BUY)
   if (Utils.OrderType()==OP_BUY)
      {
      // если тралим в убытке, то отступаем от стоплосса (если он не 0, если 0 - от открытия)
      if (trlinloss==true)
         {
         if (Utils.OrderStopLoss()==0) newstop =Utils.OrderOpenPrice() + times2change*(trlstep*Point);
         else newstop =Utils.OrderStopLoss() + times2change*(trlstep*Point); 
         }
      else
      // иначе - от курса открытия позиции
      newstop =Utils.OrderOpenPrice() + times2change*(trlstep*Point); 
         
      if (times2change>0)
         {
         if ((newstop>Utils.OrderStopLoss()) && (newstop<Utils.Bid()- StopLevelPoints))
            {
                ChangeOrder(order,newstop,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            }
         }
      }
      
   // если короткая позиция (OP_SELL)
   if (Utils.OrderType()==OP_SELL)
      {
      // если тралим в убытке, то отступаем от стоплосса (если он не 0, если 0 - от открытия)
      if (trlinloss==true)
         {
         if (Utils.OrderStopLoss()==0) newstop =Utils.OrderOpenPrice() - times2change*(trlstep*Point) - Utils.Spread()*Point;
         else newstop =Utils.OrderStopLoss() - times2change*(trlstep*Point) - Utils.Spread()*Point;
         }
      else
      newstop =Utils.OrderOpenPrice() - times2change*(trlstep*Point) - Utils.Spread()*Point;
                
      if (times2change>0)
         {
         if (((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()<Utils.OrderOpenPrice())) && (newstop>Utils.Ask()+StopLevelPoints))
            {
                ChangeOrder(order,newstop,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            }
         else
         if ((newstop<Utils.OrderStopLoss()) && (newstop>Utils.Ask()+StopLevelPoints))
            {
                ChangeOrder(order,newstop,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            }
         }
      }      
   }
//+------------------------------------------------------------------+

void TrailEachNewBar(Order& order, ENUM_TIMEFRAMES tf)
{
   if ((!order.Valid()) || (!order.Select())  )
   {
      Print("Трейлинг функцией TrailingByATR() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
   }
   double sl = DefaultStopLoss();
   double tp = DefaultTakeProfit();
   double ask = Utils.Ask();
   double bid = Utils.Bid();
   double OP = Utils.OrderOpenPrice();

   if (order.type==OP_BUY)
   {
      // откладываем от текущего курса (новый стоплосс)
      sl = OP - sl*Point;
      tp = OP + tp*Point;  
   }
   if (order.type==OP_SELL)
   {
      sl = OP + sl*Point;
      tp = OP - tp*Point;  
   }

   ChangeOrder(order, sl,tp, order.expiration, TrailingColor);
}

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО ATR (Average True Range, Средний истинный диапазон)  |
//| Функции передаётся тикет позиции, период АТR и коэффициент, на   |
//| который умножается ATR. Т.о. стоплосс "тянется" на расстоянии    |
//| ATR х N от текущего курса; перенос - на новом баре (т.е. от цены |
//| открытия очередного бара) coeffSL = 2, coeffTP =3                |
//+------------------------------------------------------------------+
void TrailingByATR(Order& order,int atr_timeframe, int atr_shift, double coeffSL, double coeffTP,bool trlinloss)
{
   // проверяем переданные значения   
   if ((!order.Valid()) || (!order.Select()) || (atr_shift<0) )
      {
      Print("Трейлинг функцией TrailingByATR() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      }
   
   double curr_atr; // текущее значение ATR - 1
   //double curr_atr2; // текущее значение ATR - 2
   double best_atr; // большее из значений ATR
   double atrXcoeffSL, atrXcoeffTP; // результат умножения большего из ATR на коэффициент
   double newstop; // новый стоплосс
   double newtp;
   
   // текущее значение ATR-1, ATR-2
   curr_atr = signals.GetATR(atr_shift);
   //curr_atr2 = Utils.iATR((ENUM_TIMEFRAMES)atr_timeframe,atr2_period,atr2_shift);
   
   // большее из значений
   best_atr = curr_atr;//MathMax(curr_atr1,curr_atr2);
   
   // после умножения на коэффициент
   atrXcoeffSL = best_atr * coeffSL;
   atrXcoeffTP = best_atr * coeffTP;
   
   double ask = Utils.tick.ask;
   double bid = Utils.tick.bid;
              
   // если длинная позиция (OP_BUY)
   if (order.type==OP_BUY)
      {
      // откладываем от текущего курса (новый стоплосс)
      newstop = bid - atrXcoeffSL;
      newtp = ask + atrXcoeffTP;  
               
      // если trlinloss==true (т.е. следует тралить в зоне лоссов), то
      if (trlinloss==true)      
         {
         // если стоплосс неопределен, то тралим в любом случае
         if ((Utils.OrderStopLoss()==0) && (newstop<bid-StopLevelPoints))
            {
               ChangeOrder(order, newstop,newtp,order.expiration, TrailingColor);
            }
         // иначе тралим только если новый стоп лучше старого
         else
            {
            if ((newstop>Utils.OrderStopLoss()) && (newstop<bid-StopLevelPoints))
               ChangeOrder(order,newstop,newtp,order.expiration, TrailingColor);
            }
         }
      else
         {
         // если стоплосс неопределен, то тралим, если стоп лучше открытия
         if ((Utils.OrderStopLoss()==0) && (newstop>Utils.OrderOpenPrice()) && (newstop<bid-StopLevelPoints))
            {
               ChangeOrder(order,newstop,newtp,order.expiration, TrailingColor);
            }
         // если стоп не равен 0, то меняем его, если он лучше предыдущего и курса открытия
         else
            {
            if ((newstop>Utils.OrderStopLoss()) && (newstop>Utils.OrderOpenPrice()) && (newstop<bid-StopLevelPoints))
               ChangeOrder(order,newstop,newtp,order.expiration, TrailingColor);
               //if (!OrderModify(ticket,Utils.OrderOpenPrice(),newstop,Utils.OrderTakeProfit(),Utils.OrderExpiration()))
               //Print("Не удалось модифицировать ордер №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      }
      
   // если короткая позиция (OP_SELL)
   if (order.type==OP_SELL)
      {
      // откладываем от текущего курса (новый стоплосс)
      newstop = ask + atrXcoeffSL;
      newtp = bid - atrXcoeffTP;
      
      // если trlinloss==true (т.е. следует тралить в зоне лоссов), то
      if (trlinloss==true)      
         {
         // если стоплосс неопределен, то тралим в любом случае
         if ((Utils.OrderStopLoss()==0) && (newstop>ask+StopLevelPoints))
            {
               ChangeOrder(order,newstop,newtp,order.expiration, TrailingColor);
            }
         // иначе тралим только если новый стоп лучше старого
         else
            {
            if ((newstop<Utils.OrderStopLoss()) && (newstop>ask+StopLevelPoints))
               ChangeOrder(order,newstop,newtp,order.expiration, TrailingColor);
            }
         }
      else
         {
         // если стоплосс неопределен, то тралим, если стоп лучше открытия
         if ((Utils.OrderStopLoss()==0) && (newstop<Utils.OrderOpenPrice()) && (newstop>ask+StopLevelPoints))
            {
               ChangeOrder(order,newstop,newtp,order.expiration, TrailingColor);
            }
         // если стоп не равен 0, то меняем его, если он лучше предыдущего и курса открытия
         else
            {
            if ((newstop<Utils.OrderStopLoss()) && (newstop<Utils.OrderOpenPrice()) && (newstop>ask+StopLevelPoints))
               ChangeOrder(order,newstop,newtp,order.expiration, TrailingColor);
            }
         }
      }      
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ RATCHET БАРИШПОЛЬЦА                                     |
//| При достижении профитом уровня 1 стоплосс - в +1, при достижении |
//| профитом уровня 2 профита - стоплосс - на уровень 1, когда       |
//| профит достигает уровня 3 профита, стоплосс - на уровень 2       |
//| (дальше можно трейлить другими методами)                         |
//| при работе в лоссовом участке - тоже 3 уровня, но схема работы   |
//| с ними несколько иная, а именно: если мы опустились ниже уровня, |
//| а потом поднялись выше него (пример для покупки), то стоплосс    |
//| ставим на следующий, более глубокий уровень (например, уровни    |
//| -5, -10 и -25, стоплосс -40; если опустились ниже -10, а потом   |
//| поднялись выше -10, то стоплосс - на -25, если поднимемся выще   |
//| -5, то стоплосс перенесем на -10, при -2 (спрэд) стоп на -5      |
//| работаем только с одной позицией одновременно                    |
//+------------------------------------------------------------------+
void TrailingRatchetB(Order& order,int pf_level_1,int pf_level_2,int pf_level_3,int ls_level_1,int ls_level_2,int ls_level_3,bool trlinloss)
   {
    
   // проверяем переданные значения
   if ((!order.Valid()) || (!order.Select()) || (pf_level_2<=pf_level_1) || (pf_level_3<=pf_level_2) || 
   (pf_level_3<=pf_level_1) || (pf_level_2-pf_level_1<=StopLevelPoints) || (pf_level_3-pf_level_2<=StopLevelPoints) ||
   (pf_level_1<=Utils.StopLevel()))
      {
      Print("Трейлинг функцией TrailingRatchetB() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      }
                
   // если длинная позиция (OP_BUY)
   if (Utils.OrderType()==OP_BUY)
      {
      double dBid = Utils.Bid();
      
      // Работаем на участке профитов
      
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_3+спрэд", стоплосс переносим в "pf_level_2+спрэд"
      if ((dBid-Utils.OrderOpenPrice())>=pf_level_3*Point)
         {
         if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()<Utils.OrderOpenPrice() + pf_level_2 *Point))
            ChangeOrder(order,Utils.OrderOpenPrice() + pf_level_2*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      else
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_2+спрэд", стоплосс переносим в "pf_level_1+спрэд"
      if ((dBid-Utils.OrderOpenPrice())>=pf_level_2*Point)
         {
         if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()<Utils.OrderOpenPrice() + pf_level_1*Point))
            ChangeOrder(order,Utils.OrderOpenPrice() + pf_level_1*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      else        
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_1+спрэд", стоплосс переносим в +1 ("открытие + спрэд")
      if ((dBid-Utils.OrderOpenPrice())>=pf_level_1*Point)
      // если стоплосс не определен или хуже чем "открытие+1"
         {
         if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()<Utils.OrderOpenPrice() + 1*Point))
            ChangeOrder(order,Utils.OrderOpenPrice() + 1*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }

      // Работаем на участке лоссов
      if (trlinloss==true)      
         {
         // Глобальная переменная терминала содержит значение самого уровня убытка (ls_level_n), ниже которого опускался курс
         // (если он после этого поднимается выше, устанавливаем стоплосс на ближайшем более глубоком уровне убытка (если это не начальный стоплосс позиции)
         // Создаём глобальную переменную (один раз)
         if(!GlobalVariableCheck("zeticket")) 
            {
            GlobalVariableSet("zeticket",order.Id());
            // при создании присвоим ей "0"
            GlobalVariableSet("dpstlslvl",0);
            }
         // если работаем с новой сделкой (новый тикет), затираем значение dpstlslvl
         if (GlobalVariableGet("zeticket")!=order.Id())
            {
            GlobalVariableSet("dpstlslvl",0);
            GlobalVariableSet("zeticket",order.Id());
            }
      
         // убыточным считаем участок ниже курса открытия и до первого уровня профита
         if ((dBid-Utils.OrderOpenPrice())<pf_level_1*Point)         
            {
            // если (текущий_курс лучше/равно открытие) и (dpstlslvl>=ls_level_1), стоплосс - на ls_level_1
            if (dBid>=Utils.OrderOpenPrice()) 
            if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()<(Utils.OrderOpenPrice()-ls_level_1*Point)))
              ChangeOrder(order,Utils.OrderOpenPrice()-ls_level_1*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
              //OrderModify(ticket,Utils.OrderOpenPrice(),Utils.OrderOpenPrice()-ls_level_1*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration());
      
            // если (текущий_курс лучше уровня_убытка_1) и (dpstlslvl>=ls_level_1), стоплосс - на ls_level_2
            if ((dBid>=Utils.OrderOpenPrice()-ls_level_1*Point) && (GlobalVariableGet("dpstlslvl")>=ls_level_1))
            if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()<(Utils.OrderOpenPrice()-ls_level_2*Point)))
               ChangeOrder(order,Utils.OrderOpenPrice()-ls_level_2*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
               //OrderModify(ticket,Utils.OrderOpenPrice(),Utils.OrderOpenPrice()-ls_level_2*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration());
      
            // если (текущий_курс лучше уровня_убытка_2) и (dpstlslvl>=ls_level_2), стоплосс - на ls_level_3
            if ((dBid>=Utils.OrderOpenPrice()-ls_level_2*Point) && (GlobalVariableGet("dpstlslvl")>=ls_level_2))
            if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()<(Utils.OrderOpenPrice()-ls_level_3*Point)))
               ChangeOrder(order,Utils.OrderOpenPrice()-ls_level_3*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
               //OrderModify(ticket,Utils.OrderOpenPrice(),Utils.OrderOpenPrice()-ls_level_3*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration());
      
            // проверим/обновим значение наиболее глубокой "взятой" лоссовой "ступеньки"
            // если "текущий_курс-курс открытия+спрэд" меньше 0, 
            if ((dBid-Utils.OrderOpenPrice()+Utils.Spread()*Point)<0)
            // проверим, не меньше ли он того или иного уровня убытка
               {
               if (dBid<=Utils.OrderOpenPrice()-ls_level_3*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_3)
               GlobalVariableSet("dpstlslvl",ls_level_3);
               else
               if (dBid<=Utils.OrderOpenPrice()-ls_level_2*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_2)
               GlobalVariableSet("dpstlslvl",ls_level_2);   
               else
               if (dBid<=Utils.OrderOpenPrice()-ls_level_1*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_1)
               GlobalVariableSet("dpstlslvl",ls_level_1);
               }
            } // end of "if ((dBid-Utils.OrderOpenPrice())<pf_level_1*Point)"
         } // end of "if (trlinloss==true)"
      }
      
   // если короткая позиция (OP_SELL)
   if (Utils.OrderType()==OP_SELL)
      {
      double dAsk = Utils.Ask();
      
      // Работаем на участке профитов
      
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_3+спрэд", стоплосс переносим в "pf_level_2+спрэд"
      if ((Utils.OrderOpenPrice()-dAsk)>=pf_level_3*Point)
         {
         if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()>Utils.OrderOpenPrice() - (pf_level_2 + Utils.Spread())*Point))
            ChangeOrder(order,Utils.OrderOpenPrice() - (pf_level_2 + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            //OrderModify(ticket,Utils.OrderOpenPrice(),Utils.OrderOpenPrice() - (pf_level_2 + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration());
         }
      else
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_2+спрэд", стоплосс переносим в "pf_level_1+спрэд"
      if ((Utils.OrderOpenPrice()-dAsk)>=pf_level_2*Point)
         {
         if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()>Utils.OrderOpenPrice() - (pf_level_1 + Utils.Spread())*Point))
            ChangeOrder(order,Utils.OrderOpenPrice() - (pf_level_1 + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            //OrderModify(ticket,Utils.OrderOpenPrice(),Utils.OrderOpenPrice() - (pf_level_1 + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration());
         }
      else        
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_1+спрэд", стоплосс переносим в +1 ("открытие + спрэд")
      if ((Utils.OrderOpenPrice()-dAsk)>=pf_level_1*Point)
      // если стоплосс не определен или хуже чем "открытие+1"
         {
         if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()>Utils.OrderOpenPrice() - (1 + Utils.Spread())*Point))
            ChangeOrder(order,Utils.OrderOpenPrice() - (1 + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            //OrderModify(ticket,Utils.OrderOpenPrice(),Utils.OrderOpenPrice() - (1 + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration());
         }

      // Работаем на участке лоссов
      if (trlinloss==true)      
         {
         // Глобальная переменная терминала содержит значение самого уровня убытка (ls_level_n), ниже которого опускался курс
         // (если он после этого поднимается выше, устанавливаем стоплосс на ближайшем более глубоком уровне убытка (если это не начальный стоплосс позиции)
         // Создаём глобальную переменную (один раз)
         if(!GlobalVariableCheck("zeticket")) 
            {
            GlobalVariableSet("zeticket",order.Id());
            // при создании присвоим ей "0"
            GlobalVariableSet("dpstlslvl",0);
            }
         // если работаем с новой сделкой (новый тикет), затираем значение dpstlslvl
         if (GlobalVariableGet("zeticket")!=order.Id())
            {
            GlobalVariableSet("dpstlslvl",0);
            GlobalVariableSet("zeticket",order.Id());
            }
      
         // убыточным считаем участок ниже курса открытия и до первого уровня профита
         if ((Utils.OrderOpenPrice()-dAsk)<pf_level_1*Point)         
            {
            // если (текущий_курс лучше/равно открытие) и (dpstlslvl>=ls_level_1), стоплосс - на ls_level_1
            if (dAsk<=Utils.OrderOpenPrice()) 
            if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()>(Utils.OrderOpenPrice() + (ls_level_1 + Utils.Spread())*Point)))
                ChangeOrder(order,Utils.OrderOpenPrice() + (ls_level_1 + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
      
            // если (текущий_курс лучше уровня_убытка_1) и (dpstlslvl>=ls_level_1), стоплосс - на ls_level_2
            if ((dAsk<=Utils.OrderOpenPrice() + (ls_level_1 + Utils.Spread())*Point) && (GlobalVariableGet("dpstlslvl")>=ls_level_1))
            if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()>(Utils.OrderOpenPrice() + (ls_level_2 + Utils.Spread())*Point)))
               ChangeOrder(order,Utils.OrderOpenPrice() + (ls_level_2 + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
      
            // если (текущий_курс лучше уровня_убытка_2) и (dpstlslvl>=ls_level_2), стоплосс - на ls_level_3
            if ((dAsk<=Utils.OrderOpenPrice() + (ls_level_2 + Utils.Spread())*Point) && (GlobalVariableGet("dpstlslvl")>=ls_level_2))
            if ((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()>(Utils.OrderOpenPrice() + (ls_level_3 + Utils.Spread())*Point)))
               ChangeOrder(order,Utils.OrderOpenPrice() + (ls_level_3 + Utils.Spread())*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
      
            // проверим/обновим значение наиболее глубокой "взятой" лоссовой "ступеньки"
            // если "текущий_курс-курс открытия+спрэд" меньше 0, 
            if ((Utils.OrderOpenPrice()-dAsk+Utils.Spread()*Point)<0)
            // проверим, не меньше ли он того или иного уровня убытка
               {
               if (dAsk>=Utils.OrderOpenPrice()+(ls_level_3+Utils.Spread())*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_3)
               GlobalVariableSet("dpstlslvl",ls_level_3);
               else
               if (dAsk>=Utils.OrderOpenPrice()+(ls_level_2+Utils.Spread())*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_2)
               GlobalVariableSet("dpstlslvl",ls_level_2);   
               else
               if (dAsk>=Utils.OrderOpenPrice()+(ls_level_1+Utils.Spread())*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_1)
               GlobalVariableSet("dpstlslvl",ls_level_1);
               }
            } // end of "if ((dBid-Utils.OrderOpenPrice())<pf_level_1*Point)"
         } // end of "if (trlinloss==true)"
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО ЦЕНВОМУ КАНАЛУ                                       |
//| Функции передаётся тикет позиции, период (кол-во баров) для      | 
//| рассчета верхней и нижней границ канала, отступ (пунктов), на    |
//| котором размещается стоплосс от границы канала                   |
//| Трейлинг по закрывшимся барам.                                   |
//+------------------------------------------------------------------+
void TrailingByPriceChannel(Order& order,int iBars_n,int iIndent)
   {     
   
   // проверяем переданные значения
   if ((iBars_n<1) || (iIndent<0) || (!order.Valid()) || (!order.Select()))
      {
      Print("Трейлинг функцией TrailingByPriceChannel() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      } 
   
   double   dChnl_max; // верхняя граница канала
   double   dChnl_min; // нижняя граница канала
   
   // определяем макс.хай и мин.лоу за iBars_n баров начиная с [1] (= верхняя и нижняя границы ценового канала)
   dChnl_max = iHigh(Symbol, Period(), iHighest(Symbol(),0,2,iBars_n,1)) + (iIndent+Utils.Spread())*Point;
   dChnl_min = iLow(Symbol, Period(), iLowest(Symbol(),0,1,iBars_n,1)) - iIndent*Point;   
   
   // если длинная позиция, и её стоплосс хуже (ниже нижней границы канала либо не определен, ==0), модифицируем его
   if (order.type == OP_BUY)
      {
      if ((Utils.OrderStopLoss()<dChnl_min) && (dChnl_min<Utils.Bid()-StopLevelPoints))
         {
            //if (MaxStopLoss != 0)
            //   dChnl_min = MathMax(Bid - MaxStopLoss * Point, dChnl_min);
            //double TP = OrderTakeProfit();
            //if (MaxTakeProfit != 0)
            //   TP = Ask + MaxTakeProfit* Point;
            ChangeOrder(order,dChnl_min,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      }
   
   // если позиция - короткая, и её стоплосс хуже (выше верхней границы канала или не определён, ==0), модифицируем его
   if (order.type == OP_SELL)
      {
      if (((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()>dChnl_max)) && (dChnl_min>Utils.Ask()+StopLevelPoints))
         {
            //if (MaxStopLoss != 0)
            //   dChnl_max = MathMin(Ask + MaxStopLoss * Point, dChnl_max);
            //double TP = OrderTakeProfit();
            //if (MaxTakeProfit != 0)
            //  TP = Bid - MaxTakeProfit* Point;
            ChangeOrder(order,dChnl_max,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      }
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО СКОЛЬЗЯЩЕМУ СРЕДНЕМУ                                 |
//| Функции передаётся тикет позиции и параметры средней (таймфрейм, | 
//| период, тип, сдвиг относительно графика, метод сглаживания,      |
//| составляющая OHCL для построения, № бара, на котором берется     |
//| значение средней.                                                |
//+------------------------------------------------------------------+

//    Допустимые варианты ввода:   
//    iTmFrme:    1 (M1), 5 (M5), 15 (M15), 30 (M30), 60 (H1), 240 (H4), 1440 (D), 10080 (W), 43200 (MN);
//    iMAPeriod:  2-infinity, целые числа; 
//    iMAShift:   целые положительные или отрицательные числа, а также 0;
//    MAMethod:   0 (MODE_SMA), 1 (MODE_EMA), 2 (MODE_SMMA), 3 (MODE_LWMA);
//    iApplPrice: 0 (PRICE_CLOSE), 1 (PRICE_OPEN), 2 (PRICE_HIGH), 3 (PRICE_LOW), 4 (PRICE_MEDIAN), 5 (PRICE_TYPICAL), 6 (PRICE_WEIGHTED)
//    iShift:     0-Bars, целые числа;
//    iIndent:    0-infinity, целые числа;

void TrailingByMA(Order& order,int iTmFrme,int iMAPeriod,int iMAShift,int MAMethod,int iApplPrice,int iShift,int iIndent)
   {     
   
   // проверяем переданные значения
   if ((!order.Valid()) || (!order.Select()) || ((iTmFrme!=1) && (iTmFrme!=5) && (iTmFrme!=15) && (iTmFrme!=30) && (iTmFrme!=60) && (iTmFrme!=240) && (iTmFrme!=1440) && (iTmFrme!=10080) && (iTmFrme!=43200)) ||
   (iMAPeriod<2) || (MAMethod<0) || (MAMethod>3) || (iApplPrice<0) || (iApplPrice>6) || (iShift<0) || (iIndent<0))
      {
      Print("Трейлинг функцией TrailingByMA() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      } 

   double   dMA; // значение скользящего среднего с переданными параметрами
   
   // определим значение МА с переданными функции параметрами
   dMA = Utils.iMA((ENUM_TIMEFRAMES)iTmFrme,iMAPeriod,iMAShift,(ENUM_MA_METHOD)MAMethod,(ENUM_APPLIED_PRICE)iApplPrice,iShift);
         
   // если длинная позиция, и её стоплосс хуже значения среднего с отступом в iIndent пунктов, модифицируем его
   if (Utils.OrderType()==OP_BUY)
      {
      if ((Utils.OrderStopLoss()<dMA-iIndent*Point) && (dMA-iIndent*Point<Utils.Bid()-StopLevelPoints))
         {
            ChangeOrder(order,dMA-iIndent*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      }
   
   // если позиция - короткая, и её стоплосс хуже (выше верхней границы канала или не определён, ==0), модифицируем его
   if (Utils.OrderType()==OP_SELL)
      {
      if (((Utils.OrderStopLoss()==0) || (Utils.OrderStopLoss()>dMA+(Utils.Spread()+iIndent)*Point)) && (dMA+(Utils.Spread()+iIndent)*Point>Utils.Ask()+StopLevelPoints))
         {
            ChangeOrder(order,dMA+(Utils.Spread()+iIndent)*Point,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
         }
      }
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ "ПОЛОВИНЯЩИЙ"                                           |
//| По закрытии очередного периода (бара) подтягиваем стоплосс на    |
//| половину (но можно и любой иной коэффициент) дистанции, прой-    |
//| денной курсом (т.е., например, по закрытии суток профит +55 п. - |
//| стоплосс переносим в 55/2=27 п. Если по закрытии след.           |
//| суток профит достиг, допустим, +80 п., то стоплосс переносим на  |
//| половину (напр.) расстояния между тек. стоплоссом и курсом на    |
//| закрытии бара - 27 + (80-27)/2 = 27 + 53/2 = 27 + 26 = 53 п.     |
//| iTicket - тикет позиции; iTmFrme - таймфрейм (в минутах, цифрами |
//| dCoeff - "коэффициент поджатия", в % от 0.01 до 1 (в последнем   |
//| случае стоплосс будет перенесен (если получится) вплотную к тек. |
//| курсу и позиция, скорее всего, сразу же закроется)               |
//| bTrlinloss - стоит ли тралить на лоссовом участке - если да, то  |
//| по закрытию очередного бара расстояние между стоплоссом (в т.ч.  |
//| "до" безубытка) и текущим курсом будет сокращаться в dCoeff раз  |
//| чтобы посл. вариант работал, обязательно должен быть определён   |
//| стоплосс (не равен 0)                                            |
//+------------------------------------------------------------------+

void TrailingFiftyFifty(Order& order,ENUM_TIMEFRAMES iTmFrme,double dCoeff,bool bTrlinloss)
   { 
   // активируем трейлинг только по закрытии бара
   if (sdtPrevtime == iTime(Symbol(), iTmFrme,0)) 
      return;
   else
      {
      sdtPrevtime = iTime(Symbol(), iTmFrme,0);             
      
      // проверяем переданные значения
      if ((!order.Valid()) || (!order.Select()) || 
      ((iTmFrme!=1) && (iTmFrme!=5) && (iTmFrme!=15) && (iTmFrme!=30) && (iTmFrme!=60) && (iTmFrme!=240) && 
      (iTmFrme!=1440) && (iTmFrme!=10080) && (iTmFrme!=43200)) || (dCoeff<0.01) || (dCoeff>1.0))
         {
         Print("Трейлинг функцией TrailingFiftyFifty() невозможен из-за некорректности значений переданных ей аргументов.");
         return;
         }
         
      // начинаем тралить - с первого бара после открывающего (иначе при bTrlinloss сразу же после открытия 
      // позиции стоплосс будет перенесен на половину расстояния между стоплоссом и курсом открытия)
      // т.е. работаем только при условии, что с момента OrderOpenTime() прошло не менее iTmFrme минут
      if (iTime(Symbol(), iTmFrme,0)>Utils.OrderOpenTime())
      {         
      
      double dBid = Utils.Bid();
      double dAsk = Utils.Ask();
      double dNewSl = 0;
      double dNexMove = 0;     
      
      // для длинной позиции переносим стоплосс на dCoeff дистанции от курса открытия до Bid на момент открытия бара
      // (если такой стоплосс лучше имеющегося и изменяет стоплосс в сторону профита)
      if (Utils.OrderType()==OP_BUY)
         {
         if ((bTrlinloss) && (Utils.OrderStopLoss()!=0))
            {
            dNexMove = NormalizeDouble(dCoeff*(dBid-Utils.OrderStopLoss()),Digits);
            dNewSl = NormalizeDouble(Utils.OrderStopLoss()+dNexMove,Digits);            
            }
         else
            {
            // если стоплосс ниже курса открытия, то тралим "от курса открытия"
            if (Utils.OrderOpenPrice()>Utils.OrderStopLoss())
               {
               dNexMove = NormalizeDouble(dCoeff*(dBid-Utils.OrderOpenPrice()),Digits);                 
               //Print("dNexMove = ",dCoeff,"*(",dBid,"-",Utils.OrderOpenPrice(),")");
               dNewSl = NormalizeDouble(Utils.OrderOpenPrice()+dNexMove,Digits);
               //Print("dNewSl = ",Utils.OrderOpenPrice(),"+",dNexMove);
               }
         
            // если стоплосс выше курса открытия, тралим от стоплосса
            if (Utils.OrderStopLoss()>=Utils.OrderOpenPrice())
               {
               dNexMove = NormalizeDouble(dCoeff*(dBid-Utils.OrderStopLoss()),Digits);
               dNewSl = NormalizeDouble(Utils.OrderStopLoss()+dNexMove,Digits);
               }                                      
            }
            
         // стоплосс перемещаем только в случае, если новый стоплосс лучше текущего и если смещение - в сторону профита
         // (при первом поджатии, от курса открытия, новый стоплосс может быть лучше имеющегося, и в то же время ниже 
         // курса открытия (если dBid ниже последнего) 
         if ((dNewSl>Utils.OrderStopLoss()) && (dNexMove>0) && ((dNewSl<dBid- StopLevelPoints)))
            {
               ChangeOrder(order,dNewSl,Utils.OrderTakeProfit(),Utils.OrderExpiration(),Red);
            }
         }       
      
      // действия для короткой позиции   
      if (Utils.OrderType()==OP_SELL)
         {
         if ((bTrlinloss) && (Utils.OrderStopLoss()!=0))
            {
            dNexMove = NormalizeDouble(dCoeff*(Utils.OrderStopLoss()-(dAsk+Utils.Spread()*Point)),Digits);
            dNewSl = NormalizeDouble(Utils.OrderStopLoss()-dNexMove,Digits);            
            }
         else
            {         
            // если стоплосс выше курса открытия, то тралим "от курса открытия"
            if (Utils.OrderOpenPrice()<Utils.OrderStopLoss())
               {
               dNexMove = NormalizeDouble(dCoeff*(Utils.OrderOpenPrice()-(dAsk+Utils.Spread()*Point)),Digits);                 
               dNewSl = NormalizeDouble(Utils.OrderOpenPrice()-dNexMove,Digits);
               }
         
            // если стоплосс нижу курса открытия, тралим от стоплосса
            if (Utils.OrderStopLoss()<=Utils.OrderOpenPrice())
               {
               dNexMove = NormalizeDouble(dCoeff*(Utils.OrderStopLoss()-(dAsk+Utils.Spread()*Point)),Digits);
               dNewSl = NormalizeDouble(Utils.OrderStopLoss()-dNexMove,Digits);
               }                  
            }
         
         // стоплосс перемещаем только в случае, если новый стоплосс лучше текущего и если смещение - в сторону профита
         if ((dNewSl<Utils.OrderStopLoss()) && (dNexMove>0) && (dNewSl>dAsk+StopLevelPoints))
            {
               ChangeOrder(order,dNewSl,Utils.OrderTakeProfit(),Utils.OrderExpiration(),Blue);
            }
         }               
      }
      }   
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ KillLoss                                                |
//| Применяется на участке лоссов. Суть: стоплосс движется навстречу |
//| курсу со скоростью движения курса х коэффициент (dSpeedCoeff).   |
//| При этом коэффициент можно "привязать" к скорости увеличения     |
//| убытка - так, чтобы при быстром росте лосса потерять меньше. При |
//| коэффициенте = 1 стоплосс сработает ровно посредине между уров-  |
//| нем стоплосса и курсом на момент запуска функции, при коэфф.>1   |
//| точка встречи курса и стоплосса будет смещена в сторону исход-   |
//| ного положения курса, при коэфф.<1 - наоборот, ближе к исходно-  |
//| му стоплоссу.                                                    |
//+------------------------------------------------------------------+

void KillLoss(Order& order,double dSpeedCoeff)
   {   
   // проверяем переданные значения
   if ((!order.Valid()) || (!order.Valid()) || (dSpeedCoeff<0.1))
      {
      Print("Трейлинг функцией KillLoss() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      }           
      
   double dStopPriceDiff = 0; // расстояние (пунктов) между курсом и стоплоссом   
   double dToMove; // кол-во пунктов, на которое следует переместить стоплосс   
   // текущий курс
   double dBid = Utils.Bid();
   double dAsk = Utils.Ask();      
   
   // текущее расстояние между курсом и стоплоссом
   if (Utils.OrderType()==OP_BUY) dStopPriceDiff = dBid -Utils.OrderStopLoss();
   if (Utils.OrderType()==OP_SELL) dStopPriceDiff = (Utils.OrderStopLoss() + Utils.Spread()*Point) - dAsk;                  
   
   // проверяем, если тикет != тикету, с которым работали раньше, запоминаем текущее расстояние между курсом и стоплоссом
   if (GlobalVariableGet("zeticket")!=order.Id())
      {
      GlobalVariableSet("sldiff",dStopPriceDiff);      
      GlobalVariableSet("zeticket",order.Id());
      }
   else
      {                                   
      // итак, у нас есть коэффициент ускорения изменения курса
      // на каждый пункт, который проходит курс в сторону лосса, 
      // мы должны переместить стоплосс ему на встречу на dSpeedCoeff раз пунктов
      // (например, если лосс увеличился на 3 пункта за тик, dSpeedCoeff = 1.5, то
      // стоплосс подтягиваем на 3 х 1.5 = 4.5, округляем - 5 п. Если подтянуть не 
      // удаётся (слишком близко), ничего не делаем.            
      
      // кол-во пунктов, на которое приблизился курс к стоплоссу с момента предыдущей проверки (тика, по идее)
      dToMove = (GlobalVariableGet("sldiff") - dStopPriceDiff) / Point;
      
      // записываем новое значение, но только если оно уменьшилось
      if (dStopPriceDiff<GlobalVariableGet("sldiff"))
      GlobalVariableSet("sldiff",dStopPriceDiff);
      
      // дальше действия на случай, если расстояние уменьшилось (т.е. курс приблизился к стоплоссу, убыток растет)
      if (dToMove>0)
         {       
         // стоплосс, соответственно, нужно также передвинуть на такое же расстояние, но с учетом коэфф. ускорения
         dToMove = MathRound(dToMove * dSpeedCoeff) * Point;                 
      
         // теперь проверим, можем ли мы подтянуть стоплосс на такое расстояние
         if (Utils.OrderType()==OP_BUY)
            {
            if (dBid - (Utils.OrderStopLoss() + dToMove)>StopLevelPoints)
               ChangeOrder(order,Utils.OrderStopLoss() + dToMove,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            }
         if (Utils.OrderType()==OP_SELL)
            {
            if ((Utils.OrderStopLoss() - dToMove) - dAsk>StopLevelPoints)
               ChangeOrder(order,Utils.OrderStopLoss() - dToMove,Utils.OrderTakeProfit(),Utils.OrderExpiration(), TrailingColor);
            }      
         }
      }            
   }
   
   //+------------------------------------------------------------------+ 
   bool AllowVStops() {
      return AllowVirtualStops;   
   }   
   bool AllowRStops() {
      return AllowRealStops;   
   }
};

