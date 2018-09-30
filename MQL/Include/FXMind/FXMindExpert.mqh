//+------------------------------------------------------------------+
//|                                                 FXMindExpert.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#include <FXMind\InputTypes.mqh>
#include <FXMind\IFXMindService.mqh>
#include <FXMind\TradeMethods.mqh>
#include <FXMind\TradePanel.mqh>
#include <FXMind\TradeSignals.mqh>
#include <FXMind\PendingOrders.mqh>

class FXMindExpert 
{
protected:
   string trendString;
   Order* grid_head;
   TradeMethods* methods;
   TradeSignals* signals;
   TradePanel*   panel;
   char lastChar;
   // INPUT_VARIABLE(TakeProfitLevel, int, 30)
   int   actualTakeProfitLevel;
   // INPUT_VARIABLE(StopLossLevel, int, 85)
   //int   actualStopLossLevel;
   CIsSession BUYSession;
   CIsSession SELLSession;
   PendingOrders pending;      
public:
   FXMindExpert()
     :BUYSession(BUYBegin, BUYEnd)
     ,SELLSession(SELLBegin, SELLEnd)
     ,pending(ChartID(), 0)
   {
      grid_head = NULL;
      methods = NULL;
      signals = NULL;
      panel   = NULL;
      lastChar = 0;
      trendString = "NEUTRAL";
   }
   
   ~FXMindExpert();
   
   int  Init();
   void DeInit(int reason);
   void ProcessOrders();
   void SaveGlobalProperties();
   void OnTickPendingOrders();
   void ProcessStopOrders(OrderSelection* orders);
 
#ifdef __MQL5__
   void UpdateOrders();
#endif
   
   void Draw()
   {
      if (panel == NULL)
         return;
      if ( (!Utils.IsTesting()) || Utils.IsVisualMode()) 
         panel.Draw();
   }

   //+------------------------------------------------------------------+
   bool TrailByType(Order& order);
   virtual void      OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
   string ReasonToString(int Reason);
   
   //+------------------------------------------------------------------+
   datetime TrailingTFNow;
   void OnEachNewBar(Order& order)
   {
      datetime currentBar = iTime(methods.Symbol, methods.Period, 0);
      if ( TrailingTFNow ==  currentBar )
         return;
      TrailingTFNow = currentBar;
      methods.TrailEachNewBar(order, methods.Period);
   }
   
   datetime SignalTFNow;
   int GetSignalOperationType()
   {
      /*
      if (signals.LastSignal.OnAlert())
      {
         if  (signals.LastSignal.Value > 0)
            return (OP_BUY);
         if (signals.LastSignal.Value < 0)
            return (OP_SELL);
          return -1;
      }
      */
      if (EnableNews)
      {
         if (signals.News.OpenNewsSTOPOrders(signals.LastSignal))
         {
            if (signals.LastSignal.Value > 0)
               return (OP_BUY);
            if (signals.LastSignal.Value < 0)
               return (OP_SELL);
         }
      }
      datetime currentBar = iTime(methods.Symbol, methods.Period, 0);
      if (SignalTFNow ==  currentBar)
          return -1;
      SignalTFNow = currentBar;
      bool isSignal = true;
      if ((SignalIndicator == NoIndicator) && (!EnableNews) ) // No signals - no auto trading
         return -1;
         
      signals.RefreshIndicators();
      
      if (EnableNews)
      {
         isSignal = signals.News.Process(signals.LastSignal);
      } else             
         isSignal = signals.ProcessSignal();
      
      if (panel != NULL)
         panel.TrendString = signals.GetStatusString();
         
      if ((!isSignal) && (!EnableNews))
      {
          return -1;
      }            
      if (signals.LastSignal.type == SignalCLOSEBUYPOS)
      { 
          methods.CloseTrailingPositions(OP_BUY);
          signals.SignalHandled();
          return -1;
      }  
      if (signals.LastSignal.type == SignalCLOSESELLPOS)
      {
          methods.CloseTrailingPositions(OP_SELL);
          signals.SignalHandled();
          return -1;
      }        
      bool isFilter = signals.ProcessFilter();
      if ((!isFilter) && (!EnableNews)) 
      {
          return -1;
      }
      if (panel != NULL)
      {
         panel.TrendString = signals.GetStatusString();      
         //if (SignalIndicator == NewsIndicator)
         //   panel.NewsStatString = signals.GetSignalStatusString();
      }
      return RaiseOrder(isSignal);
      /*if (isSignal && signals.LastSignal.OnAlert())
      {
         int resultSignal = WeightCalc();
         if  (resultSignal > 0)
            return (OP_BUY);
         if (resultSignal < 0)
            return (OP_SELL);
      } */   
      //return (-1);
   }
   
   int RaiseOrder(bool isSignal)
   {
      if (isSignal && signals.LastSignal.OnAlert())
      {
         int resultSignal = WeightCalc();
         if  (resultSignal > 0)
            return (OP_BUY);
         if (resultSignal < 0)
            return (OP_SELL);
      }    
      return -1;
   }
   
   int WeightCalc()
   {
       int resultSignal = 0;
       switch(WeightCalculation)
       {
          case WeightByFilter:
             return signals.FilterSignal.Value;
          case WeightBySignal:
             return signals.LastSignal.Value;
          case WeightBySum:
             return signals.LastSignal.Value + signals.FilterSignal.Value;
          case WeightByMultiply:
             return signals.LastSignal.Value * signals.FilterSignal.Value;
          case WeightByAND:
          {
             if ((signals.LastSignal.Value > 0) && (signals.FilterSignal.Value > 0))
               return 1;
             if ((signals.LastSignal.Value < 0) && (signals.FilterSignal.Value < 0))
               return -1;
          }
       }
       return resultSignal;
   }
   
   double CalculateGridLotSize(int op)
   {
       if (op == OP_BUY)
          return NormalizeDouble(LotsBUY * GridMultiplier, 2);     
       if (op == OP_SELL)
          return NormalizeDouble(LotsSELL * GridMultiplier, 2);
       return LotsBUY;
   }
   
   Order* InitManualOrder(int type) {
      Order* order = new Order(-1);
      order.type = type;
      order.SetRole(RegularTrail);
      
      double oprice = (type==OP_BUY)?Utils.Bid():Utils.Ask();
      order.setTakeProfit(methods.TakeProfit(oprice, order.type));
      order.setStopLoss(methods.StopLoss(oprice, order.type));
      
      order.lots = methods.CalculateLotSize(order.type, false);
      order.comment = "Manual";
      return order;
   }
   
   Order* InitExpertOrder(int type) {
      Order* order = new Order(-1);
      order.type = type;
      order.SetRole(RegularTrail);
      
      double oprice = (type==OP_BUY)?Utils.Bid():Utils.Ask();
      order.setTakeProfit(methods.TakeProfit(oprice, order.type));
      order.setStopLoss(methods.StopLoss(oprice, order.type));
      
      order.lots = methods.CalculateLotSize(order.type, false);
      order.comment = "Expert";
      return order;
   }
   
   Order* InitGridOrder(int type) {
      Order* order = new Order(-1);
      order.type = type;
      order.SetRole(GridHead);
      order.lots = methods.CalculateLotSize(order.type, GridHead);
      order.comment = "Grid";
      return order;
   }
   
   Order* InitFromPending(PendingOrder* pend) {
      Order* order = new Order(pend.Id());
      order.type = pend.type;
      order.SetRole(RegularTrail);
      order.lots = pend.lots;
      order.setStopLoss(pend.StopLoss(false));
      order.setTakeProfit(pend.TakeProfit(false));
      order.comment = StringFormat("%s %s", order.TypeToString(), EnumToString(pend.Role()));
      return order;
   }
      
   Order* OpenBUYOrder(Order* order)
   {
      order.signalName = signals.GetLastSignalName(order.comment);
      order = methods.OpenOrder(order);
      if (order != NULL)
      {
         if (actualAllowGRIDBUY && (order.Role() == GridHead))
             grid_head = order;
         signals.SignalHandled();
         return order;
      }
      return NULL;
   }
      
   Order* OpenSELLOrder(Order* order)
   {
      order.signalName = signals.GetLastSignalName(order.comment);
      order = methods.OpenOrder(order);
      if (order != NULL)
      {
         if (actualAllowGRIDSELL && (order.Role() == GridHead))
             grid_head = order;
         signals.SignalHandled();
         return order;
      }
      return NULL;
   }
   
};

void FXMindExpert::OnTickPendingOrders()
{
   if (pending.pendingBUY != NULL)
   {
      if (!pending.pendingBUY.isSelected())
      {
         if (pending.pendingBUY.Role() == PendingLimit) 
         {
            double bid = Utils.Bid();
            if (pending.pendingBUY.openPrice >= bid)
            {
                Order* order = OpenBUYOrder(InitFromPending(pending.pendingBUY));
                if ((order == NULL) && MoreTriesOpenOrder)
                {
                   Sleep(5000);
                   Utils.Info("Second try to open PendingOrder!");
                   order = OpenBUYOrder(InitFromPending(pending.pendingBUY));
                }
                Order::OrderMessage(order, "Pending BUYLIMIT");
                pending.DeleteBUY();   
                pending.DeleteSELL();   
                ChartRedraw(pending.chartID);
                return;
            }
         }
         if (pending.pendingBUY.Role() == PendingStop) 
         {
            double ask = Utils.Ask();
            if (pending.pendingBUY.openPrice <= ask)
            {
                Order* order = OpenBUYOrder(InitFromPending(pending.pendingBUY));
                if ((order == NULL) && MoreTriesOpenOrder)
                {
                   Sleep(5000);
                   Utils.Info("Second try to open PendingOrder ");
                   order = OpenBUYOrder(InitFromPending(pending.pendingBUY));
                }
                Order::OrderMessage(order, "Pending BUYSTOP");
                pending.DeleteBUY();   
                pending.DeleteSELL();   
                ChartRedraw(pending.chartID);
                return;
            }
         }
      }
   }
   if (pending.pendingSELL != NULL)
   {
      if (!pending.pendingSELL.isSelected())
      {
         if (pending.pendingSELL.Role() == PendingLimit) 
         {
            double ask = Utils.Ask();
            if (pending.pendingSELL.openPrice <= ask)
            {
                Order* order = OpenSELLOrder(InitFromPending(pending.pendingSELL));
                if ((order == NULL) && MoreTriesOpenOrder)
                {
                   Sleep(5000);
                   Utils.Info("Second try to open PendingOrder ");
                   order = OpenSELLOrder(InitFromPending(pending.pendingSELL));
                }
                Order::OrderMessage(order, "Pending SELLLIMIT");
                pending.DeleteBUY();   
                pending.DeleteSELL();   
                ChartRedraw(pending.chartID);
                return;
            }     
         }
         if (pending.pendingSELL.Role() == PendingStop) 
         {
            double bid = Utils.Bid();
            if (pending.pendingSELL.openPrice >= bid)
            {
                Order* order = OpenSELLOrder(InitFromPending(pending.pendingSELL));
                if ((order == NULL) && MoreTriesOpenOrder)
                {
                   Sleep(5000);
                   Utils.Info("Second try to open PendingOrder ");
                   order = OpenSELLOrder(InitFromPending(pending.pendingSELL));
                }
                Order::OrderMessage(order, "Pending SELLSTOP");
                pending.DeleteBUY();
                pending.DeleteSELL();
                ChartRedraw(pending.chartID);
                return;
            }
         }
      }
   }
}

void FXMindExpert::ProcessStopOrders(OrderSelection* orders)
{
   FOREACH_ORDER(orders)
   {
      // First close unclosed orders due to errors on Broker servers!!!
      if (!order.isPending())
      {
         double ask = Utils.Ask();
         double bid = Utils.Bid();
         double sl = order.StopLoss(false);
         double tp = order.TakeProfit(false);
         if (order.type == OP_BUY) 
         {
            if ( (bid <= sl) && (sl > 0))
            {
               order.MarkToClose();
               Utils.Info(StringFormat("Close order %s by Stoploss", order.ToString()));
            }
            if ( (ask >= tp) && (tp > 0) )
            {
               Utils.Info(StringFormat("Close order %s by TakeProfit", order.ToString()));
            }
            continue;
         }
         if (order.type == OP_SELL) 
         {
            if ( (ask >= sl) && (sl > 0))
            {
               order.MarkToClose();
               Utils.Info(StringFormat("Close order %s by Stoploss", order.ToString()));
            }
            if ( (bid <= tp) && (tp > 0) )
            {
               Utils.Info(StringFormat("Close order %s by TakeProfit", order.ToString()));
            }
            continue;
         }
      }
   }
}

void FXMindExpert::OnEvent(const int id,         // Event identifier  
                  const long& lparam,   // Event parameter of long type
                  const double& dparam, // Event parameter of double type
                  const string& sparam) // Event parameter of string type
{

  //--- the key has been pressed
  if( id == CHARTEVENT_KEYDOWN )
  {
      //int bnumber = StringToInteger(CharToString((uchar)lparam));
      
      // "gc" keyboad type closes the Grid on the current chart
      if (lparam=='G' || lparam=='g')
         lastChar = 'g';
         
      //if (lparam=='T' || lparam=='t')
      //   lastChar = 't';
         
      if (lparam=='O' || lparam=='o')
         lastChar = 'o';
         
      if (lparam=='P' || lparam=='p')
         lastChar = 'p';

      if (lastChar=='o')
      {
         if (lparam=='s' || lparam=='S')
         {
            lastChar = 0;
            OpenSELLOrder(InitManualOrder(OP_SELL));
         }

         if (lparam=='b' || lparam=='B')
         {
            lastChar = 0;
            OpenBUYOrder(InitManualOrder(OP_BUY));
            return;
         }
         
      }
      
      if (lastChar=='p')
      {
         if (lparam=='s' || lparam=='S')
         {
            lastChar = 0;
            double lots = methods.CalculateLotSize(OP_SELL, false);
            pending.CreatePendingOrderSELL(lots);
         }

         if (lparam=='b' || lparam=='B')
         {
            lastChar = 0;
            double lots = methods.CalculateLotSize(OP_BUY, false);
            pending.CreatePendingOrderBUY(lots);
            return;
         }         
      }

      
      if (lastChar=='g')
      {      
         if ((lparam=='c') || (lparam=='C')) 
         { 
            lastChar = 0;
            grid_head = NULL;
            methods.CloseGrid();
            if (panel != NULL)
               panel.SetForceRedraw();
            Alert("Closing Grid...");            
         }
         
         if ((lparam=='s' || lparam=='S') && actualAllowGRIDSELL) 
         { 
            lastChar = 0;
            OpenSELLOrder(InitGridOrder(OP_SELL));
         }

         if (((lparam=='b') || (lparam=='B')) && actualAllowGRIDBUY )
         { 
            lastChar = 0;
            OpenBUYOrder(InitGridOrder(OP_BUY));
            return;
         }
      }
  } 
  
  if ( id == CHARTEVENT_OBJECT_DRAG )
  {
/*
      if(StringFind(sparam,"SLLINE")>-1)
      if ( (StringCompare(sparam,PendingOrder::idPendingSELL,0)==0)
             && (pendingSELL != NULL))
      {
         order.Drag(lparam, dparam, sparam);
      }
            
      if ( (StringCompare(sparam,PendingOrder::idPendingBUY,0)==0) 
             && (pendingBUY != NULL))
      {
         order.Drag(lparam, dparam, sparam);
      }
*/
  }

  pending.OnEvent(id, lparam, dparam, sparam);

  
  if (panel != NULL)
     panel.OnEvent(id,lparam,dparam,sparam);

}


void FXMindExpert::DeInit(int Reason)
{
   if (Reason != REASON_PARAMETERS)
   {
      SaveGlobalProperties();
      if (methods != NULL)
         methods.SaveOrders();
   }

   DELETE_PTR(panel)

   DELETE_PTR(signals)

   DELETE_PTR(methods)

   IFXMindService* thrift = Utils.Service();
   if (thrift != NULL)
      thrift.DeInit(Reason);
   Utils.Info(StringFormat("Expert MagicNumber: %d closed with reason %s.", thrift.MagicNumber(), ReasonToString(Reason)));
   
   DELETE_PTR(Utils);
   
}

FXMindExpert::~FXMindExpert()
{
  

}

int FXMindExpert::Init()
{   
   IFXMindService* thrift = Utils.Service();
      
   if (!thrift.Init(true))
      return INIT_FAILED;
   
   actualTakeProfitLevel = 30;
   //actualStopLossLevel = 30;
   actualAllowGRIDSELL = AllowGRIDSELL;
   actualAllowGRIDBUY = AllowGRIDBUY;
   
   if ( Digits() == 3 || Digits() == 5 )
   {
      actualSlippage = Slippage*10;
      actualTakeProfitLevel = actualTakeProfitLevel*10;
      //actualStopLossLevel = actualStopLossLevel*10;
      // actualGridStep = GridStep * 10;
   }
   
   methods = new TradeMethods();
   Utils.SetTrade(methods);
   if ( PanelSize != PanelNone ) 
      panel = new TradePanel();
   signals = new TradeSignals(methods, panel);
   methods.SetSignalsProcessor(signals);
   
   SaveGlobalProperties();
   
   string initMessage = StringFormat("OnInit %s MagicNumber: %d", thrift.Name(), thrift.MagicNumber());
   Utils.Info(initMessage);
   thrift.PostMessage(initMessage);
   
   //TestOrders();
      
   if ( panel != NULL )
      panel.Init();

   methods.LoadOrders();
     
   pending.Init();
   pending.LoadOrders(Utils.Service().Settings());
   return (INIT_SUCCEEDED);
}


#ifdef __MQL5__

void FXMindExpert::UpdateOrders()
{
   if (panel == NULL)
      return;
   // OrderSelection* orders = methods.GetOpenOrders();
   if (!Utils.IsTesting() || Utils.IsVisualMode())
      panel.Draw();
}

#endif

void FXMindExpert::ProcessOrders()
{
   Utils.RefreshRates();
   OnTickPendingOrders();
   OrderSelection* orders = methods.GetOpenOrders();    
   ProcessStopOrders(orders);
   int countBUY = methods.CountOrdersByType(OP_BUY, orders);
   int countSELL = methods.CountOrdersByType(OP_SELL, orders);
   int grid_count = 0;
   double CheckPrice = 0;
   double LossLevel = 0;
   double orderProfit = 0;
   int i = 0;
   double gridProfit = 0; 
      
   int pendingDeleteCount = methods.CountOrdersByRole(ShouldBeClosed, orders);
   if (pendingDeleteCount > 0)
   {
      Utils.Info(StringFormat("!!!!!Delete hard stuck Orders count = %d!!!!!!!", pendingDeleteCount));
      FOREACH_ORDER(orders)
      {
         // First close unclosed orders due to errors on Broker servers!!!
         if (order.Role() == ShouldBeClosed)
         {
            if (methods.CloseOrder(order, clrRed))
            {  
               orders.DeleteCurrent();
               //return;
            }
         }
      }
      orders.Sort();
   }
   
   switch (signals.GetTrend())
   {
      case LATERAL:
          if (AllowGRIDSELL)
             actualAllowGRIDSELL = true;
          if (AllowGRIDBUY)
             actualAllowGRIDBUY = true;
      break;
      case DOWN:
         if (AllowGRIDSELL)
            actualAllowGRIDSELL = true;
         if (AllowGRIDBUY)
            actualAllowGRIDBUY = false;
      break;      
      case UPPER:
         if (AllowGRIDSELL)
            actualAllowGRIDSELL = false;
         if (AllowGRIDBUY)
            actualAllowGRIDBUY = true;
      break;
   }

   if (actualAllowGRIDBUY || actualAllowGRIDSELL) 
   {
      grid_head = methods.FindGridHead(orders, grid_count);
      gridProfit = methods.GetGridProfit(orders);
      if ((gridProfit >= GridProfit) ) //|| (grid_count > MaxGridOrders )
      {
         grid_head = NULL;
         methods.CloseGrid();
         if (panel != NULL)
            panel.SetForceRedraw();
         return;
      }
      
      if ((grid_count > MaxGridOrders) && (gridProfit < 0) && (MathAbs(gridProfit)>=(3*GridProfit)))
      {
         grid_head = NULL;
         methods.CloseGrid();
         if (panel != NULL)
         panel.SetForceRedraw();
         return;
      }
      
   }
   if (panel != NULL)
   {
      panel.OrdersString = StringFormat("Default(%s) TotalProfit(%g)", EnumToString(TrailingType), methods.GetProfit(orders)); 
      if (grid_count > 0)
         panel.OrdersString += StringFormat(" GridCount(%d) GridProfit(%g)", grid_count, gridProfit); 
   }

   // STARTING POINT FOR OPENING ORDERS
   int op_type = GetSignalOperationType();
      
   if (AllowBUY && (op_type == OP_BUY) &&  BUYSession.IsSession() && (countBUY == 0) && (grid_head == NULL)) 
   {
      OpenBUYOrder(InitExpertOrder(op_type));
      return;
   }
   if (AllowSELL && (op_type == OP_SELL) && SELLSession.IsSession() && (countSELL == 0) && (grid_head == NULL)) 
   {
      OpenSELLOrder(InitExpertOrder(op_type));
      return;
   }
      
   FOREACH_ORDER(orders)
   {
      if ((actualAllowGRIDBUY || actualAllowGRIDSELL) && order.Select()) 
      {
         orderProfit = order.RealProfit();
         if ((!order.isGridOrder()) && (grid_head == NULL) && (orderProfit < 0))
         {
            order.openPrice = Utils.OrderOpenPrice();
            //this is a first order to start build grid
            if (order.type == OP_BUY) 
            {
               CheckPrice = Utils.Ask();
               LossLevel = (order.openPrice - CheckPrice)/Point();
            }
            else 
            {
               CheckPrice = Utils.Bid();
               LossLevel = (CheckPrice - order.openPrice)/Point();
            }
            //LossLevel = MathAbs( CheckPrice - order.openPrice )/Point;
            if ( LossLevel >= methods.GetGridStepValue() ) {
               order.SetRole(GridTail);
               if ((order.type == OP_BUY) && actualAllowGRIDBUY)
                  grid_head = OpenBUYOrder(InitGridOrder(OP_BUY));
               if ((order.type == OP_SELL) && actualAllowGRIDSELL)
                  grid_head = OpenSELLOrder(InitGridOrder(OP_SELL));
               if (grid_head != NULL)
               {
                  Print(StringFormat("!!!Grid Started Ticket: %d", grid_head.Id()));
                  return;
               }
            }
         } else 
               if (grid_head != NULL)
               {
                  if ((order.Id() == grid_head.Id()) && (order.Role() == GridHead))
                  {
                     if (grid_head.type == OP_BUY)
                     {
                        CheckPrice = Utils.Ask();
                        LossLevel = (grid_head.openPrice - CheckPrice)/Point();
                     } 
                     else 
                     {
                        CheckPrice = Utils.Bid();
                        LossLevel = (CheckPrice - grid_head.openPrice)/Point();
                     }
                     if ((LossLevel > methods.GetGridStepValue()) && (signals.InNewsPeriod == false)) 
                     {
                        int trend = signals.ProcessFilter(); // GetBWTrend();
                        if (((trend > 0) && (order.type == OP_SELL)) 
                         || ((trend < 0) && (order.type == OP_BUY))) 
                        {
                           grid_head.SetRole(GridTail);

                           if ((order.type == OP_BUY) && actualAllowGRIDBUY)
                              grid_head = OpenBUYOrder(InitGridOrder(OP_BUY));
                           if ((order.type == OP_SELL) && actualAllowGRIDSELL)
                              grid_head = OpenSELLOrder(InitGridOrder(OP_SELL));
                           if (grid_head != NULL)
                           {
                              Print(StringFormat("!!!Grid Continue Ticket: %d", grid_head.Id()));
                              return;
                           }
                        }
                     }
                  }
               }
      }
      if (TrailByType(order))
         return;
   }
   signals.SignalHandled();
}

void FXMindExpert::SaveGlobalProperties()
{
   SettingsFile* set = Utils.Service().Settings();
   if (set!= NULL)
   {
      set.SetGlobalParam("LotsBUY", LotsBUY);
      set.SetGlobalParam("LotsSELL", LotsSELL);
      set.SetGlobalParam("LotsMIN", LotsMIN);
      //set.SetGlobalParam("AllowStopLossByDefault", AllowStopLossByDefault);
      set.SetGlobalParam("ThriftPORT", ThriftPORT);
      set.SetGlobalParam("PanelSize", (int)PanelSize);      
      set.SetGlobalParam("RefreshTimeFrame", (int)RefreshTimeFrame);      
      set.SetGlobalParam("MaxOpenedTrades", MaxOpenedTrades);
      set.SetGlobalParam("AllowBUY", AllowBUY);
      set.SetGlobalParam("AllowSELL", AllowSELL);
            
      set.SetGlobalParam("BUYBegin", BUYBegin);
      set.SetGlobalParam("BUYEnd", BUYEnd);
      set.SetGlobalParam("SELLBegin", SELLBegin);
      set.SetGlobalParam("SELLEnd", SELLEnd);

      set.SetGlobalParam("CoeffSL", CoeffSL);
      set.SetGlobalParam("CoeffTP", CoeffTP);
      //set.SetGlobalParam("TPByPercentile", TPByPercentile);
      set.SetGlobalParam("Slippage", Slippage);
      set.SetGlobalParam("PendingOrderStep", PendingOrderStep);      
      set.SetGlobalParam("MoreTriesOpenOrder", MoreTriesOpenOrder);
      set.SetGlobalParam("AllowVirtualStops", AllowVirtualStops);
      set.SetGlobalParam("AllowRealStops", AllowRealStops);
                  
      //set.SetGlobalParam("SLTPDivergence", SLTPDivergence);      

      set.SetGlobalParam("AllowGRIDBUY", AllowGRIDBUY);
      set.SetGlobalParam("AllowGRIDSELL", AllowGRIDSELL);
      set.SetGlobalParam("GridMultiplier", GridMultiplier);
      set.SetGlobalParam("GridProfit", GridProfit);
      set.SetGlobalParam("MaxGridOrders", MaxGridOrders);
      set.SetGlobalParam("TrailingIndent", TrailingIndent);
      //set.SetGlobalParam("TrailingTimeFrame", (int)TrailingTimeFrame);
      set.SetGlobalParam("TrailingType", (int)TrailingType);
      set.SetGlobalParam("TrailInLoss", TrailInLoss);
      
      set.SetGlobalParam("SignalIndicator", (int)SignalIndicator);
      //set.SetGlobalParam("SignalTimeFrame", SignalTimeFrame);
      set.SetGlobalParam("FilterIndicator", (int)FilterIndicator);
      //set.SetGlobalParam("FilterTimeFrame", FilterTimeFrame);
      set.SetGlobalParam("IshimokuPeriod1", IshimokuPeriod1);
      set.SetGlobalParam("IshimokuPeriod2", IshimokuPeriod2);
      set.SetGlobalParam("IshimokuPeriod3", IshimokuPeriod3);
      set.SetGlobalParam("NumBarsFlatPeriod", NumBarsFlatPeriod);
      set.SetGlobalParam("NumBarsToAnalyze", NumBarsToAnalyze);
      
      set.SetGlobalParam("BandsPeriod", BandsPeriod);
      set.SetGlobalParam("BandsDeviation", BandsDeviation);

      set.SetGlobalParam("EnableNews", EnableNews);
      set.SetGlobalParam("RaiseSignalBeforeEventMinutes", RaiseSignalBeforeEventMinutes);
      set.SetGlobalParam("NewsPeriodMinutes", NewsPeriodMinutes);
      set.SetGlobalParam("MinImportance", MinImportance);
      set.SetGlobalParam("comment", Utils.Service().Name());
   }
}

//+------------------------------------------------------------------+
bool FXMindExpert::TrailByType(Order& order) 
{
   if ((TrailingType == TrailingManual) || order.Role() != RegularTrail)
       return false;
   //datetime currentBar = iTime(methods.Symbol, TrailingTimeFrame, 0);
   //   if ( TrailingTFNow == currentBar )
   //     return;
   //TrailingTFNow = currentBar;
              
   ENUM_TRAILING trailing = TrailingType;
   if (order.TrailingType != TrailingDefault)
      trailing = order.TrailingType;
   switch(trailing)
   {
      case TrailingByFractals:
      case TrailingDefault:
         methods.TrailingByFractals(order,methods.Period,NumBarsToAnalyze,TrailingIndent,TrailInLoss);  // good for USDCHF USDJPY and by default
      return false;
      case TrailingByShadows:
         methods.TrailingByShadows(order,methods.Period,NumBarsToAnalyze,TrailingIndent,TrailInLoss);
      return false;
      case TrailingByATR:
         methods.TrailingByATR(order,methods.Period,1, CoeffSL, CoeffTP, TrailInLoss);             
      return false;
      case TrailingByMA:
         methods.TrailingByMA(order,methods.Period,28,0,MODE_SMA,PRICE_MEDIAN,0,TrailingIndent); // EURAUD Trailing buy+sell 
      return false;
      case TrailingStairs:
      {
         int sl = methods.DefaultStopLoss();
         double slp = Utils.StopLevel()*2;
         double step = (double)sl/4.0;
         if (slp > 0)
           step = slp;
         methods.TrailingStairs(order,sl,(int)step);  
         return false;   
      }
      case TrailingFiftyFifty:
         methods.TrailingFiftyFifty(order, methods.Period, 0.5, TrailInLoss);   // Good for EURUSD / EURAUD and for FlatTrend
      return false;
      case TrailingKillLoss:
         methods.KillLoss(order, 1.0);
      return false;
      case TrailingByPriceChannel:
      {
         methods.TrailingByPriceChannel(order, NumBarsToAnalyze, TrailingIndent); //actualStopLossLevel NumBarsFractals >= 10, TrailingIndent = 10
         return false;
      }
      case TrailingFilter:
      {
         signals.FI.Trail(order, TrailingIndent); 
         return false;
      }
      case TrailingSignal:
      {
         signals.SI.Trail(order, TrailingIndent); 
         return false;
      }
      //case TrailingIchimoku:
      //{
         //signals.TMAM15.Trail(order, TrailingIndent);
         //return true;
      //}
      case TrailEachNewBar:
         OnEachNewBar(order);
         return false;
      case TrailingManual:
         //Just skip trailing
         return false;
      return false;
   
   }
   return false;
}

string FXMindExpert::ReasonToString(int Reason)
{
   switch(Reason) 
   {
      case REASON_PROGRAM: //0
         return "0 REASON_PROGRAM - Эксперт прекратил свою работу, вызвав функцию ExpertRemove()";
      case REASON_REMOVE: //1
         return "1 REASON_REMOVE Программа удалена с графика";
      case REASON_RECOMPILE: // 2
         return "2 REASON_RECOMPILE Программа перекомпилирована";
      case REASON_CHARTCHANGE: //3
         return "3 REASON_CHARTCHANGE Символ или период графика был изменен";
      case REASON_CHARTCLOSE:
         return "4 REASON_CHARTCLOSE График закрыт";
      case REASON_PARAMETERS:          
         return "5 REASON_PARAMETERS Входные параметры были изменены пользователем";       
      case REASON_ACCOUNT:
         return "6 Активирован другой счет либо произошло переподключение к торговому серверу вследствие изменения настроек счета";
      case REASON_TEMPLATE:           
         return "7 REASON_TEMPLATE Применен другой шаблон графика";
      case REASON_INITFAILED:
         return "8 REASON_INITFAILED Признак того, что обработчик OnInit() вернул ненулевое значение";
      case REASON_CLOSE:
         return "9 REASON_CLOSE Терминал был закрыт";
   }
   return StringFormat("Unknown reason: %s", Reason);
}

/*
void TestOrders()
{
    Order* arr[];
    ArrayResize(arr, MaxOpenedTrades);
    int k = 0;
    for(k = 0; k<MaxOpenedTrades;k++)
    {
       arr[k] = new Order(k);
       methods.globalOrders.Add(arr[k]);
    }

    int i = 0;
    FOREACH_ORDER(methods.globalOrders)
    {
       if (i%2==0)
          methods.globalOrders.DeleteCurrent();
       i++;   
    }
    methods.globalOrders.Sort();
    
    FOREACH_ORDER(methods.globalOrders)
    {
       order.Print();
    }
    
    i = methods.globalOrders.Total();
    k = 100;
    while (i++ < MaxOpenedTrades)
    {
        Order* or = new Order(k++);
        methods.globalOrders.Add(or);
    }
    
    methods.globalOrders.DeleteByTicket(1);
    methods.globalOrders.DeleteByTicket(k-1);
    
    FOREACH_ORDER(methods.globalOrders)
    {
       order.Print();
    }
    
    methods.globalOrders.Clear();
}
*/

