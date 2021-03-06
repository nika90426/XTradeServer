//+------------------------------------------------------------------+
//|                                                         Deal.mqh |
//|                                                 Sergei Zhuravlev |
//|                                   http://github.com/sergiovision |
//+------------------------------------------------------------------+
#property copyright "Sergei Zhuravlev"
#property link      "http://github.com/sergiovision"
#property strict

#include <Arrays/List.mqh>
#include <XTrade/GenericTypes.mqh>
#include <XTrade/IUtils.mqh>

//+------------------------------------------------------------------+
//| Deal class                                                      |
//+------------------------------------------------------------------+
class Deal : public SerializableEntity
{
   public:
      long              ticket;
      ENUM_DEAL_TYPE    type;
      ENUM_DEAL_ENTRY   entry;
      long     magic;
      double   lots;
      double   openPrice;
      double   closePrice;
      datetime openTime;
      datetime closeTime;
      double   profit;
      double   swap;
      double   commission;
      datetime expiration;
      string   comment;
      string   symbol;
      string   signalName;
      ulong    posTicket;
      ulong    orderId;
   
      void Deal(long Ticket) 
      {    
         ticket = Ticket;
         this.entry  = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);
         this.entry = entry;
         this.openPrice = 0;
         this.closePrice = HistoryDealGetDouble(ticket,DEAL_PRICE);          
         this.closeTime  = (datetime)HistoryDealGetInteger(ticket,DEAL_TIME); 
         this.commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION); 
         this.swap =   HistoryDealGetDouble(ticket, DEAL_SWAP); 
         this.magic =  HistoryDealGetInteger(ticket, DEAL_MAGIC); 
         this.symbol = HistoryDealGetString(ticket, DEAL_SYMBOL); 
         this.type   = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE); 
         this.lots = HistoryDealGetDouble(ticket, DEAL_VOLUME); 
         this.profit = HistoryDealGetDouble(ticket, DEAL_PROFIT); 
         this.posTicket = (ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID); 
         this.orderId = (ulong)HistoryDealGetInteger(ticket, DEAL_ORDER);
      }
   
      void Deal(string fromJson)
      {
         if (StringLen(fromJson) <= 0)
            return;
         obj.Deserialize(fromJson);
         type = (ENUM_DEAL_TYPE)obj["Type"].ToInt();
         lots = obj["Lots"].ToDbl();
         symbol = obj["Symbol"].ToStr();
         if (obj.FindKey("Magic"))
           magic = obj["Magic"].ToInt();
      }
    
    virtual CJAVal* Persistent()
    {
         obj["Ticket"] = (int)ticket;
         obj["Type"] = (int)type;
         obj["Magic"] = this.magic;
         obj["Symbol"] = symbol;
         obj["Lots"] = lots;
         obj["OpenPrice"] = openPrice;
         obj["ClosePrice"] = closePrice;
         obj["OpenTime"] = TimeToString(openTime);
         obj["CloseTime"] = TimeToString(closeTime);
         obj["Profit"] = profit;
         obj["SwapValue"] = swap;
         obj["Comission"] = commission;
         obj["Account"] = Utils.GetAccountNumer();
         obj["AccountName"] = IntegerToString(Utils.GetAccountNumer());
         obj["Comment"] = comment;
         obj["OrderId"] = (long)orderId;
         return &obj;
    }
    
    virtual void ~Deal()
    {
         
    }
};

