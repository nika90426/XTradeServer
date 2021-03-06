//+------------------------------------------------------------------+
//|                                                       Orders.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#include <Arrays/List.mqh>
#include <XTrade/GenericTypes.mqh>
#include <XTrade/IUtils.mqh>

#define PENDING_BUY_TICKET  -200
#define PENDING_SELL_TICKET -300

#define FOREACH_LIST(list) for(CObject* node = (list).GetFirstNode(); node != NULL; node = (list).GetNextNode())
#define FOREACH_ORDER(list) for(Order* order = (list).GetFirstNode(); order != NULL; order = (list).GetNextNode())

#define ASCENDING             -1
#define DESCENDING            1
#define NEWEST                DESCENDING
#define OLDEST                ASCENDING

//INPUT_VARIABLE(SLTPDivergence, double, 0.2)

#define SLTPDivergence    0.3

#define SL_LINE_STYLE STYLE_SOLID
#define TP_LINE_STYLE STYLE_SOLID

#define MAX_PRICE (Utils.Ask()*3.0)

//+------------------------------------------------------------------+
//| Order class                                                      |
//+------------------------------------------------------------------+
class Order : public SerializableEntity
{
   protected:
      ENUM_ORDERROLE role;
      double   stopLoss;
      double   takeProfit;
      double   realStopLoss;
      double   realTakeProfit;
      long     ticket;
      ushort   numberContracts;
      
      color  slColor;
      color  tpColor;
      color  opColor;
      short SL_LINE_WIDTH; 
      short TP_LINE_WIDTH; 
   void _preInit() {
      TrailingType = TrailingDefault;
      role = RegularTrail;
      bDirty = true; // By default Order unsync with broker and dirty.
      signalName = "";
      slColor = clrRed;
      tpColor = clrOrange;
      opColor = clrGreen;
      SL_LINE_WIDTH = 2;
      TP_LINE_WIDTH = 2;
      symbol = Utils.Symbol;
      openPrice = 0;
      stopLoss = 0.0;
      realStopLoss = 0.0;
      takeProfit = 0.0;
      realTakeProfit = 0.0;
      profit = 0;
      numberContracts = 1;
   }
   
public:
   int      type;
   long     magic;
   double   lots;
   double   openPrice;
   double   closePrice;
   datetime openTime;
   double   profit;
   double   swap;
   double   commission;
   datetime expiration;
   string comment;
   string symbol;
   string signalName;
   
   // specific properties
   ENUM_TRAILING  TrailingType;
   bool bDirty;

   void Order(long Ticket)
   {
      _preInit();
      ticket = Ticket;
      // Print(StringFormat("C-tor Order(%d) ", ticket));
   }
      
   void Order(string fromJson)
   {
      _preInit();
      if ( StringLen(fromJson) <= 0 )
         return;
      obj.Deserialize(fromJson);
      type = (int)obj["Type"].ToInt();
      lots = obj["Lots"].ToDbl();
      stopLoss = obj["Vsl"].ToDbl();
      realStopLoss = obj["Realsl"].ToDbl();
      takeProfit = obj["Vtp"].ToDbl();
      realTakeProfit = obj["Realtp"].ToDbl();
      symbol = obj["Symbol"].ToStr();
      role = (ENUM_ORDERROLE)obj["Role"].ToInt();
      if (obj.FindKey("Magic"))        
        magic = obj["Magic"].ToInt();
      if (obj.FindKey("numberContracts"))
        this.numberContracts = (ushort)obj["numberContracts"].ToInt();
   }
    
    virtual CJAVal* Persistent()
    {
      obj["Ticket"] = (int)ticket;
      obj["Type"] = (int)type;
      obj["Lots"] = lots;
      obj["Realsl"] = StopLoss(true);
      obj["Vsl"] = StopLoss(false);
      obj["Realtp"] = TakeProfit(true);
      obj["Vtp"] = TakeProfit(false);
      obj["Symbol"] = symbol;
      obj["Openprice"] = openPrice;
      obj["Closeprice"] = closePrice;
      obj["Opentime"] = TimeToString(openTime);
      obj["Profit"] = profit;
      obj["ProfitStopsPercent"] = PriceDistanceInPercent();
      obj["Swapvalue"] = swap;
      obj["Expiration"] = TimeToString(expiration);
      obj["Comission"] = commission;
      obj["Role"] = EnumToString(role);
      obj["Magic"] = this.magic;
      obj["Account"] = Utils.GetAccountNumer();
      obj["AccountName"] = Utils.GetAccountNumer();
      obj["numberContracts"] = (int)this.numberContracts;
      return &obj;
    }
    
   virtual void ~Order()
   {
      string name = SLLineName();
      Utils.ObjDelete(name);
      name = TPLineName();
      Utils.ObjDelete(name);
      // Print(StringFormat("D-tor Order(%d) ", ticket)); 
   }
      
   string SLLineName() const { return StringFormat("SLLINE_%s:%d", TypeToString(), ticket); }
   
   string TPLineName() const { return StringFormat("TPLINE_%s:%d", TypeToString(), ticket); }
   
   string SLTooltip() const { return StringFormat("SL:%s:%d:Profit=%g", TypeToString(), ticket, ProfitForLevel(StopLoss(false))); }
   
   string TPTooltip() const { return StringFormat("TP:%s:%d:Profit=%g", TypeToString(), ticket, ProfitForLevel(TakeProfit(false))); }
      
   virtual void ShiftUp() {}
   
   virtual void ShiftDown() {}
   
   virtual bool isSelected() const { return false; }
   
   virtual void SetNContracts(ushort n) {  numberContracts = n; }
   
   virtual ushort getNContracts() {
      return numberContracts; 
   }
         
   double ProfitForLevel(double priceLevel) const
   {
      double result = 0;
      //Source: alpari.com, "How can I calculate my profits or losses on a position?"
      double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      if (this.type == OP_BUY)
      {
         //For Buy Positions: Profit/Loss = (Contract × ClosePrice) - (Contract × OpenPrice)
         result = lots * ( contractSize * priceLevel - contractSize * openPrice);
      }
      if (this.type == OP_SELL)
      {
         //For Sell Positions: Profit/Loss = (Contract × OpenPrice) - (Contract × ClosePrice)
         result = lots * (contractSize * openPrice - contractSize * priceLevel);
      }
      return result;
   }
   
   virtual void updateSL(bool forceUpdate)
   {
      if (forceUpdate || (stopLoss <= 0))
      {
         string slName = SLLineName();
         if (Utils.ObjExist(slName))
         {
            double slPrice = ObjectGetDouble(0, slName, OBJPROP_PRICE);
            if (slPrice > 0)
            {
               setStopLoss(slPrice);
            } 
         } else 
         {
            RestoreVStopLoss();
            //if (stopLoss <= 0)
            //   setStopLoss(Utils.Trade().StopLoss(openPrice, type));
         }
         if (Select())
         {
            Utils.Trade().ChangeOrder(this, realStopLoss, realTakeProfit);
         }
      }
   }
   
   virtual void updateTP(bool forceUpdate)
   {
      if (forceUpdate || (takeProfit <= 0))
      {
         string tpName = TPLineName();
         if ( Utils.ObjExist(tpName) )
         {
            double tpPrice = ObjectGetDouble(0, tpName, OBJPROP_PRICE);
            if (tpPrice > 0)
            {
               setTakeProfit(tpPrice);
            }
         } else {
            RestoreVTakeProfit();

            //if (takeProfit <= 0)
            //   setTakeProfit(Utils.Trade().TakeProfit(openPrice, type));
         }
      }
   }
   
   long Id() { return ticket; }
   
   virtual void SetId(long t)
   {
      string name = SLLineName();
      Utils.ObjDelete(name);
      name = TPLineName();
      Utils.ObjDelete(name);

      ticket = t;
   }
   
   virtual void doSelect(bool v) 
   {
        
   }

   double StopLoss(bool real)  const
   {
      if (real) 
      {
         return realStopLoss;
      }   
      return stopLoss;
   }

   double TakeProfit(bool real) const
   {
      if (real)
         return realTakeProfit;
      return takeProfit;
   }
   
   void AdjustRealStop()
   {
      int stopLevel = Utils.StopLevel();
      if (stopLevel == 0)
          stopLevel = 20; 
      int sl_points = 0;
      double pt = Point();
      if (type == OP_BUY)
      {
          sl_points = (int)MathRound((openPrice - realStopLoss)/pt);
      }
      if (type == OP_SELL)
      {
          sl_points = (int)MathRound((realStopLoss - openPrice)/pt);
      }
      int slPoints = ((int)MathRound(1 + sl_points / stopLevel))*stopLevel;
      if (type == OP_BUY)
      {
          realStopLoss = NormalizeDouble(openPrice - slPoints * Point(), _Digits);
      }
      if (type == OP_SELL)
      {
          realStopLoss = NormalizeDouble(openPrice + slPoints * Point(), _Digits);
      }
      if (realStopLoss < 0)
         realStopLoss = 0.0;
   }
   
   void AdjustRealTake()
   {
      int stopLevel = Utils.StopLevel();
      if (stopLevel <= 0)
          stopLevel = 20; 
      int tp_points = 0;
      double pt = Point();
      if (type == OP_BUY)
      {
          tp_points = (int)MathRound((realTakeProfit - openPrice)/pt);
      }
      if (type == OP_SELL)
      {
          tp_points = (int)MathRound((openPrice - realTakeProfit)/pt);
      }
      int tpPoints = ((int)MathRound(1 + tp_points / stopLevel))*stopLevel;
      if (type == OP_BUY)
      {
          realTakeProfit = NormalizeDouble(openPrice + tpPoints * Point(), _Digits);
      }
      if (type == OP_SELL)
      {
          realTakeProfit = NormalizeDouble(openPrice - tpPoints * Point(), _Digits);
      }
      if (realTakeProfit < 0)
         realTakeProfit = 0.0;
   }
   
   bool IsExpired()
   {
      if (expiration <= 0)
         return false;
      if (TimeCurrent() > expiration)
         return true;
      return false;
   }
   
   int RemainedHours()
   {
      if (expiration <= 0)
         return 0;
      double hours = (expiration - TimeCurrent())/60.0/60.0;
      return (int)MathCeil(hours);
   }
   
   virtual void setRealStopLoss(double sl) 
   {
      realStopLoss = sl;
   }
   
   virtual void setStopLoss(double sl) 
   {
      if (sl > MAX_PRICE)
         return;
      if ((sl <= 0) || !MathIsValidNumber(sl))
      {
         stopLoss = 0;
         realStopLoss = 0; 
         return;
      }
      sl = Utils.NormalizePrice(symbol, sl);
      stopLoss = sl;
      realStopLoss = sl;
      // Adjust real stops
      double slPoints = Utils.Trade().DefaultStopLoss() *  Point() * SLTPDivergence;
      if ( type == OP_BUY )
         realStopLoss = stopLoss - slPoints;
      if ( type == OP_SELL )
         realStopLoss = stopLoss + slPoints;
      AdjustRealStop();
      if (Utils.Trade().AllowVStops() && (ticket != -1) ) //&& !isPending()
      {
         string name = SLLineName();
         if (!Utils.ObjExist(name))
            Utils.HLineCreate(name,0,stopLoss,slColor,SL_LINE_STYLE,SL_LINE_WIDTH,false, true,false,0,SLTooltip());
         else 
            Utils.HLineMove(name, stopLoss, SLTooltip());
      }
   }
   
   
   virtual void setRealTakeProfit(double tp) 
   {
      realTakeProfit = tp;
   }
   
   virtual void setTakeProfit(double tp)
   {
      if (tp > MAX_PRICE)
         return;
      if ((tp <= 0) ||  !MathIsValidNumber(tp)) {
         takeProfit = 0;
         realTakeProfit = 0; 
         return;
      }
      tp = Utils.NormalizePrice(symbol, tp);
      takeProfit = tp;
      realTakeProfit = tp;
      // Adjust real takeprofits
      double tpPoints = Utils.Trade().DefaultTakeProfit() * Point() * SLTPDivergence;
      if ( type == OP_BUY )
         realTakeProfit = takeProfit + tpPoints;
      if ( type == OP_SELL )
         realTakeProfit = takeProfit - tpPoints;
      AdjustRealTake();
      if (Utils.Trade().AllowVStops() && (ticket != -1) )
      {
         string name = TPLineName();
         if (!Utils.ObjExist(name))
            Utils.HLineCreate(name,0,takeProfit,tpColor,TP_LINE_STYLE,TP_LINE_WIDTH,false,true,false,0,TPTooltip());
         else 
            Utils.HLineMove(name, takeProfit, TPTooltip());
      }
   }
   
   virtual void RestoreVStopLoss() {
      if (realStopLoss <= 0)
         return;
      double slPoints = Utils.Trade().DefaultStopLoss() *  Point() * SLTPDivergence;
      if ( type == OP_BUY )
         stopLoss = realStopLoss + slPoints;
      if ( type == OP_SELL )
         stopLoss = realStopLoss - slPoints;
         
      if (Utils.Trade().AllowVStops() && (ticket != -1) ) 
      {
         string name = SLLineName();
         if (!Utils.ObjExist(name))
            Utils.HLineCreate(name,0,stopLoss,slColor,SL_LINE_STYLE,SL_LINE_WIDTH,false, true,false,0,SLTooltip());
         else 
            Utils.HLineMove(name, stopLoss, SLTooltip());
      }
   }
   
   virtual void RestoreVTakeProfit() {
      if (realTakeProfit<=0)
         return;
      double tpPoints = Utils.Trade().DefaultTakeProfit() * Point() * SLTPDivergence;
      if ( type == OP_BUY )
         takeProfit = realTakeProfit - tpPoints;
      if ( type == OP_SELL )
         takeProfit = realTakeProfit + tpPoints;   
         
      if (Utils.Trade().AllowVStops() && (ticket != -1) )
      {
         string name = TPLineName();
         if (!Utils.ObjExist(name))
            Utils.HLineCreate(name,0,takeProfit,tpColor,TP_LINE_STYLE,TP_LINE_WIDTH,false,true,false,0,TPTooltip());
         else 
            Utils.HLineMove(name, takeProfit, TPTooltip());
      }
   }
     
   void SetRole(ENUM_ORDERROLE newrole)
   {
      if (role != ShouldBeClosed)
         role = newrole;
   }
   
   ENUM_ORDERROLE Role()
   {
      return role;
   }
   
   virtual void MarkToClose()
   {
      role = ShouldBeClosed;
   }
   
   double RealProfit() 
   {
      Select();
      return Utils.OrderSwap() + Utils.OrderCommission() + Utils.OrderProfit();
   }
   
   double Profit() 
   {
      return this.commission + swap + profit;
   }
   
   double PriceDistanceInPoint()
   {
      double CheckPrice = 0;
      if (type == OP_BUY)
      {
         CheckPrice = SymbolInfoDouble(this.symbol, SYMBOL_ASK);
         return  (openPrice - CheckPrice)/Point();
      }
      else 
      {
         CheckPrice = SymbolInfoDouble(this.symbol, SYMBOL_BID);
         return (CheckPrice - openPrice)/Point();
      }
      return 0;
   }
   
   double PriceDistanceInPercent()
   {
      double CheckPrice = 0;
      double distance = 0;
      if (type == OP_BUY) 
      {
         CheckPrice = SymbolInfoDouble(this.symbol, SYMBOL_ASK);
         distance = (CheckPrice - openPrice);
      }
      else 
      {
         CheckPrice = SymbolInfoDouble(this.symbol, SYMBOL_BID);
         distance = (openPrice - CheckPrice);
      }
      if (distance < 0) {     
         double sl = StopLoss(false);
         if (sl <= 0)
            sl = StopLoss(true);
         if (sl <= 0) 
            return 0;
         return distance/MathAbs(openPrice - sl)*100;   
      }   
      if (distance > 0) {     
         double tp = TakeProfit(false);
         if (tp <= 0)
            tp = TakeProfit(true);
         if (tp <= 0)
            return 0;
         return distance/MathAbs(tp - openPrice)*100.0;   
      }
      return 0;
   }

         
   bool CheckSL()
   {
      if (stopLoss == 0)
        return true;
      double pd = 0;
      if (type == OP_BUY)
      {
          pd = openPrice - stopLoss;
      }
      if (type == OP_SELL)
      {
          pd = stopLoss - openPrice;
      }
      double slp = Utils.StopLevelPoints();
      if (slp > pd)
      {
         if (pd < 0)
            Utils.Info("Wrong STOP LOSS higher/lower than open price!");
         else 
            Utils.Info( "Wrong STOP LOSS less than minimal stop level!");
         return false;  
      }
      
      return true;
   }
   
   bool CheckTP() 
   {
      if (takeProfit == 0)
         return false;
      double pd = 0;
      if (type == OP_BUY)
      {
          pd = takeProfit - openPrice;
      }
      if (type == OP_SELL)
      {
          pd = openPrice - takeProfit;
      }
      double slp = Utils.StopLevelPoints();
      if (slp > pd)
      {
         if (pd < 0)
            Utils.Info("Wrong TAKE PROFIT higher/lower than open price!");
         else 
            Utils.Info("Wrong TAKE PROFIT less than minimal stop level!");
         return false;  
      }
      
      return true;
   }
      
   bool isGridOrder()
   {
       return (role == GridHead) || (role == GridTail);
   }

   bool isPending()
   {
       return (role == PendingLimit) || (role == PendingStop);
   }
   
   virtual int Compare(const CObject *node, const int mode=0) const 
   {
       if (node == NULL)
       {
          Print(StringFormat("Null value passed to Order comparison %d", ticket));
          return -1;
       }
       const Order* order = dynamic_cast<const Order*>(node);
       if (order == NULL)
       {
          Print(StringFormat("Unable to Cast Order pointer for comparison %d", ticket));
          return -1;
       }
       long result = (ticket - order.ticket);
       return (int)result;
   }
   
   bool Valid()
   {
      return (ticket != 0) && (ticket != -1);
   }
   
   bool Select()
   {
      bool Sel = Utils.SelectOrder(ticket);
      return Sel;
   }
   
   bool SelectBySymbol()
   {
      bool Sel = Utils.SelectOrderBySymbol(this.symbol);
      return Sel;
   }

   bool NeedChanges(double sl, double tp, datetime expe, int trailingIndent)
   {      
      double Pt = trailingIndent * Point();
      if (MathAbs(sl-stopLoss)>Pt) 
         return true;
      if (MathAbs(tp-takeProfit)>Pt) 
         return true;
      if (expiration != expe)
         return true;
      return false;
   }
   
   string TypeToString() const
   {
       switch(type)
       {
          case OP_BUY:
             return "BUY";
          break;
          case OP_BUYSTOP:
             return "BUYSTOP";
          break;
          case OP_BUYLIMIT:
             return "BUYLIMIT";
          break;
          case OP_SELL:
             return "SELL";
          break;
          case OP_SELLLIMIT:
             return "SELLLIMIT";
          break;
          case OP_SELLSTOP:
             return "SELLSTOP";
          break;           
       }
       //Utils.Info("Error order type not set");
       return "NO_TYPE";
   }
   
   string ToString()
   {
       double currentPrice = 0;
       string orderTypeString = TypeToString();
       int sl_points = 0;
       int tp_points = 0;
       double pt = Point();
       switch(type)
       {
          case OP_BUY:
             currentPrice = SymbolInfoDouble(this.symbol, SYMBOL_ASK);
          break;
          case OP_BUYSTOP:
             currentPrice = SymbolInfoDouble(this.symbol, SYMBOL_ASK);
          break;
          case OP_BUYLIMIT:
             currentPrice = SymbolInfoDouble(this.symbol, SYMBOL_ASK);
          break;
          case OP_SELL:
             currentPrice = SymbolInfoDouble(this.symbol, SYMBOL_BID);
          break;
          case OP_SELLLIMIT:
             currentPrice = SymbolInfoDouble(this.symbol, SYMBOL_BID);
          break;
          case OP_SELLSTOP:
             currentPrice = SymbolInfoDouble(this.symbol, SYMBOL_BID);
          break;            
       }
       if (stopLoss != 0.0)
       {
         if (type == OP_BUY)
         {
             sl_points = (int)MathRound((openPrice-stopLoss)/pt);
         }
         if (type == OP_SELL)
         {
             sl_points = (int)MathRound((stopLoss - openPrice)/pt);
         }
       }
       if (takeProfit != 0.0)
       {
         if (type == OP_BUY)
         {
             tp_points = (int)MathRound((takeProfit - openPrice)/pt);
         }
         if (type == OP_SELL)
         {
             tp_points = (int)MathRound((openPrice-takeProfit)/pt);
         }
       }
         
       string signalStr = StringSubstr(signalName, 0, 15);

       string result = StringFormat("%s %s(%s) %g OP=%g SL=%d TP=%d %s", orderTypeString, EnumToString(role), symbol, lots, openPrice, sl_points, tp_points, signalStr);
       return result;
   }
   
   
   string OrderSection()
   {
      return StringFormat("ORDER_%d", ticket);
   }
   
   static string OrderSection(long Ticket)
   {
      return StringFormat("ORDER_%d", Ticket);
   }

   // Needed for Pending orders
   virtual void Delete() { }

   bool IsWrong()
   {
      if ((stopLoss == 0.0) && (takeProfit == 0.0))
      {
          return false;
      }
      if ((type == OP_BUY) || (type == OP_BUYLIMIT) || (type == OP_BUYSTOP))
      {
          if ((openPrice >= takeProfit) || (openPrice <= stopLoss))
             return true;
      }    
      if ((type == OP_SELL) || (type == OP_SELLLIMIT) || (type == OP_SELLSTOP))
      {
          if ((openPrice <= takeProfit) || (openPrice >= stopLoss))             
            return true;
      }    
      return false;
   }
   
   void PrintIfWrong(string scope)
   {
      if (IsWrong())
         Utils.Info(scope + " Wrong " + ToString());
   }
   
   void Print()
   {
       Utils.Info(ToString());
   }
   
  
};
  
//+------------------------------------------------------------------+
//| OrderSelection class                                             |
//+------------------------------------------------------------------+
/**
* Container for a selection of orders
*/

class OrderSelection //: public CList
{
   protected:
      Order            *m_array[];
      int              iterator;
      int              m_capacity;
      int              m_size;


   public:
   void OrderSelection(int capacity) // constructor for container
   {
      ArrayResize(m_array, capacity);
      m_capacity = ArraySize(m_array);
      m_size = 0;
      //Print("C-tor OrderSelection"); 
   }

   void DeleteCurrent()
   {
       Order* order = m_array[iterator];
       if (order != NULL)
       {
          delete order;
          m_array[iterator] = NULL;
          //m_size--;
          //iterator++;
          //if (iterator >= m_capacity)
          //  iterator = 0;
       }
   }
   
   Order *GetFirstNode()
   {
      iterator = 0;
      if (m_size==0)
         return NULL;
      return m_array[iterator];
   }

   Order *GetNextNode()
   {
      if (m_size==0)
         return NULL;
      iterator++;
      if (iterator < m_size)
         return m_array[iterator];
      return NULL; // reach the end of array
   }
   
   Order* GetNodeAtIndex(int index)
   {
       if ((m_size==0) || (index >= m_size))
          return NULL;
       iterator = index;
       return m_array[iterator];
   }
   
   void Clear()
   {
       for (int i=0;i<m_capacity;i++){
          Order* order = m_array[i];
          if (order != NULL)
          {
            delete order;
            m_array[i] = NULL;
          }
       }
       m_size = 0;
       iterator = 0;
   }
   
   void Add(Order* order)
   {
       while(m_array[iterator]!=NULL)
       {
           iterator++;
       }
       if (iterator >= m_capacity)
          Utils.Info(StringFormat("Can't add order to collection. Limit %d reached!", m_size));
       m_array[iterator] = order;
       m_size++;
   }

   void ~OrderSelection()  // destructor frees the memory
   {
      Clear();
      //Print("D-tor ~OrderSelection");
   }
   
   void Fill(Order &order)
   {
      //order.ticket = OrderTicket();
      order.type = Utils.OrderType();
      order.magic = Utils.OrderMagicNumber();
      order.lots = Utils.OrderLots();
      order.openPrice = Utils.OrderOpenPrice();
      //order.closePrice = Utils.OrderClosePrice();
      order.openTime = Utils.OrderOpenTime();
      //order.closeTime = Utils.OrderCloseTime();
      order.profit = Utils.OrderProfit();
      order.swap = Utils.OrderSwap();
      order.commission = Utils.OrderCommission();
      order.setRealStopLoss(Utils.OrderStopLoss());
      order.setRealTakeProfit(Utils.OrderTakeProfit());
      order.expiration = Utils.OrderExpiration();
      order.comment = Utils.OrderComment();
      order.symbol = Utils.OrderSymbol();
      order.bDirty = false;
   }
    
   
   void DeleteByTicket(long Ticket)
   {
      Order* foundOrder = SearchOrder(Ticket);
      if (foundOrder != NULL)
      {
         DeleteCurrent();
         Sort();
      } else 
          Utils.Info(StringFormat("Order with this ticket doesn't exist", Ticket));
   }
   
   void Sort()
   {
       int i = 0;
       Order* newarray[];
       ArrayResize(newarray, m_capacity);
       Order* order = NULL;
       int j = 0;
       for(i = 0; i < m_capacity; i++)
       {
           order = m_array[i];
           if (order != NULL)
           {
               newarray[j] = order;
               j++;
           }
       }
       // reinit all m_array with NULL;
       for(i = 0; i < m_capacity; i++)
       {
          m_array[i] = NULL;
       }
       m_size = j;
       for(i = 0; i < m_size;i++)
          m_array[i] = newarray[i];
       iterator = 0;
   }
   
   int Total() 
   {
       return m_size;
   }
   
   int Capacity() 
   {
       return m_capacity;
   }
   
   void RemoveDirtyObsoleteOrders()
   {
      FOREACH_ORDER(this)
      {
         if (order.bDirty && (!order.isPending())) {            
            DeleteCurrent();
         }
      }    
      Sort();  
   }
   
   void MarkOrdersAsDirty()
   {
      FOREACH_ORDER(this)
      {
         if (!order.isPending())
            order.bDirty = true;
      }
   }
   
  Order* SearchOrder(long ticket)
  {
       for (iterator=0;iterator<m_size;iterator++)
       {
          Order* order = m_array[iterator];
          if (order != NULL)
          { 
            if (order.Id() == ticket)
            {
                return order;
            }
          }
       }
       return NULL;
  }

   
};
   
